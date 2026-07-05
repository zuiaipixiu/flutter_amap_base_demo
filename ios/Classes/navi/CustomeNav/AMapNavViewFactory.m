//
//  AMapNavViewFactory.m
//  amap_base
//
//  Created by tengfei on 2020/3/16.
//

#import "AMapNavViewFactory.h"
#import <AMapNaviKit/MAMapView.h>
#import "MapNavModels.h"
#import "AMapBasePlugin.h"
#import "UnifiedAssets.h"
#import "MJExtension.h"
#import "NSString+Color.h"
#import "FunctionRegistry.h"
#import "MapHandlers.h"
#import "MarkTool.h"
#import "NavViewTopView.h"
#import "CommonDefine.h"

//获取设备屏幕尺寸
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

//获取相关高度
#define TY_StatusBarHeight          \
[[UIApplication sharedApplication] statusBarFrame].size.height  //状态栏高度
#define TY_NavBarHeight 44.0                                        //NavBar高度
#define TY_TabBarHeight (TY_StatusBarHeight > 20 ? 83 : 49)         //底部tabbar高度
#define TY_NavTopHeight (TY_StatusBarHeight + TY_NavBarHeight)      //整个导航栏高度


static NSString *mapNavChannelName = @"me.yohom/map_nav";
static NSString *naviInfoChannelName = @"me.yohom/navi_info";

@interface NavInfoEventHandler : NSObject <FlutterStreamHandler>
@property(nonatomic, copy) FlutterEventSink sink;
@end

@implementation NavInfoEventHandler
- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events {
    self.sink = events;
    return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    self.sink = nil;
    return nil;
}
@end

@implementation AMapNavViewFactory {
}

- (NSObject <FlutterMessageCodec> *)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject <FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                     viewIdentifier:(int64_t)viewId
                                          arguments:(id _Nullable)args {
  AMapNavViewOptions *options = [self parseNavOptions:args];

    AMapNavView *navView = [[AMapNavView alloc] initWithFrame:frame options:options viewIdentifier:viewId];

    return navView;
}

- (AMapNavViewOptions *)parseNavOptions:(id)args {
    id jsonObject = args;
    if ([args isKindOfClass:[NSString class]]) {
        NSData *data = [(NSString *)args dataUsingEncoding:NSUTF8StringEncoding];
        jsonObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    }
    AMapNavViewOptions *options = [AMapNavViewOptions mj_objectWithKeyValues:jsonObject];
    return options ?: [[AMapNavViewOptions alloc] init];
}

@end

@interface AMapNavView ()
/** 驾车导航视图 */
@property (nonatomic, strong) AMapNaviDriveView *driveView;
/** 地图导航参数 */
@property (nonatomic, strong) AMapNavViewOptions *options;
/** 导航顶部视图 */
@property (nonatomic, strong) NavViewTopView *topInfoView;


@property (nonatomic, strong) UIImageView *crossImageView;
@property (nonatomic, strong) UIButton *rightBrowserBtn;
@property (nonatomic, strong) UIView *trafficBarView;
@property (nonatomic, strong) UIButton *rightTrafficBtn;

@property (nonatomic, strong) FlutterMethodChannel *methodChannel;
@property (nonatomic, strong) FlutterEventChannel *naviInfoEventChannel;
@property (nonatomic, strong) NavInfoEventHandler *naviInfoEventHandler;


@end

@implementation AMapNavView

{
  CGRect _frame;
  int64_t _viewId;
  BOOL _navigationTornDown;
}


- (UIImageView *)crossImageView {
    if (!_crossImageView) {
        _crossImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    }
    return _crossImageView;
}

- (UIButton *)rightBrowserBtn {
    if (!_rightBrowserBtn) {
        _rightBrowserBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//        _rightBrowserBtn.backgroundColor = [UIColor redColor];
        [_rightBrowserBtn setImage:[UIImage imageNamed:@"default_navi_browse_ver_normal"] forState:UIControlStateNormal];
        [_rightBrowserBtn setImage:[UIImage imageNamed:@"default_navi_browse_ver_selected"] forState:UIControlStateSelected];

        [_rightBrowserBtn addTarget:self action:@selector(browserBtn:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _rightBrowserBtn;
}


- (UIView *)trafficBarView {
    if (!_trafficBarView) {
        // Newer AMapNavi iOS SDKs no longer expose the legacy traffic bar view.
        // Keep a lightweight placeholder view so the rest of the custom layout
        // and show/hide logic can continue to work without build-time SDK coupling.
        _trafficBarView = [[UIView alloc] initWithFrame:CGRectZero];
        _trafficBarView.hidden = YES;
    }
    return _trafficBarView;
}

- (UIButton *)rightTrafficBtn {
    if (!_rightTrafficBtn) {
        _rightTrafficBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightTrafficBtn setImage:[UIImage imageNamed:@"default_navi_traffic_open_normal"] forState:UIControlStateNormal];
        [_rightTrafficBtn setImage:[UIImage imageNamed:@"default_navi_traffic_close_normal"] forState:UIControlStateSelected];
//        _rightTrafficBtn.backgroundColor = [UIColor greenColor];

        [_rightBrowserBtn addTarget:self action:@selector(trafficBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _rightTrafficBtn;
}


- (instancetype)initWithFrame:(CGRect)frame
                      options:(AMapNavViewOptions *)options
               viewIdentifier:(int64_t)viewId {
  self = [super init];
  if (self) {
    _frame = frame;
    _viewId = viewId;
    self.options = options;
    self.driveView.frame = frame;
    [self setup];
  }
  return self;
}

- (UIView *)view {
  if (_navigationTornDown || !_driveView) {
    static UIView *placeholderView;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      placeholderView = [[UIView alloc] initWithFrame:CGRectZero];
    });
    return placeholderView;
  }
  return self.driveView;
}


- (AMapNaviDriveView *)driveView {
    if (_navigationTornDown) {
        return _driveView;
    }
    if (!_driveView) {
        _driveView = [[AMapNaviDriveView alloc] initWithFrame:CGRectZero];
        
        //region 初始化地图配置
        self.driveView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.driveView.showUIElements = NO;
        self.driveView.showCrossImage = NO;
        self.driveView.showTrafficBar = NO;
        self.driveView.showGreyAfterPass = YES;
        self.driveView.autoZoomMapLevel = YES;
        self.driveView.mapViewModeType = AMapNaviViewMapModeTypeDayNightAuto;
        self.driveView.autoSwitchShowModeToCarPositionLocked = YES;
        self.driveView.trackingMode = AMapNaviViewTrackingModeCarNorth;
        self.driveView.logoCenter = CGPointMake(self.driveView.logoCenter.x + 2, self.driveView.logoCenter.y + 60);
        
        [self.driveView addSubview:self.topInfoView];
        
        

        //driveManager 请在 dealloc 函数中执行 [AMapNaviDriveManager destroyInstance] 来销毁单例
        [[AMapNaviDriveManager sharedInstance] setDelegate:self];
        [[AMapNaviDriveManager sharedInstance] setIsUseInternalTTS:YES];

        // 示例仅前台导航，未开启 Background Modes -> Location updates，
        // 开启后台定位会导致 CLLocationManager 断言崩溃。
        [[AMapNaviDriveManager sharedInstance] setAllowsBackgroundLocationUpdates:NO];
        [[AMapNaviDriveManager sharedInstance] setPausesLocationUpdatesAutomatically:NO];
        
        // 将 self、driveView 添加为导航数据的 Representative。
        // iOS 新版 SDK 已不再提供旧 traffic bar view，这里降级跳过该能力。
        [[AMapNaviDriveManager sharedInstance] addDataRepresentative:self.driveView];
        [[AMapNaviDriveManager sharedInstance] addDataRepresentative:self];
        
         self.driveView.delegate = self;
        
        
    }
    return _driveView;;
}

- (void)tearDownNavigationResources {
    if (_navigationTornDown) {
        return;
    }
    _navigationTornDown = YES;
    DLog(@"nav view release resources viewId=%lld", _viewId);

    AMapNaviDriveManager *driveManager = [AMapNaviDriveManager sharedInstance];
    [driveManager stopNavi];
    [driveManager setDelegate:nil];
    if (_driveView) {
        [driveManager removeDataRepresentative:_driveView];
        _driveView.delegate = nil;
        [_driveView removeFromSuperview];
    }
    [driveManager removeDataRepresentative:self];
    [AMapNaviDriveManager destroyInstance];

    self.crossImageView.image = nil;
    _driveView = nil;
    [_methodChannel setMethodCallHandler:nil];
    [_naviInfoEventChannel setStreamHandler:nil];
    self.naviInfoEventHandler.sink = nil;
}

- (FlutterMethodChannel *)methodChannel {
    if (!_methodChannel) {
        _methodChannel = [FlutterMethodChannel methodChannelWithName:[NSString stringWithFormat:@"%@%lld", mapNavChannelName, _viewId] binaryMessenger:[AMapBasePlugin registrar].messenger];
    }
    return _methodChannel;
}


- (NavViewTopView *)topInfoView {
    if (!_topInfoView) {
        _topInfoView = [[NavViewTopView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, top_total_H)];
    }
    return _topInfoView;
}

- (NSInteger)resolveSelectedRouteID:(AMapNaviDriveManager *)driveManager {
    NSArray<NSNumber *> *routeIDs = driveManager.naviRouteIDs;
    if (routeIDs.count == 0) {
        return 0;
    }

    NSDictionary<NSNumber *, AMapNaviRoute *> *naviRoutes = driveManager.naviRoutes;
    if (naviRoutes.count == 0) {
        return [routeIDs.firstObject integerValue];
    }

    const CGFloat targetLat = self.options.selectedRouteMidLatitude;
    const CGFloat targetLng = self.options.selectedRouteMidLongitude;
    const BOOL hasRouteMidpoint = fabs(targetLat) > 1.0 || fabs(targetLng) > 1.0;
    if (hasRouteMidpoint) {
        NSNumber *bestRouteID = routeIDs.firstObject;
        CGFloat bestScore = CGFLOAT_MAX;
        for (NSNumber *routeID in routeIDs) {
            AMapNaviRoute *route = naviRoutes[routeID];
            NSArray<AMapNaviPoint *> *coords = route.routeCoordinates;
            if (route == nil || coords.count == 0) {
                continue;
            }
            AMapNaviPoint *midPoint = coords[coords.count / 2];
            const CGFloat dLat = fabs(midPoint.latitude - targetLat);
            const CGFloat dLng = fabs(midPoint.longitude - targetLng);
            const CGFloat score = dLat + dLng;
            if (score < bestScore) {
                bestScore = score;
                bestRouteID = routeID;
            }
        }
        return bestRouteID.integerValue;
    }

    if (self.options.selectedRouteDistance > 0) {
        NSNumber *bestRouteID = routeIDs.firstObject;
        NSInteger bestScore = NSIntegerMax;
        for (NSNumber *routeID in routeIDs) {
            AMapNaviRoute *route = naviRoutes[routeID];
            if (route == nil) {
                continue;
            }
            NSInteger distanceDiff = labs(route.routeLength - self.options.selectedRouteDistance);
            NSInteger durationDiff = 0;
            if (self.options.selectedRouteDuration > 0) {
                durationDiff = labs(route.routeTime - self.options.selectedRouteDuration);
            }
            NSInteger score = distanceDiff * 10 + durationDiff;
            if (score < bestScore) {
                bestScore = score;
                bestRouteID = routeID;
            }
        }
        return bestRouteID.integerValue;
    }

    NSInteger index = self.options.selectedRouteIndex;
    if (index < 0 || index >= routeIDs.count) {
        index = 0;
    }
    return [routeIDs[index] integerValue];
}

- (void)calculateDriveRouteFromStart:(AMapNaviPoint *)startNavPoint
                               toEnd:(AMapNaviPoint *)endNavPoint {
    AMapNaviDriveManager *driveManager = [AMapNaviDriveManager sharedInstance];
    if (self.options.hasPlannedRoutes) {
        [driveManager setMultipleRouteNaviMode:YES];
        [driveManager calculateDriveRouteWithStartPoints:@[startNavPoint]
                                               endPoints:@[endNavPoint]
                                               wayPoints:nil
                                         drivingStrategy:AMapNaviDrivingStrategyMultipleDefault];
    } else {
        [driveManager setMultipleRouteNaviMode:NO];
        [driveManager calculateDriveRouteWithStartPoints:@[startNavPoint]
                                               endPoints:@[endNavPoint]
                                               wayPoints:nil
                                         drivingStrategy:AMapNaviDrivingStrategySinglePrioritiseDistance];
    }
}

- (void)setup {
    
    CGFloat bottomContentH = self.options.bottomContentH;
    
    [self updateUILayoutWithBottomH:bottomContentH];
    
    //为了方便展示,选择了固定的起终点
    CLLocationCoordinate2D startPoint = [self.options.startLocation toCLLocationCoordinate2D];
    CLLocationCoordinate2D endPoint = [self.options.endLocation toCLLocationCoordinate2D];
    
    
    AMapNaviPoint *startNavPoint = [AMapNaviPoint locationWithLatitude:startPoint.latitude longitude:startPoint.longitude];
    AMapNaviPoint *endNavPoint   = [AMapNaviPoint locationWithLatitude:endPoint.latitude longitude:endPoint.longitude];
    
    [self calculateDriveRouteFromStart:startNavPoint toEnd:endNavPoint];
       
    
    
    //endregion

    self.naviInfoEventHandler = [[NavInfoEventHandler alloc] init];
    self.naviInfoEventChannel = [FlutterEventChannel eventChannelWithName:[NSString stringWithFormat:@"%@%lld", naviInfoChannelName, _viewId]
                                                          binaryMessenger:[AMapBasePlugin registrar].messenger];
    [self.naviInfoEventChannel setStreamHandler:self.naviInfoEventHandler];

    [self.methodChannel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
        
      NSString *callMethod = call.method;
      NSDictionary *paramDic = call.arguments;

      DLog(@"nav call method = %@, param = %@",callMethod, paramDic);
      
      if ([call.method isEqualToString:@"nav#changeMapRouteNaviWithInfo"]) {
          
          NSString *startLocationJson = (NSString *) paramDic[@"startLocation"];
          LatLng *startParamPoint = [LatLng mj_objectWithKeyValues:startLocationJson];
          
          NSString *endLocationJson = (NSString *) paramDic[@"endLocation"];
          LatLng *endParamPoint = [LatLng mj_objectWithKeyValues:endLocationJson];
          
          NSNumber *useEmulatorNavi = paramDic[@"useEmulatorNavi"];
          if (useEmulatorNavi != nil) {
              self.options.useEmulatorNavi = useEmulatorNavi.boolValue;
          }

          NSNumber *selectedRouteIndex = paramDic[@"selectedRouteIndex"];
          if (selectedRouteIndex != nil) {
              self.options.selectedRouteIndex = selectedRouteIndex.integerValue;
          }

          NSNumber *hasPlannedRoutes = paramDic[@"hasPlannedRoutes"];
          if (hasPlannedRoutes != nil) {
              self.options.hasPlannedRoutes = hasPlannedRoutes.boolValue;
          }

          NSNumber *selectedRouteDistance = paramDic[@"selectedRouteDistance"];
          if (selectedRouteDistance != nil) {
              self.options.selectedRouteDistance = selectedRouteDistance.integerValue;
          }

          NSNumber *selectedRouteDuration = paramDic[@"selectedRouteDuration"];
          if (selectedRouteDuration != nil) {
              self.options.selectedRouteDuration = selectedRouteDuration.integerValue;
          }

          NSNumber *selectedRouteMidLatitude = paramDic[@"selectedRouteMidLatitude"];
          if (selectedRouteMidLatitude != nil) {
              self.options.selectedRouteMidLatitude = selectedRouteMidLatitude.doubleValue;
          }

          NSNumber *selectedRouteMidLongitude = paramDic[@"selectedRouteMidLongitude"];
          if (selectedRouteMidLongitude != nil) {
              self.options.selectedRouteMidLongitude = selectedRouteMidLongitude.doubleValue;
          }
          
          AMapNaviPoint *startParamNavPoint = [AMapNaviPoint locationWithLatitude:startParamPoint.latitude longitude:startParamPoint.longitude];
          AMapNaviPoint *endParamNavPoint   = [AMapNaviPoint locationWithLatitude:endParamPoint.latitude longitude:endParamPoint.longitude];
          
          self.options.startLocation = startParamPoint;
          self.options.endLocation = endParamPoint;

          [[AMapNaviDriveManager sharedInstance] stopNavi];
          [self calculateDriveRouteFromStart:startParamNavPoint toEnd:endParamNavPoint];
          
 
      } else if([callMethod isEqualToString:@"nav#stopCustomeNavi"]){
          [[AMapNaviDriveManager sharedInstance] stopNavi];
      } else if([callMethod isEqualToString:@"nav#destroyCustomeNavi"]){
          [self tearDownNavigationResources];
      }
           result(navSuccess);

  }];


}

- (void)updateUILayoutWithBottomH:(CGFloat)bottom_H{
    
    
//    if (bottom_H == 0) {
//        bottom_H = 100;
//    }
      double statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;

        double topSafeAreaHeight = (statusBarHeight);

    
    CGFloat final_bottom_H = iOSMarginWithPx(bottom_H);
    
    CGFloat driverView_H = SCREEN_HEIGHT - top_total_H - 10 - final_bottom_H - TY_NavTopHeight + topSafeAreaHeight;
    
    
    NSLog(@"update bottom with %f final_bottom_H = %f ",driverView_H, final_bottom_H);

    
    [self.driveView addSubview:self.trafficBarView];
    self.trafficBarView.frame = CGRectMake(10, top_total_H + 10 + topSafeAreaHeight , 10, 150);
    self.trafficBarView.hidden = YES;
    
    CGFloat browBtn_Y = SCREEN_HEIGHT - final_bottom_H - 45 - TY_NavTopHeight;
    
    
    //隐藏全览按钮
//    [self.driveView addSubview:self.rightBrowserBtn];
//    self.rightBrowserBtn.frame = CGRectMake(SCREEN_WIDTH - 50, browBtn_Y + 100, 45, 45);
    
    
//    [self.driveView addSubview:self.rightTrafficBtn];
//    self.rightTrafficBtn.frame = CGRectMake(SCREEN_WIDTH - 50, topInfo_H + 150, 40, 40);
    
    [self.driveView addSubview:self.crossImageView];
    self.crossImageView.frame = CGRectMake(0, top_total_H + topSafeAreaHeight, SCREEN_WIDTH, SCREEN_WIDTH / 25 * 16);
    self.crossImageView.hidden = YES;

    

    
    
}




#pragma mark - AMapNaviDriveManager Delegate

- (void)driveManagerOnCalculateRouteSuccess:(AMapNaviDriveManager *)driveManager {
    DLog(@"onCalculateRouteSuccess");

    if (self.options.hasPlannedRoutes) {
        NSInteger routeID = [self resolveSelectedRouteID:driveManager];
        [driveManager selectNaviRouteWithRouteID:routeID];
    }
    
    //算路成功后开始导航（虚拟导航 / GPS 导航）
    if (self.options.useEmulatorNavi) {
        [[AMapNaviDriveManager sharedInstance] startEmulatorNavi];
    } else {
        [[AMapNaviDriveManager sharedInstance] startGPSNavi];
    }
}

#pragma mark - AMapNaviDriveDataRepresentable

//诱导信息
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateNaviInfo:(AMapNaviInfo *)naviInfo {
    if (naviInfo) {

        if (self.topInfoView.topInfoBgView.hidden) {
            self.topInfoView.topInfoBgView.hidden = self.topInfoView.routeRemianInfoView.hidden = NO;
        }

        self.topInfoView.topRemainLabel.text = [NSString stringWithFormat:@"%@后",[self normalizedRemainDistance:naviInfo.segmentRemainDistance]];
        self.topInfoView.topRoadLabel.text = naviInfo.nextRoadName;

        NSString *remainTime = [self normalizedRemainTime:naviInfo.routeRemainTime];
        NSString *remainDis = [self normalizedRemainDistance:naviInfo.routeRemainDistance];
        self.topInfoView.routeRemainDistanceLabel.text = [NSString stringWithFormat:@"剩余 %@",remainDis];

        self.topInfoView.routeRemainTimeLabel.text = [NSString stringWithFormat:@"需要 %@",remainTime];

        if (self.naviInfoEventHandler.sink) {
            self.naviInfoEventHandler.sink(@{
                @"routeRemainDistance": @(naviInfo.routeRemainDistance),
                @"routeRemainTime": @(naviInfo.routeRemainTime),
            });
        }

    }
}

//转向图标
- (void)driveManager:(AMapNaviDriveManager *)driveManager updateTurnIconImage:(UIImage *)turnIconImage turnIconType:(AMapNaviIconType)turnIconType {
    if (turnIconImage) {
        self.topInfoView.topTurnImageView.image = turnIconImage;
    }
}

//显示路口放大图
- (void)driveManager:(AMapNaviDriveManager *)driveManager showCrossImage:(UIImage *)crossImage {
    // 不展示车道级/路口放大图
}

//隐藏路口放大图
- (void)driveManagerHideCrossImage:(AMapNaviDriveManager *)driveManager {
    // 不展示车道级/路口放大图
}

#pragma mark - AMapNaviDriveViewDelegate

- (void)driveView:(AMapNaviDriveView *)driveView didChangeDayNightType:(BOOL)showStandardNightType {
    DLog(@"didChangeDayNightType:%ld", (long)showStandardNightType);
}

- (void)driveView:(AMapNaviDriveView *)driveView didChangeOrientation:(BOOL)isLandscape {
    DLog(@"didChangeOrientation:%ld", (long)isLandscape);

//    [self setNeedsStatusBarAppearanceUpdate];  //更新状态栏颜色
    if (self.driveView.showMode == AMapNaviDriveViewShowModeOverview) {  //如果是全览状态，重新适应一下全览路线，让其均可见
        [self.driveView updateRoutePolylineInTheVisualRangeWhenTheShowModeIsOverview];
    }
}

- (void)driveView:(AMapNaviDriveView *)driveView didChangeShowMode:(AMapNaviDriveViewShowMode)showMode {
    if (showMode == AMapNaviDriveViewShowModeOverview) {
        self.rightBrowserBtn.selected = YES;
    } else {
        self.rightBrowserBtn.selected = NO;
    }

    if (showMode != AMapNaviDriveViewShowModeCarPositionLocked) {  //非锁车，隐藏路口放大图
        self.crossImageView.hidden = YES;
        self.crossImageView.image = nil;
    }
}

//处理路口放大图
- (void)handleWhenCrossImageShowAndHide:(UIImage *)crossImage {
    self.crossImageView.hidden = YES;
    self.crossImageView.image = nil;
    self.trafficBarView.hidden = YES;
}

//返回边界Padding，来规定可见区域
- (UIEdgeInsets)driveViewEdgePadding:(AMapNaviDriveView *)driveView {

    CGFloat bottomContentH = self.options.bottomContentH;
    
//    if (bottomContentH == 0) {
//        bottomContentH = 100;
//    }

    //top left bottom right
    CGFloat offset = 20;
    CGFloat top = top_total_H ;
    CGFloat horizontal = 60;
    CGFloat left = horizontal;
    CGFloat bottom = bottomContentH;
    CGFloat right = horizontal;

    UIEdgeInsets insets = UIEdgeInsetsMake(top + offset, left, bottom, right);

    return insets;
}

#pragma mark - Button Click

 

- (void)trafficBtnClick:(id)sender {
    UIButton *btn = (UIButton *)sender;
    self.driveView.mapShowTraffic = !self.driveView.mapShowTraffic;
    btn.selected = !self.driveView.mapShowTraffic;
}

- (void)browserBtn:(id)sender {
    if (self.driveView.showMode == AMapNaviDriveViewShowModeOverview) {
        self.driveView.showMode = AMapNaviDriveViewShowModeCarPositionLocked;
    } else {
        self.driveView.showMode = AMapNaviDriveViewShowModeOverview;
    }
}

#pragma mark - Utility

- (BOOL)isiPhoneX {
    return [UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO;
}

- (NSString *)normalizedRemainDistance:(NSInteger)remainDistance {
    
    if (remainDistance < 0) {
        return nil;
    }
    
    if (remainDistance >= 1000) {
        CGFloat kiloMeter = remainDistance / 1000.0;
        return [NSString stringWithFormat:@"%.1f公里", kiloMeter];
    } else {
        return [NSString stringWithFormat:@"%ld米", (long)remainDistance];
    }
}

- (NSString *)normalizedRemainTime:(NSInteger)remainTime {
    if (remainTime < 0) {
        return nil;
    }
    
    if (remainTime < 60) {
        return [NSString stringWithFormat:@"< 1分钟"];
    } else if (remainTime >= 60 && remainTime < 60*60) {
        return [NSString stringWithFormat:@"%ld分钟", (long)remainTime/60];
    } else {
        NSInteger hours = remainTime / 60 / 60;
        NSInteger minute = remainTime / 60 % 60;
        if (minute == 0) {
            return [NSString stringWithFormat:@"%ld小时", (long)hours];
        } else {
            return [NSString stringWithFormat:@"%ld小时%ld分钟", (long)hours, (long)minute];
        }
    }
}


- (void)dealloc
{
    DLog(@"nav view dealloc");
    [self tearDownNavigationResources];
    self.topInfoView = nil;
    self.trafficBarView = nil;
    self.naviInfoEventChannel = nil;
    self.naviInfoEventHandler = nil;
    self.methodChannel = nil;
}



@end

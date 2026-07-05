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

@implementation AMapNavViewFactory {
}

- (NSObject <FlutterMessageCodec> *)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject <FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                     viewIdentifier:(int64_t)viewId
                                          arguments:(id _Nullable)args {
  AMapNavViewOptions *options = [AMapNavViewOptions mj_objectWithKeyValues:(NSString *) args];
    

    AMapNavView *navView = [[AMapNavView alloc] initWithFrame:frame options:options viewIdentifier:viewId];

    return navView;
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


@end

@implementation AMapNavView

{
  CGRect _frame;
  int64_t _viewId;
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
  return self.driveView;
}


- (AMapNaviDriveView *)driveView {
    if (!_driveView) {
        _driveView = [[AMapNaviDriveView alloc] initWithFrame:CGRectZero];
        
        //region 初始化地图配置
        self.driveView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.driveView.showUIElements = NO;
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
        
        [[AMapNaviDriveManager sharedInstance] setAllowsBackgroundLocationUpdates:YES];
        [[AMapNaviDriveManager sharedInstance] setPausesLocationUpdatesAutomatically:NO];
        
        // 将 self、driveView 添加为导航数据的 Representative。
        // iOS 新版 SDK 已不再提供旧 traffic bar view，这里降级跳过该能力。
        [[AMapNaviDriveManager sharedInstance] addDataRepresentative:self.driveView];
        [[AMapNaviDriveManager sharedInstance] addDataRepresentative:self];
        
         self.driveView.delegate = self;
        
        
    }
    return _driveView;;
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

- (void)setup {
    
    CGFloat bottomContentH = self.options.bottomContentH;
    
    [self updateUILayoutWithBottomH:bottomContentH];
    
    //为了方便展示,选择了固定的起终点
    CLLocationCoordinate2D startPoint = [self.options.startLocation toCLLocationCoordinate2D];
    CLLocationCoordinate2D endPoint = [self.options.endLocation toCLLocationCoordinate2D];
    
    
    AMapNaviPoint *startNavPoint = [AMapNaviPoint locationWithLatitude:startPoint.latitude longitude:startPoint.longitude];
    AMapNaviPoint *endNavPoint   = [AMapNaviPoint locationWithLatitude:endPoint.latitude longitude:endPoint.longitude];
    
    
    
       //算路
    [[AMapNaviDriveManager sharedInstance] calculateDriveRouteWithStartPoints:@[startNavPoint]
                                                                       endPoints:@[endNavPoint]
                                                                       wayPoints:nil
                                                           drivingStrategy:AMapNaviDrivingStrategySinglePrioritiseDistance];
       
    
    
    //endregion

    [self.methodChannel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
        
      NSString *callMethod = call.method;
      NSDictionary *paramDic = call.arguments;

      DLog(@"nav call method = %@, param = %@",callMethod, paramDic);
      
      if ([call.method isEqualToString:@"nav#changeMapRouteNaviWithInfo"]) {
          
          NSString *startLocationJson = (NSString *) paramDic[@"startLocation"];
          LatLng *startParamPoint = [LatLng mj_objectWithKeyValues:startLocationJson];
          
          NSString *endLocationJson = (NSString *) paramDic[@"endLocation"];
          LatLng *endParamPoint = [LatLng mj_objectWithKeyValues:endLocationJson];
          
          
          AMapNaviPoint *startParamNavPoint = [AMapNaviPoint locationWithLatitude:startParamPoint.latitude longitude:startParamPoint.longitude];
          AMapNaviPoint *endParamNavPoint   = [AMapNaviPoint locationWithLatitude:endParamPoint.latitude longitude:endParamPoint.longitude];
          
          
          //驾车算路
          [[AMapNaviDriveManager sharedInstance] calculateDriveRouteWithStartPoints:@[startParamNavPoint]
                                                                          endPoints:@[endParamNavPoint]
                                                                          wayPoints:nil
                                                                    drivingStrategy:AMapNaviDrivingStrategySinglePrioritiseDistance];
          
 
      } else if([callMethod isEqualToString:@"nav#stopCustomeNavi"]){
          [[AMapNaviDriveManager sharedInstance] stopNavi];
      } else if([callMethod isEqualToString:@"nav#destroyCustomeNavi"]){
          [AMapNaviDriveManager destroyInstance];
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
    
    CGFloat browBtn_Y = SCREEN_HEIGHT - final_bottom_H - 45 - TY_NavTopHeight;
    
    
    //隐藏全览按钮
//    [self.driveView addSubview:self.rightBrowserBtn];
//    self.rightBrowserBtn.frame = CGRectMake(SCREEN_WIDTH - 50, browBtn_Y + 100, 45, 45);
    
    
//    [self.driveView addSubview:self.rightTrafficBtn];
//    self.rightTrafficBtn.frame = CGRectMake(SCREEN_WIDTH - 50, topInfo_H + 150, 40, 40);
    
    [self.driveView addSubview:self.crossImageView];
    self.crossImageView.frame = CGRectMake(0, top_total_H + topSafeAreaHeight, SCREEN_WIDTH, SCREEN_WIDTH / 25 * 16);

    

    
    
}




#pragma mark - AMapNaviDriveManager Delegate

- (void)driveManagerOnCalculateRouteSuccess:(AMapNaviDriveManager *)driveManager {
    DLog(@"onCalculateRouteSuccess");
    
    //算路成功后开始导航
    [[AMapNaviDriveManager sharedInstance] startGPSNavi];
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
    [self handleWhenCrossImageShowAndHide:crossImage];
}

//隐藏路口放大图
- (void)driveManagerHideCrossImage:(AMapNaviDriveManager *)driveManager {
    [self handleWhenCrossImageShowAndHide:nil];
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
        [self handleWhenCrossImageShowAndHide:nil];
    }
}

//处理路口放大图
- (void)handleWhenCrossImageShowAndHide:(UIImage *)crossImage {
    if (crossImage && self.driveView.showMode == AMapNaviDriveViewShowModeCarPositionLocked) {
        self.crossImageView.hidden = NO;
        self.crossImageView.image = crossImage;
        self.rightBrowserBtn.hidden = YES;
        self.rightTrafficBtn.hidden = YES;
        self.topInfoView.routeRemianInfoView.hidden = YES;
        self.trafficBarView.hidden = YES;
     } else {
        self.crossImageView.hidden = YES;
        self.crossImageView.image = nil;
        self.rightBrowserBtn.hidden = NO;
        self.rightTrafficBtn.hidden = NO;
        self.topInfoView.routeRemianInfoView.hidden = NO;
        self.trafficBarView.hidden = NO;
    }
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
    CGFloat left = 40;
    CGFloat bottom = bottomContentH;
    CGFloat right = 80;

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
    [AMapNaviDriveManager destroyInstance];
    self.driveView = nil;
    self.topInfoView = nil;
    self.trafficBarView = nil;
    self.methodChannel = nil;
    
    
}



@end

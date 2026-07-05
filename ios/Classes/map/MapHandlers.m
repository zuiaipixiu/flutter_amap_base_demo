//
// Created by Yohom Bao on 2018-12-15.
//

#import "MapHandlers.h"
#import <CoreLocation/CoreLocation.h>
#import <AMapNaviKit/MAMapView.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
#import "AMapViewFactory.h"
#import "MapModels.h"
#import "MJExtension.h"
#import "UnifiedAssets.h"
#import "CustomCalloutAnnotationView.h"
#import "MarkTool.h"
#import "CommonDefine.h"

/** 司机位置获取频率 */
#define driver_update_frequency             1

/** 司机获取位置预估距离， 小于预估距离车头角度不改变 */
#define driver_update_dis_forecast          20


@implementation SetCustomMapStyleID {
    MAMapView *_mapView;
}

- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;
    NSString *styleId = (NSString *) paramDic[@"styleId"];

    DLog(@"方法map#setCustomMapStyleID iOS: styleId -> %@", styleId);

//   [_mapView setCustomMapStyleID:styleId];
    result(success);
}

@end

@implementation SetCustomMapStylePath {
    MAMapView *_mapView;
}

- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;
    NSString *path = (NSString *) paramDic[@"path"];

    DLog(@"方法map#setCustomMapStylePath iOS: path -> %@", path);

    NSData *data = [NSData dataWithContentsOfFile:[UnifiedAssets getAssetPath:path]];
//   [_mapView setCustomMapStyleWithWebData:data];
    result(success);
}

@end

@implementation SetMapCustomEnable {
    MAMapView *_mapView;
}

- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;
    BOOL enabled = [paramDic[@"enabled"] boolValue];

    DLog(@"方法map#setMapCustomEnable iOS: enabled -> %d", enabled);

    [_mapView setCustomMapStyleEnabled:enabled];

    result(success);
}

@end

@implementation ConvertCoordinate {
    MAMapView *_mapView;
}

- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;
    CGFloat lat = [paramDic[@"lat"] floatValue];
    CGFloat lon = [paramDic[@"lon"] floatValue];
    int intType = [paramDic[@"type"] intValue];
    AMapCoordinateType type = [self convertTypeWithInt:intType];
    CLLocationCoordinate2D coordinate2D = AMapCoordinateConvert(CLLocationCoordinate2DMake(lat, lon), type);
    NSString *r = [NSString stringWithFormat:@"{\"latitude\":%f,\"longitude\":%f}", coordinate2D.latitude, coordinate2D.longitude];
    result(r);
}

- (AMapCoordinateType)convertTypeWithInt:(int)type {
    switch (type) {
        case 0:
            return AMapCoordinateTypeGPS;
        case 1:
            return AMapCoordinateTypeBaidu;
        case 2:
            return AMapCoordinateTypeMapBar;
        case 3:
            return AMapCoordinateTypeMapABC;
        case 4:
            return AMapCoordinateTypeSoSoMap;
        case 5:
            return AMapCoordinateTypeAliYun;
        case 6:
            return AMapCoordinateTypeGoogle;
        default:
            return AMapCoordinateTypeGPS;
    }
}

@end

@implementation CalcDistance{
    MAMapView *_mapView;
}

- (NSObject<MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *params = [call arguments];
    NSDictionary *p1 = [params valueForKey:@"p1"];
    NSDictionary *p2 = [params valueForKey:@"p2"];
    CLLocationDistance distance = MAMetersBetweenMapPoints([self getPointFromDict:p1],[self getPointFromDict:p2]);
    result([NSNumber numberWithDouble:distance]);
}

-(MAMapPoint) getPointFromDict:(NSDictionary *) dict {
    CGFloat lat = [[dict valueForKey:@"latitude"] floatValue];
    CGFloat lng = [[dict valueForKey:@"longitude"] floatValue];
    return MAMapPointForCoordinate(CLLocationCoordinate2DMake(lat,lng));
}

@end

@implementation GetCenterPoint{
     MAMapView *_mapView;
}

- (NSObject<MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    CLLocationCoordinate2D coor = _mapView.centerCoordinate;
    LatLng *latlng = [LatLng new];
    latlng.latitude = coor.latitude;
    latlng.longitude = coor.longitude;
    result([latlng mj_JSONString]);
}

@end

@implementation ClearMap {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    [_mapView removeOverlays:_mapView.overlays];
    [_mapView removeAnnotations:_mapView.annotations];

    result(success);
}

@end

@implementation OpenOfflineManager {

}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    UIViewController *ctl = [MAOfflineMapViewController sharedInstance];
    UINavigationController *naviCtl = [[UINavigationController alloc] initWithRootViewController:ctl];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
    
//    UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
    
    [[ctl navigationItem]setLeftBarButtonItem:item];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController: naviCtl animated:YES completion:nil];
}

-(void)dismiss{
    UIViewController *ctl = [MAOfflineMapViewController sharedInstance];
    if([ctl navigationController]){
        [[ctl navigationController] dismissViewControllerAnimated:true completion:nil];
    }
}

@end

@implementation SetLanguage {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;

    // 由于iOS端是从0开始算的, 所以这里减去1
    NSString *language = (NSString *) paramDic[@"language"];

    DLog(@"方法map#setLanguage ios端参数: language -> %@", language);

    [_mapView performSelector:NSSelectorFromString(@"setMapLanguage:") withObject:language];

    result(success);
}

@end

@implementation SetMapType {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;

    // 由于iOS端是从0开始算的, 所以这里减去1
    NSInteger mapType = [paramDic[@"mapType"] integerValue] - 1;

    DLog(@"方法map#setMapType ios端参数: mapType -> %d", mapType);

    [_mapView setMapType:(MAMapType) mapType];

    result(success);
}

@end

@implementation SetMyLocationStyle {
    MAMapView *_mapView;
}

- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;

    NSString *styleJson = (NSString *) paramDic[@"myLocationStyle"];

    DLog(@"方法setMyLocationStyle ios端参数: styleJson -> %@", styleJson);
    [[UnifiedMyLocationStyle mj_objectWithKeyValues:styleJson] applyTo:_mapView];

    result(success);
}

@end

@implementation SetUiSettings {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;

    NSString *uiSettingsJson = (NSString *) paramDic[@"uiSettings"];

    DLog(@"方法setUiSettings ios端参数: uiSettingsJson -> %@", uiSettingsJson);
    [[UnifiedUiSettings mj_objectWithKeyValues:uiSettingsJson] applyTo:_mapView];

    result(success);

}

@end

@implementation ShowIndoorMap {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;

    BOOL enabled = (BOOL) paramDic[@"showIndoorMap"];

    DLog(@"方法map#showIndoorMap android端参数: enabled -> %d", enabled);

    _mapView.showsIndoorMap = enabled;

    result(success);
}

@end

@implementation AddMarker {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;

    NSString *optionsJson = (NSString *) paramDic[@"markerOptions"];

    DLog(@"方法marker#addMarker ios端参数: optionsJson -> %@", optionsJson);
    UnifiedMarkerOptions *markerOptions = [UnifiedMarkerOptions mj_objectWithKeyValues:optionsJson];

    MarkerAnnotation *annotation = [[MarkerAnnotation alloc] init];
    annotation.coordinate = [markerOptions.position toCLLocationCoordinate2D];
    annotation.title = markerOptions.title;
    annotation.subtitle = markerOptions.snippet;
    annotation.markerOptions = markerOptions;
    
    if ([markerOptions.title isEqualToString:@"car"]) {
        [MarkTool shareInstance].carPointAnnotation = annotation;
    }
   

    [_mapView addAnnotation:annotation];

    result(success);
}

@end

@implementation UpdateMarker {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;

    NSString *optionsJson = (NSString *) paramDic[@"markerOptions"];

    DLog(@"方法marker#updateMarker ios端参数: optionsJson -> %@", optionsJson);
    UnifiedMarkerOptions *markerOptions = [UnifiedMarkerOptions mj_objectWithKeyValues:optionsJson];
    
    DLog(@"需要改变的mark对应title = %@", markerOptions.title);
    
    if ([markerOptions.title isEqualToString:@"start"] && [MarkTool shareInstance].startAnnotation) {
               [[MarkTool shareInstance].startAnnotation updateAddresCalloutWithContent:markerOptions.bubbleContent];
                  [[MarkTool shareInstance].startAnnotation updateCalloutInfoWithContent:markerOptions.addressLabelContent];
        
    } else if ([markerOptions.title isEqualToString:@"end"] && [MarkTool shareInstance].startAnnotation) {
               [[MarkTool shareInstance].startAnnotation updateAddresCalloutWithContent:markerOptions.bubbleContent];
                                [[MarkTool shareInstance].startAnnotation updateCalloutInfoWithContent:markerOptions.addressLabelContent];
                      
    } else if ([markerOptions.title isEqualToString:@"car"] && [MarkTool shareInstance].startAnnotation) {
                [[MarkTool shareInstance].startAnnotation updateAddresCalloutWithContent:markerOptions.bubbleContent];
                                [[MarkTool shareInstance].startAnnotation updateCalloutInfoWithContent:markerOptions.addressLabelContent];
                      
    }
    
    


    result(success);
}

@end

@implementation AddMarkers {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;

    NSString *moveToCenter = (NSString *) paramDic[@"moveToCenter"];
    NSString *optionsListJson = (NSString *) paramDic[@"markerOptionsList"];
    BOOL clear = (BOOL) paramDic[@"clear"];

    DLog(@"方法marker#addMarkers ios端参数: optionsListJson -> %@, %@", optionsListJson, moveToCenter);
    if (clear) [_mapView removeAnnotations:_mapView.annotations];

    NSArray *rawOptionsList = [NSJSONSerialization JSONObjectWithData:[optionsListJson dataUsingEncoding:NSUTF8StringEncoding]
                                                              options:kNilOptions
                                                                error:nil];
    NSMutableArray<MarkerAnnotation *> *optionList = [NSMutableArray array];

    for (NSUInteger i = 0; i < rawOptionsList.count; ++i) {
        UnifiedMarkerOptions *options = [UnifiedMarkerOptions mj_objectWithKeyValues:rawOptionsList[i]];
        MarkerAnnotation *annotation = [[MarkerAnnotation alloc] init];
        annotation.coordinate = [options.position toCLLocationCoordinate2D];
        annotation.title =options.title;
        annotation.subtitle = options.snippet;
        annotation.markerOptions = options;

        [optionList addObject:annotation];
    }

    [_mapView addAnnotations:optionList];
    if ([moveToCenter boolValue]) {
        DLog(@"滚动到地图中间");
        [_mapView showAnnotations:optionList animated:YES];
    }

    result(success);
}

@end



@implementation AddTileOverlay {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;
//    NSLog(@"map#AddTileOverlay ios端参数: optionsListJson -> %s", "11112312312312312");
    NSString *optionsListJson = (NSString *) paramDic[@"optionsList"];
    NSLog(@"map#AddTileOverlay ios端参数: optionsListJson -> %@", optionsListJson);

    //构造热力图图层对象
    MAHeatMapTileOverlay  *heatMapTileOverlay = [[MAHeatMapTileOverlay alloc] init];

    NSMutableArray* data = [NSMutableArray array];
    NSArray <LatLng *> *rawOptionsList = [LatLng mj_objectArrayWithKeyValuesArray:optionsListJson];

    NSLog(@"map#AddTileOverlay ios端参数: rawOptionsList -> %@", rawOptionsList);
    for (NSUInteger i = 0; i < rawOptionsList.count; ++i) {
        LatLng *dic = rawOptionsList[i];
        MAHeatMapNode *node = [[MAHeatMapNode alloc] init];
        CLLocationCoordinate2D coordinate;
        coordinate.latitude  =dic.latitude ;
        coordinate.longitude  =dic.longitude ;
        node.coordinate = coordinate;
        node.intensity = 1;
     
        [data addObject:node];
    }
  

    heatMapTileOverlay.data = data;

    //将热力图添加到地图上
    //构造渐变色对象
    MAHeatMapGradient *gradient = [[MAHeatMapGradient alloc] initWithColor:@[[UIColor blueColor],[UIColor greenColor], [UIColor redColor]] andWithStartPoints:@[@(0.2),@(0.5),@(0.9)]];
    heatMapTileOverlay.gradient = gradient;

    [_mapView addOverlay:heatMapTileOverlay];
    
 
    result(success);
}


@end

@implementation AddPolyline {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSString *optionsJson = (NSString *) call.arguments[@"options"];

//    DLog(@"map#addPolyline ios端参数: optionsJson -> %@", optionsJson);
//
//    NSLog(@"map#addPolyline ios端参数: optionsJson -> %@", optionsJson);

    UnifiedPolylineOptions *options = [UnifiedPolylineOptions initWithJson:optionsJson];
    
    
    options.width = iOSMarginWithPx(options.width);
    
   // NSLog(@"SCREEN_WIDTH = %f,width = %f", SCREEN_WIDTH, options.width);
    
    NSUInteger count = options.latLngList.count;

    CLLocationCoordinate2D commonPolylineCoords[count];
    for (NSUInteger i = 0; i < count; ++i) {
        commonPolylineCoords[i] = [options.latLngList[i] toCLLocationCoordinate2D];
    }

    PolylineOverlay *polyline = [PolylineOverlay polylineWithCoordinates:commonPolylineCoords count:options.latLngList.count];
    polyline.options = options;
    [_mapView addOverlay:polyline];

    result(success);
}

@end


@implementation AddCircle {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSString *optionsJson = (NSString *) call.arguments[@"options"];

   NSLog(@"map#AddCircle ios端参数: optionsJson -> %@", optionsJson);
    UnifiedCircleOptions *options = [UnifiedCircleOptions initWithJson:optionsJson];

    //构造圆
    CircleOverlay *circle = [CircleOverlay circleWithCenterCoordinate:CLLocationCoordinate2DMake(options.target.latitude,options.target.longitude) radius:options.radius];
    circle.options = options;
//    //在地图上添加圆
    [_mapView addOverlay: circle];
    result(success);
}

@end


@implementation AddOverlay {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    DLog(@"map#addPolyline ios端参数: optionsJson -> %@", {});
    NSDictionary *paramDic = call.arguments;
    NSString *center = (NSString *) paramDic[@"center"];
//    NSInteger radius =  (NSInteger * )paramDic[@"radius"] ;
    LatLng *centerPosition = [LatLng mj_objectWithKeyValues:center];
 
    //构造圆
    
    MACircle *circle = [MACircle circleWithCenterCoordinate:CLLocationCoordinate2DMake(centerPosition.latitude, centerPosition.longitude) radius:500];
    
    //在地图上添加圆
    [_mapView addOverlay: circle];

    result(success);
}


@end


@implementation ClearMarker {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    [_mapView removeAnnotations:_mapView.annotations];

    result(success);
}

@end

@implementation ChangeLatLng {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;

    NSString *targetJson = (NSString *) paramDic[@"target"];

    LatLng *target = [LatLng mj_objectWithKeyValues:targetJson];

    [_mapView setCenterCoordinate:[target toCLLocationCoordinate2D] animated:YES];

    result(success);
}

@end

@implementation ChangeCarToLatLng {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;

    NSString *targetJson = (NSString *) paramDic[@"target"];
    
    //判断是否需要改变车头方向，适用于代驾场景
    BOOL isChangeDirection = [paramDic[@"isChangeDirection"] boolValue];
    LatLng *target = [LatLng mj_objectWithKeyValues:targetJson];

    if (isChangeDirection) {
        [self updateCarDirectionWith:[target toCLLocationCoordinate2D]];
    }
    
    [UIView animateWithDuration:driver_update_frequency animations:^{
               [MarkTool shareInstance].carPointAnnotation.coordinate = [target toCLLocationCoordinate2D];
    }];
    


    result(success);
}


#pragma mark — 计算两次经纬度之间的夹角
- (void)updateCarDirectionWith:(CLLocationCoordinate2D)carCoordinate {
    
//    if ([MarkTool shareInstance].shouldRecordSecond) {
        
        [MarkTool shareInstance].firstPoint = [MarkTool shareInstance].carPointAnnotation.coordinate;
        
        //1.将两个经纬度点转成投影点
        MAMapPoint point1 = MAMapPointForCoordinate([MarkTool shareInstance].firstPoint);
        MAMapPoint point2 = MAMapPointForCoordinate(carCoordinate);
        //2.计算距离
        CLLocationDistance distance = MAMetersBetweenMapPoints(point1,point2);
        DLog(@"获取两个点之间的距离 = %f", distance);

        if (distance < driver_update_dis_forecast) { //预估心跳内，两个点的预估距离小于指定距离，视为停止,不记录第二个点
            return;
        }
        
//        [MarkTool shareInstance].shouldRecordSecond = NO;
        [MarkTool shareInstance].secondPoint = carCoordinate;
//    } else {
//        [MarkTool shareInstance].shouldRecordSecond = YES;
//        [MarkTool shareInstance].firstPoint = carCoordinate;
//    }
    
  
    if ([MarkTool shareInstance].secondPoint.latitude == 0 || [MarkTool shareInstance].secondPoint.longitude == 0) {
        DLog(@"不符合要求的数据");
        return;
    }
    
    //1.将两个经纬度点转成投影点
    MAMapPoint point3 = MAMapPointForCoordinate([MarkTool shareInstance].firstPoint);
    MAMapPoint point4 = MAMapPointForCoordinate([MarkTool shareInstance].secondPoint);
    //2.计算距离
    CLLocationDistance lastdistance = MAMetersBetweenMapPoints(point3,point4);
    DLog(@"获取两个点之间的距离 = %f", lastdistance);
    
    if (lastdistance < driver_update_dis_forecast) { //预估心跳内，两个点的预估距离小于指定距离，视为停止,不进行角度计算
        return;
    }
    
    double angle = [self getAngelFromPoint:[MarkTool shareInstance].firstPoint toPoint:[MarkTool shareInstance].secondPoint];
 
    DLog(@"当前旋转角度 = %.3f",angle);
    [[MarkTool shareInstance].carAnnotation makeATransformWithAngel:angle * M_PI / 180.f];
}


/** 获取两个点与正北方向夹角 */
- (double)getAngelFromPoint:(CLLocationCoordinate2D)firstPoint toPoint:(CLLocationCoordinate2D)secondPoint {

    double x1 = firstPoint.longitude;
    double x2 = secondPoint.longitude;
    
    double y1 = firstPoint.latitude;
    double y2 = secondPoint.latitude;
    
    double w = fabs(x1 - x2);
    double h = fabs(y1 - y2);
    
    if (w == 0 && h == 0) {
        return [MarkTool shareInstance].latestAngel;
    }

    if (w == 0) { //同一个经度
        return (y1 > y2) ? 180 : 0;
    }
    
    double tempAngel = atan(h/w) * 180 / M_PI;
//    DLog(@"计算出来的point1 = %@, point2 = %@, 角度 %.6f", firstPoint, secondPoint, tempAngel);
//    DLog(@"计算出来的角度 %.6f",tempAngel);

    
    // A（起始点）为原点B目标点
    if(x1 < x2 && y1 < y2) { // 第一象限 或者x 正半轴, y正半轴
        DLog(@"第一象限");
        tempAngel = 90 - tempAngel;
    } else if (x1 < x2 && y1 > y2){ // 第二象限
        DLog(@"第二象限");
        tempAngel = 90 + tempAngel;
    } else if (x1 > x2 && y1 > y2){ // 第三象限
        DLog(@"第三象限");
        tempAngel = 270 - tempAngel;
    } else if (x1 > x2 && y1 < y2){ // 第四象限
        DLog(@"第四象限");
        tempAngel = 270 + tempAngel;
    } else if (x1 == x2 && y1 < y2){ // y正半轴，
        DLog(@"y正半轴");
        tempAngel = 0;
    } else if (x1 == x2 && y1 > y2){ // y负半轴，
        DLog(@"y负半轴");
        tempAngel = 180;
    } else if (x1 < x2 && y1 == y2){ // x正半轴，
        DLog(@"x正半轴");
        tempAngel = 90;
    } else if (x1 > x2 && y1 == y2){ // x负半轴，
        DLog(@"x负半轴");
        tempAngel = 270;
    }
    
    [MarkTool shareInstance].latestAngel = tempAngel;
    
    return tempAngel;
    
}




@end



@implementation SetMapStatusLimits {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;

    NSString *center = (NSString *) paramDic[@"center"];
    CGFloat deltaLat = [paramDic[@"deltaLat"] floatValue];
    CGFloat deltaLng = [paramDic[@"deltaLng"] floatValue];

    DLog(@"方法map#setMapStatusLimits ios端参数: center -> %@, deltaLat -> %f, deltaLng -> %f", center, deltaLat, deltaLng);


    LatLng *centerPosition = [LatLng mj_objectWithKeyValues:center];

    [_mapView setLimitRegion:MACoordinateRegionMake(
            [centerPosition toCLLocationCoordinate2D],
            MACoordinateSpanMake(deltaLat, deltaLng))
    ];

    result(success);
}

@end

@implementation SetPosition {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;

    NSString *target = (NSString *) paramDic[@"target"];
    CGFloat zoom = [paramDic[@"zoom"] floatValue];
    CGFloat tilt = [paramDic[@"tilt"] floatValue];

    LatLng *position = [LatLng mj_objectWithKeyValues:target];

    [_mapView setCenterCoordinate:[position toCLLocationCoordinate2D] animated:true];
    _mapView.zoomLevel = zoom;
    _mapView.rotationDegree = tilt;

    result(success);
}

@end

@implementation SetZoomLevel {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;

    CGFloat zoomLevel = [paramDic[@"zoomLevel"] floatValue];

    _mapView.zoomLevel = zoomLevel;

    result(success);
}

@end

@implementation ZoomToSpan {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *paramDic = call.arguments;

    NSString *boundJson = (NSString *) paramDic[@"bound"];
    
    NSInteger paddingL = iOSMarginWithPx([paramDic[@"paddingL"] integerValue]);
    NSInteger paddingR = iOSMarginWithPx([paramDic[@"paddingR"] integerValue]);
    NSInteger paddingT = iOSMarginWithPx([paramDic[@"paddingT"] integerValue]);
    NSInteger paddingB = iOSMarginWithPx([paramDic[@"paddingB"] integerValue]);


    NSArray <LatLng *> *latLngArray = [LatLng mj_objectArrayWithKeyValuesArray:boundJson];

    NSUInteger count = latLngArray.count;

    CLLocationCoordinate2D commonPolylineCoords[count];
    for (NSUInteger i = 0; i < count; ++i) {
        commonPolylineCoords[i] = [latLngArray[i] toCLLocationCoordinate2D];
    }

    MAPolyline *polyline = [MAPolyline polylineWithCoordinates:commonPolylineCoords count:count];
    [_mapView showOverlays:@[polyline] edgePadding:UIEdgeInsetsMake(paddingT, paddingL, paddingB, paddingR) animated:YES];
}

@end

@implementation ScreenShot {
    MAMapView *_mapView;
}
- (NSObject <MapMethodHandler> *)initWith:(MAMapView *)mapView {
    _mapView = mapView;
    return self;
}

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    CGRect rect = [_mapView frame];
    [_mapView takeSnapshotInRect:rect withCompletionBlock:^(UIImage *resultImage, NSInteger state) {
        if (resultImage == nil) {
            FlutterError *err = [FlutterError errorWithCode:@"截图失败,渲染未完成" message:@"截图失败,渲染未完成" details:nil];
            result(err);
            return;
        }
        if (state != 1) {
            FlutterError *err = [FlutterError errorWithCode:@"截图失败,渲染未完成" message:@"截图失败,渲染未完成" details:nil];
            result(err);
            return;
        }
        NSData *data = UIImageJPEGRepresentation(resultImage, 100);
        FlutterStandardTypedData *r = [FlutterStandardTypedData typedDataWithBytes:data];
        result(r);
    }];
}
@end

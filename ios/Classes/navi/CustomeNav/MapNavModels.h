//
//  MapNavModels.h
//  amap_base
//
//  Created by tengfei on 2020/3/16.
//

#import <Foundation/Foundation.h>

@class AMapNavViewOptions;
@class LatLng;


NS_ASSUME_NONNULL_BEGIN


@interface AMapNavViewOptions : NSObject
 
/// 地图导航模式
@property(nonatomic) NSInteger navType;

@property(nonatomic) LatLng *startLocation;

@property(nonatomic) LatLng *endLocation;

/// 底部高度
@property(nonatomic) CGFloat bottomContentH;

/// 是否使用虚拟导航（模拟导航）
@property(nonatomic) BOOL useEmulatorNavi;

/// 地图已规划备选路线时，选中的路线索引（0 起）
@property(nonatomic) NSInteger selectedRouteIndex;

/// 是否按地图已规划的备选路线进行多路线导航
@property(nonatomic) BOOL hasPlannedRoutes;

/// 地图选中路线的总距离（米）
@property(nonatomic) NSInteger selectedRouteDistance;

/// 地图选中路线的总耗时（秒）
@property(nonatomic) NSInteger selectedRouteDuration;

/// 地图选中路线折线中点纬度
@property(nonatomic) CGFloat selectedRouteMidLatitude;

/// 地图选中路线折线中点经度
@property(nonatomic) CGFloat selectedRouteMidLongitude;


- (NSString *)description;

@end

NS_ASSUME_NONNULL_END

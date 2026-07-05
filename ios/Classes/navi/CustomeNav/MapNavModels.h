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


- (NSString *)description;

@end

NS_ASSUME_NONNULL_END

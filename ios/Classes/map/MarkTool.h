//
//  MarkTool.h
//  amap_base
//
//  Created by tengfei on 2020/3/3.
//

#import <Foundation/Foundation.h>
#import "CustomCalloutAnnotationView.h"
#import "MapModels.h"


NS_ASSUME_NONNULL_BEGIN

@interface MarkTool : NSObject


+ (instancetype)shareInstance;


/** 起点标注 */
@property (nonatomic, strong) CustomCalloutAnnotationView *startAnnotation;
/** 汽车标注 */
@property (nonatomic, strong) CustomCalloutAnnotationView *carAnnotation;
/** 终点标注 */
@property (nonatomic, strong) CustomCalloutAnnotationView *endAnnotation;

/** 数据点汽车点 */
@property (nonatomic, strong) MarkerAnnotation *carPointAnnotation;


/** 第一个点 */
@property (nonatomic, assign) CLLocationCoordinate2D firstPoint;

/** 第二个点 */
@property (nonatomic, assign) CLLocationCoordinate2D secondPoint;

/** 标记当前是否应该记录第二个点 */
@property (nonatomic, assign) BOOL shouldRecordSecond;

/** 最新记录的角度 */
@property (nonatomic, assign) double latestAngel;


@end

NS_ASSUME_NONNULL_END

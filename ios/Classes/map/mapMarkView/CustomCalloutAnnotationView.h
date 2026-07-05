//
//  CustomCalloutAnnotationView.h
//  amap_base
//
//  Created by tengfei on 2020/3/3.
//

#import "MAMapKit.h"
#import "NormalTextCalloutView.h"
#import "OutLineLabel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CustomCalloutAnnotationView : MAAnnotationView

/** 气泡 */
@property (nonatomic, strong) NormalTextCalloutView *calloutView;

/** 地址信息 */
@property (nonatomic, strong) OutLineLabel *addressLabel;

/** 更新地址内容 */
- (void)updateAddresCalloutWithContent:(NSString *)content;

/** 更新气泡内容 */
- (void)updateCalloutInfoWithContent:(NSString *)content;

/** 旋转车辆为一定角度 */
- (void)makeATransformWithAngel:(CGFloat)angel;

@end

NS_ASSUME_NONNULL_END

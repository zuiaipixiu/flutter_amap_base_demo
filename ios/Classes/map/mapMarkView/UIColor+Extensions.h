//
//  UIColor+Extensions.h
//  amap_base
//
//  Created by tengfei on 2020/3/3.
//



#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (Extensions)

+ (UIColor *)colorWithHexString:(NSString *)hexString alpha:(float)alpha;

+ (UIColor *)colorWithHexString:(NSString *)hexString;

@end

NS_ASSUME_NONNULL_END

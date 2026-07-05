//
//  OutLineLabel.h
//  amap_base
//
//  Created by tengfei on 2020/3/3.
//

#import <UIKit/UIKit.h>
#import "UIColor+Extensions.h"

#define address_textcolor   ([UIColor colorWithHexString:@"#339A87"])

#define address_font        ([UIFont systemFontOfSize:14])

#define address_outline_color  ([UIColor whiteColor])

#define address_outline_w    (4)

NS_ASSUME_NONNULL_BEGIN

@interface OutLineLabel : UILabel


@property (strong,nonatomic) UIColor *strokeColor;


@property (assign,nonatomic) CGFloat strokeWidth;


@end

NS_ASSUME_NONNULL_END

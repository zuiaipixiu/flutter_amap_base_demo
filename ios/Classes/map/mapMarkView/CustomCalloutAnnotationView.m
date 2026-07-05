//
//  CustomCalloutAnnotationView.m
//  amap_base
//
//  Created by tengfei on 2020/3/3.
//

#import "CustomCalloutAnnotationView.h"
#import "Masonry.h"
#import "NudeIn.h"
#import "UIColor+Extensions.h"
#import "MASConstraintMaker.h"

#define kWidth  26.f
#define kHeight 43.f

static CGFloat addressFont = 12;

@interface CustomCalloutAnnotationView ()

@property (nonatomic, strong) NudeIn *stateTitleLabel;

@end



@implementation CustomCalloutAnnotationView


- (NormalTextCalloutView *)calloutView {
    if (!_calloutView) {
        _calloutView = [[NormalTextCalloutView alloc] initWithFrame:CGRectZero];
        _calloutView.hidden = YES;
    }
    return _calloutView;
}


- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL inside = [super pointInside:point withEvent:event];
    /* Points that lie outside the receiver’s bounds are never reported as hits,
     even if they actually lie within one of the receiver’s subviews.
     This can occur if the current view’s clipsToBounds property is set to NO and the affected subview extends beyond the view’s bounds.
     */
    if (!inside && self.selected)
    {
        inside = [self.calloutView pointInside:[self convertPoint:point toView:self.calloutView] withEvent:event];
    }
    
    return inside;
}

#pragma mark - Life Cycle

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.bounds = CGRectMake(0.f, 0.f, kWidth, kHeight);
        
        [self addSubview:self.calloutView];
        
        [self.calloutView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(self.mas_top).mas_offset(-k_normal_arrow_H/2);
            make.width.mas_equalTo(k_normal_Callout_W);
            make.height.mas_equalTo(k_normal_Callout_H);
            make.centerX.mas_equalTo(self.mas_centerX);
        }];
        
        [self.calloutView addSubview:self.stateTitleLabel];
        
        [self.stateTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(self.calloutView.mas_centerY).mas_offset(-k_normal_arrow_H/2);
            make.centerX.mas_equalTo(self.calloutView.mas_centerX);
            make.left.right.mas_equalTo(0);
        }];
        
        //添加地址信息标签
        [self addSubview:self.addressLabel];
        [self.addressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(k_normal_Callout_W);
            make.left.mas_equalTo(self.mas_centerX).offset(addressFont * 2);
            make.centerY.mas_equalTo(self.mas_bottom);
        }];
        
    }
    
    return self;
}



- (NudeIn *)stateTitleLabel {
    if (!_stateTitleLabel) {
        
        _stateTitleLabel = [NudeIn make:^(NUDTextMaker *make) {
            make.text(@"正在加载").fontRes([UIFont systemFontOfSize:14]).color([UIColor colorWithHexString:@"#343842"]).attach();
        }];
        _stateTitleLabel.textAlignment = NSTextAlignmentCenter;
        _stateTitleLabel.backgroundColor = [UIColor clearColor];
    }
    return _stateTitleLabel;
}

- (OutLineLabel *)addressLabel {
    if (!_addressLabel) {
        _addressLabel = [[OutLineLabel alloc] initWithFrame:CGRectZero];
        //        _addressLabel.backgroundColor = [UIColor greenColor];
        _addressLabel.hidden = YES;
        _addressLabel.text = @"地址信息";
        _addressLabel.font = address_font;
        _addressLabel.textColor = address_textcolor;
        //描边
        _addressLabel.strokeColor = address_outline_color;
        _addressLabel.strokeWidth = address_outline_w;
        _addressLabel.textAlignment = NSTextAlignmentLeft;
        _addressLabel.numberOfLines = 0;
    }
    return _addressLabel;
}



/** 更新地址内容 */
- (void)updateAddresCalloutWithContent:(NSString *)content {
    self.addressLabel.text = content;
}

/** 更新气泡内容 */
- (void)updateCalloutInfoWithContent:(NSString *)content {
    
    [self.stateTitleLabel remake:^(NUDTextMaker *make) {
        make.text(content).fontRes([UIFont systemFontOfSize:14]).color([UIColor colorWithHexString:@"#343842"]).attach();
    }];
    
    
    [self updateFrameWithText:content];
}



- (void)updateFrameWithText:(NSString *)content {
    
    self.stateTitleLabel.textAlignment = NSTextAlignmentCenter;
    
    CGFloat text_W = [self calculateRowWidth:content fontSize:14];
    
    [self.calloutView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(text_W + 30);
    }];
    
    [self.calloutView setNeedsDisplay];
}



- (CGFloat)calculateRowWidth:(NSString *)string fontSize:(CGFloat)fontSize{
    NSDictionary *dic = @{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]};
    CGRect rect =
    [string boundingRectWithSize:CGSizeMake(0, 30)/*计算宽度时要确定高度*/ options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:dic context:nil];
    return rect.size.width;
}

/** 旋转车辆为一定角度 */
- (void)makeATransformWithAngel:(CGFloat)angel {
    [UIView animateWithDuration:2 animations:^{
        self.imageView.transform = CGAffineTransformMakeRotation(angel);
    }];
    
}


@end

//
//  NavViewTopView.m
//  amap_base
//
//  Created by tengfei on 2020/3/17.
//

#import "NavViewTopView.h"
#import "Masonry.h"
#import "UIColor+Extensions.h"
#import "CommonDefine.h"


static NSString *topBackColorStr = @"#292B38";

static NSString *topEnterTextColorStr = @"#909090";

static CGFloat nav_text_max_size = 23;

static CGFloat nav_text_big_size = 20;

static CGFloat nav_text_small_size = 14;

@implementation NavViewTopView



- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
//        self.backgroundColor = [UIColor redColor];
        
        [self addSubview:self.topInfoBgView];
        [self.topInfoBgView addSubview:self.topTurnImageView];
        [self.topInfoBgView addSubview:self.topRemainLabel];
        [self.topInfoBgView addSubview:self.topRoadLabel];
        
        
        [self.topInfoBgView addSubview:self.routeRemianInfoView];
        [self.routeRemianInfoView addSubview:self.routeRemainDistanceLabel];
        [self.routeRemianInfoView addSubview:self.routeRemainTimeLabel];

        double statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
//        //导航栏高度
//        double navigationHeight = (statusBarHeight + 44);
//        //tabbar高度
//        double tabBarHeight = (statusBarHeight==44 ? 83 : 49);
        //顶部的安全距离
        double topSafeAreaHeight = (statusBarHeight - 20);

        [self.topInfoBgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(top_info_margin_H);
            make.right.mas_equalTo(-top_info_margin_H);
            make.top.mas_equalTo(top_info_margin_H).offset(topSafeAreaHeight + 20);
            make.height.mas_equalTo(topInfo_H);
        }];
        
        self.topInfoBgView.layer.cornerRadius = 8;
        self.topInfoBgView.layer.masksToBounds = YES;
        
        
        [self.topTurnImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(11);
            make.left.mas_equalTo(26);
            make.height.width.mas_equalTo(72);
        }];

        [self.topRemainLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.topTurnImageView.mas_top).offset(5);
            make.left.mas_equalTo(self.topTurnImageView.mas_right).offset(20);
//            make.width.mas_equalTo(200);
         }];
        
//        self.topRemainLabel.backgroundColor = [UIColor greenColor];

        
        [self.topRemainLabel setContentHuggingPriority:200 forAxis:UILayoutConstraintAxisHorizontal];
        
        
        UILabel *enterLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        enterLabel.text = @"进入";
        enterLabel.textAlignment = NSTextAlignmentLeft;
        enterLabel.textColor = [UIColor colorWithHexString:topEnterTextColorStr];
//        enterLabel.backgroundColor = [UIColor blueColor];
        enterLabel.font = [UIFont systemFontOfSize:nav_text_small_size];

        [self.topInfoBgView addSubview:enterLabel];
        [enterLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.topRemainLabel.mas_right).offset(5);
            make.bottom.mas_equalTo(self.topRemainLabel.mas_bottom);
//            make.width.mas_equalTo(100);
        }];
        [enterLabel setContentHuggingPriority:750 forAxis:UILayoutConstraintAxisHorizontal];
        
        
        [self.topRoadLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(self.topTurnImageView.mas_bottom).offset(-5);
            make.left.mas_equalTo(self.topRemainLabel.mas_left);
            make.right.mas_equalTo(-20);
        }];
        [self.topRoadLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        
        [self.routeRemianInfoView mas_makeConstraints:^(MASConstraintMaker *make) {
                   make.bottom.mas_equalTo(0);
                   make.height.mas_equalTo(top_road_label_H);
                   make.left.mas_equalTo(0);
                make.right.mas_equalTo(0);
        }];
//        [self.routeRemianInfoView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        
        CGFloat remindLabel_W = (SCREEN_WIDTH - 16)/2;
        
        [self.routeRemainDistanceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.mas_equalTo(0);
            make.left.mas_equalTo(0);
            make.width.mas_equalTo(remindLabel_W);
        }];
        
        
        [self.routeRemainTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.mas_equalTo(0);
            make.right.mas_equalTo(0);
            make.width.mas_equalTo(remindLabel_W);
        }];
        
        UILabel *lineLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        lineLabel.backgroundColor = [UIColor lightGrayColor];
        [self.routeRemianInfoView addSubview:lineLabel];
        
        UILabel *lineLabel2 = [[UILabel alloc] initWithFrame:CGRectZero];
        lineLabel2.backgroundColor = [UIColor lightGrayColor];
        [self.routeRemianInfoView addSubview:lineLabel2];
        
        [lineLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                   make.top.bottom.mas_equalTo(0);
            make.centerX.mas_equalTo(self.routeRemianInfoView.mas_centerX);
                   make.width.mas_equalTo(1);
               }];
        
        [lineLabel2 mas_makeConstraints:^(MASConstraintMaker *make) {
                          make.top.mas_equalTo(0);
            make.left.right.mas_equalTo(0);
                          make.height.mas_equalTo(1);
                      }];
        

        
//        [self.routeRemainDistanceLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        
        
        
    }
    return self;
}

- (UIView *)topInfoBgView {
    if (!_topInfoBgView) {
        _topInfoBgView = [[UIView alloc] initWithFrame:CGRectZero];
        _topInfoBgView.backgroundColor = [UIColor colorWithHexString:topBackColorStr];
    }
    return _topInfoBgView;
}

- (UIImageView *)topTurnImageView {
    if (!_topTurnImageView) {
        _topTurnImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _topTurnImageView.image = [UIImage imageNamed:@"default_navi_browse_ver_normal"];
    }
    return _topTurnImageView;
}

- (UILabel *)topRemainLabel {
    if (!_topRemainLabel) {
        _topRemainLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _topRemainLabel.textColor = [UIColor whiteColor];
        _topRemainLabel.text = @"XXX米后";
        if (@available(iOS 8.2, *)) {
            _topRemainLabel.font = [UIFont systemFontOfSize:nav_text_max_size weight:UIFontWeightBold];
        } else {
            _topRemainLabel.font = [UIFont systemFontOfSize:nav_text_max_size];
        }
    }
    return _topRemainLabel;
}

- (UILabel *)topRoadLabel{
    if (!_topRoadLabel) {
        _topRoadLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _topRoadLabel.textColor = [UIColor whiteColor];
        _topRoadLabel.text = @"XXX路";
        if (@available(iOS 8.2, *)) {
            _topRoadLabel.font = [UIFont systemFontOfSize:nav_text_big_size weight:UIFontWeightBold];
        } else {
            _topRoadLabel.font = [UIFont systemFontOfSize:nav_text_big_size];
        }
    }
    return _topRoadLabel;
}


- (UIView *)routeRemianInfoView {
    if (!_routeRemianInfoView) {
        _routeRemianInfoView = [[UIView alloc] initWithFrame:CGRectZero];
//        _routeRemianInfoView.backgroundColor = [UIColor redColor];
//        _routeRemianInfoView.layer.cornerRadius = 4;
//        _routeRemianInfoView.layer.masksToBounds = YES;
    }
    return _routeRemianInfoView;
}

- (UILabel *)routeRemainDistanceLabel {
    if (!_routeRemainDistanceLabel) {
        _routeRemainDistanceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _routeRemainDistanceLabel.textColor = [UIColor whiteColor];
        _routeRemainDistanceLabel.text = @"剩余 XXX公里";
        _routeRemainDistanceLabel.textAlignment = NSTextAlignmentCenter;

               if (@available(iOS 8.2, *)) {
                   _routeRemainDistanceLabel.font = [UIFont systemFontOfSize:nav_text_small_size weight:UIFontWeightBold];
               } else {
                   _routeRemainDistanceLabel.font = [UIFont systemFontOfSize:nav_text_small_size];
               }
    }
    return _routeRemainDistanceLabel;
}


- (UILabel *)routeRemainTimeLabel {
    if (!_routeRemainTimeLabel) {
        _routeRemainTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _routeRemainTimeLabel.textColor = [UIColor whiteColor];
        _routeRemainTimeLabel.text = @"需要 X小时X分钟";
        _routeRemainTimeLabel.textAlignment = NSTextAlignmentCenter;

               if (@available(iOS 8.2, *)) {
                   _routeRemainTimeLabel.font = [UIFont systemFontOfSize:nav_text_small_size weight:UIFontWeightBold];
               } else {
                   _routeRemainTimeLabel.font = [UIFont systemFontOfSize:nav_text_small_size];
               }
    }
    return _routeRemainTimeLabel;
}






/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

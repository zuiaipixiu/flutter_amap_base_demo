//
//  NavViewTopView.h
//  amap_base
//
//  Created by tengfei on 2020/3/17.
//

#import <UIKit/UIKit.h>
#import <AMapNaviKit/AMapNaviKit.h>

NS_ASSUME_NONNULL_BEGIN


#define topInfo_H  140
#define top_info_margin_H  5
#define top_road_label_H    42

#define top_total_H (topInfo_H + top_info_margin_H)

@interface NavViewTopView : UIView

//顶部深色背景视图
@property (nonatomic, strong) UIView *topInfoBgView;

//转向图标
@property (nonatomic, strong) UIImageView *topTurnImageView;

//剩余距离label
@property (nonatomic, strong) UILabel *topRemainLabel;

//路名label
@property (nonatomic, strong) UILabel *topRoadLabel;

//剩余里程和时间图标
@property (nonatomic, strong) UIView *routeRemianInfoView;

//剩余里程label
@property (nonatomic, strong) UILabel *routeRemainDistanceLabel;

//剩余时间label
@property (nonatomic, strong) UILabel *routeRemainTimeLabel;


@end

NS_ASSUME_NONNULL_END

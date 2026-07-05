//
//  AMapNavViewFactory.h
//  amap_base
//
//  Created by tengfei on 2020/3/16.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "MAMapKit.h"
#import <AMapNaviKit/AMapNaviKit.h>


@class AMapNavViewOptions;

NS_ASSUME_NONNULL_BEGIN

static NSString *navSuccess = @"调用成功";

@interface AMapNavViewFactory : NSObject <FlutterPlatformViewFactory>

@end


@interface AMapNavView : NSObject <FlutterPlatformView, AMapNaviDriveManagerDelegate, AMapNaviDriveDataRepresentable, AMapNaviDriveViewDelegate>

- (instancetype)initWithFrame:(CGRect)frame
                      options:(AMapNavViewOptions *)options
               viewIdentifier:(int64_t)viewId;

- (void) setup;

@end



NS_ASSUME_NONNULL_END

//
//  MarkTool.m
//  amap_base
//
//  Created by tengfei on 2020/3/3.
//

#import "MarkTool.h"

@implementation MarkTool

static MarkTool *singleton = nil;
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}


@end

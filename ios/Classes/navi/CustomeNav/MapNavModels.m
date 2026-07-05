//
//  MapNavModels.m
//  amap_base
//
//  Created by tengfei on 2020/3/16.
//

#import "MapNavModels.h"

@implementation AMapNavViewOptions {

}
- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@", self.navType=%ld", (long)self.navType];
    [description appendFormat:@"self.startLocation=%@", self.startLocation];
    [description appendFormat:@"self.endLocation=%@", self.endLocation];
    [description appendFormat:@"self.bottomContentH=%.2f", self.bottomContentH];

    [description appendString:@">"];
    return description;
}

@end

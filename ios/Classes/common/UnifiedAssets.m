//
// Created by Yohom Bao on 2018-12-01.
//

#import "UnifiedAssets.h"
#import "AMapBasePlugin.h"

@implementation UnifiedAssets {

}

+ (NSString *)pathForAsset:(NSString *)asset {
    if (asset == nil || asset.length == 0) {
        return nil;
    }

    NSArray<NSString *> *packages = @[@"", @"flutter_amap_base", @"amap_base"];
    for (NSString *package in packages) {
        NSString *key;
        if (package.length == 0) {
            key = [AMapBasePlugin.registrar lookupKeyForAsset:asset];
        } else {
            key = [AMapBasePlugin.registrar lookupKeyForAsset:asset fromPackage:package];
        }
        if (key == nil) {
            continue;
        }
        NSString *path = [[NSBundle mainBundle] pathForResource:key ofType:nil];
        if (path != nil && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
            return path;
        }
    }
    return nil;
}

+ (NSString *)getAssetPath:(NSString *)asset {
    return [self pathForAsset:asset];
}

+ (NSString *)getDefaultAssetPath:(NSString *)asset {
    return [self pathForAsset:asset];
}

@end

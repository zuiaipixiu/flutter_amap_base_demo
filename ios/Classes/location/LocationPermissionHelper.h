#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef void (^LocationPermissionCompletion)(BOOL granted);

@interface LocationPermissionHelper : NSObject

+ (CLAuthorizationStatus)cachedAuthorizationStatus;

+ (BOOL)isLocationAuthorized;

+ (void)requestWhenInUseAuthorization:(LocationPermissionCompletion)completion;

/// AMap SDK 回调入口：不再在此处主动请求权限，避免主线程重复弹窗。
+ (void)requestWhenInUseIfNeeded:(CLLocationManager *)locationManager;

@end

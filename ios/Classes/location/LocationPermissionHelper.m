#import "LocationPermissionHelper.h"

@interface LocationPermissionHelper () <CLLocationManagerDelegate>
@property(nonatomic, strong) CLLocationManager *locationManager;
@property(nonatomic, copy) LocationPermissionCompletion pendingCompletion;
@property(nonatomic, assign) CLAuthorizationStatus cachedAuthorizationStatus;
@end

@implementation LocationPermissionHelper

+ (instancetype)sharedHelper {
    static LocationPermissionHelper *helper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[LocationPermissionHelper alloc] init];
    });
    return helper;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cachedAuthorizationStatus = kCLAuthorizationStatusNotDetermined;
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return self;
}

+ (CLAuthorizationStatus)cachedAuthorizationStatus {
    return [self sharedHelper].cachedAuthorizationStatus;
}

+ (BOOL)isLocationAuthorized {
    CLAuthorizationStatus status = [self cachedAuthorizationStatus];
    return status == kCLAuthorizationStatusAuthorizedWhenInUse
        || status == kCLAuthorizationStatusAuthorizedAlways;
}

+ (void)requestWhenInUseIfNeeded:(CLLocationManager *)locationManager {
    (void)locationManager;
}

+ (void)requestWhenInUseAuthorization:(LocationPermissionCompletion)completion {
    if (completion == nil) {
        return;
    }

    LocationPermissionHelper *helper = [self sharedHelper];
    CLAuthorizationStatus status = helper.locationManager.authorizationStatus;
    helper.cachedAuthorizationStatus = status;

    if (status == kCLAuthorizationStatusAuthorizedWhenInUse
        || status == kCLAuthorizationStatusAuthorizedAlways) {
        completion(YES);
        return;
    }

    if (status == kCLAuthorizationStatusDenied
        || status == kCLAuthorizationStatusRestricted) {
        completion(NO);
        return;
    }

    helper.pendingCompletion = completion;
    [helper.locationManager requestWhenInUseAuthorization];
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager API_AVAILABLE(ios(14.0)) {
    [self handleAuthorizationChangeForManager:manager];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self handleAuthorizationChangeForManager:manager];
}

- (void)handleAuthorizationChangeForManager:(CLLocationManager *)manager {
    CLAuthorizationStatus status = manager.authorizationStatus;
    self.cachedAuthorizationStatus = status;

    if (self.pendingCompletion == nil || status == kCLAuthorizationStatusNotDetermined) {
        return;
    }

    BOOL granted = status == kCLAuthorizationStatusAuthorizedWhenInUse
        || status == kCLAuthorizationStatusAuthorizedAlways;
    LocationPermissionCompletion completion = self.pendingCompletion;
    self.pendingCompletion = nil;
    completion(granted);
}

@end

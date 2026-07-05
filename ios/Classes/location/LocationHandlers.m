//
// Created by Yohom Bao on 2018-12-15.
//

#import "LocationHandlers.h"
#import "LocationPermissionHelper.h"
#import "MJExtension.h"
#import "AMapBasePlugin.h"
#import "LocationModels.h"
#import "CommonDefine.h"

static AMapLocationManager *_locationManager;
static FlutterEventSink _locationEventSink;
static StartLocate *_locationStreamHandler;

static AMapLocationManager *LocationManagerInstance(void) {
    if (_locationManager == nil) {
        _locationManager = [[AMapLocationManager alloc] init];
        _locationManager.distanceFilter = 1;
        _locationManager.locationTimeout = 10;
        _locationManager.reGeocodeTimeout = 10;
    }
    return _locationManager;
}

void RegisterLocationEventChannel(NSObject<FlutterPluginRegistrar> *registrar) {
    if (_locationStreamHandler != nil) {
        return;
    }
    _locationStreamHandler = [StartLocate new];
    FlutterEventChannel *locationEventChannel = [FlutterEventChannel
            eventChannelWithName:@"me.yohom/location_event"
                 binaryMessenger:[registrar messenger]];
    [locationEventChannel setStreamHandler:_locationStreamHandler];
}

@implementation Init {
}

- (instancetype)init {
    self = [super init];
    if (self) {
        LocationManagerInstance();
    }

    return self;
}


- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    result(@"成功");
}

@end


#pragma 开始定位

@implementation StartLocate

- (instancetype)init {
    self = [super init];
    return self;
}


- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *params = call.arguments;
    NSString *optionJson = params[@"options"];

    DLog(@"startLocate ios端: options.toJsonString() -> %@", optionJson);

    UnifiedLocationClientOptions *options = [UnifiedLocationClientOptions mj_objectWithKeyValues:optionJson];
    AMapLocationManager *locationManager = LocationManagerInstance();

    locationManager.delegate = self;

    [options applyTo:locationManager];

    if (options.isOnceLocation) {
        BOOL needReGeocode = options.isNeedAddress || options.locatingWithReGeocode;
        [locationManager requestLocationWithReGeocode:needReGeocode
                                      completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
            NSString *json = [[[UnifiedAMapLocation alloc] initWithLocation:location
                                                             withRegoecode:regeocode
                                                                 withError:error] mj_JSONString];
            if (_locationEventSink) {
                _locationEventSink(json);
            }
            if (location != nil) {
                result(json);
                return;
            }
            if (error) {
                result([FlutterError errorWithCode:[NSString stringWithFormat:@"%ld", (long)error.code]
                                           message:error.localizedDescription
                                           details:error.localizedDescription]);
            } else {
                result([FlutterError errorWithCode:@"-1"
                                           message:@"未获取到定位结果"
                                           details:nil]);
            }
        }];
    } else {
        [locationManager startUpdatingLocation];
        result(@"开始定位");
    }

}

- (void)amapLocationManager:(AMapLocationManager *)manager doRequireLocationAuth:(CLLocationManager *)locationManager {
    [LocationPermissionHelper requestWhenInUseIfNeeded:locationManager];
}

- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)reGeocode {
    DLog(@"location:{lat:%f; lon:%f; accuracy:%f, time:%@, timeStamap:%lld}", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy,location.timestamp, [self getDateTimeTOMilliSeconds:location.timestamp]);
    if (_locationEventSink) {
        _locationEventSink([[[UnifiedAMapLocation alloc] initWithLocation:location
                                                           withRegoecode:reGeocode
                                                               withError:nil] mj_JSONString]);
    }
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _locationEventSink = events;
    return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _locationEventSink = nil;
    return nil;
}

//将NSDate类型的时间转换为时间戳,从1970/1/1开始
-(long long)getDateTimeTOMilliSeconds:(NSDate *)datetime {
    NSTimeInterval interval = [datetime timeIntervalSince1970];
    long long totalMilliseconds = interval*1000 ;
    return totalMilliseconds;
}


@end


#pragma 结束定位

@implementation StopLocate {

}
- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    [LocationManagerInstance() stopUpdatingLocation];
    result(@"停止定位");
}

@end

//
// Created by Yohom Bao on 2018-12-15.
//

#import "LocationHandlers.h"
#import "MJExtension.h"
#import "AMapBasePlugin.h"
#import "LocationModels.h"
#import "CommonDefine.h"

static AMapLocationManager *_locationManager;

@implementation Init {
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _locationManager = [[AMapLocationManager alloc] init];
        _locationManager.distanceFilter = 1;
        _locationManager.locationTimeout = 2;
    }

    return self;
}


- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    result(@"成功");
}

@end


#pragma 开始定位

@implementation StartLocate {
    FlutterEventChannel *_locationEventChannel;
    FlutterEventSink _sink;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _locationEventChannel = [FlutterEventChannel eventChannelWithName:@"me.yohom/location_event"
                                                          binaryMessenger:[[AMapBasePlugin registrar] messenger]];
        [_locationEventChannel setStreamHandler:self];
    }

    return self;
}


- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *params = call.arguments;
    NSString *optionJson = params[@"options"];

    DLog(@"startLocate ios端: options.toJsonString() -> %@", optionJson);

    UnifiedLocationClientOptions *options = [UnifiedLocationClientOptions mj_objectWithKeyValues:optionJson];

    _locationManager.delegate = self;

    [options applyTo:_locationManager];

    if (options.isOnceLocation) {
        [_locationManager requestLocationWithReGeocode:YES
                                       completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
                                           if (error) {
                                               result([FlutterError errorWithCode:[NSString stringWithFormat:@"%d", error.code]
                                                                          message:error.localizedDescription
                                                                          details:error.localizedDescription]);
                                           } else {
                                               result(@"开始定位");
                                           }

            self->_sink([[[UnifiedAMapLocation alloc] initWithLocation:location
                                                                                  withRegoecode:regeocode
                                                                                      withError:error] mj_JSONString]);
                                       }];
    } else {
        [_locationManager startUpdatingLocation];
    }

}

- (void)amapLocationManager:(AMapLocationManager *)manager doRequireLocationAuth:(CLLocationManager *)locationManager {
        [locationManager requestAlwaysAuthorization];
}

- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)reGeocode {
    DLog(@"location:{lat:%f; lon:%f; accuracy:%f, time:%@, timeStamap:%lld}", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy,location.timestamp, [self getDateTimeTOMilliSeconds:location.timestamp]);
    if (_sink) {
        _sink([[[UnifiedAMapLocation alloc] initWithLocation:location
                                               withRegoecode:reGeocode
                                                   withError:nil] mj_JSONString]);
    }
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _sink = events;
    return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
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
    [_locationManager stopUpdatingLocation];
}

@end

//
// Created by Yohom Bao on 2018-12-15.
//

#import <AMapLocationKit/AMapLocationManager.h>
#import "LocationModels.h"

@interface AMapLocationManager (FlutterAmapBaseCompat)
- (void)setReGeocodeLanguage:(NSInteger)language;
@end


@implementation UnifiedAMapLocation {

}

- (instancetype)initWithLocation:(CLLocation *)location withRegoecode:(AMapLocationReGeocode *)regoecode withError:(NSError *)error {
    self = [super init];
    if (self) {
//        _accuracy = location.a;
//        _locationDetail = regoecode.z;
//        _locationType = location.a;
//        _bearing = location.a;
//        _gpsAccuracyStatus = lo;
//        _provider = a;
//        _streetNum = regoecode.str;
        _accuracy = location.horizontalAccuracy;
        _altitude = location.altitude;
        _floor = location.floor.level;
        _latitude = location.coordinate.latitude;
        _longitude = location.coordinate.longitude;
        _speed = location.speed;
        _time = [self getDateTimeTOMilliSeconds:location.timestamp];

        if (error) {
            _errorCode = error.code;
            _errorInfo = error.localizedDescription;
        }

        if (regoecode) {
            _adCode = regoecode.adcode;
            _address = regoecode.formattedAddress;
            _aoiName = regoecode.AOIName;
            _buildingId = regoecode.building;
            _city = regoecode.city;
            _cityCode = regoecode.citycode;
            _district = regoecode.district;
            _poiName = regoecode.POIName;
            _province = regoecode.province;
            _street = regoecode.street;
        }
    }

    return self;
}


//将NSDate类型的时间转换为时间戳,从1970/1/1开始
-(long long)getDateTimeTOMilliSeconds:(NSDate *)datetime {
    NSTimeInterval interval = [datetime timeIntervalSince1970];
    long long totalMilliseconds = interval*1000 ;
    return totalMilliseconds;
}


@end


@implementation UnifiedLocationClientOptions {

}
- (void)applyTo:(AMapLocationManager *)locationManager {
    locationManager.distanceFilter = _distanceFilter;
    if (_locationMode == 0) {
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    } else if (_locationMode == 1) {
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    } else if (_locationMode == 2) {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    } else {
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    }
    locationManager.pausesLocationUpdatesAutomatically = _pausesLocationUpdatesAutomatically;
    if (_allowsBackgroundLocationUpdates) {
        locationManager.allowsBackgroundLocationUpdates = YES;
    }
    locationManager.locationTimeout = _locationTimeout;
    locationManager.reGeocodeTimeout = _reGeocodeTimeout;
    locationManager.locatingWithReGeocode = _isNeedAddress || _locatingWithReGeocode;
    if ([locationManager respondsToSelector:@selector(setReGeocodeLanguage:)]) {
        [locationManager setReGeocodeLanguage:_geoLanguage];
    }
    locationManager.detectRiskOfFakeLocation = _detectRiskOfFakeLocation;
}

@end

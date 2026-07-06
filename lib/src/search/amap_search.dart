import 'dart:convert';
import 'dart:io';

import 'package:flutter_amap_base/amap_base.dart';
import 'package:flutter_amap_base/src/common/log.dart';
import 'package:flutter_amap_base/src/search/model/bus_station_result.dart';
import 'package:flutter_amap_base/src/search/model_ios/bus_station_result.ios.dart';
import 'package:flutter/services.dart';

class AMapSearch {
  static AMapSearch? _instance;

  static const _searchChannel = MethodChannel('me.yohom/search');

  AMapSearch._();

  factory AMapSearch() {
    if (_instance == null) {
      _instance = AMapSearch._();
      return _instance ?? AMapSearch();
    } else {
      return _instance ?? AMapSearch();
    }
  }

  /// 搜索poi
  Future<PoiResult> searchPoi(PoiSearchQuery query) {
    L.p('方法searchPoi dart端参数: query.toJsonString() -> ${query.toJsonString()}');

    return _searchChannel.invokeMethod('search#searchPoi', {'query': query.toJsonString()}).then((result) => result).then((jsonString) => PoiResult.fromJson(jsonDecode(jsonString as String) as Map<String, dynamic>));
  }

  /// 搜索poi 周边搜索
  Future<PoiResult> searchPoiBound(PoiSearchQuery query) {
    L.p('searchPoiBound dart端参数: query.toJsonString() -> ${query.toJsonString()}');

    return _searchChannel.invokeMethod('search#searchPoiBound', {'query': query.toJsonString()}).then((result) => result).then((jsonString) => PoiResult.fromJson(jsonDecode(jsonString as String) as Map<String, dynamic>));
  }

  /// 搜索poi 多边形搜索
  Future<PoiResult> searchPoiPolygon(PoiSearchQuery query) {
    L.p('searchPoiPolygon dart端参数: query.toJsonString() -> ${query.toJsonString()}');

    return _searchChannel.invokeMethod('search#searchPoiPolygon', {'query': query.toJsonString()}).then((result) => result).then((jsonString) => PoiResult.fromJson(jsonDecode(jsonString as String) as Map<String, dynamic>));
  }

  /// 按id搜索poi
  Future<PoiItem> searchPoiId(String id) {
    L.p('searchPoiId dart端参数: id -> $id');

    return _searchChannel.invokeMethod('search#searchPoiId', {'id': id}).then((result) => result).then((jsonString) => PoiItem.fromJson(jsonDecode(jsonString as String) as Map<String, dynamic>));
  }

  /// 道路沿途直线检索POI
  Future<RoutePoiResult> searchRoutePoiLine(RoutePoiSearchQuery query) {
    L.p('searchRoutePoiLine dart端参数: query.toJsonString() -> ${query.toJsonString()}');

    return _searchChannel.invokeMethod('search#searchRoutePoiLine', {'query': query.toJsonString()}).then((result) => result).then((jsonString) => RoutePoiResult.fromJson(jsonDecode(jsonString as String) as Map<String, dynamic>));
  }

  /// 道路沿途多边形检索POI
  Future<RoutePoiResult> searchRoutePoiPolygon(RoutePoiSearchQuery query) {
    L.p('searchRoutePoiPolygon dart端参数: query.toJsonString() -> ${query.toJsonString()}');

    return _searchChannel.invokeMethod('search#searchRoutePoiPolygon', {'query': query.toJsonString()}).then((result) => result).then((jsonString) => RoutePoiResult.fromJson(jsonDecode(jsonString as String) as Map<String, dynamic>));
  }

  /// 计算驾驶路线
  Future<DriveRouteResult> calculateDriveRoute(RoutePlanParam param) {
    final _routePlanParam = param.toJsonString();
    L.p('方法calculateDriveRoute dart端参数: _routePlanParam -> $_routePlanParam');
    return _searchChannel
        .invokeMethod(
          'search#calculateDriveRoute',
          {'routePlanParam': _routePlanParam},
        )
        .then((result) => result)
        .then((jsonResult) => DriveRouteResult.fromJson(jsonDecode(jsonResult as String) as Map<String, dynamic>));
  }

  /// 计算骑行路线
  Future<DriveRouteResult> calculateRidingRoute(RoutePlanParam param) {
    final _routePlanParam = param.toJsonString();
    L.p('方法calculateRidingRoute dart端参数: _routePlanParam -> $_routePlanParam');
    return _searchChannel
        .invokeMethod(
          'search#calculateRidingRoute',
          {'routePlanParam': _routePlanParam},
        )
        .then((result) => result)
        .then((jsonResult) => DriveRouteResult.fromJson(jsonDecode(jsonResult as String) as Map<String, dynamic>));
  }

  /// 地址转坐标 [name]表示地址，第二个参数表示查询城市，中文或者中文全拼，citycode、adcode
  Future<GeocodeResult> searchGeocode(String name, String city) {
    L.p('方法searchGeocode dart端参数: name -> $name, cityCode -> $city');

    return _searchChannel
        .invokeMethod(
          'search#searchGeocode',
          {'name': name, 'city': city},
        )
        .then((result) => result)
        .then((jsonResult) => GeocodeResult.fromJson(jsonDecode(jsonResult as String) as Map<String, dynamic>));
  }

  /// 逆地理编码（坐标转地址）
  Future<ReGeocodeResult> searchReGeocode(
    LatLng point,
    double radius,
    int latLonType,
  ) {
    L.p('方法searchReGeocode dart端参数: point -> ${point.toJsonString()}, radius -> $radius, latLonType -> $latLonType');

    return _searchChannel
        .invokeMethod(
          'search#searchReGeocode',
          {
            'point': point.toJsonString(),
            'radius': radius,
            'latLonType': latLonType,
          },
        )
        .then((result) => result)
        .then((jsonResult) => ReGeocodeResult.fromJson(jsonDecode(jsonResult as String) as Map<String, dynamic>));
  }

  /// 距离测量 参考[链接](https://lbs.amap.com/api/android-sdk/guide/computing-equipment/distancesearch)
  ///
  /// type 分别对应
  Future<List<int>> distanceSearch(List<LatLng> origins, LatLng target, DistanceSearchType type) async {
    List<Map<String, dynamic>> oriList = [];

    origins.forEach((o) {
      oriList.add(o.toJson());
    });

    Map<String, dynamic> params = {
      "origin": oriList,
      "target": target.toJson(),
      "type": DistanceSearchType.values.indexOf(type),
    };

    final List<dynamic> result = await _searchChannel.invokeMethod("tool#distanceSearch", params) as List<dynamic>;
    return result.map((v) => v as int).toList();
  }

  /// 公交站点查询
  ///
  /// [stationName] 公交站点名
  /// [city] 所在城市名或者城市区号
  Future<BusStationResult?> searchBusStation(String stationName, String city) {
    L.p('方法searchBusStation dart端参数: stationName -> $stationName, city -> $city');

    return _searchChannel
        .invokeMethod(
          'search#searchBusStation',
          {'stationName': stationName, 'city': city},
        )
        .then((result) => result)
        .then((json) {
          if (Platform.isIOS) {
            return BusStationResult.ios(BusStationResult_iOS.fromJson(jsonDecode(json as String) as Map<String, dynamic>));
          } else if (Platform.isAndroid) {
            return BusStationResult.fromJson(jsonDecode(json as String) as Map<String, dynamic>);
          } else {
            return null;
          }
        });
  }
}

enum DistanceSearchType {
  line,
  driver,
}

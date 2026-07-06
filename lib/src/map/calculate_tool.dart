import 'dart:convert';

import 'package:flutter/services.dart';

import '../map/model/latlng.dart';

class CalculateTools {
  static const _channel = MethodChannel('me.yohom/tool');

  static CalculateTools? _instance;

  CalculateTools._();

  factory CalculateTools() {
    if (_instance == null) {
      _instance = CalculateTools._();
      return _instance ?? CalculateTools();
    } else {
      return _instance ?? CalculateTools();
    }
  }

  /// 转换坐标系
  ///
  /// [lat] 纬度
  /// [lon] 经度
  ///
  /// [type] 原坐标类型, 这部分请查阅高德地图官方文档
  Future<LatLng?> convertCoordinate({
    required double lat,
    required double lon,
    required LatLngType type,
  }) async {
    int intType = LatLngType.values.indexOf(type);

    final dynamic methodResult = await _channel.invokeMethod(
      'tool#convertCoordinate',
      {
        'lat': lat,
        'lon': lon,
        'type': intType,
      },
    );

    if (methodResult == null) {
      return null;
    }

    return LatLng.fromJson(jsonDecode(methodResult as String) as Map<String, dynamic>);
  }

  Future<double> calcDistance(LatLng latLng1, LatLng latLng2) async {
    Map<String, dynamic> params = {
      "p1": latLng1.toJson(),
      "p2": latLng2.toJson(),
    };

    final double length = await _channel.invokeMethod("tool#calcDistance", params) as double;
    return length;
  }
}

enum LatLngType {
  gps,
  baidu,
  mapBar,
  mapABC,
  soSoMap,
  aliYun,
  google,
}

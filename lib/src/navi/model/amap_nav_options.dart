import 'dart:convert';

import 'package:flutter_amap_base/src/map/model/latlng.dart';

const NAVI_TYPE_DRIVER = 0;
const NAVI_TYPE_WALK = 1;
const NAVI_TYPE_RIDE = 2;

class AMapNavOptions {
  const AMapNavOptions({
    this.navType = NAVI_TYPE_DRIVER,
    required this.startLocation,
    required this.endLocation,
    this.bottomContentH = 100,
    this.useEmulatorNavi = false,
  });

  /// 导航模式
  final int navType;

  /// 导航起点
  final LatLng startLocation;

  /// 导航终点
  final LatLng endLocation;

  ///底部地图内容绘制区域向上偏移的高度
  final double bottomContentH;

  /// 是否使用虚拟导航（模拟导航），false 则为 GPS 真实导航
  final bool useEmulatorNavi;

  Map<String, dynamic> toJson() {
    return {
      'navType': navType,
      'startLocation': startLocation.toJson(),
      'endLocation': endLocation.toJson(),
      'bottomContentH': bottomContentH,
      'useEmulatorNavi': useEmulatorNavi,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  AMapNavOptions copyWith({
    int? navType,
    bool? useEmulatorNavi,
  }) {
    return AMapNavOptions(
      navType: navType ?? this.navType,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      bottomContentH: bottomContentH ?? this.bottomContentH,
      useEmulatorNavi: useEmulatorNavi ?? this.useEmulatorNavi,
    );
  }

  @override
  String toString() {
    return 'AMapNavOptions{navType: $navType, startLocation:$startLocation, endLocation:$endLocation, bottomContentH:$bottomContentH}';
  }
}

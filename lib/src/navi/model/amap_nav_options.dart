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
    this.selectedRouteIndex = 0,
    this.hasPlannedRoutes = false,
    this.selectedRouteDistance = 0,
    this.selectedRouteDuration = 0,
    this.selectedRouteMidLatitude = 0,
    this.selectedRouteMidLongitude = 0,
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

  /// 地图已规划备选路线时，选中的路线索引（0 起，仅作兜底）
  final int selectedRouteIndex;

  /// 是否按地图已规划的备选路线进行多路线导航
  final bool hasPlannedRoutes;

  /// 地图选中路线的总距离（米），用于与导航 SDK 备选路线匹配
  final num selectedRouteDistance;

  /// 地图选中路线的总耗时（秒），用于与导航 SDK 备选路线匹配
  final num selectedRouteDuration;

  /// 地图选中路线折线中点纬度，用于与导航 SDK 备选路线几何匹配
  final num selectedRouteMidLatitude;

  /// 地图选中路线折线中点经度，用于与导航 SDK 备选路线几何匹配
  final num selectedRouteMidLongitude;

  Map<String, dynamic> toJson() {
    return {
      'navType': navType,
      'startLocation': startLocation.toJson(),
      'endLocation': endLocation.toJson(),
      'bottomContentH': bottomContentH,
      'useEmulatorNavi': useEmulatorNavi,
      'selectedRouteIndex': selectedRouteIndex,
      'hasPlannedRoutes': hasPlannedRoutes,
      'selectedRouteDistance': selectedRouteDistance,
      'selectedRouteDuration': selectedRouteDuration,
      'selectedRouteMidLatitude': selectedRouteMidLatitude,
      'selectedRouteMidLongitude': selectedRouteMidLongitude,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  AMapNavOptions copyWith({
    int? navType,
    bool? useEmulatorNavi,
    int? selectedRouteIndex,
    bool? hasPlannedRoutes,
    num? selectedRouteDistance,
    num? selectedRouteDuration,
    num? selectedRouteMidLatitude,
    num? selectedRouteMidLongitude,
  }) {
    return AMapNavOptions(
      navType: navType ?? this.navType,
      startLocation: startLocation,
      endLocation: endLocation,
      bottomContentH: bottomContentH,
      useEmulatorNavi: useEmulatorNavi ?? this.useEmulatorNavi,
      selectedRouteIndex: selectedRouteIndex ?? this.selectedRouteIndex,
      hasPlannedRoutes: hasPlannedRoutes ?? this.hasPlannedRoutes,
      selectedRouteDistance: selectedRouteDistance ?? this.selectedRouteDistance,
      selectedRouteDuration: selectedRouteDuration ?? this.selectedRouteDuration,
      selectedRouteMidLatitude:
          selectedRouteMidLatitude ?? this.selectedRouteMidLatitude,
      selectedRouteMidLongitude:
          selectedRouteMidLongitude ?? this.selectedRouteMidLongitude,
    );
  }

  @override
  String toString() {
    return 'AMapNavOptions{navType: $navType, startLocation:$startLocation, endLocation:$endLocation, bottomContentH:$bottomContentH, useEmulatorNavi:$useEmulatorNavi, selectedRouteIndex:$selectedRouteIndex, hasPlannedRoutes:$hasPlannedRoutes, selectedRouteDistance:$selectedRouteDistance, selectedRouteDuration:$selectedRouteDuration, selectedRouteMidLatitude:$selectedRouteMidLatitude, selectedRouteMidLongitude:$selectedRouteMidLongitude}';
  }
}

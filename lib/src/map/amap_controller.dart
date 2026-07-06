import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui show window;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_amap_base/amap_base.dart';
import 'package:flutter_amap_base/src/common/log.dart';

class AMapController {
  final MethodChannel _mapChannel;
  final EventChannel _markerClickedEventChannel;
  final EventChannel _mapMovedEventChannel;

  AMapController.withId(int id)
      : _mapChannel = MethodChannel('me.yohom/map$id'),
        _markerClickedEventChannel = EventChannel('me.yohom/marker_clicked$id'),
        _mapMovedEventChannel = EventChannel('me.yohom/map_moved$id');

  void dispose() {}

  Future<void> releaseMapView() {
    return _mapChannel.invokeMethod('map#releaseView');
  }

  Future addTileOverlay(List<LatLng> optionsList) {
    // final _optionsJson = options.toJsonString();

    final _optionsListJson = jsonEncode(optionsList.map((it) => it.toJson()).toList());
    print('addTileOverlay dart端参数: _optionsJson ->');
    return _mapChannel.invokeMethod(
      'map#addTileOverlay',
      {'optionsList': _optionsListJson},
    );
  }

  //region dart -> native
  Future setMyLocationStyle(MyLocationStyle style) {
    final _styleJson = jsonEncode(style?.toJson() ?? MyLocationStyle().toJson());

    L.p('方法setMyLocationStyle dart端参数: styleJson -> $_styleJson');
    return _mapChannel.invokeMethod(
      'map#setMyLocationStyle',
      {'myLocationStyle': _styleJson},
    );
  }

  Future setUiSettings(UiSettings uiSettings) {
    final _uiSettings = jsonEncode(uiSettings.toJson());

    L.p('方法setUiSettings dart端参数: _uiSettings -> $_uiSettings');
    return _mapChannel.invokeMethod(
      'map#setUiSettings',
      {'uiSettings': _uiSettings},
    );
  }

  Future addMarker(MarkerOptions options) {
    final _optionsJson = options.toJsonString();
    L.p('方法addMarker dart端参数: _optionsJson -> $_optionsJson');
    return _mapChannel.invokeMethod(
      'marker#addMarker',
      {'markerOptions': _optionsJson},
    );
  }


  Future updateMarker(MarkerOptions options) {
    final _optionsJson = options.toJsonString();
    L.p('方法updateMarker dart端参数: _optionsJson -> $_optionsJson');
    return _mapChannel.invokeMethod(
      'marker#updateMarker',
      {'markerOptions': _optionsJson},
    );
  }

  Future addMarkers(
    List<MarkerOptions> optionsList, {
    bool moveToCenter = true,
    bool clear = true,
  }) {
    final _optionsListJson = jsonEncode(optionsList.map((it) => it.toJson()).toList());
    L.p('方法addMarkers dart端参数: _optionsListJson -> $_optionsListJson');
    return _mapChannel.invokeMethod(
      'marker#addMarkers',
      {
        'moveToCenter': moveToCenter,
        'markerOptionsList': _optionsListJson,
        'clear': clear,
      },
    );
  }

  Future showIndoorMap(bool enable) {
    return _mapChannel.invokeMethod(
      'map#showIndoorMap',
      {'showIndoorMap': enable},
    );
  }

  Future setMapType(int mapType) {
    return _mapChannel.invokeMethod(
      'map#setMapType',
      {'mapType': mapType},
    );
  }

  Future setLanguage(int language) {
    return _mapChannel.invokeMethod(
      'map#setLanguage',
      {'language': language},
    );
  }

  Future clearMarkers() {
    return _mapChannel.invokeMethod('marker#clear');
  }

  Future clearMap() {
    return _mapChannel.invokeMethod('map#clear');
  }

  /// 设置缩放等级
  Future setZoomLevel(int level) {
    L.p('setZoomLevel dart端参数: level -> $level');

    return _mapChannel.invokeMethod(
      'map#setZoomLevel',
      {'zoomLevel': level},
    );
  }

  /// 设置地图中心点
  Future setPosition({
    required LatLng target,
    double zoom = 10,
    double tilt = 0,
    double bearing = 0,
  }) {
    L.p('setPosition dart端参数: target -> $target, zoom -> $zoom, tilt -> $tilt, bearing -> $bearing');

    return _mapChannel.invokeMethod(
      'map#setPosition',
      {
        'target': target.toJsonString(),
        'zoom': zoom,
        'tilt': tilt,
        'bearing': bearing,
      },
    );
  }

  /// 限制地图的显示范围
  Future setMapStatusLimits({
    /// 西南角 [Android]
    required LatLng swLatLng,

    /// 东北角 [Android]
    required LatLng neLatLng,

    /// 中心 [iOS]
    required LatLng center,

    /// 纬度delta [iOS]
    required double deltaLat,

    /// 经度delta [iOS]
    required double deltaLng,
  }) {
    L.p('setPosition dart端参数: swLatLng -> $swLatLng, neLatLng -> $neLatLng, center -> $center, deltaLat -> $deltaLat, deltaLng -> $deltaLng');

    return _mapChannel.invokeMethod(
      'map#setMapStatusLimits',
      {
        'swLatLng': swLatLng.toJsonString(),
        'neLatLng': neLatLng.toJsonString(),
        'center': center.toJsonString(),
        'deltaLat': deltaLat,
        'deltaLng': deltaLng,
      },
    );
  }

  /// 添加线
  Future addPolyline(PolylineOptions options) {
    L.p('addPolyline dart端参数: options -> $options');

    return _mapChannel.invokeMethod(
      'map#addPolyline',
      {'options': options.toJsonString(), 'radio': 25},
    );
  }

  /// 添加圆
  Future addCircle(CircleOptions options) {
    L.p('addPolyline dart端参数: options -> $options');

    return _mapChannel.invokeMethod(
      'map#addCircle',
      {'options': options.toJsonString()},
    );
  }



  Future addOverlay() {
    L.p('addOverlay dart端参数: options -');
    return _mapChannel.invokeMethod(
      'map#addOverlay',
      {},
    );
  }

  static int getPxFromDesignPx(int designPx) {
    MediaQueryData mediaQuery = MediaQueryData.fromWindow(ui.window);
    final size = mediaQuery.size * mediaQuery.devicePixelRatio;
//    L.e(size.width.toString());
    int res = ((size.width * designPx) / 750).toInt();

    return res;
  }

  /// 移动镜头到当前的视角
  Future zoomToSpan(
    List<LatLng> bound, {
    int paddingT = 80,
    int paddingL = 80,
    int paddingB = 80,
    int paddingR = 80,
  }) {
    final boundJson = jsonEncode(bound.map((it) => it.toJson()).toList());

    L.p('zoomToSpan dart端参数: bound -> $boundJson');

    paddingT = getPxFromDesignPx(paddingT);
    paddingL = getPxFromDesignPx(paddingL);
    paddingB = getPxFromDesignPx(paddingB);
    paddingR = getPxFromDesignPx(paddingR);

    return _mapChannel.invokeMethod(
      'map#zoomToSpan',
      {
        'bound': boundJson,
        'paddingT': paddingT,
        'paddingL': paddingL,
        'paddingB': paddingB,
        'paddingR': paddingR,
      },
    );
  }

  /// 移动指定LatLng到中心
  Future changeLatLng(LatLng target) {
    L.p('changeLatLng dart端参数: target -> $target');

    return _mapChannel.invokeMethod(
      'map#changeLatLng',
      {'target': target.toJsonString()},
    );
  }

  /// 移动车辆到指定LatLng，以及是否改变车头方向，默认false
  Future changeCarToLatLng(LatLng target, {bool isChangeDirection = false}) {
    L.p('changeLatLng dart端参数: target -> $target, isChangeDirection -> $isChangeDirection');

    return _mapChannel.invokeMethod(
      'map#changeCarToLatLng',
      {
        'target': target.toJsonString(),
        'isChangeDirection': isChangeDirection,
      },
    );
  }

  /// 获取中心点
  Future<LatLng> getCenterLatlng() async {
    final String result = await _mapChannel.invokeMethod("map#getCenterPoint") as String;
    return LatLng.fromJson(json.decode(result) as Map<String, dynamic>);
  }

  /// 获取地图蓝点（用户位置），需先开启 showMyLocation
  Future<LatLng> getUserLatLng() async {
    final String result = await _mapChannel.invokeMethod('map#getUserLocation') as String;
    return LatLng.fromJson(json.decode(result) as Map<String, dynamic>);
  }

  /// 截图
  ///
  /// 可能会抛出 [PlatformException]
  Future<Uint8List> screenShot() async {
    try {
      var result = await _mapChannel.invokeMethod("map#screenshot");
      if (result is List<dynamic>) {
        return Uint8List.fromList(result.map((i) => i as int).toList());
      } else if (result is Uint8List) {
        return result;
      }
      throw PlatformException(code: "不支持的类型");
    } catch (e) {
      if (e is PlatformException) {
        L.d(e.code);
        throw e;
      }
      throw Error();
    }
  }

  /// 设置自定义样式的文件路径
  Future setCustomMapStylePath(String path) {
    L.p('setCustomMapStylePath dart端参数: path -> $path');

    return _mapChannel.invokeMethod(
      'map#setCustomMapStylePath',
      {'path': path},
    );
  }

  /// 使能自定义样式
  Future setMapCustomEnable(bool enabled) {
    L.p('setMapCustomEnable dart端参数: enabled -> $enabled');

    return _mapChannel.invokeMethod(
      'map#setMapCustomEnable',
      {'enabled': enabled},
    );
  }

  /// 使用在线自定义样式
  Future setCustomMapStyleID(String styleId) {
    L.p('setCustomMapStyleID dart端参数: styleId -> $styleId');

    return _mapChannel.invokeMethod(
      'map#setCustomMapStyleID',
      {'styleId': styleId},
    );
  }

  //endregion

  /// marker点击事件流
  Stream<MarkerOptions> get markerClickedEvent => _markerClickedEventChannel.receiveBroadcastStream().map((data) => MarkerOptions.fromJson(jsonDecode(data as String) as Map<String, dynamic>));

  /// map移动事件流
  Stream<String> get mapMovedEvent => _mapMovedEventChannel.receiveBroadcastStream().map((result) => result as String);
}

//_locationEventChannel
//    .receiveBroadcastStream()
//.map((result) => result )
//.map((resultJson) => Location.fromJson(jsonDecode(resultJson)))
//.first

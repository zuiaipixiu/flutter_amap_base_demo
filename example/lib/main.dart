import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_amap_base/amap_base.dart';

void main() {
  runApp(const AMapExampleApp());
}

class AMapExampleApp extends StatelessWidget {
  const AMapExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMap All In One Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1261FF)),
        useMaterial3: true,
      ),
      home: const AMapAllInOneExamplePage(),
    );
  }
}

class AMapAllInOneExamplePage extends StatefulWidget {
  const AMapAllInOneExamplePage({super.key});

  @override
  State<AMapAllInOneExamplePage> createState() =>
      _AMapAllInOneExamplePageState();
}

class _AMapAllInOneExamplePageState extends State<AMapAllInOneExamplePage> {
  static const LatLng _start = LatLng(39.908823, 116.39747);
  static const LatLng _end = LatLng(39.990459, 116.481476);
  static const String _iosAmapKey = 'a6ea7fe36f8f7e55d5331d68d84f6351';

  static const double _bottomCardHeight = 220;

  final AMapSearch _search = AMapSearch();
  final AMapLocation _location = AMapLocation();

  AMapController? _mapController;
  NaviMapController? _naviController;

  DriveRouteResult? _driveRouteResult;
  LatLng? _currentLatLng;
  String _status = '等待开始';
  bool _isPlanning = false;
  bool _showEmbeddedNavi = false;
  bool _mapReady = false;
  bool _naviReady = false;
  bool _sdkReady = false;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initAmapSdk());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _naviController?.destroyCustomeNavi();
    _naviController?.dispose();
    super.dispose();
  }

  Future<void> _initAmapSdk() async {
    _setStatus('正在初始化高德 SDK...');
    try {
      await AMap.setKey(_iosAmapKey);
      if (!mounted) {
        _sdkReady = true;
        return;
      }
      setState(() {
        _sdkReady = true;
      });
      _setStatus('高德 Key 设置完成');
    } catch (e) {
      _setStatus('高德 SDK 初始化失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _sdkReady
                ? (_showEmbeddedNavi ? _buildEmbeddedNavi() : _buildMap())
                : _buildSdkLoadingView(),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _buildTopBar(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return AMapView(
      amapOptions: const AMapOptions(
        mapType: MAP_TYPE_NORMAL,
        zoomControlsEnabled: false,
        compassEnabled: true,
        scaleControlsEnabled: true,
        camera: CameraPosition(
          target: _start,
          zoom: 12,
        ),
      ),
      onAMapViewCreated: (controller) {
        _mapController = controller;
        _mapReady = true;
        _setStatus('地图已创建，正在定位当前位置...');
        unawaited(_onMapReady());
      },
    );
  }

  Widget _buildEmbeddedNavi() {
    return AMapNavView(
      amapNavOptions: const AMapNavOptions(
        startLocation: _start,
        endLocation: _end,
        bottomContentH: _bottomCardHeight,
      ),
      onMapNavViewCreated: (controller) {
        _naviController = controller;
        _naviReady = true;
        _setStatus('嵌入式导航已创建');
      },
    );
  }

  Widget _buildSdkLoadingView() {
    return Container(
      color: const Color(0xFFF3F6FB),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            '正在初始化高德地图 SDK...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.72),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              _showEmbeddedNavi ? '导航演示' : '地图与路线演示',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCard() {
    final DrivePath? firstPath = _driveRouteResult?.paths?.isNotEmpty == true
        ? _driveRouteResult!.paths!.first
        : null;

    return Container(
      height: _bottomCardHeight,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F9FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildMetric('状态', _status),
                const SizedBox(width: 12),
                _buildMetric('距离', _formatDistance(firstPath?.totalDistance)),
                const SizedBox(width: 12),
                _buildMetric('耗时', _formatDuration(firstPath?.totalDuration)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: _sdkReady && _mapReady && !_isPlanning
                      ? _planDriveRoute
                      : null,
                  child: Text(_isPlanning ? '规划中...' : '路线规划'),
                ),
                FilledButton.tonal(
                  onPressed: _sdkReady && _mapReady ? _drawRouteOnMap : null,
                  child: const Text('绘制路线'),
                ),
                FilledButton.tonal(
                  onPressed: _sdkReady
                      ? (_showEmbeddedNavi
                          ? _refreshEmbeddedNavi
                          : _showNaviView)
                      : null,
                  child: Text(_showEmbeddedNavi ? '刷新导航' : '嵌入式导航'),
                ),
                FilledButton.tonal(
                  onPressed: _sdkReady ? _startExternalNavi : null,
                  child: const Text('调起原生导航'),
                ),
                OutlinedButton(
                  onPressed: _resetToMap,
                  child: const Text('回到地图'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '说明：这个示例把地图、驾车路线规划、嵌入式导航和底部卡片放在一个文件里，方便直接参考接入方式。',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMapReady() async {
    await _renderBaseMarkers();
    await _showCurrentLocationAtCenter();
  }

  Future<void> _showCurrentLocationAtCenter() async {
    final AMapController? controller = _mapController;
    if (controller == null || _isLocating) {
      return;
    }

    _isLocating = true;
    try {
      final bool granted = await Permissions().requestPermission();
      if (!granted) {
        _setStatus('定位权限未授予，暂时无法展示当前位置');
        return;
      }

      await controller.setMyLocationStyle(
        MyLocationStyle(
          myLocationType: LOCATION_TYPE_LOCATE,
          showMyLocation: true,
          showsAccuracyRing: true,
          showsHeadingIndicator: false,
        ),
      );

      final location = await _location.getLocation(
        LocationClientOptions(
          isOnceLocation: true,
          isNeedAddress: true,
          locationMode: LocationMode.Hight_Accuracy,
          locationPurpose: AMapLocationPurpose.Transport,
          locationTimeout: 10000,
          reGeocodeTimeout: 10000,
        ),
      );

      final num? latitude = location.latitude;
      final num? longitude = location.longitude;
      if (latitude == null || longitude == null) {
        _setStatus('已开启定位图层，但未拿到有效坐标');
        return;
      }

      final currentLatLng = LatLng(latitude.toDouble(), longitude.toDouble());
      _currentLatLng = currentLatLng;

      await controller.setPosition(
        target: currentLatLng,
        zoom: 16,
      );

      _setStatus('已定位到当前位置，并移动到屏幕中心');
    } catch (e) {
      _setStatus('当前位置展示失败: $e');
    } finally {
      _isLocating = false;
      unawaited(_location.stopLocate());
    }
  }

  Widget _buildMetric(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renderBaseMarkers() async {
    final AMapController? controller = _mapController;
    if (controller == null) {
      return;
    }

    final LatLng routeStart = _currentLatLng ?? _start;

    await controller.addMarkers(
      [
        MarkerOptions(
          position: routeStart,
          icon: 'images/amap_start.png',
          title: '起点',
          snippet: _currentLatLng == null ? '天安门附近' : '当前位置',
        ),
        MarkerOptions(
          position: _end,
          icon: 'images/amap_end.png',
          title: '终点',
          snippet: '望京附近',
        ),
      ],
      moveToCenter: false,
      clear: true,
    );

    await controller.zoomToSpan(
      [routeStart, _end],
      paddingT: 120,
      paddingL: 80,
      paddingB: 320,
      paddingR: 80,
    );
  }

  Future<void> _planDriveRoute() async {
    setState(() {
      _isPlanning = true;
    });
    _setStatus('正在规划驾车路线...');

    try {
      final result = await _search.calculateDriveRoute(
        RoutePlanParam(from: _currentLatLng ?? _start, to: _end),
      );

      _driveRouteResult = result;
      await _drawRouteOnMap();
      _setStatus('路线规划完成');
    } catch (e) {
      _setStatus('路线规划失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPlanning = false;
        });
      }
    }
  }

  Future<void> _drawRouteOnMap() async {
    final AMapController? controller = _mapController;
    final DrivePath? path = _driveRouteResult?.paths?.isNotEmpty == true
        ? _driveRouteResult!.paths!.first
        : null;
    if (controller == null || path == null) {
      _setStatus('暂无可绘制路线，请先规划');
      return;
    }

    final List<LatLng> points = <LatLng>[];
    for (final step in path.steps ?? <Steps>[]) {
      points.addAll(step.polyline ?? <LatLng>[]);
    }

    if (points.isEmpty) {
      _setStatus('路线结果没有可绘制坐标');
      return;
    }

    await controller.clearMap();
    await _renderBaseMarkers();
    await controller.addPolyline(
      PolylineOptions(
        latLngList: points,
        width: 18,
        color: const Color(0xFF1261FF),
        lineCapType: PolylineOptions.LINE_CAP_TYPE_ROUND,
        lineJoinType: PolylineOptions.LINE_JOIN_ROUND,
      ),
    );
    await controller.zoomToSpan(
      points,
      paddingT: 120,
      paddingL: 80,
      paddingB: 320,
      paddingR: 80,
    );
  }

  void _showNaviView() {
    setState(() {
      _showEmbeddedNavi = true;
      _naviReady = false;
    });
    _setStatus('准备打开嵌入式导航');
  }

  Future<void> _refreshEmbeddedNavi() async {
    final NaviMapController? controller = _naviController;
    if (controller == null || !_naviReady) {
      _setStatus('导航视图尚未准备完成');
      return;
    }

    await controller.changeMapRouteNaviWithInfo(
      const AMapNavOptions(
        startLocation: _start,
        endLocation: _end,
        bottomContentH: _bottomCardHeight,
      ),
    );
    _setStatus('已刷新嵌入式导航');
  }

  void _startExternalNavi() {
    AMapNavi().startNavi(
      lat: _end.latitude,
      lon: _end.longitude,
      naviType: AMapNavi.drive,
    );
    _setStatus('已请求调起原生导航');
  }

  Future<void> _resetToMap() async {
    if (_showEmbeddedNavi && _naviController != null) {
      await _naviController!.stopCustomeNavi();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _showEmbeddedNavi = false;
    });

    if (_mapReady) {
      await _renderBaseMarkers();
      if (_driveRouteResult != null) {
        await _drawRouteOnMap();
      }
    }

    _setStatus('已切回地图模式');
  }

  String _formatDistance(num? meters) {
    if (meters == null) {
      return '--';
    }
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  String _formatDuration(num? seconds) {
    if (seconds == null) {
      return '--';
    }
    final int totalMinutes = (seconds / 60).round();
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    if (hours == 0) {
      return '$minutes 分钟';
    }
    return '$hours 小时 $minutes 分钟';
  }

  void _setStatus(String value) {
    if (!mounted) {
      _status = value;
      return;
    }
    setState(() {
      _status = value;
    });
  }
}

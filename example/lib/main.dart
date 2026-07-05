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
  static const LatLng _defaultMapCenter = LatLng(39.091090, 117.301350);
  static const LatLng _destinationFallback = LatLng(39.091090, 117.301350);
  static const String _destinationName = '榕洋金城';
  static const String _destinationAddress = '天津市东丽区利津路1号';
  static const String _destinationCity = '天津';
  static const String _iosAmapKey = 'a6ea7fe36f8f7e55d5331d68d84f6351';

  static const double _bottomCardHeight = 220;

  final AMapSearch _search = AMapSearch();
  final AMapLocation _location = AMapLocation();

  AMapController? _mapController;
  NaviMapController? _naviController;

  DriveRouteResult? _driveRouteResult;
  LatLng? _mapLocateLatLng;
  LatLng? _naviLocateLatLng;
  LatLng? _destinationLatLng;
  AMapNavOptions? _navOptions;
  String _status = '等待开始';
  bool _isPlanning = false;
  bool _isStartingNavi = false;
  bool _showEmbeddedNavi = false;
  bool _mapReady = false;
  bool _naviReady = false;
  bool _sdkReady = false;
  StreamSubscription<Location>? _continuousLocationSubscription;

  LocationClientOptions get _singleLocationOptions => LocationClientOptions(
        isOnceLocation: true,
        isNeedAddress: false,
        locationMode: LocationMode.Hight_Accuracy,
        locationPurpose: AMapLocationPurpose.Transport,
        locationTimeout: 10000,
        reGeocodeTimeout: 3000,
      );

  LocationClientOptions get _continuousLocationOptions => LocationClientOptions(
        isOnceLocation: false,
        isNeedAddress: false,
        locationMode: LocationMode.Hight_Accuracy,
        locationPurpose: AMapLocationPurpose.Transport,
        interval: 2000,
        locatingWithReGeocode: false,
        locationTimeout: 10000,
        reGeocodeTimeout: 3000,
      );

  @override
  void initState() {
    super.initState();
    unawaited(_initAmapSdk());
  }

  @override
  void dispose() {
    unawaited(_stopContinuousLocation());
    _mapController?.dispose();
    _naviController?.destroyCustomeNavi();
    _naviController?.dispose();
    super.dispose();
  }

  Future<void> _initAmapSdk() async {
    _setStatus('正在初始化高德 SDK...');
    try {
      await AMap.setKey(_iosAmapKey);
      await _location.init();
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
          if (_sdkReady && !_showEmbeddedNavi)
            Positioned(
              right: 16,
              bottom: _bottomCardHeight + 16,
              child: _buildLocateButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildLocateButton() {
    return Material(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      color: Colors.white,
      child: InkWell(
        onTap: _mapReady ? _onLocateButtonTap : null,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            Icons.my_location,
            color: Color(0xFF1261FF),
            size: 24,
          ),
        ),
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
          target: _defaultMapCenter,
          zoom: 14,
        ),
      ),
      onAMapViewCreated: (controller) {
        _mapController = controller;
        _mapReady = true;
        _setStatus('地图已就绪，点击右下角定位按钮');
        unawaited(_onMapReady());
      },
    );
  }

  Widget _buildEmbeddedNavi() {
    final AMapNavOptions? navOptions = _navOptions;
    if (navOptions == null) {
      return _buildSdkLoadingView();
    }

    return AMapNavView(
      key: ValueKey<String>(
        '${navOptions.startLocation.latitude},'
        '${navOptions.startLocation.longitude}->'
        '${navOptions.endLocation.latitude},'
        '${navOptions.endLocation.longitude}',
      ),
      amapNavOptions: navOptions,
      onMapNavViewCreated: (controller) {
        _naviController = controller;
        _naviReady = true;
        _setStatus('虚拟导航已启动，连续定位至$_destinationName');
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
                  onPressed: _sdkReady && !_isStartingNavi
                      ? (_showEmbeddedNavi
                          ? _refreshEmbeddedNavi
                          : _startEmbeddedNavi)
                      : null,
                  child: Text(
                    _showEmbeddedNavi
                        ? '刷新导航'
                        : (_isStartingNavi ? '启动中...' : '嵌入式导航'),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _sdkReady ? _startExternalNavi : null,
                  child: Text('调起原生导航至$_destinationName'),
                ),
                OutlinedButton(
                  onPressed: _resetToMap,
                  child: const Text('回到地图'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '说明：定位按钮为单点定位并居中地图；「嵌入式导航」使用连续定位并开启虚拟导航至$_destinationName。',
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
    unawaited(_resolveDestinationLatLng());
    await _renderBaseMarkers();
  }

  Future<void> _stopContinuousLocation() async {
    await _continuousLocationSubscription?.cancel();
    _continuousLocationSubscription = null;
    await _location.stopLocate();
  }

  void _updateNaviLocateLatLng(Location location) {
    final num? latitude = location.latitude;
    final num? longitude = location.longitude;
    if (latitude == null || longitude == null) {
      return;
    }
    _naviLocateLatLng = LatLng(latitude.toDouble(), longitude.toDouble());
  }

  Future<LatLng?> _performSingleLocation() async {
    try {
      final Location location =
          await _location.getLocation(_singleLocationOptions);
      final num? latitude = location.latitude;
      final num? longitude = location.longitude;
      if (latitude != null && longitude != null) {
        _mapLocateLatLng = LatLng(latitude.toDouble(), longitude.toDouble());
        return _mapLocateLatLng;
      }
    } catch (_) {}
    return null;
  }

  Future<LatLng?> _startNaviContinuousLocationAndWaitFirstFix({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    await _stopContinuousLocation();
    _naviLocateLatLng = null;

    final completer = Completer<LatLng>();
    final Stream<Location> locationStream =
        await _location.startLocate(_continuousLocationOptions);

    _continuousLocationSubscription = locationStream.listen(
      (Location location) {
        _updateNaviLocateLatLng(location);
        if (!completer.isCompleted && _naviLocateLatLng != null) {
          completer.complete(_naviLocateLatLng);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );

    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      if (_naviLocateLatLng != null) {
        return _naviLocateLatLng;
      }
      rethrow;
    }
  }

  Future<LatLng> _resolveDestinationLatLng({bool allowNetwork = true}) async {
    if (_destinationLatLng != null) {
      return _destinationLatLng!;
    }

    if (!allowNetwork) {
      _destinationLatLng = _destinationFallback;
      return _destinationFallback;
    }

    try {
      final GeocodeResult geocodeResult = await _search
          .searchGeocode(
            '$_destinationAddress$_destinationName',
            _destinationCity,
          )
          .timeout(const Duration(seconds: 8));
      final LatLng? geocodePoint =
          geocodeResult.geocodeAddressList?.firstOrNull?.latLng;
      if (geocodePoint != null) {
        _destinationLatLng = geocodePoint;
        return geocodePoint;
      }
    } catch (_) {}

    try {
      final PoiResult poiResult = await _search
          .searchPoi(
            PoiSearchQuery(
              query: _destinationName,
              city: _destinationCity,
              cityLimit: true,
              pageSize: 1,
            ),
          )
          .timeout(const Duration(seconds: 8));
      final PoiItem? poi = poiResult.pois?.firstOrNull;
      final LatLng? poiPoint = poi?.latLonPoint ?? poi?.enter;
      if (poiPoint != null) {
        _destinationLatLng = poiPoint;
        return poiPoint;
      }
    } catch (_) {}

    _destinationLatLng = _destinationFallback;
    return _destinationFallback;
  }

  Future<void> _startEmbeddedNavi() async {
    if (_isStartingNavi) {
      return;
    }

    setState(() {
      _isStartingNavi = true;
    });
    _setStatus('正在准备导航至$_destinationName...');

    try {
      final bool granted = await Permissions()
          .requestPermission()
          .timeout(const Duration(seconds: 30), onTimeout: () => false);
      if (!granted) {
        _setStatus('需要定位权限才能开始导航');
        return;
      }

      final LatLng end =
          await _resolveDestinationLatLng(allowNetwork: false);
      _setStatus('连续定位中，等待当前位置...');
      final LatLng? start = await _startNaviContinuousLocationAndWaitFirstFix();
      if (start == null) {
        _setStatus('无法获取当前位置，请检查定位权限后重试');
        await _stopContinuousLocation();
        return;
      }

      _navOptions = AMapNavOptions(
        startLocation: start,
        endLocation: end,
        bottomContentH: _bottomCardHeight,
        useEmulatorNavi: true,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _showEmbeddedNavi = true;
        _naviReady = false;
      });
      _setStatus('虚拟导航已启动，连续定位至$_destinationName');

      unawaited(
        _resolveDestinationLatLng().then((LatLng preciseEnd) {
          if (_destinationLatLng == preciseEnd || !mounted) {
            return;
          }
          _destinationLatLng = preciseEnd;
          _navOptions = AMapNavOptions(
            startLocation: start,
            endLocation: preciseEnd,
            bottomContentH: _bottomCardHeight,
            useEmulatorNavi: true,
          );
          final NaviMapController? controller = _naviController;
          if (_naviReady && controller != null) {
            unawaited(controller.changeMapRouteNaviWithInfo(_navOptions!));
          }
        }),
      );

      unawaited(
        _planDriveRoute(
          from: start,
          to: end,
          updateStatus: false,
        ),
      );
    } catch (e) {
      _setStatus('启动嵌入式导航失败: $e');
      await _stopContinuousLocation();
    } finally {
      if (mounted) {
        setState(() {
          _isStartingNavi = false;
        });
      }
    }
  }

  Future<void> _onLocateButtonTap() async {
    final AMapController? controller = _mapController;
    if (controller == null || !_mapReady || _showEmbeddedNavi) {
      return;
    }

    _setStatus('正在单点定位...');
    try {
      final bool granted = await Permissions().requestPermission();
      if (!granted) {
        _setStatus('定位权限未授予，请在系统设置中开启');
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

      final LatLng? locateLatLng = await _performSingleLocation();
      if (locateLatLng == null) {
        _setStatus('未获取到有效坐标，请稍后重试');
        return;
      }

      await controller.setPosition(
        target: locateLatLng,
        zoom: 16,
      );

      await _renderBaseMarkers(fitView: false);
      _setStatus('已单点定位到当前位置');
    } catch (e) {
      _setStatus('定位失败: $e');
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

  Future<void> _renderBaseMarkers({bool fitView = true}) async {
    final AMapController? controller = _mapController;
    if (controller == null) {
      return;
    }

    final LatLng routeStart = _mapLocateLatLng ?? _defaultMapCenter;
    final LatLng routeEnd = _destinationLatLng ?? _destinationFallback;
    final List<MarkerOptions> markers = <MarkerOptions>[
      if (_mapLocateLatLng == null)
        MarkerOptions(
          position: routeStart,
          icon: 'images/amap_start.png',
          title: '起点',
          snippet: '当前位置',
        ),
      MarkerOptions(
        position: routeEnd,
        icon: 'images/amap_end.png',
        title: '终点',
        snippet: _destinationName,
      ),
    ];

    await controller.addMarkers(
      markers,
      moveToCenter: false,
      clear: true,
    );

    if (fitView) {
      await controller.zoomToSpan(
        [routeStart, routeEnd],
        paddingT: 120,
        paddingL: 80,
        paddingB: 320,
        paddingR: 80,
      );
    }
  }

  Future<void> _planDriveRoute({
    LatLng? from,
    LatLng? to,
    bool updateStatus = true,
  }) async {
    if (updateStatus) {
      setState(() {
        _isPlanning = true;
      });
      _setStatus('正在规划驾车路线...');
    }

    try {
      final LatLng routeFrom = from ?? _mapLocateLatLng ?? _defaultMapCenter;
      final LatLng routeTo = to ?? await _resolveDestinationLatLng();
      final result = await _search
          .calculateDriveRoute(
            RoutePlanParam(from: routeFrom, to: routeTo),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('路线规划超时'),
          );

      _driveRouteResult = result;
      if (!_showEmbeddedNavi && _mapReady) {
        await _drawRouteOnMap();
      }
      if (updateStatus) {
        _setStatus('路线规划完成');
      }
    } catch (e) {
      if (updateStatus) {
        _setStatus('路线规划失败: $e');
      }
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

  Future<void> _refreshEmbeddedNavi() async {
    final NaviMapController? controller = _naviController;
    if (controller == null || !_naviReady) {
      _setStatus('导航视图尚未准备完成');
      return;
    }

    try {
      final LatLng? start = _naviLocateLatLng ??
          await _startNaviContinuousLocationAndWaitFirstFix();
      if (start == null) {
        _setStatus('连续定位失败，无法刷新导航');
        return;
      }

      final LatLng end = await _resolveDestinationLatLng();
      final AMapNavOptions navOptions = AMapNavOptions(
        startLocation: start,
        endLocation: end,
        bottomContentH: _bottomCardHeight,
        useEmulatorNavi: true,
      );
      _navOptions = navOptions;
      await controller.changeMapRouteNaviWithInfo(navOptions);
      await _planDriveRoute(
        from: navOptions.startLocation,
        to: navOptions.endLocation,
        updateStatus: false,
      );
      _setStatus('已刷新连续定位导航至$_destinationName');
    } catch (e) {
      _setStatus('刷新导航失败: $e');
    }
  }

  Future<void> _startExternalNavi() async {
    try {
      final bool granted = await Permissions().requestPermission();
      if (!granted) {
        _setStatus('需要定位权限才能导航');
        return;
      }

      final LatLng destination = await _resolveDestinationLatLng();
      AMapNavi().startNavi(
        lat: destination.latitude,
        lon: destination.longitude,
        naviType: AMapNavi.drive,
      );
      _setStatus('已请求调起原生导航至$_destinationName');
    } catch (e) {
      _setStatus('调起原生导航失败: $e');
    }
  }

  Future<void> _resetToMap() async {
    if (_showEmbeddedNavi && _naviController != null) {
      await _naviController!.stopCustomeNavi();
    }

    await _stopContinuousLocation();

    if (!mounted) {
      return;
    }

    setState(() {
      _showEmbeddedNavi = false;
    });

    if (_mapReady) {
      if (_mapController != null) {
        await _mapController!.setMyLocationStyle(
          MyLocationStyle(
            myLocationType: LOCATION_TYPE_LOCATE,
            showMyLocation: true,
            showsAccuracyRing: true,
            showsHeadingIndicator: false,
          ),
        );
      }
      if (_driveRouteResult != null) {
        await _drawRouteOnMap();
      } else {
        await _renderBaseMarkers(fitView: _mapLocateLatLng == null);
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

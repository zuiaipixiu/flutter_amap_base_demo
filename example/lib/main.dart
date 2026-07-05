import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const LatLng _defaultMapCenter = LatLng(39.091548, 117.295892);
  static const LatLng _destinationFallback = LatLng(39.091548, 117.295892);
  static const String _destinationName = '张贵庄地铁站';
  static const String _destinationCity = '天津';
  static const String _destinationPinIcon = 'images/destination_pin.png';
  static const String _iosAmapKey = 'a6ea7fe36f8f7e55d5331d68d84f6351';

  static const double _bottomCardHeight = 220;
  static const double _routeSelectorHeight = 76;

  static const List<int> _multiRoutePlanModes = <int>[
    10, // 驾车多备选：躲避拥堵/较短/较快（与高德 App 默认一致，一次最多 3 条）
    11, // 多备选：时间最短、距离最短
    12, // 多备选：躲避拥堵
  ];
  static const int _maxRouteCount = 3;
  static const List<String> _routePlanLabels = <String>[
    '方案一',
    '方案二',
    '方案三',
  ];
  static const List<Color> _routePlanColors = <Color>[
    Color(0xFF1261FF),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
  ];

  final AMapSearch _search = AMapSearch();
  final AMapLocation _location = AMapLocation();

  AMapController? _mapController;
  NaviMapController? _naviController;

  DriveRouteResult? _driveRouteResult;
  LatLng? _mapLocateLatLng;
  LatLng? _naviLocateLatLng;
  LatLng? _destinationLatLng;
  List<DrivePath> _routePathOptions = <DrivePath>[];
  int _selectedRouteIndex = 0;
  AMapNavOptions? _navOptions;
  String _status = '等待开始';
  bool _isPlanning = false;
  bool _isStartingNavi = false;
  bool _showEmbeddedNavi = false;
  bool _mapReady = false;
  bool _naviReady = false;
  bool _sdkReady = false;
  bool _useEmulatorNavi = kDebugMode;
  bool _isSwitchingPlatformView = false;
  String? _appBundleId;
  StreamSubscription<NaviProgressInfo>? _naviInfoSubscription;
  int? _liveNavRemainDistanceMeters;
  int? _liveNavRemainTimeSeconds;
  StreamSubscription<Location>? _continuousLocationSubscription;

  LocationClientOptions get _singleLocationOptions => LocationClientOptions(
        isOnceLocation: true,
        isNeedAddress: false,
        locationMode: LocationMode.Hight_Accuracy,
        locationPurpose: AMapLocationPurpose.Transport,
        locationTimeout: 20000,
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
    unawaited(_naviInfoSubscription?.cancel());
    unawaited(_teardownEmbeddedNavi());
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initAmapSdk() async {
    _setStatus('正在初始化高德 SDK...');
    try {
      await AMap.setKey(_iosAmapKey);
      _appBundleId = await AMap.getBundleId();
      if (kDebugMode && _appBundleId != null) {
        debugPrint('当前 App Bundle ID: $_appBundleId');
        debugPrint('高德 Key 1008 时请确认控制台已绑定此 Bundle ID');
      }
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
                ? (_isSwitchingPlatformView
                    ? _buildSdkLoadingView()
                    : (_showEmbeddedNavi
                        ? _buildEmbeddedNavi()
                        : _buildMap()))
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_routePathOptions.isNotEmpty && !_showEmbeddedNavi)
                  _buildRouteSelector(),
                _buildBottomCard(),
              ],
            ),
          ),
          if (_sdkReady && !_showEmbeddedNavi)
            Positioned(
              right: 16,
              bottom: _bottomCardHeight +
                  (_routePathOptions.isNotEmpty ? _routeSelectorHeight : 0) +
                  16,
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
      key: const ValueKey<String>('demo-map-view'),
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
        if (_routePathOptions.isNotEmpty) {
          unawaited(_drawRouteOnMap(showStatus: false));
        }
      },
    );
  }

  Widget _buildEmbeddedNavi() {
    final AMapNavOptions? navOptions = _navOptions;
    if (navOptions == null) {
      return _buildSdkLoadingView();
    }

    return AMapNavView(
      key: const ValueKey<String>('demo-navi-view'),
      amapNavOptions: navOptions,
      onMapNavViewCreated: (controller) {
        _naviController = controller;
        _naviReady = true;
        _listenNaviProgress(controller);
        _setStatus(
          _useEmulatorNavi
              ? '虚拟导航已启动，连续定位至$_destinationName'
              : 'GPS 导航已启动，连续定位至$_destinationName',
        );
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

  AMapNavOptions _createNavOptions({
    required LatLng start,
    required LatLng end,
  }) {
    final DrivePath? selectedPath = _selectedDrivePath;
    final LatLng? routeMidpoint = _selectedRouteMidpoint();
    return AMapNavOptions(
      startLocation: start,
      endLocation: end,
      bottomContentH: _bottomCardHeight,
      useEmulatorNavi: _useEmulatorNavi,
      selectedRouteIndex: _selectedRouteIndex,
      hasPlannedRoutes: _routePathOptions.isNotEmpty,
      selectedRouteDistance: selectedPath?.totalDistance ?? 0,
      selectedRouteDuration: selectedPath?.totalDuration ?? 0,
      selectedRouteMidLatitude: routeMidpoint?.latitude ?? 0,
      selectedRouteMidLongitude: routeMidpoint?.longitude ?? 0,
    );
  }

  Widget _buildRouteSelector() {
    return Container(
      height: _routeSelectorHeight,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: List<Widget>.generate(_routePathOptions.length, (int index) {
          final DrivePath path = _routePathOptions[index];
          final bool selected = index == _selectedRouteIndex;
          final Color color = _routePlanColors[index % _routePlanColors.length];
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 6,
                right: index == _routePathOptions.length - 1 ? 0 : 6,
              ),
              child: Material(
                color: selected ? color.withValues(alpha: 0.12) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => unawaited(_selectRoute(index)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? color : const Color(0xFFE5E7EB),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _routePlanLabels[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: selected ? color : const Color(0xFF374151),
                          ),
                        ),
                        Text(
                          '${_formatDistance(path.totalDistance)} · ${_formatDuration(path.totalDuration)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.1,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomCard() {
    final DrivePath? selectedPath = _selectedDrivePath;
    final String distanceText = _showEmbeddedNavi &&
            _liveNavRemainDistanceMeters != null
        ? _formatRemainDistance(_liveNavRemainDistanceMeters!)
        : _formatDistanceWithUnit(selectedPath?.totalDistance);
    final String durationText = _showEmbeddedNavi &&
            _liveNavRemainTimeSeconds != null
        ? _formatRemainDuration(_liveNavRemainTimeSeconds!)
        : _formatDuration(selectedPath?.totalDuration);

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
                _buildMetric('距离', distanceText),
                const SizedBox(width: 12),
                _buildMetric('耗时', durationText),
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
                  child: Text(_isPlanning ? '线路规划中...' : '线路规划'),
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
                OutlinedButton(
                  onPressed: _resetToMap,
                  child: const Text('回到地图'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (kDebugMode && !_showEmbeddedNavi)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text(
                  '虚拟导航（Debug）',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _useEmulatorNavi
                      ? '模拟行驶，不依赖真实 GPS 移动'
                      : 'GPS 真实导航，需实际移动位置',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                value: _useEmulatorNavi,
                onChanged: _isStartingNavi
                    ? null
                    : (bool value) {
                        setState(() {
                          _useEmulatorNavi = value;
                        });
                      },
              ),
            Text(
              _useEmulatorNavi
                  ? '说明：定位按钮单点定位；「线路规划」最多展示3条至$_destinationName的备选路线；「嵌入式导航」虚拟导航至$_destinationName。'
                  : '说明：定位按钮单点定位；「线路规划」最多展示3条至$_destinationName的备选路线；「嵌入式导航」GPS 导航至$_destinationName。',
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
  }

  DrivePath? get _selectedDrivePath {
    if (_routePathOptions.isEmpty) {
      return null;
    }
    final int index = _selectedRouteIndex.clamp(0, _routePathOptions.length - 1);
    return _routePathOptions[index];
  }

  LatLng? _selectedRouteMidpoint() {
    final DrivePath? path = _selectedDrivePath;
    if (path == null) {
      return null;
    }
    final List<LatLng> points = _extractPathPoints(path);
    if (points.length < 2) {
      return null;
    }
    return points[points.length ~/ 2];
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

    try {
      final GeocodeResult geocodeResult = await _search
          .searchGeocode(_destinationName, _destinationCity)
          .timeout(const Duration(seconds: 8));
      final LatLng? geocodePoint =
          geocodeResult.geocodeAddressList?.firstOrNull?.latLng;
      if (geocodePoint != null) {
        _destinationLatLng = geocodePoint;
        return geocodePoint;
      }
    } catch (_) {}

    _destinationLatLng = _destinationFallback;
    return _destinationFallback;
  }

  Future<void> _ensureMapMyLocationEnabled() async {
    final AMapController? controller = _mapController;
    if (controller == null || !_mapReady) {
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
  }

  Future<LatLng?> _tryContinuousFirstFixForMap({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (_showEmbeddedNavi && _continuousLocationSubscription != null) {
      return _naviLocateLatLng;
    }

    await _stopContinuousLocation();

    final completer = Completer<LatLng>();
    try {
      final Stream<Location> locationStream =
          await _location.startLocate(_continuousLocationOptions);

      _continuousLocationSubscription = locationStream.listen(
        (Location location) {
          final num? latitude = location.latitude;
          final num? longitude = location.longitude;
          if (latitude != null &&
              longitude != null &&
              !completer.isCompleted) {
            completer.complete(
              LatLng(latitude.toDouble(), longitude.toDouble()),
            );
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        },
      );

      return await completer.future.timeout(timeout);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    } finally {
      await _stopContinuousLocation();
    }
  }

  Future<LatLng?> _resolveMapUserLatLng() async {
    final AMapController? controller = _mapController;
    if (controller == null || !_mapReady) {
      return null;
    }

    try {
      await _ensureMapMyLocationEnabled();
      await Future<void>.delayed(const Duration(milliseconds: 800));
      final LatLng userLatLng = await controller.getUserLatLng();
      _mapLocateLatLng = userLatLng;
      return userLatLng;
    } catch (e) {
      debugPrint('地图蓝点定位失败: $e');
      return null;
    }
  }

  Future<LatLng?> _resolveRoutePlanStartLatLng() async {
    if (_mapLocateLatLng != null) {
      return _mapLocateLatLng;
    }

    final bool granted = await Permissions().requestPermission();
    if (!granted) {
      return null;
    }

    await _ensureMapMyLocationEnabled();

    final LatLng? mapFix = await _resolveMapUserLatLng();
    if (mapFix != null) {
      return mapFix;
    }

    final LatLng? continuousFix = await _tryContinuousFirstFixForMap();
    if (continuousFix != null) {
      _mapLocateLatLng = continuousFix;
      return continuousFix;
    }

    final LatLng? singleFix = await _performSingleLocation();
    if (singleFix != null) {
      return singleFix;
    }

    return null;
  }

  List<LatLng> _extractPathPoints(DrivePath path) {
    final List<LatLng> points = <LatLng>[];
    for (final step in path.steps ?? <Steps>[]) {
      points.addAll(step.polyline ?? <LatLng>[]);
    }
    return points;
  }

  bool _isSameDrivePath(DrivePath a, DrivePath b) {
    final List<LatLng> pointsA = _extractPathPoints(a);
    final List<LatLng> pointsB = _extractPathPoints(b);
    if (pointsA.length < 2 || pointsB.length < 2) {
      return false;
    }

    // 起终点相同不能作为去重依据；用路径中点判断是否为同一条折线。
    final LatLng midA = pointsA[pointsA.length ~/ 2];
    final LatLng midB = pointsB[pointsB.length ~/ 2];
    final double dLat = (midA.latitude - midB.latitude).abs();
    final double dLng = (midA.longitude - midB.longitude).abs();
    return dLat < 0.00025 && dLng < 0.00025;
  }

  bool _isValidDrivePath(DrivePath path) {
    return _extractPathPoints(path).isNotEmpty;
  }

  String _formatAmapSearchError(Object error) {
    if (error is PlatformException) {
      final String code = error.code;
      final String? message = error.message;
      if (code == '1008' || (message?.contains('MD5') ?? false)) {
        final String bundleHint = _appBundleId == null
            ? ''
            : '（当前 Bundle ID: $_appBundleId）';
        return '高德 Key 与 Bundle ID 不匹配(1008)$bundleHint，请在控制台重新绑定';
      }
      if (code == '1002') {
        return '高德 Key 不正确或已过期(1002)';
      }
      if (code == '1009') {
        return 'Key 与绑定平台不符(1009)';
      }
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    final String message = error.toString();
    if (message.contains('1008') || message.contains('MD5')) {
      final String bundleHint = _appBundleId == null
          ? ''
          : '（当前 Bundle ID: $_appBundleId）';
      return '高德 Key 与 Bundle ID 不匹配(1008)$bundleHint，请在控制台重新绑定';
    }
    if (message.contains('FormatException')) {
      return '路线规划返回异常，请检查高德 Key 配置';
    }
    return message;
  }

  bool _isKeyConfigError(Object error) {
    final String text = error.toString();
    if (error is PlatformException) {
      return error.code == '1008' ||
          error.code == '1002' ||
          error.code == '1009' ||
          (error.message?.contains('MD5') ?? false);
    }
    return text.contains('1008') ||
        text.contains('1002') ||
        text.contains('1009') ||
        text.contains('MD5');
  }

  Future<({List<DrivePath> paths, String? error})> _fetchThreeRouteAlternatives({
    required LatLng from,
    required LatLng to,
  }) async {
    final List<DrivePath> collected = <DrivePath>[];
    String? lastError;

    for (final int mode in _multiRoutePlanModes) {
      if (collected.length >= _maxRouteCount) {
        break;
      }

      try {
        final DriveRouteResult result = await _search
            .calculateDriveRoute(
              RoutePlanParam(from: from, to: to, mode: mode),
            )
            .timeout(const Duration(seconds: 15));

        final int rawPathCount = result.paths?.length ?? 0;
        debugPrint('驾车规划 mode=$mode 返回 $rawPathCount 条路线');

        for (final DrivePath path in result.paths ?? <DrivePath>[]) {
          if (collected.length >= _maxRouteCount) {
            break;
          }
          if (!_isValidDrivePath(path)) {
            continue;
          }
          final bool duplicated = collected.any(
            (DrivePath existing) => _isSameDrivePath(existing, path),
          );
          if (!duplicated) {
            collected.add(path);
          }
        }
      } catch (e) {
        lastError = _formatAmapSearchError(e);
        debugPrint('路线规划 mode=$mode 失败: $lastError');
        if (_isKeyConfigError(e)) {
          break;
        }
      }
    }

    if (collected.isEmpty && lastError != null) {
      debugPrint('全部算路策略失败，最后错误: $lastError');
    }

    return (
      paths: collected.take(_maxRouteCount).toList(),
      error: lastError,
    );
  }

  Future<void> _selectRoute(int index) async {
    if (index < 0 || index >= _routePathOptions.length) {
      return;
    }

    setState(() {
      _selectedRouteIndex = index;
    });

    await _drawRouteOnMap(showStatus: false);
    _setStatus('已切换至${_routePlanLabels[index]}');
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
    } catch (e) {
      debugPrint('单次定位失败: $e');
    }
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

  void _listenNaviProgress(NaviMapController controller) {
    unawaited(_naviInfoSubscription?.cancel());
    _naviInfoSubscription = controller.navInfoStream.listen(
      (NaviProgressInfo info) {
        if (!mounted || !_showEmbeddedNavi) {
          return;
        }
        setState(() {
          _liveNavRemainDistanceMeters = info.routeRemainDistance;
          _liveNavRemainTimeSeconds = info.routeRemainTime;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('导航进度监听失败: $error');
      },
    );
  }

  String _formatDistanceWithUnit(num? meters) {
    if (meters == null) {
      return '--';
    }
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} 公里';
    }
    return '${meters.toStringAsFixed(0)} 米';
  }

  String _formatRemainDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} 公里';
    }
    return '$meters 米';
  }

  String _formatRemainDuration(int seconds) {
    if (seconds < 60) {
      return '< 1 分钟';
    }
    if (seconds < 3600) {
      return '${seconds ~/ 60} 分钟';
    }
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds ~/ 60) % 60;
    if (minutes == 0) {
      return '$hours 小时';
    }
    return '$hours 小时 $minutes 分钟';
  }

  Future<void> _waitForPlatformViewDispose() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _releaseMapView() async {
    final AMapController? controller = _mapController;
    if (controller == null) {
      return;
    }
    try {
      await controller.releaseMapView();
    } catch (e) {
      debugPrint('释放地图视图失败: $e');
    } finally {
      _mapController = null;
      _mapReady = false;
    }
  }

  Future<void> _teardownEmbeddedNavi() async {
    await _naviInfoSubscription?.cancel();
    _naviInfoSubscription = null;
    _liveNavRemainDistanceMeters = null;
    _liveNavRemainTimeSeconds = null;
    final NaviMapController? controller = _naviController;
    if (controller != null) {
      await controller.stopCustomeNavi();
      await controller.destroyCustomeNavi();
    }
    _naviController = null;
    _naviReady = false;
    _navOptions = null;
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

      final LatLng end = _driveRouteResult?.targetPos ??
          _destinationLatLng ??
          await _resolveDestinationLatLng(allowNetwork: false);
      _setStatus('连续定位中，等待当前位置...');
      final LatLng? start = await _startNaviContinuousLocationAndWaitFirstFix();
      if (start == null) {
        _setStatus('无法获取当前位置，请检查定位权限后重试');
        await _stopContinuousLocation();
        return;
      }

      _navOptions = _createNavOptions(start: start, end: end);

      if (!mounted) {
        return;
      }

      await _releaseMapView();
      if (!mounted) {
        return;
      }

      setState(() {
        _isSwitchingPlatformView = true;
      });
      await _waitForPlatformViewDispose();
      if (!mounted) {
        return;
      }

      setState(() {
        _showEmbeddedNavi = true;
        _isSwitchingPlatformView = false;
        _naviReady = false;
      });

      final bool hasPlannedRoutes = _routePathOptions.isNotEmpty;
      final String routeHint = hasPlannedRoutes
          ? '（${_routePlanLabels[_selectedRouteIndex.clamp(0, _routePathOptions.length - 1)]}）'
          : '';
      _setStatus(
        _useEmulatorNavi
            ? '虚拟导航已启动$routeHint，连续定位至$_destinationName'
            : 'GPS 导航已启动$routeHint，连续定位至$_destinationName',
      );

      unawaited(
        _resolveDestinationLatLng().then((LatLng preciseEnd) {
          if (_destinationLatLng == preciseEnd || !mounted) {
            return;
          }
          _destinationLatLng = preciseEnd;
          _navOptions = _createNavOptions(start: start, end: preciseEnd);
          final NaviMapController? controller = _naviController;
          if (_naviReady && controller != null) {
            unawaited(controller.changeMapRouteNaviWithInfo(_navOptions!));
          }
        }),
      );

      if (!hasPlannedRoutes) {
        unawaited(
          _planDriveRoute(
            from: start,
            to: end,
            updateStatus: false,
            updateRouteSelector: false,
          ),
        );
      }
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

      await _ensureMapMyLocationEnabled();

      final LatLng? locateLatLng = await _resolveRoutePlanStartLatLng();
      if (locateLatLng == null) {
        _setStatus('未获取到有效坐标，请稍后重试');
        return;
      }

      await controller.setPosition(
        target: locateLatLng,
        zoom: 16,
      );

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
              maxLines: title == '状态' ? 2 : 1,
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

  MarkerOptions _buildDestinationPinMarker({
    required LatLng position,
    required String name,
  }) {
    return MarkerOptions(
      position: position,
      icon: _destinationPinIcon,
      anchorU: 0.5,
      anchorV: 1.0,
      isFlat: true,
      zIndex: 1000,
      title: '终点',
      snippet: name,
      infoWindowEnable: false,
    );
  }

  LatLng? get _plannedDestinationLatLng => _driveRouteResult?.targetPos;

  Future<void> _renderDestinationMarker({bool clear = true}) async {
    final AMapController? controller = _mapController;
    final LatLng? endPoint = _plannedDestinationLatLng;
    if (controller == null ||
        endPoint == null ||
        _routePathOptions.isEmpty) {
      return;
    }

    await controller.addMarkers(
      <MarkerOptions>[
        _buildDestinationPinMarker(
          position: endPoint,
          name: _destinationName,
        ),
      ],
      moveToCenter: false,
      clear: clear,
    );
  }

  void _markRoutePlanningFinished({
    required int routeCount,
    DrivePath? primaryPath,
  }) {
    if (!mounted) {
      return;
    }
    final String distance = _formatDistance(primaryPath?.totalDistance);
    final String duration = _formatDuration(primaryPath?.totalDuration);
    setState(() {
      _isPlanning = false;
      _status =
          '已规划 $routeCount 条备选线路至$_destinationName（$distance · $duration）';
    });
  }

  Future<void> _planDriveRoute({
    LatLng? from,
    LatLng? to,
    bool updateStatus = true,
    bool updateRouteSelector = true,
  }) async {
    if (updateStatus) {
      setState(() {
        _isPlanning = true;
      });
      _setStatus('正在查询$_destinationName坐标...');
    }

    try {
      final bool granted = await Permissions().requestPermission();
      if (!granted) {
        _setStatus('需要定位权限才能进行线路规划');
        return;
      }

      _setStatus('正在获取当前位置...');
      final LatLng? currentLatLng =
          from ?? await _resolveRoutePlanStartLatLng();
      if (currentLatLng == null) {
        _setStatus('无法获取当前位置，请检查定位权限后重试');
        return;
      }
      _mapLocateLatLng = currentLatLng;

      _setStatus('正在查询$_destinationName坐标...');
      final LatLng routeTo = to ?? await _resolveDestinationLatLng();

      _setStatus('正在规划备选线路（最多$_maxRouteCount条）...');
      final ({List<DrivePath> paths, String? error}) planResult =
          await _fetchThreeRouteAlternatives(
        from: currentLatLng,
        to: routeTo,
      );
      final List<DrivePath> paths = planResult.paths;

      if (paths.isEmpty) {
        _setStatus(
          planResult.error ??
              '未能规划备选线路（最多$_maxRouteCount条），请检查网络后重试',
        );
        return;
      }

      if (mounted) {
        setState(() {
          _driveRouteResult = DriveRouteResult(
            paths: paths,
            startPos: currentLatLng,
            targetPos: routeTo,
          );
          _destinationLatLng = routeTo;
          if (updateRouteSelector && !_showEmbeddedNavi) {
            _routePathOptions = paths;
            _selectedRouteIndex = 0;
          }
        });
      } else {
        _driveRouteResult = DriveRouteResult(
          paths: paths,
          startPos: currentLatLng,
          targetPos: routeTo,
        );
        _destinationLatLng = routeTo;
        if (updateRouteSelector && !_showEmbeddedNavi) {
          _routePathOptions = paths;
          _selectedRouteIndex = 0;
        }
      }

      if (updateStatus) {
        _markRoutePlanningFinished(
          routeCount: paths.length,
          primaryPath: paths.first,
        );
      }

      if (!_showEmbeddedNavi) {
        await _drawRouteOnMap(showStatus: false);
      }
    } catch (e) {
      if (updateStatus) {
        _setStatus('线路规划失败: $e');
      }
    } finally {
      if (mounted && _isPlanning) {
        setState(() {
          _isPlanning = false;
        });
      }
    }
  }

  Future<void> _drawRouteOnMap({bool showStatus = true}) async {
    final AMapController? controller = _mapController;
    final DrivePath? path = _selectedDrivePath;
    if (controller == null || path == null) {
      if (showStatus) {
        _setStatus('暂无可显示线路，请先进行线路规划');
      }
      return;
    }

    final List<LatLng> points = _extractPathPoints(path);
    if (points.isEmpty) {
      if (showStatus) {
        _setStatus('线路结果没有可显示坐标');
      }
      return;
    }

    final LatLng routeStart =
        _driveRouteResult?.startPos ?? _mapLocateLatLng ?? _defaultMapCenter;
    final LatLng routeEnd =
        _driveRouteResult?.targetPos ?? _destinationLatLng ?? _destinationFallback;
    await controller.clearMap();

    for (int index = 0; index < _routePathOptions.length; index++) {
      final List<LatLng> routePoints =
          _extractPathPoints(_routePathOptions[index]);
      if (routePoints.isEmpty) {
        continue;
      }

      final bool selected = index == _selectedRouteIndex;
      await controller.addPolyline(
        PolylineOptions(
          latLngList: routePoints,
          width: selected ? 18 : 10,
          color: selected
              ? _routePlanColors[index % _routePlanColors.length]
              : const Color(0xFFB0BEC5),
          lineCapType: PolylineOptions.LINE_CAP_TYPE_ROUND,
          lineJoinType: PolylineOptions.LINE_JOIN_ROUND,
        ),
      );
    }

    await _renderDestinationMarker(clear: false);

    await controller.zoomToSpan(
      <LatLng>[routeStart, routeEnd, ...points],
      paddingT: 120,
      paddingL: 80,
      paddingB: (_bottomCardHeight +
              (_routePathOptions.isNotEmpty ? _routeSelectorHeight : 0) +
              80)
          .round(),
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

      final LatLng end = _driveRouteResult?.targetPos ??
          _destinationLatLng ??
          await _resolveDestinationLatLng();
      final AMapNavOptions navOptions = _createNavOptions(start: start, end: end);
      _navOptions = navOptions;
      await controller.changeMapRouteNaviWithInfo(navOptions);
      if (_routePathOptions.isEmpty) {
        await _planDriveRoute(
          from: navOptions.startLocation,
          to: navOptions.endLocation,
          updateStatus: false,
        );
      }
      final String routeHint = _routePathOptions.isNotEmpty
          ? '（${_routePlanLabels[_selectedRouteIndex.clamp(0, _routePathOptions.length - 1)]}）'
          : '';
      _setStatus('已刷新连续定位导航$routeHint至$_destinationName');
    } catch (e) {
      _setStatus('刷新导航失败: $e');
    }
  }

  /// 调起高德原生导航页（当前示例未挂载按钮，保留供后续使用）。
  // ignore: unused_element
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
    if (!_showEmbeddedNavi) {
      return;
    }

    await _teardownEmbeddedNavi();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSwitchingPlatformView = true;
    });
    await _waitForPlatformViewDispose();

    if (!mounted) {
      return;
    }

    await _stopContinuousLocation();

    setState(() {
      _showEmbeddedNavi = false;
      _isSwitchingPlatformView = false;
      _mapReady = false;
      _mapController = null;
    });

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

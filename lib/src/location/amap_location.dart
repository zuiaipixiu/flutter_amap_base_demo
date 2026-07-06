import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_amap_base/src/common/log.dart';
import 'package:flutter_amap_base/src/location/model/location.dart';
import 'package:flutter_amap_base/src/location/model/location_client_options.dart';

class AMapLocation {
  static AMapLocation? _instance;

  static const _locationChannel = MethodChannel('me.yohom/location');
  static const _locationEventChannel = EventChannel('me.yohom/location_event');

  bool _initialized = false;

  AMapLocation._();

  factory AMapLocation() {
    if (_instance == null) {
      _instance = AMapLocation._();
      return _instance ?? AMapLocation();
    } else {
      return _instance ?? AMapLocation();
    }
  }

  /// 初始化
  Future init() {
    return _ensureInitialized();
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    await _locationChannel.invokeMethod('location#init');
    _initialized = true;
  }

  Location _parseLocationResult(dynamic result) {
    return Location.fromJson(jsonDecode(result as String) as Map<String, dynamic>);
  }

  int _locationTimeoutMs(LocationClientOptions options) {
    return (options.locationTimeout + options.reGeocodeTimeout + 5000).toInt();
  }

  Future<void> _safeCancelSubscription(StreamSubscription<dynamic>? subscription) async {
    if (subscription == null) {
      return;
    }
    try {
      await subscription.cancel();
    } on PlatformException catch (error) {
      final String message = error.message ?? '';
      if (error.code == 'error' && message.contains('No active stream to cancel')) {
        return;
      }
      rethrow;
    }
  }

  /// 只定位一次
  Future<Location> getLocation(LocationClientOptions options) async {
    L.p('getLocation dart端参数: options.toJsonString() -> ${options.toJsonString()}');

    await _ensureInitialized();

    final dynamic methodResult = await _locationChannel
        .invokeMethod(
          'location#startLocate',
          {'options': options.toJsonString()},
        )
        .timeout(
          Duration(milliseconds: _locationTimeoutMs(options)),
          onTimeout: () => throw TimeoutException('定位超时，请检查定位权限和网络后重试'),
        );

    if (methodResult is String && methodResult.startsWith('{')) {
      final Location location = _parseLocationResult(methodResult);
      if (location.latitude != null && location.longitude != null) {
        return location;
      }
      final String errorInfo = location.errorInfo ?? '未知错误';
      throw StateError('定位失败: $errorInfo');
    }

    throw StateError('定位结果无效: $methodResult');
  }

  /// 开始定位, 返回定位 结果流
  Future<Stream<Location>> startLocate(LocationClientOptions options) async {
    L.p('startLocate dart端参数: options.toJsonString() -> ${options.toJsonString()}');

    await _ensureInitialized();

    final controller = StreamController<Location>();
    StreamSubscription<dynamic>? subscription;
    subscription = _locationEventChannel.receiveBroadcastStream().listen(
      (result) => controller.add(_parseLocationResult(result)),
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = () => _safeCancelSubscription(subscription);

    await _locationChannel.invokeMethod(
      'location#startLocate',
      {'options': options.toJsonString()},
    );

    return controller.stream;
  }

  /// 结束定位, 但是仍然可以打开, 其实严格说是暂停
  Future stopLocate() {
    return _locationChannel.invokeMethod('location#stopLocate');
  }

  ///注销定位服务
  Future unbindService() async {
    return await _locationChannel.invokeMethod('location#unbindService');
  }
}

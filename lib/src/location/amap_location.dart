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
    return Location.fromJson(jsonDecode(result as String));
  }

  int _locationTimeoutMs(LocationClientOptions options) {
    return (options.locationTimeout + options.reGeocodeTimeout + 5000).toInt();
  }

  /// 只定位一次
  Future<Location> getLocation(LocationClientOptions options) async {
    L.p('getLocation dart端参数: options.toJsonString() -> ${options.toJsonString()}');

    await _ensureInitialized();

    final completer = Completer<Location>();

    void completeOnce(Location location) {
      if (!completer.isCompleted) {
        completer.complete(location);
      }
    }

    void completeErrorOnce(Object error, [StackTrace? stackTrace]) {
      if (!completer.isCompleted) {
        if (stackTrace != null) {
          completer.completeError(error, stackTrace);
        } else {
          completer.completeError(error);
        }
      }
    }

    late final StreamSubscription<dynamic> subscription;
    subscription = _locationEventChannel.receiveBroadcastStream().listen(
      (result) {
        unawaited(subscription.cancel());
        completeOnce(_parseLocationResult(result));
      },
      onError: (Object error, StackTrace stackTrace) {
        unawaited(subscription.cancel());
        completeErrorOnce(error, stackTrace);
      },
    );

    try {
      final dynamic methodResult = await _locationChannel.invokeMethod(
        'location#startLocate',
        {'options': options.toJsonString()},
      );
      if (methodResult is String && methodResult.startsWith('{')) {
        unawaited(subscription.cancel());
        completeOnce(_parseLocationResult(methodResult));
      }
    } catch (error, stackTrace) {
      unawaited(subscription.cancel());
      completeErrorOnce(error, stackTrace);
    }

    return completer.future.timeout(
      Duration(milliseconds: _locationTimeoutMs(options)),
      onTimeout: () {
        unawaited(subscription.cancel());
        throw TimeoutException('定位超时，请检查定位权限和网络后重试');
      },
    );
  }

  /// 开始定位, 返回定位 结果流
  Future<Stream<Location>> startLocate(LocationClientOptions options) async {
    L.p('startLocate dart端参数: options.toJsonString() -> ${options.toJsonString()}');

    await _ensureInitialized();

    final controller = StreamController<Location>();
    late StreamSubscription<Location> subscription;
    subscription = _locationEventChannel
        .receiveBroadcastStream()
        .map(_parseLocationResult)
        .listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
    controller.onCancel = () => subscription.cancel();

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

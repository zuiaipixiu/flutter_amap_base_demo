import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

class Permissions {
  static Permissions? _instance;

  static const _permissionChannel = MethodChannel('me.yohom/permission');

  Permissions._();

  factory Permissions() {
    if (_instance == null) {
      _instance = Permissions._();
      return _instance ?? Permissions();
    } else {
      return _instance ?? Permissions();
    }
  }

  /// 请求地图相关权限
  Future<bool> requestPermission() async {
    ///make no effect to ios
    var sdkInt = 23;

    if (Platform.isAndroid) {
      var info = await DeviceInfoPlugin().androidInfo;
      sdkInt = info.version.sdkInt;
    }
    if (sdkInt >= 23) {
      final dynamic result = await _permissionChannel
          .invokeMethod('requestPermission')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => false,
          );
      return result == true;
    } else {
      ///when under sdk 23 (exclusive)
      ///permissions already declared in manifest and granted when downloaded
      return true;
    }
  }

  /// 请求打开设置页面
  requestPermissionOpenSetting() async {
    ///make no effect to Android
    if (Platform.isIOS) {
      _permissionChannel.invokeMethod('requestPermissionOpenSetting');
    } else {}
  }
}

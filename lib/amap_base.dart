library amap_base;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/location/amap_location.dart';

export 'amap_base.dart';
export 'src/common/permissions.dart';
export 'src/common/permissions.dart';
export 'src/common/permissions.dart';
export 'src/location/amap_location.dart';
export 'src/location/model/location.dart';
export 'src/location/model/location_client_options.dart';
export 'src/map/amap_controller.dart';
export 'src/map/amap_view.dart';
export 'src/map/calculate_tool.dart';
export 'src/map/model/amap_options.dart';
export 'src/map/model/camera_position.dart';
export 'src/map/model/latlng.dart';
export 'src/map/model/marker_options.dart';
export 'src/map/model/my_location_style.dart';
export 'src/map/model/polyline_options.dart';
export 'src/map/model/circle_options.dart';
export 'src/map/model/route_overlay.dart';
export 'src/map/model/ui_settings.dart';
export 'src/map/offline_manager.dart';
export 'src/navi/amap_navi.dart';
export "src/navi/amap_navi_view.dart";
export 'src/navi/amap_navi_view_controller.dart';
export 'src/navi/model/amap_nav_options.dart';
export 'src/navi/model/navi_progress_info.dart';
export 'src/search/amap_search.dart';
export 'src/search/model/drive_route_result.dart';
export 'src/search/model/geocode_result.dart';
export 'src/search/model/poi_extension.dart';
export 'src/search/model/poi_item.dart';
export 'src/search/model/poi_query.dart';
export 'src/search/model/poi_result.dart';
export 'src/search/model/poi_search_query.dart';
export 'src/search/model/regeocode_result.dart';
export 'src/search/model/route_plan_param.dart';
export 'src/search/model/route_poi_result.dart';
export 'src/search/model/route_poi_search_query.dart';
export 'src/search/model/search_bound.dart';

class AMap {
  static final _channel = MethodChannel('me.yohom/amap_base');

  static Map<String, List<String>>? assetManifest;

  static Future init(String key) async {
    await _channel.invokeMethod('setKey', {'key': key});

    // 加载 asset 相关信息，供区分图片分辨率用（native 端无法区分分辨率）
    assetManifest = await _loadAssetManifestMap();
  }

  /// 从 AssetManifest.bin 构建 {逻辑路径: [各分辨率路径]} 映射。
  /// Flutter 3.x 已移除 AssetManifest.json，需使用官方 API。
  static Future<Map<String, List<String>>> _loadAssetManifestMap() async {
    try {
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final Map<String, List<String>> result = <String, List<String>>{};
      for (final String key in manifest.listAssets()) {
        final List<AssetMetadata>? variants = manifest.getAssetVariants(key);
        if (variants != null && variants.isNotEmpty) {
          result[key] = variants.map((AssetMetadata v) => v.key).toList();
        } else {
          result[key] = <String>[key];
        }
      }
      return result;
    } catch (_) {
      return <String, List<String>>{};
    }
  }

  @Deprecated('使用init方法初始化的时候设置key')
  static Future setKey(String key) {
    return _channel.invokeMethod('setKey', {'key': key});
  }

  /// 获取当前 App 的 Bundle ID / 包名，用于核对高德 Key 绑定信息
  static Future<String?> getBundleId() async {
    final dynamic result = await _channel.invokeMethod('getBundleId');
    if (result is String && result.isNotEmpty) {
      return result;
    }
    return null;
  }
}

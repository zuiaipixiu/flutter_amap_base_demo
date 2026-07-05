import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_amap_base/src/common/log.dart';

import 'model/amap_nav_options.dart';
import 'model/navi_progress_info.dart';

class NaviMapController {
  final MethodChannel _navChannel;
  final EventChannel _naviInfoEventChannel;

  NaviMapController.withId(int id)
      : _navChannel = MethodChannel('me.yohom/map_nav$id'),
        _naviInfoEventChannel = EventChannel('me.yohom/navi_info$id');

  void dispose() {}

  Stream<NaviProgressInfo> get navInfoStream => _naviInfoEventChannel
      .receiveBroadcastStream()
      .map(NaviProgressInfo.fromDynamic);

  //region dart -> native
  Future changeMapRouteNaviWithInfo(AMapNavOptions navOptions) {
    final _navInfoJson = jsonEncode(navOptions.toJson());

    final _startLocation = jsonEncode(navOptions.startLocation.toJson());
    final _endLocation = jsonEncode(navOptions.endLocation.toJson());

    final _navType = navOptions.navType;
    final _bottomContentH = navOptions.bottomContentH;
    final _useEmulatorNavi = navOptions.useEmulatorNavi;

    L.p('方法changeMapRouteNaviWithInfo dart端参数: navInfoJson -> $_navInfoJson');

    return _navChannel.invokeMethod(
      'nav#changeMapRouteNaviWithInfo',
      {
        'startLocation': _startLocation,
        'endLocation': _endLocation,
        'navType': _navType,
        'bottomContentH': _bottomContentH,
        'useEmulatorNavi': _useEmulatorNavi,
        'selectedRouteIndex': navOptions.selectedRouteIndex,
        'hasPlannedRoutes': navOptions.hasPlannedRoutes,
        'selectedRouteDistance': navOptions.selectedRouteDistance,
        'selectedRouteDuration': navOptions.selectedRouteDuration,
        'selectedRouteMidLatitude': navOptions.selectedRouteMidLatitude,
        'selectedRouteMidLongitude': navOptions.selectedRouteMidLongitude,
      },
    );
  }

  //region dart -> native
  Future stopCustomeNavi() {
//    L.p('方法changeMapRouteNaviWithInfo dart端参数: navInfoJson -> $_navInfoJson');

    return _navChannel.invokeMethod('nav#stopCustomeNavi');
  }

  //region dart -> native
  Future destroyCustomeNavi() {
    return _navChannel.invokeMethod('nav#destroyCustomeNavi');
  }
}

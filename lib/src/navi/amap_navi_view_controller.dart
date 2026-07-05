import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_amap_base/src/common/log.dart';

import 'model/amap_nav_options.dart';

class NaviMapController {
  final MethodChannel _navChannel;

  NaviMapController.withId(int id) : _navChannel = MethodChannel('me.yohom/map_nav$id');

  void dispose() {}

  //region dart -> native
  Future changeMapRouteNaviWithInfo(AMapNavOptions navOptions) {
    final _navInfoJson = jsonEncode(navOptions?.toJson());

    final _startLocation = jsonEncode(navOptions.startLocation.toJson());
    final _endLocation = jsonEncode(navOptions.endLocation.toJson());

    final _navType = navOptions.navType;
    final _bottomContentH = navOptions.bottomContentH;

    L.p('方法changeMapRouteNaviWithInfo dart端参数: navInfoJson -> $_navInfoJson');

    return _navChannel.invokeMethod(
      'nav#changeMapRouteNaviWithInfo',
      {
        'startLocation': _startLocation,
        'endLocation': _endLocation,
        'navType': _navType,
        'bottomContentH': _bottomContentH,
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

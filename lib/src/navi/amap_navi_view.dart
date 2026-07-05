import 'dart:convert';

import 'package:flutter_amap_base/amap_base.dart';
import 'package:flutter_amap_base/src/common/misc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

const _viewType = 'me.yohom/AMapView_nav';

typedef void NavCreatedCallback(NaviMapController controller);

class AMapNavView extends StatelessWidget {
  const AMapNavView({
    Key? key,
    this.onMapNavViewCreated,
    this.hitTestBehavior = PlatformViewHitTestBehavior.opaque,
    this.layoutDirection,
    required this.amapNavOptions,
  }) : super(key: key);

  final NavCreatedCallback? onMapNavViewCreated;
  final PlatformViewHitTestBehavior? hitTestBehavior;
  final TextDirection? layoutDirection;
  final AMapNavOptions? amapNavOptions;

  @override
  Widget build(BuildContext context) {
    devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    final gestureRecognizers = <Factory<OneSequenceGestureRecognizer>>[
      Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
    ].toSet();

    final String params = jsonEncode(amapNavOptions?.toJson());
    final messageCodec = StandardMessageCodec();
    if (defaultTargetPlatform == TargetPlatform.android) {
      //TODO add platform view
      return AndroidView(
        viewType: _viewType,
        hitTestBehavior: hitTestBehavior!,
        gestureRecognizers: gestureRecognizers,
        onPlatformViewCreated: _onViewCreated,
        layoutDirection: layoutDirection,
        creationParams: params,
        creationParamsCodec: messageCodec,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: _viewType,
        hitTestBehavior: hitTestBehavior!,
        gestureRecognizers: gestureRecognizers,
        onPlatformViewCreated: _onViewCreated,
        layoutDirection: layoutDirection,
        creationParams: params,
        creationParamsCodec: messageCodec,
      );
    } else {
      return Text(
        '$defaultTargetPlatform is not yet supported by the maps plugin',
      );
    }
  }

  void _onViewCreated(int id) {
    print('-----------------------onViewCreated $id');
    final controller = NaviMapController.withId(id);
    if (onMapNavViewCreated != null) {
      onMapNavViewCreated!(controller);
    }
  }
}

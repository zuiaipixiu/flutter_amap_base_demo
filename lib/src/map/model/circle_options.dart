import 'dart:convert';

import 'package:flutter_amap_base/amap_base.dart';
import 'package:flutter/material.dart';

class CircleOptions {

  final LatLng target;
  final double radius;
  final Color fillColor ;
  final Color strokeColor ;
  final double strokeWidth;

  CircleOptions({
    required this.target,
    required this.radius,
    this.fillColor = Colors.black,
    this.strokeColor = Colors.black,
    this.strokeWidth = 2.0,
  });

  Map<String, dynamic> toJson() {
    return {'target': target.toJson(), 'radius': radius,
      'fillColor': fillColor.value.toRadixString(16),
      'strokeColor': strokeColor.value.toRadixString(16),
      'strokeWidth': strokeWidth,};
  }

  String toJsonString() => jsonEncode(toJson());

 
}

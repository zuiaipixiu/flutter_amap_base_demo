import 'dart:convert';

import 'package:flutter_amap_base/amap_base.dart';

class RoutePoiResult {
  List<RoutePoiItem>? routePoiList;
  Map? query;

  RoutePoiResult.fromJson(Map<String, dynamic> json) {
    if (json['routePoiList'] != null) {
      routePoiList = [];
      json['routePoiList'].forEach((v) {
        routePoiList?.add(RoutePoiItem.fromJson(v));
      });
    }
    query = json['query'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['routePoiList'] = routePoiList?.map((it) => it.toJson()).toList();
    data['query'] = query;
    return data;
  }

  @override
  String toString() {
    return 'RoutePoiResult{routePoiList: $routePoiList, query: $query}';
  }
}

class RoutePoiItem {
  String? id;
  String? title;
  LatLng? point;
  num? distance;
  num? duration;

  RoutePoiItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    point = LatLng.fromJson(json['point']);
    distance = json['distance'];
    duration = json['duration'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['point'] = point?.toJson();
    data['distance'] = distance;
    data['duration'] = duration;
    return data;
  }

  @override
  String toString() {
    return JsonEncoder.withIndent('  ').convert(toJson());
  }
}

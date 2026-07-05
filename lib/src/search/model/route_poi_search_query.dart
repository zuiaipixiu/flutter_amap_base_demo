import 'dart:convert';

import 'package:flutter_amap_base/amap_base.dart';

class RoutePoiSearchQuery {
  LatLng? from;
  LatLng? to;
  int? mode;
  int? searchType;
  int? range;
  List<LatLng>? polylines;

  RoutePoiSearchQuery.line({
    required this.from,
    required this.to,
    required this.searchType,
    this.mode = 0,
    this.range = 250,
  });

  RoutePoiSearchQuery.polygon({
    required this.searchType,
    required this.polylines,
    this.range = 250,
  });

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'mode': mode,
      'searchType': searchType,
      'range': range,
      'polylines': polylines,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  @override
  String toString() {
    return 'RoutePOISearchQuery{from: $from, to: $to, mode: $mode, searchType: $searchType, range: $range, polylines: $polylines}';
  }
}

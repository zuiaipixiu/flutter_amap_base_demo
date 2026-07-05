import 'dart:convert';

import 'package:flutter_amap_base/amap_base.dart';

class DriveRouteResult {
  List<DrivePath>? paths;
  LatLng? startPos;
  LatLng? targetPos;
  num? taxiCost;

  DriveRouteResult({
    this.paths,
    this.startPos,
    this.targetPos,
    this.taxiCost,
  });

  DriveRouteResult.fromJson(Map<String, dynamic> json) {
    if (json['paths'] != null) {
      paths = [];
      json['paths'].forEach((v) {
        paths?.add(DrivePath.fromJson(v));
      });
    }
    startPos = json['startPos'] != null ? LatLng.fromJson(json['startPos']) : null;
    targetPos = json['targetPos'] != null ? LatLng.fromJson(json['targetPos']) : null;
    taxiCost = json['taxiCost'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (this.paths != null) {
      data['paths'] = this.paths?.map((v) => v.toJson()).toList();
    }
    if (this.startPos != null) {
      data['startPos'] = this.startPos?.toJson();
    }
    if (this.targetPos != null) {
      data['targetPos'] = this.targetPos?.toJson();
    }
    data['taxiCost'] = this.taxiCost;
    return data;
  }

  DriveRouteResult copyWith({
    List<DrivePath>? paths,
    LatLng? startPos,
    LatLng? targetPos,
    num? taxiCost,
  }) {
    return DriveRouteResult(
      paths: paths ?? this.paths,
      startPos: startPos ?? this.startPos,
      targetPos: targetPos ?? this.targetPos,
      taxiCost: taxiCost ?? this.taxiCost,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriveRouteResult && runtimeType == other.runtimeType && paths == other.paths && startPos == other.startPos && targetPos == other.targetPos && taxiCost == other.taxiCost;

  @override
  int get hashCode => paths.hashCode ^ startPos.hashCode ^ targetPos.hashCode ^ taxiCost.hashCode;

  @override
  String toString() {
    return JsonEncoder.withIndent('  ').convert(toJson());
  }
}

class DrivePath {
  num? restriction;
  List<Steps>? steps;
  String? strategy;
  num? tollDistance;
  num? totalDuration;

  ///预计耗时（单位：秒）
  num? totalDistance;

  ///起点和终点的距离
  num? tolls;
  num? totalTrafficlights;

  DrivePath({
    this.restriction,
    this.steps,
    this.strategy,
    this.tollDistance,
    this.totalDuration,
    this.totalDistance,
    this.tolls,
    this.totalTrafficlights,
  });

  DrivePath.fromJson(Map<String, dynamic> json) {
    restriction = json['restriction'];
    if (json['steps'] != null) {
      steps = [];
      json['steps'].forEach((v) {
        steps?.add(Steps.fromJson(v));
      });
    }
    strategy = json['strategy'];
    tollDistance = json['tollDistance'];
    totalDuration = json['totalDuration'];
    totalDistance = json['totalDistance'];
    tolls = json['tolls'];
    totalTrafficlights = json['totalTrafficlights'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['restriction'] = this.restriction;
    if (this.steps != null) {
      data['steps'] = this.steps?.map((v) => v.toJson()).toList();
    }
    data['strategy'] = this.strategy;
    data['tollDistance'] = this.tollDistance;
    data['totalDuration'] = this.totalDuration;
    data['totalDistance'] = this.totalDistance;
    data['tolls'] = this.tolls;
    data['totalTrafficlights'] = this.totalTrafficlights;
    return data;
  }

  DrivePath copyWith({
    int? restriction,
    List<Steps>? steps,
    String? strategy,
    num? tollDistance,
    num? totalDuration,
    num? totalDistance,
    num? tolls,
    int? totalTrafficlights,
  }) {
    return DrivePath(
      restriction: restriction ?? this.restriction,
      steps: steps ?? this.steps,
      strategy: strategy ?? this.strategy,
      tollDistance: tollDistance ?? this.tollDistance,
      totalDuration: totalDuration ?? this.totalDuration,
      totalDistance: totalDistance ?? this.totalDistance,
      tolls: tolls ?? this.tolls,
      totalTrafficlights: totalTrafficlights ?? this.totalTrafficlights,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is DrivePath && runtimeType == other.runtimeType && restriction == other.restriction && steps == other.steps && strategy == other.strategy && tollDistance == other.tollDistance && totalDuration == other.totalDuration && totalDistance == other.totalDistance && tolls == other.tolls && totalTrafficlights == other.totalTrafficlights;

  @override
  int get hashCode => restriction.hashCode ^ steps.hashCode ^ strategy.hashCode ^ tollDistance.hashCode ^ totalDuration.hashCode ^ totalDistance.hashCode ^ tolls.hashCode ^ totalTrafficlights.hashCode;

  @override
  String toString() {
    return '''Paths{
		restriction: $restriction,
		steps: $steps,
		strategy: $strategy,
		tollDistance: $tollDistance,
		totalDuration: $totalDuration,
		totalDistance: $totalDistance,
		tolls: $tolls,
		totalTrafficlights: $totalTrafficlights}''';
  }
}

class Steps {
  List<TMC>? TMCs;
  String? action;
  String? assistantAction;
  num? distance;
  num? duration;
  String? instruction;
  String? orientation;
  List<LatLng>? polyline;
  String? road;
  List<RouteSearchCityList>? routeSearchCityList;
  num? tollDistance;
  String? tollRoad;
  num? tolls;

  Steps({
    this.TMCs,
    this.action,
    this.assistantAction,
    this.distance,
    this.duration,
    this.instruction,
    this.orientation,
    this.polyline,
    this.road,
    this.routeSearchCityList,
    this.tollDistance,
    this.tollRoad,
    this.tolls,
  });

  Steps.fromJson(Map<String, dynamic> json) {
    if (json['TMCs'] != null) {
      TMCs = [];
      json['TMCs'].forEach((v) {
        TMCs?.add(TMC.fromJson(v));
      });
    }
    action = json['action'];
    assistantAction = json['assistantAction'];
    distance = json['distance'];
    duration = json['duration'];
    instruction = json['instruction'];
    orientation = json['orientation'];
    if (json['polyline'] != null) {
      polyline = [];
      json['polyline'].forEach((v) {
        polyline?.add(LatLng.fromJson(v));
      });
    }
    road = json['road'];
    if (json['routeSearchCityList'] != null) {
      routeSearchCityList = [];
      json['routeSearchCityList'].forEach((v) {
        routeSearchCityList?.add(RouteSearchCityList.fromJson(v));
      });
    }
    tollDistance = json['tollDistance'];
    tollRoad = json['tollRoad'];
    tolls = json['tolls'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (this.TMCs != null) {
      data['TMCs'] = this.TMCs?.map((v) => v.toJson()).toList();
    }
    data['action'] = this.action;
    data['assistantAction'] = this.assistantAction;
    data['distance'] = this.distance;
    data['duration'] = this.duration;
    data['instruction'] = this.instruction;
    data['orientation'] = this.orientation;
    if (this.polyline != null) {
      data['polyline'] = this.polyline?.map((v) => v.toJson()).toList();
    }
    data['road'] = this.road;
    if (this.routeSearchCityList != null) {
      data['routeSearchCityList'] = this.routeSearchCityList?.map((v) => v.toJson()).toList();
    }
    data['tollDistance'] = this.tollDistance;
    data['tollRoad'] = this.tollRoad;
    data['tolls'] = this.tolls;
    return data;
  }

  Steps copyWith({
    List<TMC>? TMCs,
    String? action,
    String? assistantAction,
    num? distance,
    num? duration,
    String? instruction,
    String? orientation,
    List<LatLng>? polyline,
    String? road,
    List<RouteSearchCityList>? routeSearchCityList,
    num? tollDistance,
    String? tollRoad,
    num? tolls,
  }) {
    return Steps(
      TMCs: TMCs ?? this.TMCs,
      action: action ?? this.action,
      assistantAction: assistantAction ?? this.assistantAction,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      instruction: instruction ?? this.instruction,
      orientation: orientation ?? this.orientation,
      polyline: polyline ?? this.polyline,
      road: road ?? this.road,
      routeSearchCityList: routeSearchCityList ?? this.routeSearchCityList,
      tollDistance: tollDistance ?? this.tollDistance,
      tollRoad: tollRoad ?? this.tollRoad,
      tolls: tolls ?? this.tolls,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is Steps && runtimeType == other.runtimeType && TMCs == other.TMCs && action == other.action && assistantAction == other.assistantAction && distance == other.distance && duration == other.duration && instruction == other.instruction && orientation == other.orientation && polyline == other.polyline && road == other.road && routeSearchCityList == other.routeSearchCityList && tollDistance == other.tollDistance && tollRoad == other.tollRoad && tolls == other.tolls;

  @override
  int get hashCode => TMCs.hashCode ^ action.hashCode ^ assistantAction.hashCode ^ distance.hashCode ^ duration.hashCode ^ instruction.hashCode ^ orientation.hashCode ^ polyline.hashCode ^ road.hashCode ^ routeSearchCityList.hashCode ^ tollDistance.hashCode ^ tollRoad.hashCode ^ tolls.hashCode;

  @override
  String toString() {
    return '''Steps{
		TMCs: $TMCs,
		action: $action,
		assistantAction: $assistantAction,
		distance: $distance,
		duration: $duration,
		instruction: $instruction,
		orientation: $orientation,
		polyline: $polyline,
		road: $road,
		routeSearchCityList: $routeSearchCityList,
		tollDistance: $tollDistance,
		tollRoad: $tollRoad,
		tolls: $tolls}''';
  }
}

/// 道路拥堵情况
class TMC {
  num? distance;
  List<LatLng>? polyline;
  String? status;

  TMC({
    this.distance,
    this.polyline,
    this.status,
  });

  TMC.fromJson(Map<String, dynamic> json) {
    distance = json['distance'];
    if (json['polyline'] != null) {
      polyline = [];
      json['polyline'].forEach((v) {
        polyline?.add(LatLng.fromJson(v));
      });
    }
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['distance'] = this.distance;
    if (this.polyline != null) {
      data['polyline'] = this.polyline?.map((v) => v.toJson()).toList();
    }
    data['status'] = this.status;
    return data;
  }

  TMC copyWith({
    int? distance,
    List<LatLng>? polyline,
    String? status,
  }) {
    return TMC(
      distance: distance ?? this.distance,
      polyline: polyline ?? this.polyline,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is TMC && runtimeType == other.runtimeType && distance == other.distance && polyline == other.polyline && status == other.status;

  @override
  int get hashCode => distance.hashCode ^ polyline.hashCode ^ status.hashCode;

  @override
  String toString() {
    return '''TMCs{
		distance: $distance,
		polyline: $polyline,
		status: $status}''';
  }
}

class RouteSearchCityList {
  List<Districts>? districts;

  RouteSearchCityList({
    this.districts,
  });

  RouteSearchCityList.fromJson(Map<String, dynamic> json) {
    if (json['districts'] != null) {
      districts = [];
      json['districts'].forEach((v) {
        districts?.add(Districts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (this.districts != null) {
      data['districts'] = this.districts?.map((v) => v.toJson()).toList();
    }
    return data;
  }

  RouteSearchCityList copyWith({
    List<Districts>? districts,
  }) {
    return RouteSearchCityList(
      districts: districts ?? this.districts,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is RouteSearchCityList && runtimeType == other.runtimeType && districts == other.districts;

  @override
  int get hashCode => districts.hashCode;

  @override
  String toString() {
    return '''RouteSearchCityList{
		districts: $districts}''';
  }
}

class Districts {
  String? districtAdcode;
  String? districtName;

  Districts({
    this.districtAdcode,
    this.districtName,
  });

  Districts.fromJson(Map<String, dynamic> json) {
    districtAdcode = json['districtAdcode'];
    districtName = json['districtName'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['districtAdcode'] = this.districtAdcode;
    data['districtName'] = this.districtName;
    return data;
  }

  Districts copyWith({
    String? districtAdcode,
    String? districtName,
  }) {
    return Districts(
      districtAdcode: districtAdcode ?? this.districtAdcode,
      districtName: districtName ?? this.districtName,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is Districts && runtimeType == other.runtimeType && districtAdcode == other.districtAdcode && districtName == other.districtName;

  @override
  int get hashCode => districtAdcode.hashCode ^ districtName.hashCode;

  @override
  String toString() {
    return '''Districts{
		districtAdcode: $districtAdcode,
		districtName: $districtName}''';
  }
}

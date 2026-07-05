import 'package:flutter_amap_base/amap_base.dart';

// ignore: camel_case_types
class District_iOS {
  ///区域编码
  String? adcode;

  ///城市编码
  String? citycode;

  ///行政区名称
  String? name;

  ///级别
  String? level;

  ///城市中心点
  LatLng? center;

  ///下级行政区域数组
  List<District_iOS>? districts;

  ///行政区边界坐标点, String 数组
  List<String>? polylines;

  District_iOS({
    this.adcode,
    this.citycode,
    this.name,
    this.level,
    this.center,
    this.districts,
    this.polylines,
  });

  District_iOS.fromJson(Map<String, dynamic> json) {
    adcode = json['adcode'];
    citycode = json['citycode'];
    name = json['name'];
    level = json['level'];
    if (json['center'] != null) {
      center = LatLng.fromJson(json['center']);
    }
    if (json['districts'] != null) {
      districts = [];
      json['districts'].forEach((v) {
        districts?.add(District_iOS.fromJson(v));
      });
    }
    if (json['polylines'] != null) {
      polylines = [];
      json['polylines'].forEach((v) {
        polylines?.add(v);
      });
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'adcode': adcode,
      'citycode': citycode,
      'name': name,
      'level': level,
      'center': center,
      'districts': districts,
      'polylines': polylines,
    };
  }

  @override
  String toString() {
    return 'District_iOS{adcode: $adcode, citycode: $citycode, name: $name, level: $level, center: $center, districts: $districts, polylines: $polylines}';
  }
}

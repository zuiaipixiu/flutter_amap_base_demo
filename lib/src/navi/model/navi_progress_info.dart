class NaviProgressInfo {
  const NaviProgressInfo({
    required this.routeRemainDistance,
    required this.routeRemainTime,
  });

  /// 路线剩余距离（米）
  final int routeRemainDistance;

  /// 路线剩余时间（秒）
  final int routeRemainTime;

  factory NaviProgressInfo.fromDynamic(Object? data) {
    if (data is! Map) {
      throw ArgumentError('Invalid nav progress payload: $data');
    }
    return NaviProgressInfo(
      routeRemainDistance: (data['routeRemainDistance'] as num).toInt(),
      routeRemainTime: (data['routeRemainTime'] as num).toInt(),
    );
  }
}

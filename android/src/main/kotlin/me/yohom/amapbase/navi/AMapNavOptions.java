package me.yohom.amapbase.navi;

import com.amap.api.maps.model.LatLng;

public class AMapNavOptions {

    public static final int NAVI_TYPE_DRIVER = 0;
    public static final int NAVI_TYPE_WALK = 1;
    public static final int NAVI_TYPE_RIDE = 2;

    public AMapNavOptions(int navType, LatLng startLocation, LatLng endLocation, double bottomContentH) {
        this.navType = navType;
        this.startLocation = startLocation;
        this.endLocation = endLocation;
        this.bottomContentH = bottomContentH;
    }

    /// 导航模式
    int navType;

    /// 导航起点
    LatLng startLocation;

    /// 导航终点
    LatLng endLocation;

    ///底部地图内容绘制区域向上偏移的高度
    double bottomContentH;

    public int getNavType() {
        return navType;
    }

    public LatLng getStartLocation() {
        return startLocation;
    }

    public LatLng getEndLocation() {
        return endLocation;
    }

    public double getBottomContentH() {
        return bottomContentH;
    }
}

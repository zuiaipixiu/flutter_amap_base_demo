package me.yohom.amapbase.navi;

import com.amap.api.maps.model.LatLng;

public class AMapNavOptions {

    public static final int NAVI_TYPE_DRIVER = 0;
    public static final int NAVI_TYPE_WALK = 1;
    public static final int NAVI_TYPE_RIDE = 2;

    public AMapNavOptions(int navType, LatLng startLocation, LatLng endLocation, double bottomContentH, boolean useEmulatorNavi, int selectedRouteIndex, boolean hasPlannedRoutes, double selectedRouteDistance, long selectedRouteDuration, double selectedRouteMidLatitude, double selectedRouteMidLongitude) {
        this.navType = navType;
        this.startLocation = startLocation;
        this.endLocation = endLocation;
        this.bottomContentH = bottomContentH;
        this.useEmulatorNavi = useEmulatorNavi;
        this.selectedRouteIndex = selectedRouteIndex;
        this.hasPlannedRoutes = hasPlannedRoutes;
        this.selectedRouteDistance = selectedRouteDistance;
        this.selectedRouteDuration = selectedRouteDuration;
        this.selectedRouteMidLatitude = selectedRouteMidLatitude;
        this.selectedRouteMidLongitude = selectedRouteMidLongitude;
    }

    int navType;
    LatLng startLocation;
    LatLng endLocation;
    double bottomContentH;
    boolean useEmulatorNavi;
    int selectedRouteIndex;
    boolean hasPlannedRoutes;
    double selectedRouteDistance;
    long selectedRouteDuration;
    double selectedRouteMidLatitude;
    double selectedRouteMidLongitude;

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

    public boolean isUseEmulatorNavi() {
        return useEmulatorNavi;
    }

    public int getSelectedRouteIndex() {
        return selectedRouteIndex;
    }

    public boolean isHasPlannedRoutes() {
        return hasPlannedRoutes;
    }

    public double getSelectedRouteDistance() {
        return selectedRouteDistance;
    }

    public long getSelectedRouteDuration() {
        return selectedRouteDuration;
    }

    public double getSelectedRouteMidLatitude() {
        return selectedRouteMidLatitude;
    }

    public double getSelectedRouteMidLongitude() {
        return selectedRouteMidLongitude;
    }
}

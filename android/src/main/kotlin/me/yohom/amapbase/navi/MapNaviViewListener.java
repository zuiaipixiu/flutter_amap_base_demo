package me.yohom.amapbase.navi;

import android.util.Log;

import com.amap.api.navi.AMapNaviViewListener;

public abstract class MapNaviViewListener implements AMapNaviViewListener {
    String TAG = "dsm_navi_view";
    @Override
    public void onNaviSetting() {
        Log.d(TAG, "onNaviSetting: ");
    }

    @Override
    public void onNaviCancel() {
        Log.d(TAG, "onNaviCancel: ");

    }

    @Override
    public boolean onNaviBackClick() {
        return false;
    }

    @Override
    public void onNaviMapMode(int i) {
        Log.d(TAG, "onNaviMapMode: ");

    }

    @Override
    public void onNaviTurnClick() {
        Log.d(TAG, "onNaviTurnClick: ");

    }

    @Override
    public void onNextRoadClick() {
        Log.d(TAG, "onNextRoadClick: ");

    }

    @Override
    public void onScanViewButtonClick() {
        Log.d(TAG, "onScanViewButtonClick: ");

    }

//    @Override
//    public void onLockMap(boolean b) {
//        Log.d(TAG, "onLockMap: "+ b);
//
//    }

    @Override
    public void onNaviViewLoaded() {
        Log.d(TAG, "onNaviViewLoaded: ");

    }

    @Override
    public void onMapTypeChanged(int i) {
        Log.d(TAG, "onMapTypeChanged: ");

    }

//    @Override
//    public void onNaviViewShowMode(int i) {
//        Log.d(TAG, "onNaviViewShowMode: "+ i);
//
//
//    }
}

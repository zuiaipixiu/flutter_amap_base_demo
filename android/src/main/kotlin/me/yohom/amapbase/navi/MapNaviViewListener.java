package me.yohom.amapbase.navi;

import android.util.Log;

import com.amap.api.navi.AMapNaviViewListener;
import com.amap.api.navi.AmapPageType;

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

    @Override
    public void onStopSpeaking() {
        Log.d(TAG, "onStopSpeaking: ");
    }

    @Override
    public void onViewTypeChanged(AmapPageType amapPageType) {
        Log.d(TAG, "onViewTypeChanged: ");
    }

    @Override
    public void onAMapNaviViewExit() {
        Log.d(TAG, "onAMapNaviViewExit: ");
    }

    @Override
    public void onStrategyChanged(int i) {
        Log.d(TAG, "onStrategyChanged: ");
    }

    @Override
    public void onBroadcastModeChanged(int i) {
        Log.d(TAG, "onBroadcastModeChanged: ");
    }

    @Override
    public void onDayAndNightModeChanged(int i) {
        Log.d(TAG, "onDayAndNightModeChanged: ");
    }

    @Override
    public void onScaleAutoChanged(boolean b) {
        Log.d(TAG, "onScaleAutoChanged: ");
    }

    @Override
    public void onListenToVoiceDuringCallChanged(boolean b) {
        Log.d(TAG, "onListenToVoiceDuringCallChanged: ");
    }

    @Override
    public void onControlMusicVolumeModeChanged(int i) {
        Log.d(TAG, "onControlMusicVolumeModeChanged: ");
    }

    @Override
    public void onEagleChanged(boolean b) {
        Log.d(TAG, "onEagleChanged: ");
    }

    @Override
    public void onNaviRouteHighlightChange(long l, int i) {
        Log.d(TAG, "onNaviRouteHighlightChange: ");
    }

//    @Override
//    public void onNaviViewShowMode(int i) {
//        Log.d(TAG, "onNaviViewShowMode: "+ i);
//
//
//    }
}

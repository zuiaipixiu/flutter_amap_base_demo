package me.yohom.amapbase.location;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Binder;
import android.os.IBinder;
import android.os.PowerManager;
import android.util.Log;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.location.AMapLocationListener;

import androidx.annotation.Nullable;

import static me.yohom.amapbase.AMapBasePlugin.registrar;

public class LocationService extends Service {
    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        System.out.println( "dsm_service onBind: ");
        try {
            locationClient = new AMapLocationClient(this);
            startForeground(NotifyUtils.NOTIFY_ID, NotifyUtils.buildNotification(this));
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        return new LocalBinder();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        System.out.println( "dsm_service onStartCommand: ");
//        Log.d("dsm_service", "onStartCommand: "+ this);
        return super.onStartCommand(intent, flags, startId);
    }

    @Override
    public boolean onUnbind(Intent intent) {
        deactiveAlarm();
        return super.onUnbind(intent);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        deactiveAlarm();
    }

    private AMapLocationClient locationClient;
    private AMapLocationListener mapLocationListener;
    private PowerManager.WakeLock wakeLock = null;
    private String TAG =  "LocationService";

    public void setLocationListener(AMapLocationListener listener) {
        System.out.println( "dsm_service dsm_service onStartCommand: etLocationListener: locationclient null?"+ (locationClient == null));
        this.mapLocationListener = listener;
        locationClient.setLocationListener(this.mapLocationListener);
    }

    public AMapLocationClient getLocationClient() {
        return locationClient;
    }

    //start locating according to option
    public void startLocate(AMapLocationClientOption option) {
//        locationClient = new AMapLocationClient(registrar.activity().getApplicationContext());
//        if (mapLocationListener != null) {
//            locationClient.setLocationListener(this.mapLocationListener);
//        }
        System.out.println( "dsm_service startLocating: in service: ");
//        Log.d("dsm_service", "startLocating: in service");
        locationClient.setLocationOption(option);
        locationClient.startLocation();

        activeRepeatedly();

    }

    public void stopLocating(){
        Log.d("dsm_service", "stopLocating: in service");
        if (locationClient != null) {
            locationClient.stopLocation();
        }


    }

    private AlarmManager alarmManager;
    private void activeRepeatedly(){
        Intent intent = new Intent("TFDRIVER_LOCATION_CLOCK");
        PendingIntent pendingIntent = PendingIntent.getBroadcast(this, 0, intent, 0);
        alarmManager = (AlarmManager)getSystemService(ALARM_SERVICE);
        alarmManager.cancel(pendingIntent);
        long second = 20 * 1000; //actually interval millis is at least one minute in android
        alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, System.currentTimeMillis(), second, pendingIntent);
        Log.d("dsm_service", "sendbroadcast: in service");
        acquireWakeLock();

    }
    /**

     获取电源锁，保持该服务在屏幕熄灭时仍然获取CPU时，保持运行

     */

    private void acquireWakeLock() {

        if (null == wakeLock) {

            PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);

            wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK

                    | PowerManager.ON_AFTER_RELEASE, getClass()

                    .getCanonicalName());

            if (null != wakeLock) {

                Log.i(TAG, "call acquireWakeLock");

                wakeLock.acquire(10*60*1000L /*10 minutes*/);

            }

        }

    }

// 释放设备电源锁
    private void releaseWakeLock() {
        if (null != wakeLock && wakeLock.isHeld()) {
            Log.i(TAG, "call releaseWakeLock");
            wakeLock.release();

            wakeLock = null;

        }

    }

    //stop the alarm
    public void deactiveAlarm() {

        locationClient.unRegisterLocationListener(mapLocationListener);
        if (alarmManager != null){
            Intent intent = new Intent("TFDRIVER_LOCATION_CLOCK");
            PendingIntent pendingIntent = PendingIntent.getBroadcast(this, 0, intent, 0);
            alarmManager.cancel(pendingIntent);
        }
        releaseWakeLock();
    }


    public class LocalBinder extends Binder{
        public Service getService(){
            return LocationService.this;
        }
    }
}

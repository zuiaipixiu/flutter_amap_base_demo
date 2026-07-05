package me.yohom.amapbase.location

//import me.yohom.amapbase.location.Init.locationClient

import android.annotation.SuppressLint
import android.content.ComponentName
import android.content.ServiceConnection
import android.os.IBinder
import android.util.Log
import com.amap.api.location.AMapLocationClient
import com.amap.api.maps.MapsInitializer
import me.yohom.amapbase.location.LocationService
import me.yohom.amapbase.location.NotifyUtils
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import me.yohom.amapbase.AMapBasePlugin.Companion.registrar
import me.yohom.amapbase.LocationMethodHandler
import me.yohom.amapbase.common.log
import me.yohom.amapbase.common.parseFieldJson
import me.yohom.amapbase.common.toFieldJson
import me.yohom.amapbase.location.Init.locationClient


object Init : LocationMethodHandler, ServiceConnection {
    @SuppressLint("StaticFieldLeak")
    lateinit var locationClient: AMapLocationClient

    private var locationEventChannel: EventChannel? = null
    var eventSink: EventChannel.EventSink? = null
        private set

    fun registerEventChannel(messenger: io.flutter.plugin.common.BinaryMessenger) {
        if (locationEventChannel != null) {
            return
        }
        locationEventChannel = EventChannel(messenger, "me.yohom/location_event")
        locationEventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(p0: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
            }

            override fun onCancel(p0: Any?) {
                eventSink = null
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        registerEventChannel(registrar.messenger())

        if (!::locationClient.isInitialized) {
            Log.d("dsm_flutter", "----------location client init ")
            locationClient = AMapLocationClient(registrar.activity()?.applicationContext).apply {
                setLocationListener {
                    eventSink?.success(UnifiedAMapLocation(it).toFieldJson())
                }
            }
        }

        //deprecated service
//        registrar.activity().bindService(Intent(registrar.activity(), LocationService::class.java), this, BIND_AUTO_CREATE)

        result.success("初始化成功")
    }


    override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
        Log.d("dsm_service", "onServiceConnected")
        val binder: LocationService.LocalBinder = service as LocationService.LocalBinder;
        mLocationService = binder.service as LocationService
        locationClient = mLocationService.locationClient
        mLocationService.setLocationListener {
            Log.d("dsm_service", "listener:" + this + "  location" + UnifiedAMapLocation(it).toFieldJson()[0].toString())
            eventSink?.success(UnifiedAMapLocation(it).toFieldJson())
        }
    }

    override fun onServiceDisconnected(name: ComponentName?) {
        Log.d("dsm_service", "onServiceDisconnected")
    }

}

lateinit var mLocationService: LocationService;

object StartLocate : LocationMethodHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val optionJson = call.argument<String>("options") ?: "{}"

        log("startLocate android端: options.toJsonString() -> $optionJson")
        val clientOptions = optionJson.parseFieldJson<UnifiedLocationClientOptions>().toLocationClientOptions()
        locationClient.setLocationOption(clientOptions)

        if (clientOptions.isOnceLocation) {
            var replied = false
            locationClient.setLocationListener { location ->
                val json = UnifiedAMapLocation(location).toFieldJson()
                Init.eventSink?.success(json)
                if (!replied) {
                    replied = true
                    result.success(json)
                    locationClient.stopLocation()
                }
            }
            locationClient.startLocation()
        } else {
            locationClient.startLocation()
            result.success("开始定位")
        }

        //deprecated service
//        mLocationService?.startLocate(optionJson.parseFieldJson<UnifiedLocationClientOptions>().toLocationClientOptions())
//        result.success("开始定位")
    }
}

object StopLocate : LocationMethodHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

        locationClient.stopLocation()
        //deprecated service
//        if (mLocationService != null) {
//            mLocationService.stopLocating()
//        }
        log("停止定位")
        Log.d("dsm_service", "停止定位")

        result.success("停止定位")
    }
}

object UnbindService : LocationMethodHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (Init != null) {
            Log.d("dsm_service_unbind", "init: " + Init)
            registrar.activity()?.unbindService(Init)
        }
        Log.d("dsm_service_unbind", "注销服务")
        result.success("注销定位服务")
    }
}

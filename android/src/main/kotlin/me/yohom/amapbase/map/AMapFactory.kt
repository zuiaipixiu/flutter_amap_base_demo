package me.yohom.amapbase.map

import android.annotation.SuppressLint
import android.app.Activity
import android.app.Application
import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.util.Log
import android.view.View
import com.amap.api.maps.*
import com.amap.api.maps.AMap.OnCameraChangeListener
import com.amap.api.maps.model.*
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import me.yohom.amapbase.*
import me.yohom.amapbase.AMapBasePlugin.Companion.registrar
import me.yohom.amapbase.common.parseFieldJson
import me.yohom.amapbase.common.toFieldJson
import me.yohom.amapbase.location.Init.locationClient
import me.yohom.amapbase.navi.HeatMapActivity
import java.util.*
import java.util.concurrent.atomic.AtomicInteger


const val mapChannelName = "me.yohom/map"
const val markerClickedChannelName = "me.yohom/marker_clicked"
const val mapMovedChannelName = "me.yohom/map_moved"
const val success = "调用成功"

class AMapFactory(private val activityState: AtomicInteger)
    : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, id: Int, params: Any?): PlatformView {

        val view = AMapView(
                context,
                id,
                activityState,
                (params as String).parseFieldJson<UnifiedAMapOptions>().toAMapOption()
        )
        view.setup()
        return view
    }
}

@SuppressLint("CheckResult")
class AMapView(context: Context,
               private val id: Int,
               private val activityState: AtomicInteger,
               amapOptions: AMapOptions) : PlatformView, Application.ActivityLifecycleCallbacks {

    private val mapView = TextureMapView(context, amapOptions)
    private var mAMap: AMap? = null
    private var disposed = false
    private val registrarActivityHashCode: Int = AMapBasePlugin.registrar.activity().hashCode()

    override fun getView(): View = mapView

    override fun dispose() {
//        Log.d("dsm_flutter","amapfactory.kt dispose")
        if (disposed) {
            return
        }
        disposed = true
        mapView.onDestroy()

        registrar.activity()?.application?.unregisterActivityLifecycleCallbacks(this)
    }
    private val STROKE_COLOR: Int = Color.argb(180, 3, 145, 255)
    private val FILL_COLOR: Int = Color.argb(10, 0, 0, 180)
    fun setup() {
      
        mAMap = mapView.map;
        when (activityState.get()) {
            STOPPED -> {
//                Log.d("dsm_flutter", "STOPPED")
                mapView.onCreate(null)
                mapView.onResume()
                mapView.onPause()
            }
            RESUMED -> {
//                Log.d("dsm_flutter", "RESUMED")
                mapView.onCreate(null)
                mapView.onResume()
                //we suppose the moment this class created, the activity state must be RESUMED
                savedMarkers.clear()
            }
            CREATED -> {
//                Log.d("dsm_flutter", "CREATED")
                mapView.onCreate(null)
            }
            DESTROYED -> {
//                Log.d("dsm_flutter", "DESTROYED")
            }
            else -> throw IllegalArgumentException("Cannot interpret " + activityState.get() + " as an activity activityState")
        }


        // 地图相关method channel
        val mapChannel = MethodChannel(registrar.messenger(), "$mapChannelName$id")
        mapChannel.setMethodCallHandler { call, result ->
            MAP_METHOD_HANDLER[call.method]
                    ?.with(mapView.map)
                    ?.onMethodCall(call, result) ?: result.notImplemented()
        }

        // marker click event channel
        var eventSink: EventChannel.EventSink? = null
        val markerClickedEventChannel = EventChannel(registrar.messenger(), "$markerClickedChannelName$id")
        markerClickedEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(p0: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
            }

            override fun onCancel(p0: Any?) {}
        })
        mapView.map.setOnMarkerClickListener { marker ->
//            println(marker);
            Log.d("setOnMar",marker.title)
            Log.d("setOnMar",marker.snippet)
            Log.d("setOnMar options",marker.options.title)
            if(marker.isInfoWindowShown){
                marker.hideInfoWindow()
            }else{
                marker.showInfoWindow()
            }
            eventSink?.success(UnifiedMarkerOptions(marker.options).toFieldJson())
            true
        }
        //地图移动事件
        var moveEventSink: EventChannel.EventSink? = null
        val mapMovedEventChannel = EventChannel(registrar.messenger(), "$mapMovedChannelName$id")
        mapMovedEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(p0: Any?, sink: EventChannel.EventSink?) {
                moveEventSink = sink
            }

            override fun onCancel(p0: Any?) {}
        })

        mapView.map.setOnCameraChangeListener(object : OnCameraChangeListener {
            override fun onCameraChangeFinish(position: CameraPosition) {
                moveEventSink?.success(UnifiedCameraPosition(position).toFieldJson())
            }

            override fun onCameraChange(position: CameraPosition) {
//                moveEventSink?.success(UnifiedCameraPosition(position).toFieldJson())
            }
        })

        // 注册生命周期
        registrar.activity()?.application?.registerActivityLifecycleCallbacks(this)

    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
//        Log.d("dsm_flutter", "onActivityCreated")
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        mapView.onCreate(savedInstanceState)
        mAMap = mapView.map;

    }

    override fun onActivityStarted(activity: Activity) {
//        Log.d("dsm_flutter", "onActivityStarted")
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
    }

    override fun onActivityResumed(activity: Activity) {
//        Log.d("dsm_flutter", "onActivityResumed")
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        mapView.onResume()
    }

    override fun onActivityPaused(activity: Activity) {
//        Log.d("dsm_flutter", "onActivityPaused")
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        mapView.onPause()
    }

    override fun onActivityStopped(activity: Activity) {
//        Log.d("dsm_flutter", "onActivityStopped")
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
    }

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        mapView.onSaveInstanceState(outState)
    }

    override fun onActivityDestroyed(activity: Activity) {
//        Log.d("dsm_flutter", "onActivityDestroyed")
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        dispose()
        savedMarkers.clear()
        locationClient.onDestroy()
        mapView.onDestroy()
    }



}
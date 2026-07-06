package me.yohom.amapbase.navi.handler

import android.util.Log
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.Poi
import com.amap.api.navi.AMapNavi
import com.amap.api.navi.AmapNaviPage
import com.amap.api.navi.AmapNaviParams
import com.amap.api.navi.AmapNaviType
import com.amap.api.navi.enums.PathPlanningStrategy
import com.amap.api.navi.model.NaviLatLng
import me.yohom.amapbase.navi.AMapNavOptions
import me.yohom.amapbase.navi.NaviView
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import me.yohom.amapbase.AMapBasePlugin
import me.yohom.amapbase.AMapBasePlugin.Companion.registrar
import me.yohom.amapbase.NaviMethodHandler
import me.yohom.amapbase.map.success
import org.json.JSONObject

object StartNavi : NaviMethodHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val lat = call.argument<Double>("lat")!!
        val lon = call.argument<Double>("lon")!!
        val naviType = call.argument<Int>("naviType") ?: AmapNaviType.DRIVER

        val end = Poi(null, LatLng(lat, lon), "")
        AmapNaviPage.getInstance().showRouteActivity(
                registrar.activity(),
                AmapNaviParams(null, null, end, when (naviType) {
                    0 -> AmapNaviType.DRIVER
                    1 -> AmapNaviType.WALK
                    2 -> AmapNaviType.RIDE
                    else -> AmapNaviType.DRIVER
                }),
                null
        )
        result.success(success)
    }
}

// object CustomSpeak : NaviMethodHandler {
//     override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
//         //stop navi from the amapnavi instance
//         val speak = call.argument<Double>("speak") ?: true
//         val currentNavi = AMapNavi.getInstance(registrar.activity().applicationContext)
//         // currentNavi?.stopNavi()
   
//         if(speak){
//             currentNavi?.stopSpeak()
//         }else{
//             currentNavi?.startSpeak()
//         }
//         result.success(success)
//     }
// }
object StopCustomNavi : NaviMethodHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        //stop navi from the amapnavi instance

        val currentNavi = AMapNavi.getInstance(registrar.activity()?.applicationContext)
        currentNavi?.stopNavi()
        currentNavi?.stopSpeak()
        result.success(success)
    }
}

object DestroyCustomNavi : NaviMethodHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        //stop navi from the amapnavi instance
        //Log.e("bear","DestroyCustomNavi");
        val currentNavi = AMapNavi.getInstance(registrar.activity()?.applicationContext)
        currentNavi?.stopNavi()
        currentNavi?.stopSpeak()
//        currentNavi?.destroy()
        result.success(success)
    }
}




object ChangeMapRouteNaviWithInfo : NaviMethodHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

        //params
        val startStr = call.argument<String>("startLocation")!!
        val endStr = call.argument<String>("endLocation")!!
        val startJson = JSONObject(startStr)
        val endJson = JSONObject(endStr)
        val startLocation = LatLng(startJson.optDouble("latitude"), startJson.optDouble("longitude"))
        val endLocation = LatLng(endJson.optDouble("latitude"), endJson.optDouble("longitude"))
        val navType = call.argument<Int>("navType") ?: AmapNaviType.DRIVER //default as
        val bottomContentH = call.argument<Double>("bottomContentH ") ?: 100.0
        val useEmulatorNavi = call.argument<Boolean>("useEmulatorNavi") ?: false
        val selectedRouteIndex = call.argument<Int>("selectedRouteIndex") ?: 0
        val hasPlannedRoutes = call.argument<Boolean>("hasPlannedRoutes") ?: false
        val selectedRouteDistance = call.argument<Number>("selectedRouteDistance")?.toDouble() ?: 0.0
        val selectedRouteDuration = call.argument<Number>("selectedRouteDuration")?.toLong() ?: 0L
        val selectedRouteMidLatitude = call.argument<Number>("selectedRouteMidLatitude")?.toDouble() ?: 0.0
        val selectedRouteMidLongitude = call.argument<Number>("selectedRouteMidLongitude")?.toDouble() ?: 0.0

        NaviView.activeUseEmulatorNavi = useEmulatorNavi
        NaviView.activeSelectedRouteIndex = selectedRouteIndex
        NaviView.activeHasPlannedRoutes = hasPlannedRoutes
        NaviView.activeSelectedRouteDistance = selectedRouteDistance
        NaviView.activeSelectedRouteDuration = selectedRouteDuration
        NaviView.activeSelectedRouteMidLatitude = selectedRouteMidLatitude
        NaviView.activeSelectedRouteMidLongitude = selectedRouteMidLongitude

        val mapNav = AMapNavi.getInstance(registrar.context())
        mapNav.stopNavi()
        mapNav.stopSpeak()
        //驾车路径计算
        val start = NaviLatLng(startLocation.latitude, startLocation.longitude)
        val end = NaviLatLng(endLocation.latitude, endLocation.longitude)

        when (navType) {
            AMapNavOptions.NAVI_TYPE_DRIVER -> {
                mapNav.setMultipleRouteNaviMode(hasPlannedRoutes)
                val strategy = if (hasPlannedRoutes) {
                    PathPlanningStrategy.DRIVING_MULTIPLE_ROUTES_DEFAULT
                } else {
                    mapNav.strategyConvert(true, false, false, false, false)
                }
                mapNav.calculateDriveRoute(listOf(start), listOf(end), null, strategy)
            }

            AMapNavOptions.NAVI_TYPE_RIDE ->
                mapNav.calculateRideRoute(start, end)

            AMapNavOptions.NAVI_TYPE_WALK ->
                mapNav.calculateWalkRoute(start, end)
        }

        result.success(success)
    }
}

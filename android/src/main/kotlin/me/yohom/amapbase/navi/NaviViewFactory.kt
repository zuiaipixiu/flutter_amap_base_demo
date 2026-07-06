package me.yohom.amapbase.navi
import android.widget.LinearLayout.LayoutParams
import android.annotation.SuppressLint
import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.res.Resources
import android.graphics.Color
import android.os.Bundle
import android.util.DisplayMetrics
import android.util.Log
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import com.amap.api.maps.MapsInitializer
import com.amap.api.maps.model.*
import com.amap.api.navi.AMapNavi
import com.amap.api.navi.AMapNaviView
import com.amap.api.navi.AMapNaviViewOptions
import com.amap.api.navi.NaviSetting
import com.amap.api.navi.enums.NaviType
import com.amap.api.navi.enums.PathPlanningStrategy
import com.amap.api.navi.model.*
import com.amap.api.navi.view.NextTurnTipView
import com.amap.api.navi.view.ZoomInIntersectionView
import com.amap.api.navi.view.TrafficProgressBar;
import com.amap.api.navi.view.AMapModeCrossOverlay;
import me.yohom.amapbase.R
import me.yohom.amapbase.navi.AMapNavOptions
import me.yohom.amapbase.navi.MapNaviListener
import me.yohom.amapbase.navi.MapNaviViewListener
import me.yohom.amapbase.navi.MapTouchListener

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import me.yohom.amapbase.*
import me.yohom.amapbase.AMapBasePlugin.Companion.registrar
import me.yohom.amapbase.common.parseFieldJson
import me.yohom.amapbase.map.success
import me.yohom.amapbase.map.UnifiedAMapNavOptions
import java.math.BigDecimal
import java.math.RoundingMode
import java.util.*
import java.util.concurrent.atomic.AtomicInteger
import kotlin.concurrent.schedule

const val navChannelName = "me.yohom/map_nav"
const val navInfoChannelName = "me.yohom/navi_info"

const val CREATED = 1
const val RESUMED = 3
const val STOPPED = 5
const val DESTROYED = 6

class NaviViewFactory(private val activityState: AtomicInteger)
    : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, id: Int, params: Any?): PlatformView {

        val view = NaviView(
                registrar.context(),
                id,
                activityState,
                (params as String).parseFieldJson<UnifiedAMapNavOptions>().toAMapNavOption()
        )

        view.setup()
        return view
    }
}

@SuppressLint("CheckResult")
class NaviView(context: Context,
               private val id: Int,
               private val activityState: AtomicInteger,
               naviOptions: AMapNavOptions
)
    : PlatformView, Application.ActivityLifecycleCallbacks {

    private val view: View = LayoutInflater.from(registrar.activity()).inflate(R.layout.amap_nav, null)

    private val navView: AMapNaviView = view.findViewById<AMapNaviView>(R.id.navi_view)
    var timer = Timer()
    private var touchTime : Long =  0

    private val mapNav = AMapNavi.getInstance(context)
    private val modeCrossOverlay = AMapModeCrossOverlay(context,navView.map)

    private var disposed = false
    private val registrarActivityHashCode: Int = registrar.activity().hashCode()
    private val naviOpts: AMapNavOptions = naviOptions;
    private var trafficBarView = TrafficProgressBar(context)
    private var useEmulatorNavi: Boolean = naviOptions.isUseEmulatorNavi
    private var naviInfoEventSink: EventChannel.EventSink? = null
    private var navigationTornDown = false

    companion object {
        @JvmStatic
        var activeUseEmulatorNavi: Boolean = false

        @JvmStatic
        var activeSelectedRouteIndex: Int = 0

        @JvmStatic
        var activeHasPlannedRoutes: Boolean = false

        @JvmStatic
        var activeSelectedRouteDistance: Double = 0.0

        @JvmStatic
        var activeSelectedRouteDuration: Long = 0

        @JvmStatic
        var activeSelectedRouteMidLatitude: Double = 0.0

        @JvmStatic
        var activeSelectedRouteMidLongitude: Double = 0.0

        @JvmStatic
        fun selectPlannedRoute(mapNav: AMapNavi, result: AMapCalcRouteResult?) {
            if (!activeHasPlannedRoutes) {
                return
            }
            val routeIds = result?.routeid ?: return
            if (routeIds.isEmpty()) {
                return
            }

            val hasRouteMidpoint = kotlin.math.abs(activeSelectedRouteMidLatitude) > 1.0 ||
                    kotlin.math.abs(activeSelectedRouteMidLongitude) > 1.0
            val selectedId = if (hasRouteMidpoint) {
                val naviPaths = mapNav.naviPaths
                routeIds.minByOrNull { id ->
                    val path = naviPaths[id] ?: return@minByOrNull Double.MAX_VALUE
                    val coords = path.coordList ?: return@minByOrNull Double.MAX_VALUE
                    if (coords.isEmpty()) {
                        return@minByOrNull Double.MAX_VALUE
                    }
                    val midPoint = coords[coords.size / 2]
                    kotlin.math.abs(midPoint.latitude - activeSelectedRouteMidLatitude) +
                            kotlin.math.abs(midPoint.longitude - activeSelectedRouteMidLongitude)
                } ?: routeIds[0]
            } else if (activeSelectedRouteDistance > 0) {
                val naviPaths = mapNav.naviPaths
                routeIds.minByOrNull { id ->
                    val path = naviPaths[id] ?: return@minByOrNull Long.MAX_VALUE
                    val distanceDiff = kotlin.math.abs(path.allLength - activeSelectedRouteDistance.toInt())
                    val durationDiff = if (activeSelectedRouteDuration > 0) {
                        kotlin.math.abs(path.allTime - activeSelectedRouteDuration.toInt())
                    } else {
                        0
                    }
                    distanceDiff * 10L + durationDiff
                } ?: routeIds[0]
            } else {
                routeIds[activeSelectedRouteIndex.coerceIn(0, routeIds.lastIndex)]
            }
            mapNav.selectRouteId(selectedId)
        }
    }

    override fun getView(): View = view //must return the whole view otherwise it does not work




    /**
     * 获取plugin自带的图片
     */
    fun getDefaultBitmapDescriptor(asset: String): BitmapDescriptor {
        return BitmapDescriptorFactory.fromAsset(registrar.lookupKeyForAsset(asset, "flutter_amap_base"))
    }
    fun setup() {
        useEmulatorNavi = naviOpts.isUseEmulatorNavi
        activeUseEmulatorNavi = useEmulatorNavi
        activeSelectedRouteIndex = naviOpts.selectedRouteIndex
        activeHasPlannedRoutes = naviOpts.hasPlannedRoutes
        activeSelectedRouteDistance = naviOpts.selectedRouteDistance
        activeSelectedRouteDuration = naviOpts.selectedRouteDuration
        activeSelectedRouteMidLatitude = naviOpts.selectedRouteMidLatitude
        activeSelectedRouteMidLongitude = naviOpts.selectedRouteMidLongitude
       
        navView.setAMapNaviViewListener(object : MapNaviViewListener() {
            override fun onLockMap(locked: Boolean) {
                Log.d("dsm_navi_locked", locked.toString());
                if (!locked) {
                    timer =  Timer("recoverlock", false)
                    timer.schedule(object : TimerTask() {
                        override fun run() {
                            Log.d("dsm_navi_locked ","time");
                            if(touchTime+4000<Calendar.getInstance().timeInMillis){
                                navView.recoverLockMode()
                            }
                        }
                    }, 5000, 5000)

                }else{
                    timer.cancel()
                }
            }

            override fun onNaviViewShowMode(p0: Int) {
//                Log.d("dsm_navi_showmode", p0.toString());
            }



        });


        navView.setOnMapTouchListener( object: MapTouchListener() {
            override fun onTouch(motionEvent: MotionEvent?) {
                touchTime= Calendar.getInstance().timeInMillis
                super.onTouch(motionEvent)
            }
        })






        //set the bottom padding from the car point
        val dm: DisplayMetrics = Resources.getSystem().displayMetrics
        val screenHeightDp: Float = dm.heightPixels / dm.density
        val paddingBottomPercent: Double = naviOpts.bottomContentH / screenHeightDp
        val options =  AMapNaviViewOptions()

        options.setPointToCenter(0.5, 0.5)
        options.setEndPointBitmap(getDefaultBitmapDescriptor("images/blank.png").getBitmap())
        options.setStartPointBitmap(getDefaultBitmapDescriptor("images/blank.png").getBitmap())

        val routeOverlayOptions = RouteOverlayOptions()
        routeOverlayOptions.arrowColor = Color.WHITE
        routeOverlayOptions.arrowSideColor = Color.parseColor("#4477FF")
        routeOverlayOptions.normalRoute = getDefaultBitmapDescriptor("images/unknow.png").getBitmap()
        routeOverlayOptions.smoothTraffic = getDefaultBitmapDescriptor("images/smooth.png").getBitmap() //畅通路况下
        routeOverlayOptions.slowTraffic = getDefaultBitmapDescriptor("images/slow.png").getBitmap() //缓慢路况下
        routeOverlayOptions.jamTraffic = getDefaultBitmapDescriptor("images/jam.png").getBitmap() //拥堵路况下
        routeOverlayOptions.veryJamTraffic = getDefaultBitmapDescriptor("images/veryjam.png").getBitmap() //严重拥堵路况下
        routeOverlayOptions.passRoute = getDefaultBitmapDescriptor("images/pass.png").getBitmap()
        routeOverlayOptions.unknownTraffic = getDefaultBitmapDescriptor("images/unknow.png").bitmap
        routeOverlayOptions.lineWidth = 22.0f
        options.isCompassEnabled =false //指南针是否显示
        options.carBitmap =  getDefaultBitmapDescriptor("images/icon_daohang.png").bitmap
        options.isTrafficBarEnabled=false;

        options.tilt = 50
        options.isLayoutVisible = true
        options.isAutoDrawRoute = true
        options.isAfterRouteAutoGray = true
        options.isTrafficBarEnabled=false
        options.isRealCrossDisplayShow = false
        options.setModeCrossDisplayShow(false)

        options.routeOverlayOptions = routeOverlayOptions
        navView.viewOptions = options

        trafficBarView = view.findViewById(R.id.myTrafficBar)
        trafficBarView.visibility = View.GONE

        val myNextTurnView: NextTurnTipView = view.findViewById(R.id.myNextTurnView) as NextTurnTipView
        navView.lazyNextTurnTipView = myNextTurnView;

        options.isLayoutVisible = false


       val viewlltop: LinearLayout = view.findViewById(R.id.lltop) as LinearLayout

//        val mAddressLayout = view.findViewById<LinearLayout>(R.id.ll_address_label)
//        val mAddressLabelTv = view.findViewById<TextView>(R.id.tv_address)
//        //have address
//        if (this@UnifiedMarkerOptions.haveAddressLabel == true) {
//            mAddressLabelTv.text = this@UnifiedMarkerOptions.addressLabelContent
////                        mAddressLabelTv.visibility = View.VISIBLE
//            mAddressLayout.visibility = View.VISIBLE//!!!
//
//            if (this@UnifiedMarkerOptions.icon != null || this@UnifiedMarkerOptions.haveBubble == true) {
////                            val param: ViewGroup.MarginLayoutParams = mAddressLabelTv.layoutParams as ViewGroup.MarginLayoutParams
//                val param: ViewGroup.MarginLayoutParams = mAddressLayout.layoutParams as ViewGroup.MarginLayoutParams
//                val density: Int = (Resources.getSystem().displayMetrics.density).toInt()
//                param.topMargin = -8 * density // about half height of one line
//            }

 

		//获取status_bar_height资源的ID
		val resourceId = Resources.getSystem().getIdentifier("status_bar_height", "dimen", "android");
		if (resourceId > 0) {
               val param: ViewGroup.MarginLayoutParams = viewlltop.layoutParams as ViewGroup.MarginLayoutParams
                param.topMargin =  Resources.getSystem().getDimensionPixelSize(resourceId);
			//根据资源ID获取响应的尺寸值
		}
     



        //根据当前状态初始化
        when (activityState.get()) {
            STOPPED -> {
                navView.onCreate(null)
                navView.onResume()
                navView.onPause()
            }
            RESUMED -> {
                navView.onCreate(null)
                navView.onResume()
            }
            CREATED -> {
                navView.onCreate(null)
            }
            DESTROYED -> {
                navView.setAMapNaviViewListener(null)
                navView.onDestroy()
                mapNav.stopNavi()
                mapNav.stopSpeak()
//                mapNav.destroy()

            }
            else -> throw IllegalArgumentException("Cannot interpret " + activityState.get() + " as an activity activityState")
        }


        // 导航相关method channel
        val naviChannel = MethodChannel(registrar.messenger(), "$navChannelName$id")
        naviChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "nav#destroyCustomeNavi" -> {
                    tearDownNavigationResources()
                    result.success(success)
                }
                else -> NAVI_METHOD_HANDLER[call.method]
                        ?.onMethodCall(call, result) ?: result.notImplemented()
            }
        }

        EventChannel(registrar.messenger(), "$navInfoChannelName$id").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                naviInfoEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                naviInfoEventSink = null
            }
        })


        // 注册生命周期
        registrar.activity()?.application?.registerActivityLifecycleCallbacks(this)



        //自定义顶部导航显示文字
        val tvNextDistense: TextView = view.findViewById(R.id.tvNextDistense) as TextView
        val tvNextRoad: TextView = view.findViewById(R.id.tvNextRoad) as TextView
        val tvDistense: TextView = view.findViewById(R.id.tvDistense) as TextView
        val tvTimeleave: TextView = view.findViewById(R.id.tvTimeleave) as TextView
        val tvNextDistenseUnit: TextView = view.findViewById(R.id.tvNextDistenseUnit) as TextView


        val myllZoomInIntersectionView: LinearLayout = view.findViewById(R.id.myllZoomInIntersectionView) as LinearLayout
        myllZoomInIntersectionView.visibility = View.GONE



        mapNav.addAMapNaviListener( object: MapNaviListener(){

            override fun onCalculateRouteSuccess(aMapCalcRouteResult: AMapCalcRouteResult?) {
                NaviView.selectPlannedRoute(mapNav, aMapCalcRouteResult)

                val naviType = if (useEmulatorNavi || activeUseEmulatorNavi) {
                    NaviType.EMULATOR
                } else {
                    NaviType.GPS
                }
                mapNav.startNavi(naviType)
                mapNav.startSpeak()

                Log.e("onCalculateRouteSuccess", "开始导航($naviType)======》")

            }

            override fun onGpsSignalWeak(p0: Boolean) {
                Log.e("手机卫星定位信号强弱变化的回调", "true: 信号弱;false：信号强 =====> $p0")
            }

            override fun showCross(aMapNaviCross: AMapNaviCross?) {
                myllZoomInIntersectionView.visibility = View.GONE
            }

            override fun showModeCross(aMapModelCross: AMapModelCross?) {
                myllZoomInIntersectionView.visibility = View.GONE
            }

            override fun hideModeCross() {
                Log.e("bear","hideModeCross  " )
                myllZoomInIntersectionView.visibility=View.GONE
            }

            override fun hideCross() {
                Log.e("bear","hideCross  " )
                myllZoomInIntersectionView.visibility=View.GONE
            }


            fun  format1(value: Double, count:Int): String? {
                var bd = BigDecimal(value)
                bd = bd.setScale(count, RoundingMode.HALF_UP)
                return bd.toString()
            }

            override fun onNaviInfoUpdate(naviInfo: NaviInfo) {

                //转换米和时间
                var curDistenseUnit="米"
                var curDistance = ""
                if(naviInfo.curStepRetainDistance>1000){
                    curDistance=  format1(naviInfo.curStepRetainDistance /1000.0,1) + ""
                    curDistenseUnit=  "公里"

                }else{
                    curDistance = format1(naviInfo.curStepRetainDistance *1.0,0) + ""
                    curDistenseUnit=  "米"
                }


                var pathDistance = "米"
                pathDistance = if(naviInfo.pathRetainDistance>1000){
                    format1(naviInfo.pathRetainDistance /1000.0,1)+ "公里"
                }else{
                    format1(naviInfo.pathRetainDistance *1.0,0) + "米"
                }


                var pathRetainTime= ""

                pathRetainTime = if(naviInfo.pathRetainTime> 3600){
                    (naviInfo.pathRetainTime/3600).toString()   + "小时"  +( (naviInfo.pathRetainTime % 3600) / 60) .toString()+"分钟"
                }else if(naviInfo.pathRetainTime> 60){
                    ( naviInfo.pathRetainTime  / 60) .toString()+"分钟"
                }else {
                    ( naviInfo.pathRetainTime ) .toString()+"秒"
                }



                tvNextDistenseUnit.text = curDistenseUnit
                tvNextDistense.text = curDistance
                tvNextRoad.text = naviInfo.nextRoadName
                tvDistense.text=  pathDistance
                tvTimeleave.text=  pathRetainTime

                naviInfoEventSink?.success(mapOf(
                    "routeRemainDistance" to naviInfo.pathRetainDistance,
                    "routeRemainTime" to naviInfo.pathRetainTime
                ))

            }


        })

        //set voice source
        mapNav.setUseInnerVoice(true)


        //setup the offline voice in the 4G circumstance
//        val naviSetting: NaviSetting = mapNav.getNaviSetting()
//        if (naviSetting != null) {
//            NaviSetting.setUseOfflineVoice(true)
//            NaviSetting.setIgnoreWifi(true)
//        }

        startNavi(naviOpts.startLocation, naviOpts.endLocation, naviOpts.navType)
    }




    //开始计算路径(并在计算完毕后开始导航)
    fun startNavi(startLocation: LatLng, endLocation: LatLng, type: Int) {
        mapNav.stopNavi()
        mapNav.stopSpeak()
        //驾车路径计算
        val start = NaviLatLng(startLocation.latitude, startLocation.longitude)
        val end = NaviLatLng(endLocation.latitude, endLocation.longitude)

        when (type) {
            AMapNavOptions.NAVI_TYPE_DRIVER -> {
                mapNav.setMultipleRouteNaviMode(activeHasPlannedRoutes)
                val strategy = if (activeHasPlannedRoutes) {
                    PathPlanningStrategy.DRIVING_MULTIPLE_ROUTES_DEFAULT
                } else {
                    PathPlanningStrategy.DRIVING_SHORTEST_DISTANCE
                }
                mapNav.calculateDriveRoute(listOf(start), listOf(end), null, strategy)
            }

            AMapNavOptions.NAVI_TYPE_RIDE ->
                mapNav.calculateRideRoute(start, end)

            AMapNavOptions.NAVI_TYPE_WALK ->
                mapNav.calculateWalkRoute(start, end)
        }
    }



    private fun tearDownNavigationResources() {
        if (navigationTornDown) {
            return
        }
        navigationTornDown = true
        naviInfoEventSink = null
        mapNav.stopNavi()
        mapNav.stopSpeak()
        if (!disposed) {
            navView.onPause()
            navView.onDestroy()
            disposed = true
        }
    }

    override fun dispose() {
        tearDownNavigationResources()
        registrar.activity()?.application?.unregisterActivityLifecycleCallbacks(this)
    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        navView.onCreate(savedInstanceState)
    }

    override fun onActivityStarted(activity: Activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
    }

    override fun onActivityResumed(activity: Activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        navView.onResume()
    }

    override fun onActivityPaused(activity: Activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        navView.onPause()
    }

    override fun onActivityStopped(activity: Activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
    }

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        navView.onSaveInstanceState(outState)
    }

    override fun onActivityDestroyed(activity: Activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        dispose()
    }

}

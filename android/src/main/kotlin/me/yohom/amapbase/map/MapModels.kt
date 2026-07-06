package me.yohom.amapbase.map

import android.content.Context
import android.content.res.Resources
import android.graphics.Bitmap
import android.graphics.Color
import android.text.Html
import android.text.TextUtils
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.amap.api.maps.AMap
import com.amap.api.maps.AMapOptions
import com.amap.api.maps.model.*
import me.yohom.amapbase.R
import me.yohom.amapbase.common.hexStringToColorInt
import me.yohom.amapbase.navi.AMapNavOptions
import java.util.*


/**
 * 由于高德的AMapOption被混淆了, 无法通过Gson直接反序列化, 这里用这个类过渡一下
 * [CameraPosition]和[LatLng]没有被混淆, 所以可以直接使用
 * 另外这个类和ios端的做一个统一
 */
class UnifiedAMapOptions(
        /// “高德地图”Logo的位置
        private val logoPosition: Int = AMapOptions.LOGO_POSITION_BOTTOM_LEFT,
        private val zOrderOnTop: Boolean = false,
        /// 地图模式
        private val mapType: Int = AMap.MAP_TYPE_NORMAL,
        /// 地图初始化时的地图状态， 默认地图中心点为北京天安门，缩放级别为 10.0f。
        private val camera: CameraPosition? = null,
        /// 比例尺功能是否可用
        private val scaleControlsEnabled: Boolean = false,
        /// 地图是否允许缩放
        private val zoomControlsEnabled: Boolean = true,
        /// 指南针是否可用。
        private val compassEnabled: Boolean = false,
        /// 拖动手势是否可用
        private val scrollGesturesEnabled: Boolean = true,
        /// 缩放手势是否可用
        private val zoomGesturesEnabled: Boolean = true,
        /// 地图倾斜手势（显示3D效果）是否可用
        private val tiltGesturesEnabled: Boolean = true,
        /// 地图旋转手势是否可用
        private val rotateGesturesEnabled: Boolean = true
) {
    fun toAMapOption(): AMapOptions {
        return AMapOptions()
                .logoPosition(logoPosition)
                .zOrderOnTop(zOrderOnTop)
                .mapType(mapType)
                .camera(camera)
                .scaleControlsEnabled(scaleControlsEnabled)
                .zoomControlsEnabled(zoomControlsEnabled)
                .compassEnabled(compassEnabled)
                .scrollGesturesEnabled(scrollGesturesEnabled)
                .zoomGesturesEnabled(zoomGesturesEnabled)
                .tiltGesturesEnabled(tiltGesturesEnabled)
                .rotateGesturesEnabled(rotateGesturesEnabled)
    }
}

class UnifiedAMapNavOptions(
        /// 导航模式
        val navType: Int = 0,
        /// 导航起点
        val startLocation: LatLng,
        /// 导航终点
        val endLocation: LatLng,
        ///底部地图内容绘制区域向上偏移的高度
        val bottomContentH: Double = 100.0,
        /// 是否使用虚拟导航（模拟导航）
        val useEmulatorNavi: Boolean = false,
        /// 地图已规划备选路线时，选中的路线索引（0 起）
        val selectedRouteIndex: Int = 0,
        /// 是否按地图已规划的备选路线进行多路线导航
        val hasPlannedRoutes: Boolean = false,
        /// 地图选中路线的总距离（米）
        val selectedRouteDistance: Double = 0.0,
        /// 地图选中路线的总耗时（秒）
        val selectedRouteDuration: Long = 0,
        /// 地图选中路线折线中点纬度
        val selectedRouteMidLatitude: Double = 0.0,
        /// 地图选中路线折线中点经度
        val selectedRouteMidLongitude: Double = 0.0
) {
    fun toAMapNavOption(): AMapNavOptions {
        return AMapNavOptions(
                navType, startLocation, endLocation, bottomContentH, useEmulatorNavi, selectedRouteIndex, hasPlannedRoutes, selectedRouteDistance, selectedRouteDuration, selectedRouteMidLatitude, selectedRouteMidLongitude
        )
    }

    override fun toString(): String {
        return "navType:"+ navType + " startLocation:"+ startLocation.toString() + " endLocation:"+ endLocation.toString() + " bottomH:"+ bottomContentH + " useEmulatorNavi:"+ useEmulatorNavi + " selectedRouteIndex:"+ selectedRouteIndex + " hasPlannedRoutes:"+ hasPlannedRoutes + " selectedRouteDistance:"+ selectedRouteDistance + " selectedRouteDuration:"+ selectedRouteDuration + " selectedRouteMidLatitude:"+ selectedRouteMidLatitude + " selectedRouteMidLongitude:"+ selectedRouteMidLongitude
    }
}

val savedMarkers: MutableList<Marker> = mutableListOf()

class UnifiedMarkerOptions(
        /// Marker覆盖物的图标
        private val icon: String?,
        /// Marker覆盖物的动画帧图标列表，动画的描点和大小以第一帧为准，建议图片大小保持一致
        private val icons: List<String>,
        /// Marker覆盖物的透明度
        private val alpha: Float,
        /// Marker覆盖物锚点在水平范围的比例
        private val anchorU: Float,
        /// Marker覆盖物锚点垂直范围的比例
        private val anchorV: Float,
        /// Marker覆盖物是否可拖拽
        private val draggable: Boolean,
        /// Marker覆盖物的InfoWindow是否允许显示, 可以通过 MarkerOptions.infoWindowEnable(kotlin.Booleanean) 进行设置
        private val infoWindowEnable: Boolean,
        /// 设置多少帧刷新一次图片资源，Marker动画的间隔时间，值越小动画越快
        private val period: Int,
        /// Marker覆盖物的位置坐标
        private val position: LatLng,
        /// Marker覆盖物的图片旋转角度，从正北开始，逆时针计算
        private val rotateAngle: Float,
        /// Marker覆盖物是否平贴地图
        private val isFlat: Boolean,
        /// Marker覆盖物的坐标是否是Gps，默认为false
        private val isGps: Boolean,
        /// Marker覆盖物的水平偏移距离
        private val infoWindowOffsetX: Int,
        /// Marker覆盖物的垂直偏移距离
        private val infoWindowOffsetY: Int,
        /// 设置 Marker覆盖物的 文字描述
        private val snippet: String,
        /// Marker覆盖物 的标题
        private val title: String,
        /// Marker覆盖物是否可见
        private val visible: Boolean,
        /// todo 缺少文档
        private val autoOverturnInfoWindow: Boolean,
        /// Marker覆盖物 zIndex
        private val zIndex: Float,
        /// 显示等级 缺少文档
        private val displayLevel: Int,
        /// 是否在掩层下 缺少文档
        private val belowMaskLayer: Boolean,


//        /// 显示在默认弹出框左侧的view [iOS暂未实现]
//        private val leftCalloutAccessoryView: String,
//        /// 显示在默认弹出框右侧的view [iOS暂未实现]
//        private val rightCalloutAccessoryView: String,
        ///是否自定义有气泡,默认没有[自研iOS]
        ///是否自定义有地址信息,默认没有[自研iOS]
        private val haveAddressLabel: Boolean?,
        ///地址label内容[自研iOS]
        private val addressLabelContent: String?,
        private val haveBubble: Boolean?,
        ///气泡内容[自研iOS]
        private val bubbleContent: String?

) {
    constructor(markerOptions: MarkerOptions) : this(
            "",
            /// Marker覆盖物的动画帧图标列表，动画的描点和大小以第一帧为准，建议图片大小保持一致
            listOf(""),
            /// Marker覆盖物的透明度
            markerOptions.alpha,
            /// Marker覆盖物锚点在水平范围的比例
            markerOptions.anchorU,
            /// Marker覆盖物锚点垂直范围的比例
            markerOptions.anchorV,
            /// Marker覆盖物是否可拖拽
            /// Marker覆盖物的InfoWindow是否允许显示, 可以通过 MarkerOptions.infoWindowEnable(kotlin.Booleanean) 进行设置
            /// 设置多少帧刷新一次图片资源，Marker动画的间隔时间，值越小动画越快
            false,false,

            markerOptions.period,
            /// Marker覆盖物的位置坐标
            markerOptions.position,
            /// Marker覆盖物的图片旋转角度，从正北开始，逆时针计算
            markerOptions.rotateAngle,
            /// Marker覆盖物是否平贴地图
            markerOptions.isFlat,
            /// Marker覆盖物的坐标是否是Gps，默认为false
            markerOptions.isGps,
            /// Marker覆盖物的水平偏移距离
            markerOptions.infoWindowOffsetX,
            /// Marker覆盖物的垂直偏移距离
            markerOptions.infoWindowOffsetY,
            /// 设置 Marker覆盖物的 文字描述
            markerOptions.snippet,
            /// Marker覆盖物 的标题
            markerOptions.title,
            true,false,
            /// Marker覆盖物 zIndex
            markerOptions.zIndex,
            /// 显示等级 缺少文档
            markerOptions.displayLevel,
            /// 是否在掩层下 缺少文档
            false,false,"",false,""


    )
    //only for update bubble content
    fun copyWith(options: UnifiedMarkerOptions): UnifiedMarkerOptions {
        return UnifiedMarkerOptions(
                position = this.position,
                haveBubble = this.haveBubble ?: options.haveBubble,
                bubbleContent = this.bubbleContent,
                haveAddressLabel = this.haveAddressLabel ?: options.haveAddressLabel,
                addressLabelContent = this.addressLabelContent ?: options.addressLabelContent,

                icon = this.icon ?: options.icon,
                icons = this.icons ?: options.icons,

                alpha = options.alpha,
                anchorU = options.anchorU,
                anchorV = options.anchorV,
                draggable = options.draggable,
                infoWindowEnable = options.infoWindowEnable,
                period = options.period,
                rotateAngle = options.rotateAngle,
                isFlat = options.isFlat,
                isGps = options.isGps,
                infoWindowOffsetX = options.infoWindowOffsetX,
                infoWindowOffsetY = options.infoWindowOffsetY,
                snippet = options.snippet,
                title = options.title,
                visible = options.visible,
                autoOverturnInfoWindow = options.autoOverturnInfoWindow,
                zIndex = options.zIndex,
                displayLevel = options.displayLevel,
                belowMaskLayer = options.belowMaskLayer
        )
    }

    //for adding marker
    fun applyTo(map: AMap, context: Context) {
        val marker = map.addMarker(toMarkerOption(context))
        marker.`object` = this
        savedMarkers.add(marker)
//        map.addMarker(toMarkerOption(context)).`object` = this
    }


    //for update marker, actually is copy with the old one and add a new one
    fun updateMarker(map: AMap, context: Context) {
        val marker2rm: Marker? = findMarker(map, position)
        val oldOptions: UnifiedMarkerOptions = marker2rm?.`object` as UnifiedMarkerOptions
        val currentOpions = this.copyWith(oldOptions)

        val marker = map.addMarker(currentOpions.toMarkerOption(context))
        marker.`object` = currentOpions
        savedMarkers.add(marker)

        rmMarker(marker2rm) //remove after adding to prevent marker flashing
    }


    fun findMarker(map: AMap, target: LatLng): Marker? {
        for (item: Marker in savedMarkers) {
            if (item.position.equals(target)) {
                return item
            }
        }
        return null
    }

    fun rmMarker(marker: Marker?) {
        marker?.remove()
        savedMarkers.remove(marker)
    }

    fun toMarkerOption(context: Context): MarkerOptions = MarkerOptions()
            .alpha(alpha)
            .anchor(anchorU, anchorV)
            .draggable(draggable)
            .infoWindowEnable(infoWindowEnable)
            .period(period)
            .position(position)
            .rotateAngle(rotateAngle)
            .setFlat(isFlat)
            .setGps(isGps)
            .setInfoWindowOffset(infoWindowOffsetX, infoWindowOffsetY)
            .snippet(snippet)
            .title(title)
            .visible(visible)
            .autoOverturnInfoWindow(autoOverturnInfoWindow)
            .zIndex(zIndex)
            .displayLevel(displayLevel)
            .belowMaskLayer(belowMaskLayer)
            .apply {

                //TODO if have bubble then set the layout of bubble and set bubble  content
                if (this@UnifiedMarkerOptions.haveBubble == true || this@UnifiedMarkerOptions.haveAddressLabel == true) {
                    //set the custom view to the bubble

                    val view: View = LayoutInflater.from(context).inflate(R.layout.layout_marker_pop, null)

                    //icon related
                    val markerIcon = view.findViewById<ImageView>(R.id.marker_icon)
                    if (this@UnifiedMarkerOptions.icon != null) {
                        markerIcon.setImageBitmap(UnifiedAssets.getBitmapDescriptor(this@UnifiedMarkerOptions.icon).bitmap)//.setImageResource(iconId)
                        markerIcon.visibility = View.VISIBLE
                    } else {
                        markerIcon.visibility = View.GONE
                    }


                    //bubble related
                    val mPopTv = view.findViewById<TextView>(R.id.pop_tv)
                    //have bubble
                    if (this@UnifiedMarkerOptions.haveBubble == true) {

                        if (TextUtils.isEmpty(this@UnifiedMarkerOptions.bubbleContent)) {
                            mPopTv.setVisibility(View.GONE)
                        } else {
                            mPopTv.setText(Html.fromHtml(this@UnifiedMarkerOptions.bubbleContent))
                            mPopTv.setVisibility(View.VISIBLE)
                        }
                    } else {
                        mPopTv.visibility = View.GONE
                    }

                    val mAddressLayout = view.findViewById<LinearLayout>(R.id.ll_address_label)
                    val mAddressLabelTv = view.findViewById<TextView>(R.id.tv_address)
                    //have address
                    if (this@UnifiedMarkerOptions.haveAddressLabel == true) {
                        mAddressLabelTv.text = this@UnifiedMarkerOptions.addressLabelContent
//                        mAddressLabelTv.visibility = View.VISIBLE
                        mAddressLayout.visibility = View.VISIBLE//!!!

                        if (this@UnifiedMarkerOptions.icon != null || this@UnifiedMarkerOptions.haveBubble == true) {
//                            val param: ViewGroup.MarginLayoutParams = mAddressLabelTv.layoutParams as ViewGroup.MarginLayoutParams
                            val param: ViewGroup.MarginLayoutParams = mAddressLayout.layoutParams as ViewGroup.MarginLayoutParams
                            val density: Int = (Resources.getSystem().displayMetrics.density).toInt()
                            param.topMargin = -8 * density // about half height of one line
                        }
                    } else {
//                        mAddressLabelTv.visibility = View.GONE
                        mAddressLayout.visibility = View.GONE //!!!
                    }

                    //set the custom icon
                    val bitmap: Bitmap? = UnifiedAssets.convertViewToBitmap(view)
                    icon(BitmapDescriptorFactory.fromBitmap(bitmap))

                } else {
                    //don't have bubble, so let it be the default style
                    if (this@UnifiedMarkerOptions.icon != null) {
                        icon(UnifiedAssets.getBitmapDescriptor(this@UnifiedMarkerOptions.icon))
                    } else {
                        icon(UnifiedAssets.getDefaultBitmapDescriptor("images/default_marker.png"))
                    }

                    if (this@UnifiedMarkerOptions.icons.isNotEmpty()) {
                        icons(ArrayList(this@UnifiedMarkerOptions.icons.map { UnifiedAssets.getBitmapDescriptor(it) }))
                    }

                }

            }
}

class UnifiedCameraPosition(
        val target: LatLng,
        val zoom: Float,
        val tilt: Float,
        val bearing: Float,
        val isAbroad: Boolean
) {
    constructor(position: CameraPosition) : this(
            position.target,
            position.zoom,
            position.tilt,
            position.bearing,
            position.isAbroad
    ) {
        fun toCameraPosition(): CameraPosition = CameraPosition.builder()
                .target(target)
                .zoom(zoom)
                .tilt(tilt)
                .bearing(bearing)
                .build()
    }
}

class UnifiedMyLocationStyle(
        // todo 实现自定义的图标
        /// 当前位置的图标
        private val myLocationIcon: String,
        /// 锚点横坐标方向的偏移量
        private val anchorU: Float,
        /// 锚点纵坐标方向的偏移量
        private val anchorV: Float,
        /// 圆形区域（以定位位置为圆心，定位半径的圆形区域）的填充颜色值
        private val radiusFillColor: String,
        /// 圆形区域（以定位位置为圆心，定位半径的圆形区域）边框的颜色值
        private val strokeColor: String,
        /// 圆形区域（以定位位置为圆心，定位半径的圆形区域）边框的宽度
        private val strokeWidth: Float,
        /// 我的位置展示模式
        private val myLocationType: Int,
        /// 定位请求时间间隔
        private val interval: Long,
        /// 是否显示定位小蓝点
        private val showMyLocation: Boolean
) {
    fun applyTo(map: AMap) {
        map.isMyLocationEnabled = showMyLocation
        map.myLocationStyle = MyLocationStyle()
                .myLocationIcon(null)
                .anchor(anchorU, anchorV)
//                .radiusFillColor(radiusFillColor.hexStringToColorInt()
//                        ?: Color.argb(100, 0, 0, 180))
//                .strokeColor(strokeColor.hexStringToColorInt() ?: Color.argb(255, 0, 0, 220))
                .radiusFillColor(Color.TRANSPARENT)
                .strokeColor(Color.TRANSPARENT)
                .strokeWidth(strokeWidth)
                .myLocationType(myLocationType)
                .interval(interval)
                .showMyLocation(showMyLocation)
//        Log.d("dsm_flutter", "--------set locationType = " + myLocationType)
    }

}

class UnifiedPolylineOptions(
        /// 顶点
        private val latLngList: List<LatLng>,
        /// 线段的宽度
        val width: Double,
        /// 线段的颜色
        val color: String,
        //自定义纹路
        private val customTexture: String,
        /// 线段的Z轴值
        private val zIndex: Double,
        /// 线段的可见属性
        private val isVisible: Boolean,
        /// 线段是否画虚线，默认为false，画实线
        private val isDottedLine: Boolean,
        /// 线段是否为大地曲线，默认false，不画大地曲线
        private val isGeodesic: Boolean,
        /// 虚线形状
        private val dottedLineType: Int,
        /// Polyline尾部形状
        private val lineCapType: Int,
        /// Polyline连接处形状
        private val lineJoIntype: Int,
        /// 线段是否使用渐变色
        private val isUseGradient: Boolean,
        /// 线段是否使用纹理贴图
        private val isUseTexture: Boolean
) {

    fun applyTo(map: AMap) {
        map.addPolyline(PolylineOptions().apply {
            addAll(this@UnifiedPolylineOptions.latLngList)
            width(this@UnifiedPolylineOptions.width.toFloat())
            color(this@UnifiedPolylineOptions.color.hexStringToColorInt() ?: Color.BLACK)
            zIndex(this@UnifiedPolylineOptions.zIndex.toFloat())
            visible(this@UnifiedPolylineOptions.isVisible)
            isDottedLine = this@UnifiedPolylineOptions.isDottedLine
            geodesic(this@UnifiedPolylineOptions.isGeodesic)
            dottedLineType = this@UnifiedPolylineOptions.dottedLineType
            if (this@UnifiedPolylineOptions.isUseTexture &&
                    this@UnifiedPolylineOptions.customTexture.isNotBlank()) {
                setCustomTexture(
                    UnifiedAssets.getBitmapDescriptor(this@UnifiedPolylineOptions.customTexture)
                )
            }
            lineCapType(when (this@UnifiedPolylineOptions.lineCapType) {
                0 -> PolylineOptions.LineCapType.LineCapButt
                1 -> PolylineOptions.LineCapType.LineCapSquare
                2 -> PolylineOptions.LineCapType.LineCapArrow
                3 -> PolylineOptions.LineCapType.LineCapRound
                else -> PolylineOptions.LineCapType.LineCapButt
            })
            lineJoinType(when (this@UnifiedPolylineOptions.lineJoIntype) {
                0 -> PolylineOptions.LineJoinType.LineJoinBevel
                1 -> PolylineOptions.LineJoinType.LineJoinMiter
                2 -> PolylineOptions.LineJoinType.LineJoinRound
                else -> PolylineOptions.LineJoinType.LineJoinBevel
            })
            useGradient(this@UnifiedPolylineOptions.isUseGradient)
            isUseTexture = this@UnifiedPolylineOptions.isUseTexture
        })
    }

}

class UnifiedCircleOptions(
        private val target: LatLng,
        private val radius: Double,
        private val fillColor: String,
        private val strokeColor: String,
        private val strokeWidth: Float,
) {

    fun applyTo(map: AMap) {
        map.addCircle(CircleOptions().apply{
            center(this@UnifiedCircleOptions.target)
            radius(this@UnifiedCircleOptions.radius)
            fillColor(this@UnifiedCircleOptions.fillColor.hexStringToColorInt() ?: Color.BLACK)
            strokeColor(this@UnifiedCircleOptions.strokeColor.hexStringToColorInt() ?: Color.BLACK)
            strokeWidth(this@UnifiedCircleOptions.strokeWidth)
        });
    }
}

class UnifiedUiSettings(
        /// 是否允许显示缩放按钮
        private val isZoomControlsEnabled: Boolean,
        /// 设置缩放按钮的位置
        private val zoomPosition: Int,
        /// 指南针
        private val isCompassEnabled: Boolean,
        /// 定位按钮
        private val isMyLocationButtonEnabled: Boolean,
        /// 比例尺控件
        private val isScaleControlsEnabled: Boolean,
        /// 地图Logo
        private val logoPosition: Int,
        /// 缩放手势
        private val isZoomGesturesEnabled: Boolean,
        /// 滑动手势
        private val isScrollGesturesEnabled: Boolean,
        /// 旋转手势
        private val isRotateGesturesEnabled: Boolean,
        /// 倾斜手势
        private val isTiltGesturesEnabled: Boolean
) {
    fun applyTo(map: AMap) {
        map.uiSettings.run {
            isZoomControlsEnabled = this@UnifiedUiSettings.isZoomControlsEnabled
            zoomPosition = this@UnifiedUiSettings.zoomPosition
            isCompassEnabled = this@UnifiedUiSettings.isCompassEnabled
            isMyLocationButtonEnabled = this@UnifiedUiSettings.isMyLocationButtonEnabled
            // 需要设置一下我的位置使能, 不然按按钮没反应
            map.isMyLocationEnabled = true
            isScaleControlsEnabled = this@UnifiedUiSettings.isScaleControlsEnabled
            logoPosition = this@UnifiedUiSettings.logoPosition
            isZoomGesturesEnabled = this@UnifiedUiSettings.isZoomGesturesEnabled
            isScrollGesturesEnabled = this@UnifiedUiSettings.isScrollGesturesEnabled
            isRotateGesturesEnabled = this@UnifiedUiSettings.isRotateGesturesEnabled
            isTiltGesturesEnabled = this@UnifiedUiSettings.isTiltGesturesEnabled
        }
    }
}

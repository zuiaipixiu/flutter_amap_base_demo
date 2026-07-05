package me.yohom.amapbase.navi

import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import com.amap.api.maps.AMap
import com.amap.api.maps.MapView
import com.amap.api.maps.model.Gradient
import com.amap.api.maps.model.HeatmapTileProvider
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.TileOverlayOptions
import java.util.*

class HeatMapActivity : Activity() {
    private val mMapView: MapView? = null
    private var mAMap: AMap? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        //        setContentView(R.layout.heatmap_activity);
//        mMapView = (MapView) findViewById(R.id.map);
        mMapView!!.onCreate(savedInstanceState)
        mAMap = mMapView.map
        initDataAndHeatMap()
    }

    private fun initDataAndHeatMap() {
        // 第一步： 生成热力点坐标列表
        val latlngs = arrayOfNulls<LatLng>(500)
        val x = 39.904979
        val y = 116.40964
        for (i in 0..499) {
            var x_ = 0.0
            var y_ = 0.0
            x_ = Math.random() * 0.5 - 0.25
            y_ = Math.random() * 0.5 - 0.25
            latlngs[i] = LatLng(x + x_, y + y_)
        }

        // 第二步： 构建热力图 TileProvider
        val builder = HeatmapTileProvider.Builder()
        builder.data(Arrays.asList(*latlngs)) // 设置热力图绘制的数据
            .gradient(ALT_HEATMAP_GRADIENT) // 设置热力图渐变，有默认值 DEFAULT_GRADIENT，可不设置该接口
        // Gradient 的设置可见参考手册
        // 构造热力图对象
        val heatmapTileProvider = builder.build()

        // 第三步： 构建热力图参数对象
        val tileOverlayOptions = TileOverlayOptions()
        tileOverlayOptions.tileProvider(heatmapTileProvider) // 设置瓦片图层的提供者

        // 第四步： 添加热力图
        mAMap!!.addTileOverlay(tileOverlayOptions)
    }

    /**
     * 方法必须重写
     */
    override fun onResume() {
        super.onResume()
        mMapView!!.onResume()
    }

    /**
     * 方法必须重写
     */
    override fun onPause() {
        super.onPause()
        mMapView!!.onPause()
    }

    /**
     * 方法必须重写
     */
    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        mMapView!!.onSaveInstanceState(outState)
    }

    /**
     * 方法必须重写
     */
    override fun onDestroy() {
        super.onDestroy()
        mMapView!!.onDestroy()
    }

    companion object {
        private val ALT_HEATMAP_GRADIENT_COLORS = intArrayOf(
            Color.argb(0, 0, 255, 255),
            Color.argb(255 / 3 * 2, 0, 255, 0),
            Color.rgb(125, 191, 0),
            Color.rgb(185, 71, 0),
            Color.rgb(255, 0, 0)
        )
        val ALT_HEATMAP_GRADIENT_START_POINTS = floatArrayOf(
            0.0f,
            0.10f, 0.20f, 0.60f, 1.0f
        )
        val ALT_HEATMAP_GRADIENT = Gradient(
            ALT_HEATMAP_GRADIENT_COLORS, ALT_HEATMAP_GRADIENT_START_POINTS
        )
    }
}
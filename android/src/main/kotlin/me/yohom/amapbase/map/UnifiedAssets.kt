package me.yohom.amapbase.map

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.view.View
import com.amap.api.maps.model.BitmapDescriptor
import com.amap.api.maps.model.BitmapDescriptorFactory
import me.yohom.amapbase.AMapBasePlugin.Companion.registrar

object UnifiedAssets {
    private val assetManager = registrar.context().assets

    private fun resolveAssetKey(asset: String): String? {
        for (pkg in listOf<String?>(null, "flutter_amap_base", "amap_base")) {
            try {
                val key = if (pkg == null) {
                    registrar.lookupKeyForAsset(asset)
                } else {
                    registrar.lookupKeyForAsset(asset, pkg)
                }
                assetManager.openFd(key).close()
                return key
            } catch (_: Exception) {
            }
        }
        return null
    }

    /**
     * 优先从宿主 app 查找图片，找不到则回退到插件包 flutter_amap_base / amap_base。
     */
    fun getBitmapDescriptor(asset: String): BitmapDescriptor {
        val key = resolveAssetKey(asset)
            ?: throw IllegalArgumentException("Asset not found: $asset")
        val assetFileDescriptor = assetManager.openFd(key)
        val bitmap = BitmapFactory.decodeStream(assetFileDescriptor.createInputStream())
        assetFileDescriptor.close()
        return BitmapDescriptorFactory.fromBitmap(bitmap)
    }

    /**
     * 获取 plugin 自带的图片（与 getBitmapDescriptor 使用同一查找逻辑）。
     */
    fun getDefaultBitmapDescriptor(asset: String): BitmapDescriptor {
        return getBitmapDescriptor(asset)
    }

    /**
     * 将 view 转成 bitmap
     * 当前仅用于高德地图 marker
     */
    fun convertViewToBitmap(view: View): Bitmap? {
        view.measure(View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED), View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED))
        view.layout(0, 0, view.measuredWidth, view.measuredHeight)
        view.buildDrawingCache()
        return view.drawingCache
    }
}

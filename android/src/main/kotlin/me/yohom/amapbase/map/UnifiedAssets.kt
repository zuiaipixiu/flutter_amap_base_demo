package me.yohom.amapbase.map

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.view.View
import com.amap.api.maps.model.BitmapDescriptor
import com.amap.api.maps.model.BitmapDescriptorFactory
import me.yohom.amapbase.AMapBasePlugin.Companion.registrar

object UnifiedAssets {
    private val assetManager = registrar.context().assets

    /**
     * 获取宿主app的图片
     */
    fun getBitmapDescriptor(asset: String): BitmapDescriptor {
        val assetFileDescriptor = assetManager.openFd(registrar.lookupKeyForAsset(asset))
        return BitmapDescriptorFactory.fromBitmap(BitmapFactory.decodeStream(assetFileDescriptor.createInputStream()))
    }

    /**
     * 获取plugin自带的图片
     */
    fun getDefaultBitmapDescriptor(asset: String): BitmapDescriptor {
        return BitmapDescriptorFactory.fromAsset(registrar.lookupKeyForAsset(asset, "amap_base"))
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
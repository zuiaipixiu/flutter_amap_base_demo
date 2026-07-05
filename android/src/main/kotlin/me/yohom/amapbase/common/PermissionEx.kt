package me.yohom.amapbase.common

import android.Manifest
import androidx.core.app.ActivityCompat
import me.yohom.amapbase.AMapBasePlugin

fun Any.checkPermission() {
    AMapBasePlugin.registrar.activity()?.let {
        ActivityCompat.requestPermissions(
            it,
            arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION,
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.READ_PHONE_STATE),
            321
    )
    }
}
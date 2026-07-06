package me.yohom.amapbase

import android.Manifest
import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.amap.api.location.AMapLocationClient
import com.amap.api.maps.MapsInitializer
import com.amap.api.services.core.ServiceSettings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformViewRegistry
import me.yohom.amapbase.location.Init
import me.yohom.amapbase.navi.NaviViewFactory
import me.yohom.amapbase.map.AMapFactory
import me.yohom.amapbase.navi.CREATED
import me.yohom.amapbase.navi.DESTROYED
import me.yohom.amapbase.navi.RESUMED
import me.yohom.amapbase.navi.STOPPED
import java.util.concurrent.atomic.AtomicInteger

class AMapBasePlugin : FlutterPlugin, ActivityAware, Application.ActivityLifecycleCallbacks {

    private var permissionResultListener:
        io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Companion.plugin = this
        flutterAssets = binding.flutterAssets
        applicationContext = binding.applicationContext
        binaryMessenger = binding.binaryMessenger
        platformViewRegistry = binding.platformViewRegistry
        maybeInitializePlugin()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        unregisterLifecycleCallbacks()
        unregisterPermissionListener()
        permissionChannel?.setMethodCallHandler(null)
        amapBaseChannel?.setMethodCallHandler(null)
        toolChannel?.setMethodCallHandler(null)
        offlineChannel?.setMethodCallHandler(null)
        searchChannel?.setMethodCallHandler(null)
        naviChannel?.setMethodCallHandler(null)
        locationChannel?.setMethodCallHandler(null)

        permissionChannel = null
        amapBaseChannel = null
        toolChannel = null
        offlineChannel = null
        searchChannel = null
        naviChannel = null
        locationChannel = null
        pluginInitialized = false

        platformViewRegistry = null
        binaryMessenger = null
        activityBinding = null
        activity = null
        activityState.set(DESTROYED)
        if (plugin === this) {
            plugin = null
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        registrarActivityHashCode = binding.activity.hashCode()
        registerLifecycleCallbacks()
        maybeInitializePlugin()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        unregisterLifecycleCallbacks()
        unregisterPermissionListener()
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        unregisterLifecycleCallbacks()
        unregisterPermissionListener()
        activity = null
        activityBinding = null
    }

    private fun maybeInitializePlugin() {
        val messenger = binaryMessenger ?: return
        val context = applicationContext ?: return
        val registry = platformViewRegistry ?: return
        val currentActivity = activity

        setupPrivacy(context)
        registerChannels(messenger, context)
        registerPlatformViews(registry)

        if (currentActivity != null) {
            registerLifecycleCallbacks()
        }

        pluginInitialized = true
    }

    private fun setupPrivacy(context: Context) {
        ServiceSettings.updatePrivacyShow(context, true, true)
        ServiceSettings.updatePrivacyAgree(context, true)
        MapsInitializer.updatePrivacyShow(context, true, true)
        MapsInitializer.updatePrivacyAgree(context, true)
        AMapLocationClient.updatePrivacyShow(context, true, true)
        AMapLocationClient.updatePrivacyAgree(context, true)
    }

    private fun registerChannels(messenger: BinaryMessenger, context: Context) {
        if (permissionChannel == null) {
            permissionChannel = MethodChannel(messenger, "me.yohom/permission").also { channel ->
                channel.setMethodCallHandler { methodCall, result ->
                    when (methodCall.method) {
                        "requestPermission" -> handlePermissionRequest(methodCall, result)
                        else -> result.notImplemented()
                    }
                }
            }
        }

        if (amapBaseChannel == null) {
            amapBaseChannel = MethodChannel(messenger, "me.yohom/amap_base").also { channel ->
                channel.setMethodCallHandler { methodCall, result ->
                    when (methodCall.method) {
                        "setKey" -> result.success("android端需要在Manifest里配置key")
                        "getBundleId" -> result.success(context.packageName)
                        else -> result.notImplemented()
                    }
                }
            }
        }

        if (toolChannel == null) {
            toolChannel = MethodChannel(messenger, "me.yohom/tool").also { channel ->
                channel.setMethodCallHandler { call, result ->
                    MAP_METHOD_HANDLER[call.method]
                        ?.onMethodCall(call, result) ?: result.notImplemented()
                }
            }
        }

        if (offlineChannel == null) {
            offlineChannel = MethodChannel(messenger, "me.yohom/offline").also { channel ->
                channel.setMethodCallHandler { call, result ->
                    MAP_METHOD_HANDLER[call.method]
                        ?.onMethodCall(call, result) ?: result.notImplemented()
                }
            }
        }

        if (searchChannel == null) {
            searchChannel = MethodChannel(messenger, "me.yohom/search").also { channel ->
                channel.setMethodCallHandler { call, result ->
                    SEARCH_METHOD_HANDLER[call.method]
                        ?.onMethodCall(call, result) ?: result.notImplemented()
                }
            }
        }

        if (naviChannel == null) {
            naviChannel = MethodChannel(messenger, "me.yohom/navi").also { channel ->
                channel.setMethodCallHandler { call, result ->
                    NAVI_METHOD_HANDLER[call.method]
                        ?.onMethodCall(call, result) ?: result.notImplemented()
                }
            }
        }

        Init.registerEventChannel(messenger)

        if (locationChannel == null) {
            locationChannel = MethodChannel(messenger, "me.yohom/location").also { channel ->
                channel.setMethodCallHandler { call, result ->
                    LOCATION_METHOD_HANDLER[call.method]
                        ?.onMethodCall(call, result) ?: result.notImplemented()
                }
            }
        }
    }

    private fun registerPlatformViews(registry: PlatformViewRegistry) {
        if (platformViewsRegistered) {
            return
        }
        registry.registerViewFactory("me.yohom/AMapView", AMapFactory(activityState))
        registry.registerViewFactory("me.yohom/AMapView_nav", NaviViewFactory(activityState))
        platformViewsRegistered = true
    }

    private fun handlePermissionRequest(
        methodCall: MethodCall,
        result: MethodChannel.Result
    ) {
        val currentActivity = activity
        val binding = activityBinding
        if (currentActivity == null || binding == null) {
            result.error("NO_ACTIVITY", "Plugin is not attached to an Activity.", null)
            return
        }

        permissionRequestCode = methodCall.hashCode()
        methodResult = result

        val locationPermissions = mutableListOf(
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_FINE_LOCATION,
        )

        val missingPermissions = locationPermissions.filter { permission ->
            ContextCompat.checkSelfPermission(currentActivity, permission) !=
                PackageManager.PERMISSION_GRANTED
        }

        if (missingPermissions.isEmpty()) {
            methodResult?.success(true)
            methodResult = null
            return
        }

        unregisterPermissionListener()
        permissionResultListener =
            io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener { code, _, grantResults ->
                if (code == permissionRequestCode) {
                    val granted = grantResults.isNotEmpty() &&
                        grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                    methodResult?.success(granted)
                    methodResult = null
                    true
                } else {
                    false
                }
            }
        binding.addRequestPermissionsResultListener(permissionResultListener!!)

        ActivityCompat.requestPermissions(
            currentActivity,
            missingPermissions.toTypedArray(),
            permissionRequestCode
        )
    }

    private fun registerLifecycleCallbacks() {
        val currentActivity = activity ?: return
        if (!lifecycleRegistered) {
            currentActivity.application.registerActivityLifecycleCallbacks(this)
            lifecycleRegistered = true
        }
    }

    private fun unregisterLifecycleCallbacks() {
        val currentActivity = activity
        if (lifecycleRegistered && currentActivity != null) {
            currentActivity.application.unregisterActivityLifecycleCallbacks(this)
        }
        lifecycleRegistered = false
    }

    private fun unregisterPermissionListener() {
        val listener = permissionResultListener
        val binding = activityBinding
        if (listener != null && binding != null) {
            binding.removeRequestPermissionsResultListener(listener)
        }
        permissionResultListener = null
    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        if (activity.hashCode() != registrarActivityHashCode) {
            return
        }
        activityState.set(CREATED)
    }

    override fun onActivityStarted(activity: Activity) {
        if (activity.hashCode() != registrarActivityHashCode) {
            return
        }
    }

    override fun onActivityResumed(activity: Activity) {
        if (activity.hashCode() != registrarActivityHashCode) {
            return
        }
        activityState.set(RESUMED)
    }

    override fun onActivityPaused(activity: Activity) {
        if (activity.hashCode() != registrarActivityHashCode) {
            return
        }
    }

    override fun onActivityStopped(activity: Activity) {
        if (activity.hashCode() != registrarActivityHashCode) {
            return
        }
        activityState.set(STOPPED)
    }

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}

    override fun onActivityDestroyed(activity: Activity) {
        if (activity.hashCode() != registrarActivityHashCode) {
            return
        }
        activityState.set(DESTROYED)
    }

    companion object {
        @JvmStatic
        var plugin: AMapBasePlugin? = null
            private set

        @JvmStatic
        var applicationContext: Context? = null
            private set

        @JvmStatic
        var binaryMessenger: BinaryMessenger? = null
            private set

        @JvmStatic
        var platformViewRegistry: PlatformViewRegistry? = null
            private set

        @JvmStatic
        var activityBinding: ActivityPluginBinding? = null
            private set

        @JvmStatic
        var activity: Activity? = null
            private set

        @JvmStatic
        var flutterAssets: FlutterPlugin.FlutterAssets? = null
            private set

        @JvmStatic
        val registrar = PluginCompat

        @JvmStatic
        var registrarActivityHashCode: Int = 0

        @JvmStatic
        val activityState = AtomicInteger(0)

        @JvmStatic
        var permissionRequestCode = 0

        @JvmStatic
        var methodResult: MethodChannel.Result? = null

        private var pluginInitialized = false
        private var platformViewsRegistered = false
        private var lifecycleRegistered = false
        private var permissionChannel: MethodChannel? = null
        private var amapBaseChannel: MethodChannel? = null
        private var toolChannel: MethodChannel? = null
        private var offlineChannel: MethodChannel? = null
        private var searchChannel: MethodChannel? = null
        private var naviChannel: MethodChannel? = null
        private var locationChannel: MethodChannel? = null
    }
}

object PluginCompat {
    fun activity(): Activity? = AMapBasePlugin.activity

    fun context(): Context =
        AMapBasePlugin.activity?.applicationContext
            ?: AMapBasePlugin.applicationContext
            ?: error("AMapBasePlugin is not attached to a context.")

    fun messenger(): BinaryMessenger =
        AMapBasePlugin.binaryMessenger
            ?: error("AMapBasePlugin is not attached to the Flutter engine.")

    fun platformViewRegistry(): PlatformViewRegistry =
        AMapBasePlugin.platformViewRegistry
            ?: error("AMapBasePlugin is not attached to the Flutter engine.")

    fun addRequestPermissionsResultListener(
        listener: io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
    ): Boolean {
        val binding = AMapBasePlugin.activityBinding ?: return false
        binding.addRequestPermissionsResultListener(listener)
        return true
    }

    fun removeRequestPermissionsResultListener(
        listener: io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
    ): Boolean {
        val binding = AMapBasePlugin.activityBinding ?: return false
        binding.removeRequestPermissionsResultListener(listener)
        return true
    }

    fun lookupKeyForAsset(asset: String): String =
        AMapBasePlugin.flutterAssets?.getAssetFilePathByName(asset)
            ?: asset

    fun lookupKeyForAsset(asset: String, packageName: String): String =
        AMapBasePlugin.flutterAssets?.getAssetFilePathBySubpath(asset, packageName)
            ?: "packages/$packageName/$asset"
}

package com.xingshe.app

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class LocationBridge(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {
    private val methodChannel = MethodChannel(messenger, "com.xingshe.app/location")
    private val eventChannel = EventChannel(messenger, "com.xingshe.app/location_events")
    private var eventSink: EventChannel.EventSink? = null

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        TripLocationService.eventListener = ::emit
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getTrackingStatus" -> result.success(mapOf("status" to status()))
            "getPendingTrackPoints" -> result.success(emptyList<Map<String, Any?>>())
            "clearPendingTrackPoints" -> result.success(mapOf("cleared" to 0))
            "startLocationTracking" -> start(call, result)
            "pauseLocationTracking" -> command(TripLocationService.ACTION_PAUSE, result)
            "resumeLocationTracking" -> command(TripLocationService.ACTION_RESUME, result)
            "stopLocationTracking" -> command(TripLocationService.ACTION_STOP, result)
            else -> result.notImplemented()
        }
    }

    private fun start(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *>
        val tripID = arguments?.get("trip_id") as? String
        val interval = (arguments?.get("interval_ms") as? Number)?.toLong()
        val distance = (arguments?.get("min_distance_meters") as? Number)?.toDouble()
        if (tripID.isNullOrBlank() || interval == null || interval !in 1000..60000 ||
            distance == null || distance < 0
        ) {
            result.error("LOCATION_INVALID_ARGUMENT", "定位参数无效", null)
            return
        }
        if (context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.error("LOCATION_PERMISSION_DENIED", "未获得前台定位权限", null)
            return
        }
        startService(
            Intent(context, TripLocationService::class.java)
                .setAction(TripLocationService.ACTION_START)
                .putExtra(TripLocationService.EXTRA_TRIP_ID, tripID)
                .putExtra(TripLocationService.EXTRA_INTERVAL_MS, interval)
                .putExtra(TripLocationService.EXTRA_MIN_DISTANCE, distance.toFloat()),
        )
        result.success(mapOf("status" to "recording"))
    }

    private fun command(action: String, result: MethodChannel.Result) {
        if (status() == "idle" && action != TripLocationService.ACTION_STOP) {
            result.error("LOCATION_INVALID_STATE", "当前没有进行中的定位", null)
            return
        }
        startService(Intent(context, TripLocationService::class.java).setAction(action))
        val next = when (action) {
            TripLocationService.ACTION_PAUSE -> "paused"
            TripLocationService.ACTION_RESUME -> "recording"
            else -> "idle"
        }
        result.success(mapOf("status" to next))
    }

    private fun startService(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            intent.action != TripLocationService.ACTION_STOP
        ) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    private fun status(): String = context
        .getSharedPreferences(TripLocationService.PREFERENCES, Context.MODE_PRIVATE)
        .getString(TripLocationService.KEY_STATUS, "idle") ?: "idle"

    private fun emit(event: Map<String, Any?>) {
        eventSink?.success(event)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}

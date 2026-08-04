package com.xingshe.app

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class LocationBridge(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {
    private val methodChannel = MethodChannel(messenger, "com.xingshe.app/location")
    private val eventChannel = EventChannel(messenger, "com.xingshe.app/location_events")
    private var eventSink: EventChannel.EventSink? = null
    private val databaseExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        TripLocationService.eventListener = ::emit
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getTrackingStatus" -> result.success(mapOf("status" to status()))
            "getPendingTrackPoints" -> pending(call, result)
            "clearPendingTrackPoints" -> clear(call, result)
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

    private fun pending(call: MethodCall, result: MethodChannel.Result) {
        val tripID = (call.arguments as? Map<*, *>)?.get("trip_id") as? String
        databaseExecutor.execute {
            val points = NativeTrackDatabase.get(context).logs().pending(tripID).map { it.toMap() }
            mainHandler.post { result.success(points) }
        }
    }

    private fun clear(call: MethodCall, result: MethodChannel.Result) {
        val values = (call.arguments as? Map<*, *>)?.get("native_log_ids") as? List<*>
        val ids = values?.filterIsInstance<String>() ?: emptyList()
        if (ids.isEmpty()) {
            result.error("LOCATION_INVALID_ARGUMENT", "待清理轨迹编号不能为空", null)
            return
        }
        databaseExecutor.execute {
            val count = NativeTrackDatabase.get(context).logs().delete(ids)
            mainHandler.post { result.success(mapOf("cleared" to count)) }
        }
    }

    private fun NativeTrackLog.toMap(): Map<String, Any?> = mapOf(
        "type" to "location",
        "native_log_id" to nativeLogId,
        "trip_id" to tripId,
        "coordinate_system" to coordinateSystem,
        "latitude" to latitude,
        "longitude" to longitude,
        "altitude" to altitude,
        "accuracy" to accuracy,
        "speed" to speed,
        "bearing" to bearing,
        "source" to source,
        "recorded_at" to java.text.SimpleDateFormat(
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            java.util.Locale.US,
        ).apply { timeZone = java.util.TimeZone.getTimeZone("UTC") }.format(java.util.Date(recordedAt)),
    )

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}

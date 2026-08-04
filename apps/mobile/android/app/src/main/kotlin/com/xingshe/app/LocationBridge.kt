package com.xingshe.app

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class LocationBridge(messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {
    private val methodChannel = MethodChannel(messenger, "com.xingshe.app/location")
    private val eventChannel = EventChannel(messenger, "com.xingshe.app/location_events")
    private var eventSink: EventChannel.EventSink? = null

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getTrackingStatus" -> result.success(mapOf("status" to "idle"))
            "getPendingTrackPoints" -> result.success(emptyList<Map<String, Any?>>())
            "clearPendingTrackPoints" -> result.success(mapOf("cleared" to 0))
            "startLocationTracking" -> start(call, result)
            "pauseLocationTracking", "resumeLocationTracking", "stopLocationTracking" ->
                result.error("LOCATION_NOT_READY", "定位服务尚未启动", null)
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
        result.error("LOCATION_NOT_READY", "定位服务尚未启动", null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}

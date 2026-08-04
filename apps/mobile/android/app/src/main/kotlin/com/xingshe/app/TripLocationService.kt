package com.xingshe.app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.IBinder
import android.os.Handler
import android.os.Looper
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID
import java.util.concurrent.Executors

class TripLocationService : Service(), LocationListener {
    private lateinit var locationManager: LocationManager
    private var tripID: String? = null
    private var intervalMs = 5000L
    private var minDistance = 10f
    private val databaseExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onCreate() {
        super.onCreate()
        locationManager = getSystemService(LocationManager::class.java)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> start(intent)
            ACTION_PAUSE -> pause()
            ACTION_RESUME -> resume()
            ACTION_STOP -> stop()
            else -> restore()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onLocationChanged(location: Location) {
        if (status() != "recording") return
        val currentTripID = tripID ?: return
        val log = NativeTrackLog(
            nativeLogId = UUID.randomUUID().toString(),
            tripId = currentTripID,
            latitude = location.latitude,
            longitude = location.longitude,
            altitude = location.altitude,
            accuracy = location.accuracy.toDouble(),
            speed = location.speed.toDouble(),
            bearing = location.bearing.toDouble(),
            recordedAt = location.time,
            source = location.provider ?: "gps",
        )
        databaseExecutor.execute {
            if (NativeTrackDatabase.get(this).logs().insert(log) != -1L) {
                mainHandler.post { eventListener?.invoke(log.toEvent()) }
            }
        }
    }

    override fun onDestroy() {
        locationManager.removeUpdates(this)
        databaseExecutor.shutdown()
        super.onDestroy()
    }

    private fun start(intent: Intent) {
        tripID = intent.getStringExtra(EXTRA_TRIP_ID)
        intervalMs = intent.getLongExtra(EXTRA_INTERVAL_MS, 5000L)
        minDistance = intent.getFloatExtra(EXTRA_MIN_DISTANCE, 10f)
        preferences().edit()
            .putString(KEY_STATUS, "recording")
            .putString(KEY_TRIP_ID, tripID)
            .putLong(KEY_INTERVAL_MS, intervalMs)
            .putFloat(KEY_MIN_DISTANCE, minDistance)
            .apply()
        startForeground(NOTIFICATION_ID, notification("正在记录行摄位置"))
        requestLocations()
    }

    private fun pause() {
        locationManager.removeUpdates(this)
        preferences().edit().putString(KEY_STATUS, "paused").apply()
        startForeground(NOTIFICATION_ID, notification("行摄位置记录已暂停"))
    }

    private fun resume() {
        val values = preferences()
        tripID = values.getString(KEY_TRIP_ID, null)
        if (tripID == null) {
            stop()
            return
        }
        intervalMs = values.getLong(KEY_INTERVAL_MS, 5000L)
        minDistance = values.getFloat(KEY_MIN_DISTANCE, 10f)
        values.edit().putString(KEY_STATUS, "recording").apply()
        startForeground(NOTIFICATION_ID, notification("正在记录行摄位置"))
        requestLocations()
    }

    private fun restore() {
        when (status()) {
            "recording" -> resume()
            "paused" -> pause()
            else -> stopSelf()
        }
    }

    private fun stop() {
        locationManager.removeUpdates(this)
        preferences().edit().putString(KEY_STATUS, "idle").apply()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun requestLocations() {
        if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            stop()
            return
        }
        locationManager.removeUpdates(this)
        for (provider in listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)) {
            if (locationManager.isProviderEnabled(provider)) {
                locationManager.requestLocationUpdates(
                    provider,
                    intervalMs,
                    minDistance,
                    this,
                )
            }
        }
    }

    private fun notification(message: String): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
        return builder
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle("行摄")
            .setContentText(message)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        getSystemService(NotificationManager::class.java).createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "行摄位置记录", NotificationManager.IMPORTANCE_LOW),
        )
    }

    private fun preferences() = getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    private fun status() = preferences().getString(KEY_STATUS, "idle")

    private fun timestamp(time: Long): String = SimpleDateFormat(
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        Locale.US,
    ).apply { timeZone = TimeZone.getTimeZone("UTC") }.format(Date(time))

    private fun NativeTrackLog.toEvent(): Map<String, Any?> = mapOf(
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
        "recorded_at" to timestamp(recordedAt),
    )

    companion object {
        const val ACTION_START = "com.xingshe.app.location.START"
        const val ACTION_PAUSE = "com.xingshe.app.location.PAUSE"
        const val ACTION_RESUME = "com.xingshe.app.location.RESUME"
        const val ACTION_STOP = "com.xingshe.app.location.STOP"
        const val EXTRA_TRIP_ID = "trip_id"
        const val EXTRA_INTERVAL_MS = "interval_ms"
        const val EXTRA_MIN_DISTANCE = "min_distance_meters"
        const val PREFERENCES = "xingshe_location"
        const val KEY_STATUS = "status"
        const val KEY_TRIP_ID = "trip_id"
        const val KEY_INTERVAL_MS = "interval_ms"
        const val KEY_MIN_DISTANCE = "min_distance_meters"
        private const val CHANNEL_ID = "xingshe_tracking"
        private const val NOTIFICATION_ID = 1001
        var eventListener: ((Map<String, Any?>) -> Unit)? = null
    }
}

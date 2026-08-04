package com.xingshe.app

import android.app.Activity
import android.content.ClipData
import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

class PhotoCaptureBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "com.xingshe.app/media")
    private var pendingResult: MethodChannel.Result? = null
    private var pendingUri: android.net.Uri? = null

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "capturePhoto" -> capture(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun capture(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("MEDIA_BUSY", "已有拍照操作正在进行", null)
            return
        }
        val uri = try {
            createImageUri()
        } catch (_: RuntimeException) {
            result.error("MEDIA_CREATE_FAILED", "无法创建系统相册照片", null)
            return
        }
        if (uri == null) {
            result.error("MEDIA_CREATE_FAILED", "无法创建系统相册照片", null)
            return
        }
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
            putExtra(MediaStore.EXTRA_OUTPUT, uri)
            clipData = ClipData.newRawUri("XingShe photo", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        }
        if (intent.resolveActivity(activity.packageManager) == null) {
            activity.contentResolver.delete(uri, null, null)
            result.error("MEDIA_CAMERA_UNAVAILABLE", "未找到可用相机", null)
            return
        }
        pendingResult = result
        pendingUri = uri
        try {
            activity.startActivityForResult(intent, REQUEST_CAPTURE)
        } catch (_: RuntimeException) {
            pendingResult = null
            pendingUri = null
            activity.contentResolver.delete(uri, null, null)
            result.error("MEDIA_CAMERA_UNAVAILABLE", "无法启动相机", null)
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != REQUEST_CAPTURE) return false
        val result = pendingResult
        val uri = pendingUri
        pendingResult = null
        pendingUri = null
        if (result == null || uri == null) return true
        if (resultCode != Activity.RESULT_OK) {
            activity.contentResolver.delete(uri, null, null)
            result.success(null)
            return true
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            activity.contentResolver.update(
                uri,
                ContentValues().apply { put(MediaStore.Images.Media.IS_PENDING, 0) },
                null,
                null,
            )
        }
        result.success(mapOf("uri" to uri.toString(), "taken_at" to System.currentTimeMillis()))
        return true
    }

    fun dispose() {
        pendingUri?.let { runCatching { activity.contentResolver.delete(it, null, null) } }
        pendingResult?.error("MEDIA_ACTIVITY_CLOSED", "拍照操作已中止", null)
        pendingUri = null
        pendingResult = null
        channel.setMethodCallHandler(null)
    }

    private fun createImageUri(): android.net.Uri? {
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "XingShe_${System.currentTimeMillis()}.jpg")
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/XingShe")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            } else {
                val directory = File(
                    Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
                    "XingShe",
                ).apply { mkdirs() }
                put(MediaStore.Images.Media.DATA, File(directory, "XingShe_${System.currentTimeMillis()}.jpg").path)
            }
        }
        return activity.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
    }

    companion object {
        private const val REQUEST_CAPTURE = 4101
    }
}

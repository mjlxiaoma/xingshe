package com.xingshe.app

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class ShareBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "com.xingshe.app/share")

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "shareImage" -> shareImage(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun shareImage(call: MethodCall, result: MethodChannel.Result) {
        val file = runCatching {
            call.argument<String>("path")?.let(::File)?.canonicalFile
        }.getOrNull()
        val shareRoot = runCatching {
            File(activity.cacheDir, "xingshe_share").canonicalFile
        }.getOrNull()
        if (
            file == null ||
            shareRoot == null ||
            !file.isFile ||
            file.extension.lowercase() != "png" ||
            !file.path.startsWith(shareRoot.path + File.separator)
        ) {
            result.error("SHARE_INVALID_FILE", "分享图片不可用", null)
            return
        }
        try {
            val uri = FileProvider.getUriForFile(
                activity,
                "${activity.packageName}.fileprovider",
                file,
            )
            val send = Intent(Intent.ACTION_SEND).apply {
                type = "image/png"
                putExtra(Intent.EXTRA_STREAM, uri)
                clipData = ClipData.newRawUri("XingShe share image", uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            activity.startActivity(Intent.createChooser(send, "分享行摄记录"))
            result.success(null)
        } catch (_: RuntimeException) {
            result.error("SHARE_UNAVAILABLE", "无法打开系统分享", null)
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}

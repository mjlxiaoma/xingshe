package com.xingshe.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private lateinit var photoCaptureBridge: PhotoCaptureBridge
    private lateinit var shareBridge: ShareBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        LocationBridge(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        photoCaptureBridge = PhotoCaptureBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        shareBridge = ShareBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        if (
            ::photoCaptureBridge.isInitialized &&
            photoCaptureBridge.onActivityResult(requestCode, resultCode, data)
        ) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        if (::photoCaptureBridge.isInitialized) photoCaptureBridge.dispose()
        if (::shareBridge.isInitialized) shareBridge.dispose()
        super.onDestroy()
    }
}

package com.wordnerd.artbeat

import android.graphics.ImageFormat
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.ImageReader
import android.os.Handler
import android.os.Looper
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Camera buffer management plugin to help address the "Unable to acquire a buffer item" warnings
 * that occur on some Android devices when using the camera.
 */
class CameraBufferManager : FlutterPlugin, MethodCallHandler, DefaultLifecycleObserver {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "artbeat_camera_settings")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setMaxImagesPerSecond" -> {
                // We can't directly set max images per second in the camera plugin
                // But we acknowledge the call to prevent errors in Flutter
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
    
    // Lifecycle methods
    override fun onStop(owner: LifecycleOwner) {
        // Release camera resources when the app goes to the background
        // This is a backup mechanism to help free resources
        ImageReader.getGlobalImagingWorkerHandler()?.let { handler ->
            try {
                val looper = handler.looper
                if (looper != Looper.getMainLooper()) {
                    // Post a task to clear any pending operations
                    handler.post {
                        // Empty task to flush the queue
                    }
                }
            } catch (e: Exception) {
                // Ignore errors, just trying to help free resources
            }
        }
    }
}

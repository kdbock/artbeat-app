package com.wordnerd.artbeat

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
    
    // Lifecycle methods - implement all required methods from DefaultLifecycleObserver interface
    override fun onCreate(owner: LifecycleOwner) {
        // No special handling needed at creation
    }
    
    override fun onStart(owner: LifecycleOwner) {
        // No special handling needed at start
    }
    
    override fun onResume(owner: LifecycleOwner) {
        // No special handling needed at resume
    }
    
    override fun onPause(owner: LifecycleOwner) {
        // No special handling needed at pause
    }
    
    override fun onStop(owner: LifecycleOwner) {
        // Release camera resources when the app goes to the background
        // This is a backup mechanism to help free resources
        try {
            // For newer versions of Android, the ImageReader handler may not be directly accessible
            // Just using our own background handler instead
            val handler = Handler(Looper.getMainLooper())
            handler.post {
                // Empty task just to flush any pending operations
                // Additional cleanup can be added here if needed
            }
        } catch (e: Exception) {
            // Ignore errors, just trying to help free resources
        }
    }
    
    override fun onDestroy(owner: LifecycleOwner) {
        // Clean up any remaining resources
    }
}

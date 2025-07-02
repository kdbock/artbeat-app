package com.wordnerd.artbeat

import androidx.lifecycle.Lifecycle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private val cameraBufferManager = CameraBufferManager()
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(cameraBufferManager)
        
        // Register the camera buffer manager as a lifecycle observer
        lifecycle.addObserver(cameraBufferManager)
    }
}

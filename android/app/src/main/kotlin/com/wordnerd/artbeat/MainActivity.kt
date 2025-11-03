package com.wordnerd.artbeat

import android.os.Bundle
import androidx.core.view.WindowCompat
import androidx.lifecycle.Lifecycle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions

class MainActivity : FlutterActivity() {
    private val cameraBufferManager = CameraBufferManager()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge display for Android 15+ compatibility
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
        
        // Pre-initialize Google Sign-In to prevent null object crashes
        initializeGoogleSignIn()
    }
    
    private fun initializeGoogleSignIn() {
        try {
            // Pre-fetch the default GoogleSignInClient to ensure it's initialized
            // This prevents null object reference crashes in SignInHubActivity
            val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestEmail()
                .build()
            
            GoogleSignIn.getClient(this, gso)
        } catch (e: Exception) {
            // Log but don't crash - Google Sign-In will be initialized via Flutter
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(cameraBufferManager)
        
        // Register the camera buffer manager as a lifecycle observer
        lifecycle.addObserver(cameraBufferManager)
    }
}

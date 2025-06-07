plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.wordnerd.artbeat"
    compileSdk = flutter.compileSdkVersion
    // Comment out NDK version if not using native code
    // ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Match the package name in google-services.json
        applicationId = "com.wordnerd.artbeat"
        namespace = "com.wordnerd.artbeat"
        
        minSdk = 23 // Updated minSdk from 21 to 23 for Firebase Auth compatibility
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Enable OnBackInvokedCallback for predictive back gesture
        manifestPlaceholders["enableOnBackInvokedCallback"] = "true"

        // Add OpenGL ES version requirement
        manifestPlaceholders["glEsVersion"] = "0x00020000" // OpenGL ES 2.0 for better compatibility
        
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
        }
        
        // Required for camera functionality
        manifestPlaceholders["cameraPermission"] = "android.permission.CAMERA"
        
        // Firebase App Check Configuration
        buildConfigField("String", "FIREBASE_APP_CHECK_DEBUG_TOKEN", "\"fae8ac60-fccf-486c-9844-3e3dbdb9ea3f\"")
        buildConfigField("boolean", "FIREBASE_APP_CHECK_DEBUG_MODE", "true")
        manifestPlaceholders["firebase_app_check_debug"] = "true"
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appName"] = "@string/app_name"
            resValue("string", "app_name", "ARTbeat Debug")
            
            // Enable App Check debugging with proper configuration
            isDebuggable = true
            manifestPlaceholders["firebase_app_check_debug"] = "true"
            resValue("string", "google_app_check_debug_token", "fae8ac60-fccf-486c-9844-3e3dbdb9ea3f")
            resValue("bool", "firebase_app_check_debug_enabled", "true")
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // Optimize for release
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    buildFeatures {
        buildConfig = true
        // Explicitly disable NDK features if not using native code
        prefab = false
    }
    
    // No native build configuration needed
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.android.material:material:1.11.0") // Required by Stripe
    implementation("com.google.android.gms:play-services-maps:18.2.0")
    implementation("com.google.android.gms:play-services-location:21.2.0")
    implementation("com.google.android.gms:play-services-base:18.3.0")
    implementation("com.google.android.gms:play-services-auth:21.0.0")
    
    // Camera and ML Kit dependencies
    implementation("androidx.camera:camera-camera2:1.3.2")
    implementation("androidx.camera:camera-lifecycle:1.3.2")
    implementation("androidx.camera:camera-view:1.3.2")
    implementation("com.google.mlkit:text-recognition:16.0.0")
}

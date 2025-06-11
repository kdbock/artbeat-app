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
        
        // D8/R8 Configurations for handling larger classes
        multiDexEnabled = true
        dexOptions {
            javaMaxHeapSize = "4g"
            preDexLibraries = true
        }
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
    
    packaging {
        // Fix for Bouncy Castle conflicts
        resources {
            excludes += listOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/*.kotlin_module",
                "META-INF/BCKEY.DSA",
                "META-INF/BCKEY.SF",
                "META-INF/BC1024KE.DSA",
                "META-INF/BC1024KE.SF",
                "META-INF/BC2048KE.DSA",
                "META-INF/BC2048KE.SF"
            )
            pickFirsts += listOf(
                "META-INF/versions/9/previous-compilation-data.bin",
                "lib/arm64-v8a/libcrypto.so",
                "lib/arm64-v8a/libssl.so",
                "lib/armeabi-v7a/libcrypto.so",
                "lib/armeabi-v7a/libssl.so",
                "lib/x86_64/libcrypto.so",
                "lib/x86_64/libssl.so"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Force Bouncy Castle version to 1.76 to avoid conflicts
    constraints {
        implementation("org.bouncycastle:bcprov-jdk15to18:1.76")
        implementation("org.bouncycastle:bcpkix-jdk15to18:1.76")
    }
    
    // D8/R8 Configuration
    configurations.all {
        resolutionStrategy {
            force("org.bouncycastle:bcprov-jdk15to18:1.76")
            force("org.bouncycastle:bcpkix-jdk15to18:1.76")
        }
    }
}

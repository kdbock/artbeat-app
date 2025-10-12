import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load API keys and signing configuration from properties file
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.wordnerd.artbeat"
    compileSdk = 36  // Updated for latest plugin compatibility
    ndkVersion = "27.0.12077973"

    buildFeatures {
        buildConfig = true
    }

    // Add build optimization
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }
    
    // Setup signing configuration for release builds
    signingConfigs {
        create("release") {
            val keystoreFile = keystoreProperties.getProperty("storeFile")?.let { 
                rootProject.file(it)
            }
            if (keystoreFile != null && keystoreFile.exists()) {
                storeFile = keystoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias") 
                keyPassword = keystoreProperties.getProperty("keyPassword")
            } else {
                logger.warn("Release signing config not found - using debug signing")
            }
        }
    }

    defaultConfig {
        // ARTbeat application ID
        applicationId = "com.wordnerd.artbeat"
        minSdk = 24  // Android 7.0 (2016) - Explicit minimum for Firebase compatibility
        targetSdk = 36  // Updated to match compileSdk
        versionCode = 52
        versionName = "2.0.6"
        
        // Pass API keys to the build
        manifestPlaceholders["mapsApiKey"] = keystoreProperties.getProperty("mapsApiKey", "")
        
        // Override manifest attributes for plugins with incompatible minSdk
        manifestPlaceholders["minSdkVersion"] = 24
    }

    buildTypes {
        release {
            // Robust check for release signing config
            val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null &&
                keystoreProperties.getProperty("storePassword") != null &&
                keystoreProperties.getProperty("keyAlias") != null &&
                keystoreProperties.getProperty("keyPassword") != null &&
                rootProject.file(keystoreProperties.getProperty("storeFile")).exists()
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("Release keystore not found or incomplete, using debug signing for release build.")
                signingConfigs.getByName("debug")
            }
            
            // Temporarily disable minification to avoid Stripe SDK issues
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Keep ProGuard rules for future use
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        
        debug {
            // Debug builds continue to use debug signing
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring for flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

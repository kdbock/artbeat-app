import java.io.FileInputStream
import java.util.Properties
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load API keys and signing configuration from properties file
val keystoreProperties = Properties().apply {
    val propertiesFile = rootProject.file("key.properties")
    if (propertiesFile.exists()) {
        load(FileInputStream(propertiesFile))
    }
}

android {
    namespace = "com.wordnerd.artbeat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
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
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Pass API keys to the build
        manifestPlaceholders["mapsApiKey"] = keystoreProperties.getProperty("mapsApiKey", "")
    }

    buildTypes {
        release {
            // Use the release signing config for release builds
            signingConfig = signingConfigs.getByName("release")
            
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

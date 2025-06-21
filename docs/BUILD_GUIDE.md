# ARTbeat Build Guide

This document outlines the steps to build ARTbeat for iOS and Android platforms.

## Prerequisites

1. Flutter SDK installed and updated
2. Android Studio or Xcode for platform-specific builds
3. CocoaPods for iOS dependencies 
4. JDK 17 or newer for Android builds
5. Firebase project with required services enabled
6. Google Maps API Key
7. Keystore file for Android release signing (located at `android/app/signing/artbeat-upload-key.jks`)

> **Note:** For detailed information about release signing, see [RELEASE_SIGNING_GUIDE.md](./RELEASE_SIGNING_GUIDE.md)

## Build Scripts

We've provided several scripts to simplify the build process:

### Android Builds

```bash
# Build all Android artifacts (debug APK, release APK, and app bundle)
./scripts/build_android_all.sh

# Build only a debug APK (fastest for testing)
flutter build apk --debug

# Build a properly signed release bundle for Google Play Store
./scripts/build_playstore_release.sh

# Verify your signing configuration
./scripts/check_signing_config.sh
```

### iOS Builds

```bash
# Build iOS app in release mode without code signing
./scripts/build_ios.sh

# Open Xcode to archive and distribute to App Store
open ios/Runner.xcworkspace
```

## Known Issues and Solutions

### Android Stripe SDK Issues

The Stripe SDK has some compatibility issues with R8 full mode shrinking. To work around this:
- Minification has been disabled for release builds in `android/app/build.gradle.kts`
- A ProGuard configuration is available in `android/app/proguard-rules.pro` for future use

### Java Version Warnings

If you see Java version warnings, update your `android/app/build.gradle.kts` file to use Java 17:

```kotlin
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

kotlinOptions {
    jvmTarget = JavaVersion.VERSION_17.toString()
}
```

## API Keys

API keys are managed securely through:
- Android: `android/key.properties` file (not committed to Git)
- iOS: Xcode configuration

Make sure to add your Google Maps API key to `android/key.properties`:
```
mapsApiKey=YOUR_MAPS_API_KEY_HERE
```

## Release Checklist

Before creating a production release:

1. Update version in `pubspec.yaml`
2. Ensure all tests pass
3. Verify app icons and splash screens
4. Check Firebase configuration
5. Test on multiple device sizes
6. Review storage.rules and firestore.rules
7. Verify all translations are complete
8. Generate release notes

## Signing Configuration

### Android

The app is now configured for release signing with the keystore located at `android/app/signing/artbeat-upload-key.jks`. This keystore file and its credentials are required for Play Store publishing.

**Key details:**
- Keystore location: `android/app/signing/artbeat-upload-key.jks`
- Key alias: `artbeat_upload_key`
- Validity: 10,000 days

**Important:** Keep your keystore file and credentials secure! If you lose this keystore, you won't be able to update your app on the Play Store.

The signing configuration is already set up in `android/app/build.gradle.kts` and the credentials are stored in `android/key.properties`.
```

### iOS

Code signing is managed through Xcode. Open `ios/Runner.xcworkspace` and:
1. Select the Runner project
2. Go to Signing & Capabilities
3. Select your team and profile

## Troubleshooting

- **Firebase initializer error**: Verify `firebase_options.dart` has correct project settings
- **Missing Google Maps on Android**: Check `key.properties` has valid API key
- **Stripe SDK issues**: Try building with `--no-shrink` flag
- **iOS build fails**: Run `pod install` in the `ios` directory

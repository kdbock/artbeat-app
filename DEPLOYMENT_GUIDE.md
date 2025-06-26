# ARTbeat App Deployment Guide - Closed Testing

## Pre-Deployment Checklist ✅

### 1. Version Management
- [x] Current Version: `1.0.4+6` (version 1.0.4, build 6)
- [x] Version follows semantic versioning
- [x] Build number increments for each deployment

### 2. App Configuration
- [x] App name: "ARTbeat" 
- [x] Bundle ID (iOS): `com.wordnerd.artbeat`
- [x] Package name (Android): `com.wordnerd.artbeat`
- [x] Proper app icons configured
- [x] Splash screen configured

### 3. API Keys & Security
- [x] Google Maps API key configured and working
- [x] Firebase project configured
- [x] API keys are secure (not hardcoded in public code)
- [x] Firestore security rules deployed

### 4. Permissions & Features
- [x] Camera permission (for art capture)
- [x] Location permission (for art walks)
- [x] Photo library access (for image selection)
- [x] Network access for Firebase services

---

## Android Deployment 🤖

### 1. Generate Release APK

```bash
# Clean and prepare
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Build release AAB (recommended for Google Play)
flutter build appbundle --release
```

**Output Files:**
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### 2. Google Play Console Setup

1. **Upload to Google Play Console**
   - Go to [Google Play Console](https://play.google.com/console)
   - Select your app or create new app
   - Upload the AAB file (preferred) or APK

2. **Internal Testing Setup**
   - Go to Testing → Internal testing
   - Upload your release
   - Add test users (up to 100 emails)
   - Publish to internal testing

3. **Closed Testing Setup** 
   - Go to Testing → Closed testing
   - Create new release
   - Upload your AAB/APK
   - Set up test user lists
   - Publish to closed testing

### 3. Testing Distribution
- Share the Google Play Console testing link with testers
- Testers need to join via the link and download from Play Store
- Monitor crash reports and feedback

---

## iOS Deployment 🍎

### 1. Xcode Project Setup

```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace
```

**In Xcode:**
1. Select Runner target
2. Go to Signing & Capabilities
3. Ensure proper Team is selected
4. Verify Bundle Identifier: `com.wordnerd.artbeat`
5. Check provisioning profile is valid

### 2. Build and Archive

```bash
# Clean and prepare  
flutter clean
flutter pub get

# Build iOS release
flutter build ios --release
```

**In Xcode:**
1. Select "Any iOS Device" as target
2. Product → Archive
3. Wait for archive to complete
4. Click "Distribute App"
5. Choose "App Store Connect"
6. Follow the upload wizard

### 3. App Store Connect Setup

1. **TestFlight Internal Testing**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Select your app
   - Go to TestFlight tab
   - Add internal testers (up to 100)
   - Submit build for internal testing

2. **TestFlight External Testing**
   - Create external testing group
   - Add up to 10,000 external testers
   - Submit for Beta App Review (required)
   - Distribute once approved

### 4. Testing Distribution
- Testers receive email invitation
- Download TestFlight app from App Store
- Install and test the beta build
- Provide feedback through TestFlight

---

## Build Commands Summary 📋

### Quick Deployment Commands

```bash
# Increment version (optional)
# Update pubspec.yaml: version: 1.0.4+6

# Android - Internal Testing
flutter clean && flutter pub get
flutter build appbundle --release

# iOS - TestFlight
flutter clean && flutter pub get
flutter build ios --release
# Then archive in Xcode

# Android - Direct APK (for sideloading)
flutter build apk --release --split-per-abi
```

### Version Increment Helper

```bash
# Current: 1.0.3+5
# Next release: 1.0.4+6
# Bug fixes: 1.0.3+6 (keep version, increment build)
# New features: 1.0.4+6 (increment version and build)
```

---

## Testing Phase Checklist 🧪

### Core Functionality
- [ ] User registration and authentication
- [ ] Profile creation and editing
- [ ] Art capture with camera
- [ ] Google Maps integration
- [ ] Art walk creation and viewing
- [ ] Community features (posts, comments)
- [ ] Settings and preferences

### Platform-Specific Testing
- [ ] **Android**: Test on different devices/screen sizes
- [ ] **iOS**: Test on iPhone and iPad
- [ ] **Permissions**: Camera, location, photos
- [ ] **Maps**: Verify markers and navigation work
- [ ] **Performance**: Check app startup and responsiveness

### Known Issues to Test
- [ ] iOS gray map background (if still occurring)
- [ ] Firestore permission errors (should be fixed)
- [ ] UI overflow on small screens (should be fixed)
- [ ] Camera capture and image upload

---

## Troubleshooting 🔧

### Common Android Issues
- **Signing errors**: Check `key.properties` file exists and keystore is valid
- **Maps not working**: Verify API key in `key.properties`
- **Build failures**: Run `flutter clean` and try again

### Common iOS Issues  
- **Code signing**: Ensure valid developer account and certificates
- **Maps not working**: Check `Info.plist` has correct API key
- **Archive failures**: Clean Xcode project and derived data

### Testing Issues
- **Crashes**: Check Firebase Crashlytics for reports
- **Performance**: Use Flutter DevTools for profiling
- **Connectivity**: Test offline/online scenarios

---

## Next Steps After Testing 📈

1. **Collect Feedback**: Gather tester feedback and crash reports
2. **Fix Critical Issues**: Address any blocking bugs
3. **Increment Version**: Update to next version for production
4. **Production Release**: Deploy to Google Play Store and App Store
5. **Monitor**: Track app analytics and user engagement

---

## Contact & Support 📞

- **Developer**: GitHub Copilot Assistant
- **Project**: ARTbeat Flutter App
- **Repository**: Private repo with modular architecture
- **Documentation**: See `docs/` folder for detailed guides

---

*Last Updated: June 24, 2025*
*Status: Ready for closed testing deployment*

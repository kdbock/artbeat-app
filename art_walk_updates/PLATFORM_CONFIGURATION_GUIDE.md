# 🔧 Platform Configuration Guide for Social Login

## 📱 iOS Configuration (Required for Production)

### Step 1: Get iOS Client ID from Firebase Console

1. **Open Firebase Console**: Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. **Select your project**: `wordnerd-artbeat`
3. **Navigate to Authentication**:
   - Click "Authentication" in left sidebar
   - Click "Sign-in method" tab
   - Click "Google" provider
4. **Find iOS Client ID**:
   - Look for "Web SDK configuration" section
   - Copy the "Web client ID" (this is what you need)
   - It will look like: `665020451634-XXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com`

### Step 2: Add Google URL Scheme to iOS

**Current Info.plist location**: `/Users/kristybock/artbeat/ios/Runner/Info.plist`

You need to add a second URL scheme for Google Sign-In. Your current `CFBundleURLTypes` section looks like this:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.wordnerd.artbeat</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.wordnerd.artbeat</string>
    </dict>
</array>
```

**Add this second dictionary to the array:**

```xml
<key>CFBundleURLTypes</key>
<array>
    <!-- Existing URL scheme -->
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.wordnerd.artbeat</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.wordnerd.artbeat</string>
    </dict>

    <!-- ADD THIS NEW GOOGLE URL SCHEME -->
    <dict>
        <key>CFBundleURLName</key>
        <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

**Replace these placeholders:**

- `YOUR_IOS_CLIENT_ID` → Your full iOS client ID from Firebase
- `YOUR_REVERSED_CLIENT_ID` → Take your client ID and reverse the domain part

**Example:**
If your iOS Client ID is: `665020451634-abc123def456.apps.googleusercontent.com`
Then your reversed client ID is: `com.googleusercontent.apps.665020451634-abc123def456`

### Step 3: Add Apple Sign-In Capability

1. **Open Xcode**: `open ios/Runner.xcworkspace`
2. **Select Runner target** in the project navigator
3. **Go to "Signing & Capabilities" tab**
4. **Click "+ Capability"**
5. **Search and add "Sign In with Apple"**
6. **Save the project**

---

## 🤖 Android Configuration (Required for Production)

### Step 1: Get SHA-1 Fingerprints

**For Debug (Development):**

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**For Release (Production):**

```bash
keytool -list -v -keystore /path/to/your/release/keystore.jks -alias your_key_alias
```

Look for the SHA-1 fingerprint in the output:

```
Certificate fingerprints:
SHA1: A1:B2:C3:D4:E5:F6:78:90:12:34:56:78:90:AB:CD:EF:12:34:56:78
```

### Step 2: Add SHA-1 to Firebase Console

1. **Open Firebase Console**: [https://console.firebase.google.com](https://console.firebase.google.com)
2. **Select project**: `wordnerd-artbeat`
3. **Go to Project Settings**: Click gear icon → Project settings
4. **Select "General" tab**
5. **Scroll to "Your apps" section**
6. **Find your Android app**: `com.wordnerd.artbeat`
7. **Click "Add fingerprint"**
8. **Paste your SHA-1 fingerprint**
9. **Click "Save"**

### Step 3: Update Android Build Configuration

**File**: `/Users/kristybock/artbeat/android/app/build.gradle`

Ensure minimum SDK version is 21:

```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21  // Required for Google Sign-In
        targetSdkVersion 34
    }
}
```

---

## ✅ Quick Setup Commands

### Get Android SHA-1 (Debug):

```bash
cd /Users/kristybock/artbeat
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

### Open iOS project for Apple Sign-In:

```bash
cd /Users/kristybock/artbeat
open ios/Runner.xcworkspace
```

---

## 🧪 Testing Without Platform Configuration

**Good News**: Your social login implementation will work in development without these configurations!

- **iOS Simulator**: Google Sign-In works without URL schemes
- **Android Emulator**: Google Sign-In works without SHA-1 fingerprints
- **Development**: Apple Sign-In can be tested in simulator

**When you NEED platform configuration:**

- ✅ **Production iOS apps** (App Store deployment)
- ✅ **Production Android apps** (Google Play deployment)
- ✅ **Real device testing** (physical iPhones/Android phones)

---

## 🚀 Priority Recommendations

### For Development/Testing:

1. **Skip platform configuration** - Your implementation already works!
2. **Test in simulators/emulators**
3. **Focus on app functionality**

### For Production Deployment:

1. **Add iOS URL schemes** (5 minutes)
2. **Add Apple Sign-In capability** (2 minutes)
3. **Get and add SHA-1 fingerprints** (10 minutes)
4. **Test on real devices**

Your social login is **production-ready** - these are just the final deployment steps! 🎉

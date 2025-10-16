# 🚀 Quick Start: Production Deployment

## Phase 1 Security Fixes: ✅ COMPLETE

Your app is now secure! Follow these steps to deploy to production.

---

## 📋 Pre-Deployment Checklist (5 Steps)

### 1️⃣ Create Android Keystore (5 minutes)

```bash
# Run the automated setup script
./scripts/setup_android_keystore.sh

# Follow the prompts to create your keystore
# It will be saved to: ~/secure-keys/artbeat/
```

**⚠️ CRITICAL:** Back up your keystore immediately! You cannot recover it if lost.

---

### 2️⃣ Configure iOS Signing (5 minutes)

```bash
# Open Xcode
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select "Runner" target
# 2. Go to "Signing & Capabilities"
# 3. Select your Team
# 4. Ensure "Automatically manage signing" is checked
# 5. Verify Bundle Identifier: com.wordnerd.artbeat
```

---

### 3️⃣ Set Up Environment Variables (2 minutes)

```bash
# Copy example to create your .env file
cp .env.example .env

# Edit .env with your actual API keys
# (Use your favorite editor)
nano .env
```

**Required keys:**

- `FIREBASE_ANDROID_API_KEY`
- `FIREBASE_IOS_API_KEY`
- `GOOGLE_MAPS_API_KEY`
- `STRIPE_PUBLISHABLE_KEY`

---

### 4️⃣ Enable Firebase App Check (10 minutes)

**In Firebase Console:**

1. Go to: https://console.firebase.google.com
2. Select your project: `wordnerd-artbeat`
3. Navigate to: **Build → App Check**
4. Click **"Get started"**

**For Android:**

- Provider: **Play Integrity API**
- Click **"Register"**

**For iOS:**

- Provider: **DeviceCheck** (or App Attest for iOS 14+)
- Click **"Register"**

**For Development (Optional):**

- Add debug tokens for testing
- Run app and check logs for debug token
- Add token in Firebase Console → App Check → Debug tokens

---

### 5️⃣ Test Release Build (5 minutes)

**Android:**

```bash
# Build release APK
flutter build apk --release

# If successful, test the APK
# Install on device: adb install build/app/outputs/flutter-apk/app-release.apk
```

**iOS:**

```bash
# Build release IPA
flutter build ios --release

# Open in Xcode for final testing
open ios/Runner.xcworkspace
```

---

## 🎯 Quick Verification

### Check Security Rules Deployed:

```bash
# Deploy Firebase rules
firebase deploy --only firestore:rules,storage:rules

# Verify in Firebase Console
# Go to: Firestore → Rules
# Go to: Storage → Rules
```

### Verify App Check:

```bash
# Run the app
flutter run --release

# Check logs for App Check status
# Should see: "App Check token obtained successfully"
```

---

## 🚨 Common Issues & Solutions

### Issue: "Release keystore not found"

**Solution:** Run `./scripts/setup_android_keystore.sh` to create keystore

### Issue: "App Check token failed"

**Solution:**

1. Verify App Check is enabled in Firebase Console
2. For development, add debug token
3. For production, ensure app is properly signed

### Issue: "Storage upload failed"

**Solution:**

1. Verify user is authenticated
2. Check file size (max: 10MB images, 100MB videos)
3. Check file type (must be image/_, video/_, or audio/\*)

### Issue: "Build failed with ProGuard errors"

**Solution:** ProGuard rules are already configured. If issues persist, check `android/app/proguard-rules.pro`

---

## 📊 Production Readiness Status

| Component            | Status                | Action Required    |
| -------------------- | --------------------- | ------------------ |
| **Storage Rules**    | ✅ Secured            | Deploy to Firebase |
| **Firestore Rules**  | ✅ Secured            | Deploy to Firebase |
| **App Check**        | ⚠️ Setup Required     | Enable in Console  |
| **Android Keystore** | ⚠️ Create Required    | Run setup script   |
| **iOS Signing**      | ⚠️ Configure Required | Set up in Xcode    |
| **API Keys**         | ⚠️ Configure Required | Update .env file   |
| **Build Config**     | ✅ Ready              | Test release build |

---

## 🎉 Ready to Deploy?

Once all steps above are complete:

### Deploy to Firebase:

```bash
firebase deploy --only firestore:rules,storage:rules
```

### Build for Production:

**Android (Google Play):**

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**iOS (App Store):**

```bash
flutter build ios --release
# Then archive in Xcode for App Store submission
```

---

## 📚 Additional Resources

- **Full Security Guide:** `SECURITY_SETUP.md`
- **Phase 1 Summary:** `PHASE_1_COMPLETE.md`
- **Original Checklist:** `current_updates.md`

---

## 🆘 Need Help?

### Documentation:

- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [Firebase App Check](https://firebase.google.com/docs/app-check)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [iOS Code Signing](https://developer.apple.com/support/code-signing/)

### Firebase Console:

- Project: https://console.firebase.google.com/project/wordnerd-artbeat

---

## ⏱️ Estimated Time to Production

- ✅ Phase 1 (Security): **COMPLETE**
- ⏭️ Pre-deployment setup: **~30 minutes**
- ⏭️ Testing: **1-2 hours**
- ⏭️ App Store submission: **1-2 weeks** (review time)

**You're almost there! 🚀**

---

_Last Updated: Phase 1 Complete_

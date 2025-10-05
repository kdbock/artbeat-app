# 🚀 Quick Fix: Captures Not Showing

## The Problem

Captures aren't appearing because Firebase App Check is blocking image uploads with "Permission denied" errors.

## The Solution (3 Simple Steps)

### 1️⃣ Get Your Debug Token

```bash
# Restart your app
flutter run
```

Look for this in your console:

```
═══════════════════════════════════════════════════════════
🔐 APP CHECK DEBUG TOKEN - COPY THIS TO FIREBASE CONSOLE
═══════════════════════════════════════════════════════════
Token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
═══════════════════════════════════════════════════════════
```

**Copy the token!**

### 2️⃣ Register Token in Firebase

1. Go to: https://console.firebase.google.com/project/wordnerd-artbeat/appcheck/apps
2. Select your **Android app**
3. Click **"Manage debug tokens"**
4. Click **"Add debug token"**
5. Paste your token
6. Click **"Save"**

### 3️⃣ Test It

1. Wait 1-2 minutes
2. Hot restart your app
3. Create a new capture (mark as public)
4. Check if it appears in the live activity feed ✨

## ✅ What Changed

**Files Modified:**

- `packages/artbeat_core/lib/src/firebase/secure_firebase_config.dart` - Enhanced token logging
- `storage.rules` - Reverted to proper App Check enforcement

**Deployed:**

- ✅ Storage rules deployed to Firebase

## 📖 Need More Details?

See `APP_CHECK_SETUP_GUIDE.md` for complete documentation.

## 🆘 Still Having Issues?

Check that:

- [ ] You copied the **entire token** (including dashes)
- [ ] You registered it for the **Android app** (not iOS/web)
- [ ] You waited **1-2 minutes** after registering
- [ ] You did a **hot restart** (not just hot reload)
- [ ] You're running in **debug mode**

---

**Why This Happened:**
Your app uses Firebase App Check for security. In development, you need to register debug tokens so your device can pass App Check validation. Without a registered token, Firebase blocks all uploads.

**Production:**
This is only needed for development. Production apps use Google Play Integrity (Android) and DeviceCheck (iOS) automatically - no tokens needed!

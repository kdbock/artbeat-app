# ✅ App Check Setup Checklist

Use this checklist to fix the "Captures Not Showing" issue.

## Pre-Flight Check

- [ ] I understand this is a **one-time setup** per device
- [ ] I have access to **Firebase Console**
- [ ] I can **restart my app**

---

## Step 1: Get Debug Token

- [ ] Stop the app completely
- [ ] Run: `flutter run` (or hot restart)
- [ ] Wait for app to fully initialize
- [ ] Look for the debug token box in console output
- [ ] Token found? → Copy it!

**Token looks like:** `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`

**My token:** `_________________________________`

---

## Step 2: Register in Firebase Console

- [ ] Open: https://console.firebase.google.com/project/wordnerd-artbeat/appcheck/apps
- [ ] Click on **Android app** (com.artbeat.app or similar)
- [ ] Click **"Manage debug tokens"** or **"Debug tokens"** tab
- [ ] Click **"Add debug token"** button
- [ ] Paste the token I copied
- [ ] Give it a name: `_________________________________`
- [ ] Click **"Save"**
- [ ] Token appears in the list? ✅

---

## Step 3: Wait & Restart

- [ ] Wait **2 minutes** (set a timer!)
- [ ] Hot restart the app (not just hot reload)
- [ ] App fully restarted? ✅

---

## Step 4: Test Capture Upload

- [ ] Open camera/capture screen
- [ ] Take or select a photo
- [ ] **Mark as PUBLIC** (important!)
- [ ] Submit the capture
- [ ] Watch console output for errors

**Expected console output:**

```
✅ No "Permission denied" errors
✅ "StorageService: Upload successful" messages
✅ "SocialService: Activity posted" messages
```

---

## Step 5: Verify Success

### In the App:

- [ ] Go to Dashboard/Live Activity Feed
- [ ] My capture appears? ✅
- [ ] Image loads correctly? ✅

### In Firebase Console:

**Storage:**

- [ ] Go to: https://console.firebase.google.com/project/wordnerd-artbeat/storage
- [ ] Navigate to: `capture_images/{my-user-id}/`
- [ ] Image file exists? ✅

**Firestore:**

- [ ] Go to: https://console.firebase.google.com/project/wordnerd-artbeat/firestore
- [ ] Open: `socialActivities` collection
- [ ] New document with my capture? ✅

---

## 🎉 Success Criteria

All of these should be true:

- ✅ Debug token registered in Firebase Console
- ✅ No "Permission denied" errors in console
- ✅ Capture appears in live activity feed
- ✅ Image visible in Firebase Storage
- ✅ Document exists in Firestore `socialActivities`

---

## 🔧 Troubleshooting

### Token Not Showing?

- [ ] Running in debug mode? (not release)
- [ ] Checked entire console output?
- [ ] Tried full stop and restart?

### Still Getting Errors?

- [ ] Waited 2+ minutes after registering token?
- [ ] Registered for correct app (Android)?
- [ ] Token copied completely (with dashes)?
- [ ] Did hot restart (not just hot reload)?

### Multiple Devices?

- [ ] Each device needs its own token
- [ ] Registered token for current device?
- [ ] Using same Firebase project?

---

## 📝 Notes

**Date completed:** `_________________________________`

**Device/Emulator:** `_________________________________`

**Token name in Firebase:** `_________________________________`

**Issues encountered:**

```
_________________________________
_________________________________
_________________________________
```

**Resolution:**

```
_________________________________
_________________________________
_________________________________
```

---

## 🔄 For Additional Devices

If you develop on multiple devices:

1. Run app on new device
2. Get that device's debug token
3. Register it in Firebase Console (with different name)
4. Repeat for each device

**Registered Devices:**

- [ ] Device 1: `_________________________________`
- [ ] Device 2: `_________________________________`
- [ ] Device 3: `_________________________________`

---

## ✨ All Done!

Once this checklist is complete, your captures should upload successfully and appear in the live activity feed!

**Need help?** See `APP_CHECK_SETUP_GUIDE.md` for detailed documentation.

# Firebase App Check Setup Guide

## What is App Check?

Firebase App Check is a security feature that validates requests come from your legitimate app, protecting your Firebase resources from abuse.

## Current Issue

Your app is configured to use App Check, but the debug tokens are not registered in Firebase Console. This causes uploads to fail with "Permission denied" errors.

## ✅ Complete Solution (Follow These Steps)

### Step 1: Get Your Debug Token

1. **Stop your app** if it's currently running
2. **Hot restart** (not hot reload) your app or run it fresh:

   ```bash
   flutter run
   ```

3. **Look for the debug token** in your console output. You should see a large box like this:

   ```
   ═══════════════════════════════════════════════════════════
   🔐 APP CHECK DEBUG TOKEN - COPY THIS TO FIREBASE CONSOLE
   ═══════════════════════════════════════════════════════════
   Token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ═══════════════════════════════════════════════════════════
   ```

4. **Copy the token** (the long string after "Token:")

### Step 2: Register the Token in Firebase Console

1. **Open Firebase Console**:

   - Go to: https://console.firebase.google.com/project/wordnerd-artbeat/appcheck/apps
   - Or navigate: Firebase Console → Your Project → App Check

2. **Select your Android app** from the list

3. **Click "Manage debug tokens"** (or "Debug tokens" tab)

4. **Add the debug token**:
   - Click "Add debug token"
   - Paste the token you copied
   - Give it a name (e.g., "Development Device" or "Kristy's Phone")
   - Click "Save"

### Step 3: Test the Fix

1. **Wait 1-2 minutes** for the token to propagate

2. **Hot restart your app** (not just hot reload)

3. **Create a new capture** and mark it as public

4. **Check the console** - you should see:
   - ✅ No more "Permission denied" errors
   - ✅ Successful image upload messages
   - ✅ Social activity posted messages
   - ✅ The capture appears in your live activity feed

### Step 4: Verify in Firebase Console

1. **Check Firebase Storage**:

   - Go to: https://console.firebase.google.com/project/wordnerd-artbeat/storage
   - Navigate to `capture_images/{your-user-id}/`
   - You should see your uploaded image

2. **Check Firestore**:
   - Go to: https://console.firebase.google.com/project/wordnerd-artbeat/firestore
   - Open the `socialActivities` collection
   - You should see a new document with your capture

## 🔍 Troubleshooting

### Token Not Showing in Console?

If you don't see the debug token box:

1. Make sure you're running in **debug mode** (not release mode)
2. Check that `kDebugMode` is true
3. Look earlier in the console output - it appears during app initialization
4. Try a **full restart** (stop and start, not hot restart)

### Still Getting Permission Denied?

1. **Verify the token is registered**: Check Firebase Console → App Check → Debug tokens
2. **Wait a few minutes**: Token registration can take 1-2 minutes to propagate
3. **Check you're using the right app**: Make sure you registered the token for the Android app (not iOS or web)
4. **Try force-stopping the app** and starting fresh

### Multiple Devices?

If you develop on multiple devices or emulators:

- Each device/emulator will have a **different debug token**
- You need to register **each token separately** in Firebase Console
- Tokens are tied to the device, not the user

## 📱 Production Considerations

### For Production Release:

The current setup uses **debug providers** in debug mode:

- Android: `AndroidProvider.debug`
- iOS: `AppleProvider.debug`

For production, the app automatically switches to:

- Android: `AndroidProvider.playIntegrity` (Google Play Integrity API)
- iOS: `AppleProvider.deviceCheck` (Apple DeviceCheck)

### Before Production Deployment:

1. **Enable App Check** in Firebase Console for your production app
2. **Configure Play Integrity** (Android):

   - Link your app to Google Play Console
   - Enable Play Integrity API
   - No additional code changes needed

3. **Configure DeviceCheck** (iOS):
   - Ensure your app is properly signed
   - DeviceCheck is automatically available for iOS apps
   - No additional configuration needed

## 🔐 Security Notes

### Why App Check?

App Check protects your Firebase resources from:

- ✅ Unauthorized API access
- ✅ Quota theft
- ✅ Data scraping
- ✅ Abuse from modified apps

### Debug Tokens

- Debug tokens are **only for development**
- They bypass normal App Check validation
- **Never use debug tokens in production**
- You can revoke tokens anytime in Firebase Console

### Storage Rules

The storage rules now properly require App Check:

```javascript
function hasAppCheck() {
  return request.app != null || isDebugMode();
}
```

With `isDebugMode()` set to `false`, App Check is enforced. Debug tokens allow your development devices to pass this check.

## 📚 Additional Resources

- [Firebase App Check Documentation](https://firebase.google.com/docs/app-check)
- [App Check for Android](https://firebase.google.com/docs/app-check/android/debug-provider)
- [Play Integrity API](https://firebase.google.com/docs/app-check/android/play-integrity-provider)

## ✨ Summary

**What we fixed:**

1. ✅ Enhanced debug token logging for easy visibility
2. ✅ Reverted temporary storage rules bypass
3. ✅ Deployed proper storage rules with App Check enforcement
4. ✅ Provided clear instructions for token registration

**What you need to do:**

1. 🔄 Restart your app to get the debug token
2. 📋 Copy the token from console output
3. 🔐 Register it in Firebase Console
4. 🎉 Test creating a capture

Once the debug token is registered, your captures will upload successfully and appear in the live activity feed!

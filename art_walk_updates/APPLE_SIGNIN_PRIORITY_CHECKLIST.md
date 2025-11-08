# Apple Sign-In Configuration Checklist - Error -7091 Fix

## Priority 1: Essential Configuration (Do These First)

### 1. App ID Configuration

- [ ] Go to **Identifiers** → **App IDs**
- [ ] Find: `com.wordnerd.artbeat`
- [ ] Ensure **Sign In with Apple** capability is **ENABLED** ✅
- [ ] Click **Edit** → Check capabilities → Save

### 2. Services ID Configuration (Critical for -7091)

- [ ] Go to **Identifiers** → **Services IDs**
- [ ] Find or create: `com.wordnerd.artbeat` (same as bundle ID)
- [ ] Enable **Sign In with Apple**
- [ ] Click **Configure** next to Sign In with Apple
- [ ] Set **Primary App ID**: `com.wordnerd.artbeat`
- [ ] Add **Domains and Subdomains**: `wordnerd-artbeat.firebaseapp.com`
- [ ] Add **Return URLs**: `https://wordnerd-artbeat.firebaseapp.com/__/auth/handler`
- [ ] **Save** configuration

### 3. Key Configuration

- [ ] Go to **Keys**
- [ ] Find your Apple Sign-In key (Key ID: `5G5237Z826`)
- [ ] Ensure it has **Sign In with Apple** capability
- [ ] Download .p8 file if you don't have it

## Priority 2: Domain Verification (Main Cause of -7091)

### Firebase Hosting Domain Verification

This is the **most common cause** of error -7091:

- [ ] In Services ID config, when you add `wordnerd-artbeat.firebaseapp.com`, Apple will ask to verify
- [ ] Download the verification file Apple provides
- [ ] Upload it to your Firebase Hosting root directory
- [ ] OR use Firebase CLI: `firebase deploy --only hosting`
- [ ] Wait for verification to complete (can take 10-15 minutes)

### Alternative: App-Only Flow (Bypass Domain Verification)

If domain verification fails, use the simplified approach:

- [ ] Use `signInWithAppleSimple()` method I created
- [ ] This bypasses web authentication entirely
- [ ] No domain verification needed

## Priority 3: Optional Services Configuration

### Sign in with Apple for Email Communication (Optional)

Only configure this if you need to send emails to users:

- [ ] Go to **Services** → **Sign in with Apple for Email Communication**
- [ ] Click **Configure**
- [ ] Add your app's bundle ID: `com.wordnerd.artbeat`
- [ ] Configure email domains (only if sending emails)

## Do NOT Configure These (Not Needed):

- ❌ Account & Organizational Data Sharing
- ❌ Apple Pay (unless you're using Apple Pay)
- ❌ WeatherKit (unless you're using weather data)
- ❌ Maps (you're using Google Maps)

## Testing Steps After Configuration:

1. **Wait 10-15 minutes** after making changes
2. **Test on physical iOS device** (not simulator)
3. **Check device is signed into iCloud**
4. **Run the simplified approach first**:
   ```dart
   await _authService.signInWithAppleSimple();
   ```

## If Still Getting -7091:

1. **Try app-only flow** (bypasses domain verification)
2. **Double-check bundle IDs match everywhere**
3. **Ensure App ID has Apple Sign-In capability**
4. **Contact Apple Developer Support** for domain verification help

## Quick Test Command:

```bash
./debug_apple_signin.sh
```

The configuration issue is almost certainly in the **Identifiers** section, not Services. Focus on App ID and Services ID configuration first!

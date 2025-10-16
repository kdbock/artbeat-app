# GitHub Secrets Setup Guide

This guide will help you configure all the GitHub Secrets needed for your CI/CD pipeline.

## 📋 Overview

You need to add **15+ secrets** to your GitHub repository. This guide provides the exact values and instructions for each one.

**Time Required:** ~45 minutes

---

## 🔐 How to Add Secrets to GitHub

1. Go to your repository: https://github.com/kdbock/artbeat-app
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Enter the **Name** and **Value** from the sections below
5. Click **Add secret**

---

## ✅ Step 1: Android Secrets (4 secrets)

### 1. ANDROID_KEYSTORE_BASE64

**What it is:** Your Android release keystore encoded in base64

**How to get it:**

```bash
cat /Users/kristybock/secure-keys/artbeat/keystore-base64.txt
```

**Instructions:**

- Copy the ENTIRE contents of the file (all 3,729 characters)
- Paste into GitHub as the secret value
- Make sure there are no extra spaces or line breaks

---

### 2. ANDROID_KEYSTORE_PASSWORD

**Value:** `passcode100328`

**What it is:** The password for your keystore file

---

### 3. ANDROID_KEY_ALIAS

**Value:** `artbeat-release`

**What it is:** The alias name for your signing key

---

### 4. ANDROID_KEY_PASSWORD

**Value:** `passcode100328`

**What it is:** The password for your signing key (same as keystore password)

---

## 🔥 Step 2: Firebase Secrets (5 secrets)

### 5. FIREBASE_TOKEN

**How to get it:**

```bash
firebase login:ci
```

**Instructions:**

1. Run the command above in your terminal
2. It will open a browser for authentication
3. After logging in, copy the token from the terminal
4. Paste it as the secret value

**Note:** This token allows GitHub Actions to deploy to Firebase

---

### 6. FIREBASE_SERVICE_ACCOUNT

**How to get it:**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **production** project: `wordnerd-artbeat`
3. Click the **gear icon** → **Project Settings**
4. Go to **Service Accounts** tab
5. Click **Generate new private key**
6. Download the JSON file
7. Open the JSON file and copy the ENTIRE contents
8. Paste into GitHub as the secret value

**What it is:** Service account credentials for Firebase deployments

---

### 7. FIREBASE_ANDROID_APP_ID_STAGING

**How to get it:**

1. Go to Firebase Console
2. Select your **staging** project (you'll create this in Step 2)
3. Go to **Project Settings**
4. Scroll to **Your apps** section
5. Find your Android app
6. Copy the **App ID** (looks like: `1:123456789:android:abc123...`)

**Note:** You'll need to create the staging project first (see Step 2 below)

---

### 8. FIREBASE_IOS_APP_ID_STAGING

**How to get it:**

1. Same as above, but for the iOS app
2. Copy the **App ID** (looks like: `1:123456789:ios:abc123...`)

**Note:** You'll need to create the staging project first (see Step 2 below)

---

### 9. FIREBASE_ANDROID_APP_ID_PRODUCTION

**How to get it:**

1. Go to Firebase Console
2. Select your **production** project: `wordnerd-artbeat`
3. Go to **Project Settings**
4. Scroll to **Your apps** section
5. Find your Android app
6. Copy the **App ID**

---

## 🔑 Step 3: Environment Variables (2 secrets)

### 10. ENV_STAGING

**How to get it:**

```bash
cat /Users/kristybock/artbeat/.env.staging
```

**Instructions:**

1. First, you need to fill in the actual API keys in `.env.staging`
2. Then copy the ENTIRE contents of the file
3. Paste into GitHub as the secret value

**What needs to be filled in:**

- `FIREBASE_ANDROID_API_KEY` - Get from Firebase Console → Project Settings → Android app
- `FIREBASE_IOS_API_KEY` - Get from Firebase Console → Project Settings → iOS app
- `FIREBASE_PROJECT_ID` - Your staging project ID
- `FIREBASE_MESSAGING_SENDER_ID` - Get from Firebase Console
- `FIREBASE_APP_ID_ANDROID` - Same as FIREBASE_ANDROID_APP_ID_STAGING
- `FIREBASE_APP_ID_IOS` - Same as FIREBASE_IOS_APP_ID_STAGING

---

### 11. ENV_PRODUCTION

**How to get it:**

```bash
cat /Users/kristybock/artbeat/.env.production
```

**Instructions:**

1. Create `.env.production` file (copy from `.env.production.example`)
2. Fill in all the actual API keys for production
3. Copy the ENTIRE contents
4. Paste into GitHub as the secret value

---

## 📱 Step 4: Google Play Secrets (1 secret) - OPTIONAL FOR NOW

### 12. GOOGLE_PLAY_SERVICE_ACCOUNT

**How to get it:**

1. Go to [Google Play Console](https://play.google.com/console/)
2. Select your app (or create one if you haven't)
3. Go to **Setup** → **API access**
4. Click **Create new service account**
5. Follow the link to Google Cloud Console
6. Create service account: `github-actions-deploy`
7. Grant role: **Service Account User**
8. Create and download JSON key
9. Back in Play Console, grant access to the service account
10. Give permissions: **Admin** (Releases)
11. Copy the entire JSON content
12. Paste into GitHub as the secret value

**Note:** You can skip this for now if you're not ready to deploy to Google Play

---

## 🍎 Step 5: iOS Secrets (5 secrets) - OPTIONAL FOR NOW

These are needed for iOS builds and App Store deployment. You can skip these for now if you're focusing on Android first.

### 13. IOS_CERTIFICATE_P12

### 14. IOS_CERTIFICATE_PASSWORD

### 15. IOS_PROVISIONING_PROFILE_STAGING

### 16. IOS_PROVISIONING_PROFILE_PRODUCTION

### 17. APPSTORE_ISSUER_ID

### 18. APPSTORE_API_KEY_ID

### 19. APPSTORE_API_PRIVATE_KEY

**Instructions:** See `CI_CD_SETUP.md` for detailed iOS setup instructions

---

## 🎯 Quick Start: Minimum Secrets to Get Started

To test the CI/CD pipeline with just Android, you need these **9 secrets minimum:**

1. ✅ ANDROID_KEYSTORE_BASE64
2. ✅ ANDROID_KEYSTORE_PASSWORD
3. ✅ ANDROID_KEY_ALIAS
4. ✅ ANDROID_KEY_PASSWORD
5. ⏸️ FIREBASE_TOKEN
6. ⏸️ FIREBASE_SERVICE_ACCOUNT
7. ⏸️ FIREBASE_ANDROID_APP_ID_STAGING
8. ⏸️ ENV_STAGING
9. ⏸️ ENV_PRODUCTION

**Status:**

- ✅ = Ready to add (values prepared)
- ⏸️ = Needs Firebase staging project first

---

## 📝 Checklist

Use this checklist to track your progress:

### Android Secrets

- [ ] ANDROID_KEYSTORE_BASE64
- [ ] ANDROID_KEYSTORE_PASSWORD
- [ ] ANDROID_KEY_ALIAS
- [ ] ANDROID_KEY_PASSWORD

### Firebase Secrets

- [ ] FIREBASE_TOKEN
- [ ] FIREBASE_SERVICE_ACCOUNT
- [ ] FIREBASE_ANDROID_APP_ID_STAGING
- [ ] FIREBASE_IOS_APP_ID_STAGING (optional)
- [ ] FIREBASE_ANDROID_APP_ID_PRODUCTION (optional)

### Environment Variables

- [ ] ENV_STAGING
- [ ] ENV_PRODUCTION

### Google Play (Optional)

- [ ] GOOGLE_PLAY_SERVICE_ACCOUNT

### iOS (Optional)

- [ ] IOS_CERTIFICATE_P12
- [ ] IOS_CERTIFICATE_PASSWORD
- [ ] IOS_PROVISIONING_PROFILE_STAGING
- [ ] IOS_PROVISIONING_PROFILE_PRODUCTION
- [ ] APPSTORE_ISSUER_ID
- [ ] APPSTORE_API_KEY_ID
- [ ] APPSTORE_API_PRIVATE_KEY

---

## 🔒 Security Best Practices

1. **Never commit secrets to git** - Always use GitHub Secrets
2. **Rotate secrets regularly** - Update passwords and tokens periodically
3. **Use different credentials for staging and production**
4. **Backup your keystore** - Store it in a secure location (password manager, encrypted backup)
5. **Limit access** - Only give repository access to trusted team members

---

## 🆘 Troubleshooting

### "Secret not found" error in GitHub Actions

- Make sure the secret name matches exactly (case-sensitive)
- Check that you added it to the correct repository
- Verify the secret has a value (not empty)

### "Invalid keystore format" error

- Make sure you copied the entire base64 string
- Check for extra spaces or line breaks
- Verify the keystore file exists and is valid

### "Firebase authentication failed" error

- Regenerate the Firebase token: `firebase login:ci`
- Make sure the service account has the correct permissions
- Verify the project ID matches your Firebase project

---

## 📚 Additional Resources

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Firebase CLI Documentation](https://firebase.google.com/docs/cli)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)

---

## ✅ Next Steps

After adding all secrets:

1. **Test the pipeline** - Create a test pull request
2. **Verify builds** - Check that Android builds successfully
3. **Test deployment** - Push to `develop` branch to test staging deployment
4. **Monitor logs** - Check GitHub Actions logs for any errors

Good luck! 🚀

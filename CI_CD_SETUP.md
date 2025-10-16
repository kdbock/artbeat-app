# CI/CD Setup Guide for ArtBeat

This guide will help you set up automated Continuous Integration and Continuous Deployment (CI/CD) for the ArtBeat app using GitHub Actions.

## 📋 Table of Contents

1. [What is CI/CD?](#what-is-cicd)
2. [Overview](#overview)
3. [Prerequisites](#prerequisites)
4. [GitHub Secrets Setup](#github-secrets-setup)
5. [Firebase Setup](#firebase-setup)
6. [Android Setup](#android-setup)
7. [iOS Setup](#ios-setup)
8. [Testing the Pipeline](#testing-the-pipeline)
9. [Troubleshooting](#troubleshooting)

---

## 🤔 What is CI/CD?

**CI/CD** stands for **Continuous Integration / Continuous Deployment**. It's an automated system that:

- **Watches your code** - Automatically detects when you push code to GitHub
- **Tests your code** - Runs tests to catch bugs early
- **Builds your app** - Creates Android and iOS app files
- **Deploys your app** - Uploads to app stores or testing platforms

**Benefits:**

- ✅ Saves hours of manual work
- ✅ Catches bugs before they reach users
- ✅ Consistent builds every time
- ✅ Faster releases

---

## 🎯 Overview

### Workflows Created

We've set up 3 automated workflows:

#### 1. **Pull Request Checks** (`pr-checks.yml`)

- **Triggers:** When you create a pull request
- **Actions:**
  - Checks code formatting
  - Runs lint checks
  - Runs all unit tests
  - Builds Android APK (debug)
  - Builds iOS (no signing)
- **Purpose:** Ensure code quality before merging

#### 2. **Deploy to Staging** (`deploy-staging.yml`)

- **Triggers:** When you push to `develop` branch
- **Actions:**
  - Runs all tests
  - Builds Android AAB (staging)
  - Builds iOS IPA (staging)
  - Uploads to Firebase App Distribution
  - Deploys Firebase rules to staging
- **Purpose:** Internal testing before production

#### 3. **Deploy to Production** (`deploy-production.yml`)

- **Triggers:** When you push to `main` branch or create a version tag
- **Actions:**
  - Runs all tests
  - Runs security validation
  - Builds Android AAB (production)
  - Builds iOS IPA (production)
  - Uploads to Google Play Store
  - Uploads to Apple App Store
  - Deploys Firebase rules to production
  - Creates GitHub release
- **Purpose:** Automated production deployment

### Workflow Diagram

```
┌─────────────────────────────────────────────────────────┐
│  Developer Actions                                      │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  Create Pull Request                                    │
│  → pr-checks.yml runs                                   │
│  → Lint, test, build (no deploy)                       │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  Merge to 'develop' branch                              │
│  → deploy-staging.yml runs                              │
│  → Build & deploy to Firebase App Distribution         │
│  → Internal testers get notified                        │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  Merge to 'main' branch                                 │
│  → deploy-production.yml runs                           │
│  → Build & deploy to app stores                         │
│  → Users get updates                                    │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ Prerequisites

Before setting up CI/CD, ensure you have:

- [x] GitHub repository with admin access
- [x] Firebase project (production and staging)
- [x] Google Play Console account with app created
- [x] Apple Developer account with app created
- [x] Android keystore created (run `./scripts/setup_android_keystore.sh`)
- [x] iOS signing certificates and provisioning profiles

---

## 🔐 GitHub Secrets Setup

GitHub Secrets are encrypted environment variables that store sensitive information securely.

### How to Add Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret below

### Required Secrets

#### 🔥 Firebase Secrets

| Secret Name                       | Description              | How to Get                                                                        |
| --------------------------------- | ------------------------ | --------------------------------------------------------------------------------- |
| `FIREBASE_TOKEN`                  | Firebase CLI token       | Run: `firebase login:ci`                                                          |
| `FIREBASE_SERVICE_ACCOUNT`        | Service account JSON     | Firebase Console → Project Settings → Service Accounts → Generate new private key |
| `FIREBASE_ANDROID_APP_ID_STAGING` | Android app ID (staging) | Firebase Console → Project Settings → Your apps → Android app → App ID            |
| `FIREBASE_IOS_APP_ID_STAGING`     | iOS app ID (staging)     | Firebase Console → Project Settings → Your apps → iOS app → App ID                |

#### 📱 Android Secrets

| Secret Name                   | Description             | How to Get                                                        |
| ----------------------------- | ----------------------- | ----------------------------------------------------------------- |
| `ANDROID_KEYSTORE_BASE64`     | Base64-encoded keystore | See [Android Setup](#android-setup) below                         |
| `ANDROID_KEYSTORE_PASSWORD`   | Keystore password       | From when you created keystore                                    |
| `ANDROID_KEY_ALIAS`           | Key alias               | From when you created keystore                                    |
| `ANDROID_KEY_PASSWORD`        | Key password            | From when you created keystore                                    |
| `GOOGLE_PLAY_SERVICE_ACCOUNT` | Service account JSON    | Google Play Console → Setup → API access → Create service account |

#### 🍎 iOS Secrets

| Secret Name                           | Description                         | How to Get                                                   |
| ------------------------------------- | ----------------------------------- | ------------------------------------------------------------ |
| `IOS_CERTIFICATE_P12`                 | Base64-encoded certificate          | See [iOS Setup](#ios-setup) below                            |
| `IOS_CERTIFICATE_PASSWORD`            | Certificate password                | From when you exported certificate                           |
| `IOS_PROVISIONING_PROFILE_STAGING`    | Base64-encoded profile (staging)    | Download from Apple Developer → Certificates, IDs & Profiles |
| `IOS_PROVISIONING_PROFILE_PRODUCTION` | Base64-encoded profile (production) | Download from Apple Developer → Certificates, IDs & Profiles |
| `APPSTORE_ISSUER_ID`                  | App Store Connect issuer ID         | App Store Connect → Users and Access → Keys → Issuer ID      |
| `APPSTORE_API_KEY_ID`                 | App Store Connect API key ID        | App Store Connect → Users and Access → Keys → Key ID         |
| `APPSTORE_API_PRIVATE_KEY`            | App Store Connect API private key   | Download when creating API key                               |

#### 🔑 Environment Variables

| Secret Name      | Description                      | Content                            |
| ---------------- | -------------------------------- | ---------------------------------- |
| `ENV_STAGING`    | Staging environment variables    | Contents of `.env.staging` file    |
| `ENV_PRODUCTION` | Production environment variables | Contents of `.env.production` file |

---

## 🔥 Firebase Setup

### 1. Get Firebase CLI Token

```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Login and get token
firebase login:ci
```

Copy the token and add it as `FIREBASE_TOKEN` secret in GitHub.

### 2. Get Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Project Settings** (gear icon)
4. Go to **Service Accounts** tab
5. Click **Generate new private key**
6. Download the JSON file
7. Copy the entire JSON content and add as `FIREBASE_SERVICE_ACCOUNT` secret

### 3. Get App IDs

1. In Firebase Console → **Project Settings**
2. Scroll to **Your apps** section
3. For Android app: Copy the **App ID** (looks like `1:123456789:android:abc123...`)
4. For iOS app: Copy the **App ID** (looks like `1:123456789:ios:abc123...`)
5. Add as `FIREBASE_ANDROID_APP_ID_STAGING` and `FIREBASE_IOS_APP_ID_STAGING`

### 4. Set Up Firebase Projects

You should have two Firebase projects:

- **Production:** `artbeat-production` (or your production project name)
- **Staging:** `artbeat-staging` (or your staging project name)

Update `.firebaserc` to include both:

```json
{
  "projects": {
    "default": "artbeat-production",
    "production": "artbeat-production",
    "staging": "artbeat-staging"
  }
}
```

---

## 🤖 Android Setup

### 1. Encode Your Keystore

```bash
# Navigate to your keystore location
cd ~/secure-keys/artbeat/

# Encode keystore to base64
base64 -i artbeat-release.keystore -o keystore.base64.txt

# Copy the contents
cat keystore.base64.txt
```

Add the base64 string as `ANDROID_KEYSTORE_BASE64` secret.

### 2. Get Keystore Details

From your `key.properties` file:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=artbeat-release.keystore
```

Add these as GitHub secrets:

- `ANDROID_KEYSTORE_PASSWORD` = storePassword value
- `ANDROID_KEY_PASSWORD` = keyPassword value
- `ANDROID_KEY_ALIAS` = keyAlias value

### 3. Set Up Google Play Service Account

1. Go to [Google Play Console](https://play.google.com/console/)
2. Select your app
3. Go to **Setup** → **API access**
4. Click **Create new service account**
5. Follow the link to Google Cloud Console
6. Create service account with name like `github-actions-deploy`
7. Grant role: **Service Account User**
8. Create and download JSON key
9. Back in Play Console, grant access to the service account
10. Give permissions: **Admin** (Releases)
11. Copy the entire JSON content and add as `GOOGLE_PLAY_SERVICE_ACCOUNT` secret

---

## 🍎 iOS Setup

### 1. Export Distribution Certificate

```bash
# Open Keychain Access on Mac
# Find your "Apple Distribution" certificate
# Right-click → Export "Apple Distribution: Your Name"
# Save as .p12 file with a password
# Remember this password!

# Encode to base64
base64 -i YourCertificate.p12 -o certificate.base64.txt

# Copy the contents
cat certificate.base64.txt
```

Add as `IOS_CERTIFICATE_P12` secret.
Add the password as `IOS_CERTIFICATE_PASSWORD` secret.

### 2. Export Provisioning Profiles

1. Go to [Apple Developer](https://developer.apple.com/)
2. Go to **Certificates, Identifiers & Profiles**
3. Click **Profiles**
4. Download your **App Store** provisioning profile (production)
5. Download your **Ad Hoc** or **App Store** profile (staging)

```bash
# Encode staging profile
base64 -i YourApp_Staging.mobileprovision -o staging.base64.txt
cat staging.base64.txt

# Encode production profile
base64 -i YourApp_Production.mobileprovision -o production.base64.txt
cat production.base64.txt
```

Add as `IOS_PROVISIONING_PROFILE_STAGING` and `IOS_PROVISIONING_PROFILE_PRODUCTION`.

### 3. Create App Store Connect API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Go to **Users and Access** → **Keys** tab
3. Click **+** to create new key
4. Name it `GitHub Actions Deploy`
5. Select role: **App Manager**
6. Click **Generate**
7. Download the `.p8` file (you can only download once!)
8. Note the **Key ID** and **Issuer ID**

Add secrets:

- `APPSTORE_API_KEY_ID` = Key ID
- `APPSTORE_ISSUER_ID` = Issuer ID
- `APPSTORE_API_PRIVATE_KEY` = Contents of the .p8 file

### 4. Create Export Options Plists

Create `ios/ExportOptions-Staging.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>ad-hoc</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.artbeat.app.staging</key>
        <string>YOUR_STAGING_PROFILE_NAME</string>
    </dict>
</dict>
</plist>
```

Create `ios/ExportOptions-Production.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.artbeat.app</key>
        <string>YOUR_PRODUCTION_PROFILE_NAME</string>
    </dict>
</dict>
</plist>
```

---

## 🔑 Environment Variables Setup

### 1. Create Staging Environment File

Edit `.env.staging` with your actual staging values:

```bash
FIREBASE_ANDROID_API_KEY=your_staging_android_key
FIREBASE_IOS_API_KEY=your_staging_ios_key
GOOGLE_MAPS_API_KEY=your_staging_maps_key
STRIPE_PUBLISHABLE_KEY=pk_test_your_test_key
ENVIRONMENT=staging
DEBUG_MODE=false
```

### 2. Create Production Environment File

Edit `.env.production` with your actual production values:

```bash
FIREBASE_ANDROID_API_KEY=your_production_android_key
FIREBASE_IOS_API_KEY=your_production_ios_key
GOOGLE_MAPS_API_KEY=your_production_maps_key
STRIPE_PUBLISHABLE_KEY=pk_live_your_live_key
ENVIRONMENT=production
DEBUG_MODE=false
```

### 3. Add to GitHub Secrets

```bash
# Copy entire contents of staging file
cat .env.staging
# Add as ENV_STAGING secret

# Copy entire contents of production file
cat .env.production
# Add as ENV_PRODUCTION secret
```

---

## 🧪 Testing the Pipeline

### Test Pull Request Checks

```bash
# Create a new branch
git checkout -b test/ci-cd-setup

# Make a small change
echo "# CI/CD Test" >> README.md

# Commit and push
git add README.md
git commit -m "test: CI/CD pipeline"
git push origin test/ci-cd-setup

# Create pull request on GitHub
# Watch the checks run!
```

### Test Staging Deployment

```bash
# Switch to develop branch
git checkout develop

# Merge your test branch
git merge test/ci-cd-setup

# Push to trigger staging deployment
git push origin develop

# Check GitHub Actions tab to see progress
# Check Firebase App Distribution for the build
```

### Test Production Deployment

```bash
# Switch to main branch
git checkout main

# Merge develop (after thorough testing!)
git merge develop

# Push to trigger production deployment
git push origin main

# Or create a version tag
git tag v2.0.7
git push origin v2.0.7

# Check GitHub Actions tab
# Check app stores for submission
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. **Build Fails: "Keystore not found"**

**Solution:**

- Ensure `ANDROID_KEYSTORE_BASE64` secret is set correctly
- Check that the base64 encoding is complete (no line breaks)

#### 2. **iOS Build Fails: "Code signing error"**

**Solution:**

- Verify certificate and provisioning profile are valid
- Check that Team ID in ExportOptions.plist matches your Apple Developer team
- Ensure provisioning profile includes the correct bundle ID

#### 3. **Firebase Deploy Fails: "Permission denied"**

**Solution:**

- Verify `FIREBASE_TOKEN` is valid (regenerate if needed)
- Check that service account has proper permissions in Firebase Console

#### 4. **Tests Fail in CI but Pass Locally**

**Solution:**

- Check for environment-specific dependencies
- Ensure all test files are committed to git
- Look for hardcoded paths or local-only configurations

#### 5. **Google Play Upload Fails: "Invalid credentials"**

**Solution:**

- Verify service account JSON is complete and valid
- Check that service account has "Release Manager" role in Play Console
- Ensure app is created in Play Console

### Getting Help

1. **Check GitHub Actions Logs:**

   - Go to **Actions** tab in GitHub
   - Click on the failed workflow
   - Expand failed steps to see detailed logs

2. **Validate Locally:**

   ```bash
   # Run tests locally
   ./scripts/run_tests.sh

   # Build locally
   ./scripts/build_android_release.sh staging
   ./scripts/build_ios_release.sh staging
   ```

3. **Check Secrets:**
   - Ensure all required secrets are set
   - Verify no extra spaces or line breaks in secrets

---

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/cd)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [Google Play Publishing API](https://developers.google.com/android-publisher)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)

---

## ✅ Checklist

Use this checklist to ensure everything is set up:

### Firebase

- [ ] Firebase CLI token generated and added to GitHub secrets
- [ ] Service account JSON added to GitHub secrets
- [ ] App IDs for staging apps added to GitHub secrets
- [ ] Two Firebase projects created (staging and production)
- [ ] `.firebaserc` updated with both projects

### Android

- [ ] Keystore created and encoded to base64
- [ ] Keystore base64 added to GitHub secrets
- [ ] Keystore password, key password, and alias added to secrets
- [ ] Google Play service account created
- [ ] Service account JSON added to GitHub secrets
- [ ] Service account has "Release Manager" role in Play Console

### iOS

- [ ] Distribution certificate exported and encoded
- [ ] Certificate P12 and password added to GitHub secrets
- [ ] Provisioning profiles downloaded and encoded
- [ ] Staging and production profiles added to GitHub secrets
- [ ] App Store Connect API key created
- [ ] API key ID, issuer ID, and private key added to secrets
- [ ] ExportOptions plists created for staging and production

### Environment Variables

- [ ] `.env.staging` created with actual values
- [ ] `.env.production` created with actual values
- [ ] Both files added to GitHub secrets
- [ ] `.env.*` files added to `.gitignore`

### Testing

- [ ] Pull request checks tested and passing
- [ ] Staging deployment tested successfully
- [ ] Production deployment tested successfully (or ready to test)

---

**🎉 Congratulations!** Your CI/CD pipeline is now set up. Every push to `develop` or `main` will automatically build, test, and deploy your app!

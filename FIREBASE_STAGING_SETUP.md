# Firebase Staging Project Setup

This guide will help you create a Firebase staging project for testing before production deployment.

## 🎯 Why You Need a Staging Project

- **Test safely** - Try new features without affecting production users
- **Separate data** - Keep test data separate from real user data
- **CI/CD testing** - Automated deployments to staging before production
- **Team testing** - Internal testing environment for your team

**Time Required:** ~20 minutes

---

## 📋 Step 1: Create Staging Project

### 1.1 Go to Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project** (or **Create a project**)

### 1.2 Project Details

**Project Name:** `artbeat-staging` (or `wordnerd-artbeat-staging`)

**Note:** Choose a name that clearly indicates it's for staging/testing

### 1.3 Google Analytics (Optional)

- You can enable or disable Google Analytics for staging
- **Recommendation:** Disable it to keep staging data separate from production analytics

### 1.4 Create Project

- Click **Create project**
- Wait for Firebase to set up your project (~30 seconds)
- Click **Continue** when ready

---

## 📱 Step 2: Add Android App

### 2.1 Add Android App

1. In your new staging project, click the **Android icon** to add an Android app
2. **Android package name:** `com.artbeat.app.staging`
   - **Important:** This must match the staging build variant in your `build.gradle.kts`
   - It should be different from production: `com.artbeat.app`

### 2.2 App Nickname (Optional)

**Nickname:** `ArtBeat Android (Staging)`

### 2.3 Debug Signing Certificate (Optional)

You can skip this for now or add your debug SHA-1 certificate:

```bash
# Get your debug certificate SHA-1
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### 2.4 Download google-services.json

1. Click **Download google-services.json**
2. **Important:** Save this file as `google-services-staging.json`
3. Place it in: `/Users/kristybock/artbeat/android/app/src/staging/`

**Note:** You may need to create the `staging` directory:

```bash
mkdir -p /Users/kristybock/artbeat/android/app/src/staging/
```

### 2.5 Register App

- Click **Next** through the remaining steps
- Click **Continue to console**

---

## 🍎 Step 3: Add iOS App (Optional)

### 3.1 Add iOS App

1. Click the **iOS icon** to add an iOS app
2. **iOS bundle ID:** `com.artbeat.app.staging`
   - Must match your iOS staging configuration

### 3.2 App Nickname (Optional)

**Nickname:** `ArtBeat iOS (Staging)`

### 3.3 Download GoogleService-Info.plist

1. Click **Download GoogleService-Info.plist**
2. **Important:** Save this file as `GoogleService-Info-staging.plist`
3. Add it to your Xcode project in the staging configuration

### 3.4 Register App

- Click **Next** through the remaining steps
- Click **Continue to console**

---

## 🔥 Step 4: Enable Firebase Services

Enable the same services you use in production:

### 4.1 Authentication

1. Go to **Build** → **Authentication**
2. Click **Get started**
3. Enable the same sign-in methods as production:
   - Email/Password
   - Google
   - Apple (if using)
   - Any other providers you use

### 4.2 Firestore Database

1. Go to **Build** → **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (we'll deploy proper rules later)
4. Select a location (same as production recommended)
5. Click **Enable**

### 4.3 Storage

1. Go to **Build** → **Storage**
2. Click **Get started**
3. Choose **Start in test mode** (we'll deploy proper rules later)
4. Click **Next** → **Done**

### 4.4 Cloud Functions (Optional)

1. Go to **Build** → **Functions**
2. Click **Get started**
3. Follow the setup instructions if you use Cloud Functions

### 4.5 App Distribution

1. Go to **Release & Monitor** → **App Distribution**
2. Click **Get started**
3. This is where your staging builds will be uploaded for testing

---

## 🔧 Step 5: Update Project Configuration

### 5.1 Update .firebaserc

Edit `/Users/kristybock/artbeat/.firebaserc`:

```json
{
  "projects": {
    "default": "wordnerd-artbeat",
    "production": "wordnerd-artbeat",
    "staging": "artbeat-staging"
  }
}
```

**Replace `artbeat-staging` with your actual staging project ID**

### 5.2 Get Project Details

You'll need these for GitHub Secrets and environment variables:

1. Go to **Project Settings** (gear icon)
2. Note down:
   - **Project ID** (e.g., `artbeat-staging`)
   - **Web API Key**
   - **Project Number** (Sender ID)

### 5.3 Get App IDs

1. In **Project Settings**, scroll to **Your apps**
2. For Android app:
   - Copy the **App ID** (looks like: `1:123456789:android:abc123...`)
   - This is your `FIREBASE_ANDROID_APP_ID_STAGING`
3. For iOS app (if added):
   - Copy the **App ID** (looks like: `1:123456789:ios:abc123...`)
   - This is your `FIREBASE_IOS_APP_ID_STAGING`

---

## 📝 Step 6: Configure Environment Variables

### 6.1 Update .env.staging

Edit `/Users/kristybock/artbeat/.env.staging`:

```bash
# Firebase Configuration (Staging)
FIREBASE_ANDROID_API_KEY=your_staging_android_api_key_here
FIREBASE_IOS_API_KEY=your_staging_ios_api_key_here
FIREBASE_PROJECT_ID=artbeat-staging
FIREBASE_MESSAGING_SENDER_ID=your_staging_sender_id_here
FIREBASE_APP_ID_ANDROID=1:123456789:android:abc123...
FIREBASE_APP_ID_IOS=1:123456789:ios:abc123...

# App Configuration
APP_NAME=ArtBeat Staging
ENVIRONMENT=staging
API_BASE_URL=https://staging-api.artbeat.app

# Feature Flags
ENABLE_DEBUG_FEATURES=true
ENABLE_ANALYTICS=false
```

**Get these values from Firebase Console → Project Settings**

---

## 🔐 Step 7: Deploy Firebase Rules

Deploy your security rules to the staging project:

```bash
# Switch to staging project
firebase use staging

# Deploy Firestore and Storage rules
firebase deploy --only firestore:rules,storage:rules

# Verify deployment
firebase projects:list
```

**Important:** Make sure your rules are production-ready (from Phase 1)

---

## 🧪 Step 8: Test the Staging Setup

### 8.1 Build Staging App Locally

```bash
# Android
flutter build apk --flavor staging --debug

# iOS (if configured)
flutter build ios --flavor staging --debug
```

### 8.2 Verify Firebase Connection

1. Install the staging app on a test device
2. Try signing in
3. Check Firebase Console → Authentication to see if user was created
4. Try uploading an image
5. Check Firebase Console → Storage to see if file was uploaded

### 8.3 Check Firestore Data

1. Go to Firebase Console → Firestore Database
2. Verify that data is being written to the staging project
3. Make sure it's NOT appearing in your production project

---

## ✅ Verification Checklist

- [ ] Staging project created in Firebase Console
- [ ] Android app added with package name `com.artbeat.app.staging`
- [ ] iOS app added with bundle ID `com.artbeat.app.staging` (if using iOS)
- [ ] `google-services-staging.json` downloaded and placed correctly
- [ ] Authentication enabled with same providers as production
- [ ] Firestore Database created
- [ ] Storage enabled
- [ ] App Distribution enabled
- [ ] `.firebaserc` updated with staging project alias
- [ ] `.env.staging` filled with actual API keys
- [ ] Firebase rules deployed to staging
- [ ] Staging app builds successfully
- [ ] Staging app connects to Firebase staging project
- [ ] App IDs copied for GitHub Secrets

---

## 📊 Summary of Values for GitHub Secrets

After completing this setup, you'll have these values ready:

| Secret Name                       | Value Location                                             |
| --------------------------------- | ---------------------------------------------------------- |
| `FIREBASE_ANDROID_APP_ID_STAGING` | Firebase Console → Project Settings → Android App → App ID |
| `FIREBASE_IOS_APP_ID_STAGING`     | Firebase Console → Project Settings → iOS App → App ID     |
| `ENV_STAGING`                     | Contents of `.env.staging` file                            |

---

## 🆘 Troubleshooting

### "Package name already exists"

- The package name must be unique across all Firebase projects
- Use a different suffix like `.staging` or `.dev`

### "App not connecting to Firebase"

- Verify `google-services-staging.json` is in the correct location
- Check that the package name matches exactly
- Rebuild the app after adding the config file

### "Rules deployment failed"

- Make sure you're using the correct project: `firebase use staging`
- Check that your rules syntax is valid
- Verify you have permission to deploy to the project

### "Can't find staging flavor"

- Check your `build.gradle.kts` for the staging flavor configuration
- Make sure the package name matches: `com.artbeat.app.staging`

---

## 🎯 Next Steps

After completing this setup:

1. ✅ Add Firebase secrets to GitHub (see `GITHUB_SECRETS_SETUP.md`)
2. ✅ Test the CI/CD pipeline with a pull request
3. ✅ Deploy to staging by pushing to `develop` branch
4. ✅ Invite team members to test via Firebase App Distribution

---

## 📚 Additional Resources

- [Firebase Projects Documentation](https://firebase.google.com/docs/projects/learn-more)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [App Distribution Guide](https://firebase.google.com/docs/app-distribution)

Good luck! 🚀

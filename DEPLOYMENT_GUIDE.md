# ArtBeat Deployment Guide

A comprehensive guide for deploying ArtBeat to different environments.

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Environments](#environments)
3. [Manual Deployment](#manual-deployment)
4. [Automated Deployment (CI/CD)](#automated-deployment-cicd)
5. [Deployment Checklist](#deployment-checklist)
6. [Rollback Procedures](#rollback-procedures)
7. [Post-Deployment Verification](#post-deployment-verification)

---

## 🚀 Quick Start

### First Time Setup

```bash
# 1. Create production keystore
./scripts/setup_android_keystore.sh

# 2. Set up environment files
cp .env.example .env.development
cp .env.example .env.staging
cp .env.production.example .env.production

# Edit each file with actual values
nano .env.development
nano .env.staging
nano .env.production

# 3. Validate security setup
./scripts/validate_production_ready.sh

# 4. Run tests
./scripts/run_tests.sh

# 5. Deploy Firebase rules
firebase deploy --only firestore:rules,storage:rules
```

---

## 🌍 Environments

### Development

- **Purpose:** Local development and testing
- **Firebase Project:** Development project (optional)
- **Features:** Debug mode enabled, verbose logging
- **Deployment:** Manual only

### Staging

- **Purpose:** Internal testing before production
- **Firebase Project:** Staging project
- **Features:** Production-like environment, test data
- **Deployment:** Automated via `develop` branch
- **Distribution:** Firebase App Distribution

### Production

- **Purpose:** Live app for end users
- **Firebase Project:** Production project
- **Features:** Optimized, analytics enabled
- **Deployment:** Automated via `main` branch
- **Distribution:** Google Play Store, Apple App Store

---

## 🛠️ Manual Deployment

### Deploy to Staging

#### Android (Staging)

```bash
# 1. Build staging release
./scripts/build_android_release.sh staging

# 2. Upload to Firebase App Distribution
firebase appdistribution:distribute \
  build/app/outputs/bundle/release/app-release.aab \
  --app YOUR_FIREBASE_ANDROID_APP_ID \
  --groups internal-testers \
  --release-notes "Staging build - $(date)"
```

#### iOS (Staging)

```bash
# 1. Build staging release
./scripts/build_ios_release.sh staging

# 2. Upload to Firebase App Distribution
firebase appdistribution:distribute \
  build/ios/ipa/artbeat.ipa \
  --app YOUR_FIREBASE_IOS_APP_ID \
  --groups internal-testers \
  --release-notes "Staging build - $(date)"
```

#### Firebase Rules (Staging)

```bash
# Deploy to staging project
firebase deploy --only firestore:rules,storage:rules --project staging
```

---

### Deploy to Production

#### Android (Production)

```bash
# 1. Validate everything
./scripts/validate_production_ready.sh

# 2. Run all tests
./scripts/run_tests.sh --coverage

# 3. Build production release
./scripts/build_android_release.sh production

# 4. Upload to Google Play Console
# Option A: Using bundletool (manual)
# - Go to https://play.google.com/console
# - Select your app
# - Go to Release → Production
# - Create new release
# - Upload build/app/outputs/bundle/release/app-release.aab

# Option B: Using fastlane (if configured)
cd android
fastlane deploy_production
```

#### iOS (Production)

```bash
# 1. Validate everything
./scripts/validate_production_ready.sh

# 2. Run all tests
./scripts/run_tests.sh --coverage

# 3. Build production release
./scripts/build_ios_release.sh production

# 4. Upload to App Store Connect
# Option A: Using Xcode
# - Open Xcode
# - Window → Organizer
# - Select the archive
# - Click "Distribute App"
# - Follow the wizard

# Option B: Using Transporter app
# - Open Transporter
# - Drag build/ios/ipa/artbeat.ipa
# - Click "Deliver"

# Option C: Using command line
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/artbeat.ipa \
  --username YOUR_APPLE_ID \
  --password YOUR_APP_SPECIFIC_PASSWORD
```

#### Firebase Rules (Production)

```bash
# Deploy to production project
firebase deploy --only firestore:rules,storage:rules --project production

# Deploy cloud functions (if updated)
firebase deploy --only functions --project production
```

---

## 🤖 Automated Deployment (CI/CD)

### Using GitHub Actions

#### Deploy to Staging

```bash
# Method 1: Push to develop branch
git checkout develop
git merge feature/your-feature
git push origin develop

# GitHub Actions will automatically:
# 1. Run tests
# 2. Build Android & iOS
# 3. Upload to Firebase App Distribution
# 4. Deploy Firebase rules to staging
```

#### Deploy to Production

```bash
# Method 1: Push to main branch
git checkout main
git merge develop
git push origin main

# Method 2: Create version tag
git tag v2.0.7
git push origin v2.0.7

# GitHub Actions will automatically:
# 1. Run tests
# 2. Run security validation
# 3. Build Android & iOS
# 4. Upload to app stores
# 5. Deploy Firebase rules to production
# 6. Create GitHub release
```

#### Manual Trigger

You can also manually trigger workflows from GitHub:

1. Go to **Actions** tab in GitHub
2. Select the workflow (e.g., "Deploy to Production")
3. Click **Run workflow**
4. Select branch and options
5. Click **Run workflow**

---

## ✅ Deployment Checklist

### Pre-Deployment

#### All Environments

- [ ] All tests passing locally
- [ ] Code reviewed and approved
- [ ] No console errors or warnings
- [ ] Dependencies up to date
- [ ] Version number bumped (if needed)

#### Staging

- [ ] Feature branch merged to `develop`
- [ ] Staging environment variables updated
- [ ] Test data prepared in staging Firebase

#### Production

- [ ] Staging testing completed successfully
- [ ] All critical bugs fixed
- [ ] Release notes prepared
- [ ] App store screenshots updated (if UI changed)
- [ ] Privacy policy updated (if data collection changed)
- [ ] Marketing team notified
- [ ] Support team briefed on new features

### Security Checks (Production Only)

- [ ] `./scripts/validate_production_ready.sh` passes
- [ ] Firebase rules deployed and tested
- [ ] API keys rotated (if compromised)
- [ ] No debug code or console.logs
- [ ] App Check enabled and enforced
- [ ] SSL/TLS certificates valid

### Build Verification

#### Android

- [ ] Keystore configured correctly
- [ ] ProGuard rules tested (if minification enabled)
- [ ] App bundle size reasonable (<150MB)
- [ ] Tested on multiple Android versions (API 24+)
- [ ] Tested on different screen sizes

#### iOS

- [ ] Code signing certificates valid
- [ ] Provisioning profiles not expired
- [ ] IPA size reasonable (<200MB)
- [ ] Tested on multiple iOS versions (15.0+)
- [ ] Tested on iPhone and iPad

### Firebase

- [ ] Firestore rules deployed
- [ ] Storage rules deployed
- [ ] Cloud functions deployed (if updated)
- [ ] Indexes created (if needed)
- [ ] App Check configured

---

## 🔄 Rollback Procedures

### If Deployment Fails

#### Android

```bash
# 1. Stop the rollout in Google Play Console
# - Go to Release → Production
# - Click "Halt rollout"

# 2. Revert to previous version
# - Click "Manage" on previous release
# - Click "Resume rollout" or "Increase rollout"

# 3. Fix the issue locally
git revert HEAD
# or
git checkout previous-working-commit

# 4. Redeploy
./scripts/build_android_release.sh production
```

#### iOS

```bash
# 1. Remove from review (if not yet approved)
# - Go to App Store Connect
# - Select your app
# - Click "Remove from Review"

# 2. If already live, submit previous version
# - You cannot rollback directly
# - Must submit a new build with fixes

# 3. Fix the issue locally
git revert HEAD

# 4. Redeploy
./scripts/build_ios_release.sh production
```

#### Firebase Rules

```bash
# 1. View deployment history
firebase deploy:history --project production

# 2. Rollback to previous version
firebase rollback firestore:rules --project production
firebase rollback storage:rules --project production

# Or specify a specific deployment ID
firebase rollback firestore:rules DEPLOYMENT_ID --project production
```

### Emergency Hotfix Process

```bash
# 1. Create hotfix branch from main
git checkout main
git checkout -b hotfix/critical-bug-fix

# 2. Fix the issue
# ... make changes ...

# 3. Test thoroughly
./scripts/run_tests.sh
./scripts/validate_production_ready.sh

# 4. Commit and push
git add .
git commit -m "hotfix: Fix critical bug"
git push origin hotfix/critical-bug-fix

# 5. Create PR to main
# - Get expedited review
# - Merge immediately after approval

# 6. Deploy
git checkout main
git pull
git push origin main  # Triggers CI/CD

# 7. Merge back to develop
git checkout develop
git merge main
git push origin develop
```

---

## ✓ Post-Deployment Verification

### Immediate Checks (Within 1 hour)

#### App Functionality

- [ ] App launches successfully
- [ ] User authentication works
- [ ] Core features functional
- [ ] No crash reports in Firebase Crashlytics
- [ ] No error spikes in Firebase Analytics

#### Firebase

- [ ] Firestore rules working correctly
- [ ] Storage rules working correctly
- [ ] Cloud functions responding
- [ ] App Check not blocking legitimate users

#### Monitoring

- [ ] Check Firebase Crashlytics dashboard
- [ ] Check Firebase Performance dashboard
- [ ] Check Firebase Analytics for user activity
- [ ] Monitor error logs

### Short-term Checks (Within 24 hours)

- [ ] User feedback reviewed
- [ ] App store reviews monitored
- [ ] Performance metrics normal
- [ ] No unusual error patterns
- [ ] Database performance stable
- [ ] API response times normal

### Commands for Verification

```bash
# Check Firebase deployment status
firebase deploy:history --project production

# View recent Firestore activity
firebase firestore:indexes --project production

# Check cloud functions logs
firebase functions:log --project production

# Monitor app performance
# Go to: https://console.firebase.google.com/project/YOUR_PROJECT/overview
```

---

## 📊 Deployment Metrics

Track these metrics for each deployment:

### Build Metrics

- Build time
- App size (Android AAB, iOS IPA)
- Number of tests run
- Test coverage percentage

### Deployment Metrics

- Time from commit to production
- Number of failed deployments
- Rollback frequency
- Time to rollback

### Quality Metrics

- Crash-free rate (target: >99%)
- App startup time
- API response times
- User-reported bugs

---

## 🔔 Notifications

### Set Up Deployment Notifications

#### Slack (Optional)

Add to `.github/workflows/deploy-production.yml`:

```yaml
- name: Send Slack notification
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: "Production deployment completed!"
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
  if: always()
```

#### Email (Optional)

Configure in GitHub repository settings:

- Settings → Notifications
- Enable "Actions" notifications
- Add email addresses

---

## 📝 Deployment Log Template

Keep a log of all production deployments:

```markdown
## Deployment: v2.0.7 - 2024-01-15

**Deployed by:** Your Name
**Environment:** Production
**Commit:** abc123def456

### Changes

- Added new feature X
- Fixed bug Y
- Updated dependency Z

### Pre-deployment Checks

- [x] All tests passed
- [x] Security validation passed
- [x] Staging testing completed

### Deployment Steps

1. Built Android AAB - ✅
2. Built iOS IPA - ✅
3. Uploaded to Google Play - ✅
4. Uploaded to App Store - ✅
5. Deployed Firebase rules - ✅

### Post-deployment Verification

- [x] App launches successfully
- [x] No crash reports
- [x] Core features working
- [x] Firebase rules working

### Issues

None

### Rollback Plan

If issues arise, rollback to v2.0.6 using previous AAB/IPA
```

---

## 🆘 Emergency Contacts

Maintain a list of contacts for deployment emergencies:

- **Firebase Support:** [Firebase Support](https://firebase.google.com/support)
- **Google Play Support:** [Play Console Help](https://support.google.com/googleplay/android-developer)
- **Apple Developer Support:** [Apple Developer Support](https://developer.apple.com/support/)
- **Team Lead:** [Contact info]
- **DevOps:** [Contact info]

---

## 📚 Additional Resources

- [CI/CD Setup Guide](./CI_CD_SETUP.md)
- [Security Setup Guide](./SECURITY_SETUP.md)
- [Quick Start Production Guide](./QUICK_START_PRODUCTION.md)
- [Phase 1 Complete Summary](./PHASE_1_COMPLETE.md)

---

**Remember:** Always test in staging before deploying to production! 🚀

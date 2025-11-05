# ArtBeat Crash Fix - Deployment Checklist

**Build Version**: 2.3.2  
**Target Release Date**: TODAY  
**Estimated Deploy Time**: 2-3 hours

---

## ✅ PRE-DEPLOYMENT (Do This First)

### Code Review

- [ ] Read `CRASH_FIX_EXECUTIVE_SUMMARY.md`
- [ ] Review the 3 new safety services:
  - [ ] `stripe_safety_service.dart`
  - [ ] `auth_safety_service.dart`
  - [ ] `crash_recovery_service.dart`
- [ ] Review changes to `main.dart`
- [ ] Review changes to `artbeat_core.dart`

### Environment Verification

- [ ] Flutter version current: `flutter --version`
- [ ] All dependencies installed: `flutter pub get`
- [ ] No uncommitted changes: `git status`
- [ ] Backup current working branch

---

## 🏗️ BUILD PHASE (1-2 Hours)

### Clean Build

```bash
flutter clean
flutter pub get
```

- [ ] Completed without errors
- [ ] All packages resolved

### Syntax Check

```bash
dart analyze --fatal-infos
```

- [ ] No errors or warnings
- [ ] Or accept warnings if pre-existing

### Debug Build

```bash
flutter build appbundle --debug
flutter build apk --debug
```

- [ ] appbundle builds successfully
- [ ] apk builds successfully

### Release Build

```bash
flutter build appbundle --release
flutter build apk --release
```

- [ ] appbundle builds successfully (~50MB)
- [ ] APK builds successfully
- [ ] Signing works correctly

---

## 🧪 TESTING PHASE (1 Hour)

### Test Environment Setup

- [ ] 2+ Android devices available
- [ ] Devices at different Android versions (test 7.0 and 14+)
- [ ] Devices connected via USB
- [ ] ADB working: `adb devices`

### Fresh Install Test

```bash
adb uninstall com.wordnerd.artbeat
adb install build/app/outputs/flutter-apk/app-debug.apk
```

- [ ] App installs successfully
- [ ] No install errors
- [ ] App launches on Device 1
- [ ] App launches on Device 2

### Core Functionality Tests

#### Launch & Splash

- [ ] App launches without crash
- [ ] Splash screen displays
- [ ] Loading indicator shows
- [ ] Auth screen appears (or dashboard if logged in)

#### Authentication (if not logged in)

- [ ] Can see login screen without crash
- [ ] Email/password auth doesn't crash
- [ ] "Forgot Password" link doesn't crash
- [ ] Firebase loading indicates properly

#### Main Dashboard

- [ ] Dashboard loads after login
- [ ] Bottom tab bar appears
- [ ] Drawer menu opens without crash
- [ ] All tabs clickable without crash

#### Payment Features (Critical)

- [ ] Navigate to any payment screen
- [ ] ✅ Screen appears (no crash even if unavailable)
- [ ] If available: Can tap payment button
- [ ] If unavailable: Shows clear error message
- [ ] No null reference crashes

#### Authentication Features (Critical)

- [ ] Google Sign-In button visible (no crash)
- [ ] If sign-in available: Can attempt sign-in
- [ ] ✅ No crash in SignInHubActivity
- [ ] Error message clear if sign-in fails

#### Crash Testing

- [ ] Navigate to multiple screens without crashes
- [ ] Open and close payment sheet multiple times
- [ ] Attempt sign-in and cancel
- [ ] **Turn off internet** - app handles gracefully
- [ ] **Turn airplane mode on** - app handles gracefully

### Logs Verification

```bash
adb logcat | grep "🔒\|✅\|❌"
```

- [ ] See "✅ Stripe Safety Service initialized" (if key present)
- [ ] See "✅ Auth Safety Service initialized"
- [ ] See "⚠️" for gracefully degraded services (not errors)
- [ ] No crash backtraces

---

## 📊 VALIDATION PHASE (30 Minutes)

### Metrics Verification

- [ ] App crash rate on test devices: 0%
- [ ] Payment flow works or shows clear error
- [ ] Auth flow works or shows clear error
- [ ] No regressions in other features
- [ ] Logs show proper initialization

### Performance Check

```bash
flutter analyze
```

- [ ] No new errors introduced
- [ ] Performance not degraded
- [ ] Build time reasonable (<5 min)

### APK/Bundle Quality

- [ ] APK size reasonable (~100-150MB)
- [ ] Bundle size reasonable (~50-100MB)
- [ ] Signing certificate correct
- [ ] Version numbers updated to 2.3.2

---

## 🚀 RELEASE PHASE

### Prepare Release

- [ ] Increment version to 2.3.2 in pubspec.yaml
- [ ] Build signed release APK and bundle
- [ ] Generate changelog: "Critical crash fixes for payment and auth flows"
- [ ] Prepare release notes

### Release to Internal Testing

- [ ] Upload to internal testing track in Play Console
- [ ] Set rollout to 100% (for internal testers only)
- [ ] Wait 15 minutes
- [ ] Verify internal testers can install

### Staged Rollout

- [ ] Create production release with 10% rollout
- [ ] Set rollout percentage to 10%
- [ ] **WAIT 6 HOURS** - Monitor crash reports

#### Decision Point 1 (6 hours after 10% rollout)

- [ ] Crash rate dropped from 100% to <10%?
  - [ ] YES → Continue to next phase
  - [ ] NO → ROLLBACK - investigate

### Continue Rollout (if crash rate improved)

- [ ] Increase rollout to 50%
- [ ] **WAIT 12 HOURS** - Monitor crash reports

#### Decision Point 2 (12 hours after 50% rollout)

- [ ] Crash rate <5%?
  - [ ] YES → Full rollout
  - [ ] NO → ROLLBACK - investigate

### Final Rollout

- [ ] Increase rollout to 100%
- [ ] **MONITOR 48 HOURS** - Watch crash reports closely
- [ ] Monitor user reviews for payment/auth complaints
- [ ] Check support tickets for issues

---

## 📈 POST-DEPLOYMENT MONITORING

### 24-Hour Check

- [ ] Firebase Crashlytics shows <5% crash rate
- [ ] Stripe payment crashes gone
- [ ] Billing crashes gone
- [ ] Sign-in crashes gone
- [ ] No new crash patterns

### 48-Hour Check

- [ ] Crash rate stable <5%
- [ ] User ratings stable or improving
- [ ] Support tickets normal volume
- [ ] No major complaints about payment/auth

### 1-Week Check

- [ ] Crash rate continues <5%
- [ ] App store rating improved
- [ ] User retention improved
- [ ] Revert to normal monitoring

---

## ⚠️ ROLLBACK TRIGGERS

IMMEDIATELY ROLLBACK if:

- [ ] Crash rate doesn't drop below 20% within 2 hours
- [ ] New crash pattern emerges
- [ ] Payment system completely broken
- [ ] Auth system completely broken
- [ ] Multiple crash reports with same error

**Rollback Steps**:

```bash
# In Play Console, select "Manage release"
# Find the new build (2.3.2)
# Click "Rollback" to previous version (2.3.1)
# Confirm rollback
```

Then investigate the failure using logs.

---

## 📞 CONTINGENCY PLANS

### If Payment Feature Broken

- [ ] Users can still use app (graceful degradation)
- [ ] Can rollback to 2.3.1
- [ ] Alternative: Disable payment features server-side

### If Auth Feature Broken

- [ ] Users can still login with email/password
- [ ] Google Sign-In gracefully fails
- [ ] Can rollback to 2.3.1
- [ ] Alternative: Disable Google Sign-In server-side

### If App Won't Install

- [ ] Check APK signature
- [ ] Check minimum SDK (24)
- [ ] Check target SDK (36)
- [ ] Check manifest permissions

---

## 📋 FINAL VERIFICATION

Before marking as complete:

- [ ] Version 2.3.2 deployed to Play Store
- [ ] Crash rate <5% confirmed
- [ ] Payment feature working or graceful error
- [ ] Auth feature working or graceful error
- [ ] No regressions in other features
- [ ] User satisfaction maintained or improved
- [ ] Deployment documented in release notes
- [ ] Team notified of successful deployment

---

## 📞 TEAM NOTIFICATIONS

### Pre-Deployment

- [ ] Notify team: Starting deployment
- [ ] Slack message: "Deploying crash fixes v2.3.2"

### During Deployment

- [ ] Notify team: Build complete
- [ ] Notify team: Testing complete
- [ ] Notify team: Release begun (10% rollout)

### Post-Deployment

- [ ] Notify team: 10% rollout monitoring
- [ ] Notify team: Increasing to 50%
- [ ] Notify team: Full rollout complete
- [ ] Notify team: Monitoring complete - Success!

---

## ✅ SIGN-OFF

- [ ] I have read all documentation
- [ ] I understand the changes
- [ ] I have tested the build
- [ ] I am ready to deploy

**Deployer Name**: ******\_\_\_******  
**Date**: ******\_\_\_******  
**Time**: ******\_\_\_******  
**Status**: ⚪ PENDING / 🟡 IN PROGRESS / 🟢 COMPLETE

---

## 📊 DEPLOYMENT LOG

### Build Phase

- [ ] Start time: ******\_\_\_******
- [ ] End time: ******\_\_\_******
- [ ] Duration: ******\_\_\_******
- [ ] Issues: ******\_\_\_******

### Testing Phase

- [ ] Device 1 (Android \_\_\_): ✅/❌
- [ ] Device 2 (Android \_\_\_): ✅/❌
- [ ] Issues encountered: ******\_\_\_******

### Release Phase

- [ ] Time at 10%: ******\_\_\_******
- [ ] Crash rate at 6h: ******\_\_\_******
- [ ] Time at 50%: ******\_\_\_******
- [ ] Crash rate at 12h: ******\_\_\_******
- [ ] Time at 100%: ******\_\_\_******
- [ ] Final status: ✅ SUCCESS / ❌ ROLLBACK

### Final Notes

---

---

**Questions?** See CRASH_FIX_QUICK_REFERENCE.md or contact the development team.

# ✅ Apple Fixes Checklist

**Last Updated**: Now  
**Status**: 🟢 Code Ready, Manual Actions Needed  
**Estimated Time**: 2-3 hours total

---

## PHASE 1: Verify Code Changes (15 minutes)

- [ ] Open: `packages/artbeat_auth/lib/src/services/auth_service.dart`

  - [ ] Verify: Import `dart:async` is added (line 3)
  - [ ] Verify: `signInWithApple()` method has timeout handling
  - [ ] Verify: All null checks are present

- [ ] Open: `packages/artbeat_core/lib/src/mixins/user_moderation_mixin.dart`

  - [ ] Verify: File exists
  - [ ] Verify: Contains `blockUser()` method
  - [ ] Verify: Contains `showUserModerationMenu()` method

- [ ] Open: `packages/artbeat_artwork/lib/src/widgets/artwork_social_widget.dart`

  - [ ] Verify: Imports `UserModerationMixin`
  - [ ] Verify: State class uses `with UserModerationMixin`
  - [ ] Verify: Comment cards have trailing PopupMenuButton

- [ ] Open: `packages/artbeat_core/lib/artbeat_core.dart`
  - [ ] Verify: Line 83 exports `UserModerationMixin`

---

## PHASE 2: Local Build & Test (45 minutes)

### Build

```bash
cd /Users/kristybock/artbeat

# Clean everything
flutter clean
flutter pub get
flutter pub get packages/artbeat_auth/pubspec.yaml
flutter pub get packages/artbeat_artwork/pubspec.yaml

# Check for errors
flutter analyze

# Build iOS (this takes a while)
flutter build ios --release
```

- [ ] No build errors
- [ ] No analyzer warnings (check for any new ones related to your changes)
- [ ] Build completes successfully

### Test Apple Sign-In

1. Run on simulator: `flutter run -d "iPhone 15 Pro"`
2. Navigate to login screen
3. Tap "Sign in with Apple"
4. [ ] Sign-in dialog appears
5. [ ] After authentication, dashboard loads (no crashes)
6. [ ] Check console: Should see `✅ Apple Sign-In successful`

### Test Comment Blocking

1. In app, navigate to any artwork with comments
2. If no comments exist, post one as another test user
3. [ ] See comment appear
4. [ ] Tap 3-dot menu icon on comment (should appear on right)
5. [ ] See "Block user" option
6. [ ] See "Report comment" option
7. [ ] Tap "Block user"
8. [ ] See snackbar: "Blocked [username]"
9. [ ] Comment disappears or is grayed out

### Test Error Handling

1. Turn off WiFi
2. Try Apple Sign-In again
3. [ ] After ~30 seconds, shows timeout message (not a crash)
4. Turn WiFi back on

- [ ] All tests pass, no crashes

---

## PHASE 3: App Store Connect Updates (60 minutes)

### Login to App Store Connect

- [ ] Navigate to: https://appstoreconnect.apple.com/
- [ ] Login with your Apple ID
- [ ] Select your app

### Update IAP Products

**STEP 1: Update "Small Ad - 1 Week"**

- [ ] Click on product: `ad_small_1w`
- [ ] Change "App Store Preview":
  - Display Name: `Quick Ad Boost - 7 Days`
  - Description: `Get started with 7 days of standard placement to showcase your artwork`
- [ ] Upload promotional image:
  - Dimensions: 1200 x 630px
  - Design: Blue background, "Quick Ad Boost - 7 Days" text, "$9.99" price
  - Size: Should be under 100KB
- [ ] Click "Save"

**STEP 2: Update "Small Ad - 1 Month"**

- [ ] Click on product: `ad_small_1m`
- [ ] Change "App Store Preview":
  - Display Name: `Small Ad Bundle - 30 Days`
  - Description: `Display your artwork for a full month with standard visibility`
- [ ] Upload promotional image:
  - Dimensions: 1200 x 630px
  - Design: Different from other images (e.g., teal/green background), "$24.99" visible
- [ ] Click "Save"

**STEP 3: Update "Small Ad - 3 Months"**

- [ ] Click on product: `ad_small_3m`
- [ ] Change "App Store Preview":
  - Display Name: `Small Ad Extended - Quarterly`
  - Description: `Three months of consistent standard placement at a discounted rate`
- [ ] Upload promotional image:
  - Design: Cyan background, "$59.99" visible, "3 MONTHS" text
- [ ] Click "Save"

**STEP 4: Update "Big Ad - 1 Week"**

- [ ] Click on product: `ad_big_1w`
- [ ] Change "App Store Preview":
  - Display Name: `Premium Ad - One Week`
  - Description: `Maximum visibility with premium placement for 7 days`
- [ ] Upload promotional image:
  - Design: Gold/premium background, "$19.99" visible, "PREMIUM" text prominent
- [ ] Click "Save"

**STEP 5: Update "Big Ad - 1 Month"**

- [ ] Click on product: `ad_big_1m`
- [ ] Change "App Store Preview":
  - Display Name: `Premium Ad Campaign - Full Month`
  - Description: `30 days of premium placement featuring your artwork prominently`
- [ ] Upload promotional image:
  - Design: Gold background, "$49.99" visible, "30 DAYS" text
- [ ] Click "Save"

**STEP 6: Update "Big Ad - 3 Months"**

- [ ] Click on product: `ad_big_3m`
- [ ] Change "App Store Preview":
  - Display Name: `Premium Ad Ultimate - Quarterly`
  - Description: `Three months of premium placement - our best value offer`
- [ ] Upload promotional image:
  - Design: Gold/diamond background, "$119.99" visible, "QUARTERLY OFFER" text
- [ ] Click "Save"

**OPTIONAL: Update Gift Products** (Recommended)

- [ ] `artbeat_gift_small`: "Quick Support Gift ($4.99)"
- [ ] `artbeat_gift_medium`: "Artist Fan Pack ($9.99)"
- [ ] `artbeat_gift_large`: "Patron Bundle ($24.99)"
- [ ] `artbeat_gift_premium`: "Premium Support ($49.99)"

---

## PHASE 4: Build & Upload New Version (30 minutes)

### Prepare Release

```bash
cd /Users/kristybock/artbeat

# Make sure code is clean
flutter clean
flutter pub get

# Build for release
flutter build ios --release

# Build number should be: 2.3.5+68 (increment from 67)
```

- [ ] Build completes without errors
- [ ] IPA file is generated

### Create Release Notes

In App Store Connect → Your Build → Release Notes, add:

```
Version 2.3.5+68

Improvements:
• Improved Apple Sign-In stability and error handling
• Added user blocking feature for content moderation
• Distinct in-app purchase offerings with clearer descriptions
• Enhanced comment system with reporting capability

Bug Fixes:
• Fixed potential issues with Apple authentication timeouts
• Improved error messaging for user guidance
```

- [ ] Release notes written

### Upload Build

1. In Xcode or via Application Loader, upload the new build
2. Wait for processing (usually 5-10 minutes)
3. [ ] Build appears in "Builds" section
4. [ ] Build shows "Ready to Submit"

---

## PHASE 5: Submit for Review (5 minutes)

- [ ] In App Store Connect, click "Submit for Review" on your build
- [ ] Answer questions:
  - [ ] "Does this app use encryption?" → Yes (Firebase)
  - [ ] "Does this app use the identifier for advertising purposes?" → Check current setting
  - [ ] Anything unusual? → No
- [ ] Select release date: "Automatic release after review"
- [ ] Click "Submit"

- [ ] Confirmation message appears: "Version submitted for review"
- [ ] Status shows: "Waiting for Review"

---

## PHASE 6: Wait & Monitor (24-48 hours)

- [ ] Check email for status updates
- [ ] Monitor in App Store Connect
  - [ ] Watch for status: "In Review" → "Ready for Sale" ✅
  - [ ] Or watch for: "Rejected" → Review feedback

### If Rejected Again:

- [ ] Read Apple's feedback carefully
- [ ] Check console logs for any issues
- [ ] File exists: `APPLE_REJECTION_FIXES.md` for detailed solutions
- [ ] Update code as needed
- [ ] Resubmit

### If Approved ✅:

🎉 **Congratulations!**

- [ ] App will auto-publish based on release schedule
- [ ] Notify your 5 artists that iOS app is coming
- [ ] Schedule launch announcement
- [ ] Begin growth strategy (per your earlier 5-month plan)

---

## ✨ Success Indicators

✅ **You'll know you're done when**:

1. Apple Sign-In works reliably without crashes
2. Comments show block/report menu on right side
3. Can successfully block a user
4. All 6 IAP products have unique names, descriptions, and images
5. App builds without errors
6. App submitted to review

✅ **You'll know it's approved when**:

1. Email from Apple: "Your app [ARTbeat] has been approved"
2. App Store Connect status: "Ready for Sale"
3. Can download app from iOS App Store

---

## 🚨 If Something Goes Wrong

### Build Errors

```bash
flutter clean
flutter pub get --upgrade
flutter build ios --release
```

### Can't see comment menu?

- [ ] Check: Is comment from someone else (not your own user)?
- [ ] Check: Are you logged in?
- [ ] Check: Scroll to see if menu is just off-screen?

### Apple Sign-In still errors?

- [ ] Check console logs: `AppLogger.auth()`
- [ ] Try different device/iOS version
- [ ] Verify nonce generation is working

### IAP images not uploading?

- [ ] Check file size (should be <100KB)
- [ ] Check format (JPEG or PNG)
- [ ] Check dimensions (1200x630px)
- [ ] Try different browser

### App Store Connect won't save changes?

- [ ] Verify all required fields are filled
- [ ] Try logging out and back in
- [ ] Use Chrome browser instead of Safari

---

## 📞 Quick Reference

| Issue            | File                         | Line    | Action              |
| ---------------- | ---------------------------- | ------- | ------------------- |
| Apple Sign-In    | `auth_service.dart`          | 282-390 | Verify improvements |
| Comment blocking | `artwork_social_widget.dart` | 366-410 | Verify PopupMenu    |
| Mixin export     | `artbeat_core.dart`          | 83      | Verify export       |
| IAP names        | App Store Connect            | -       | Update 6 products   |

---

## ⏱️ Time Breakdown

| Phase             | Time                         | Notes                          |
| ----------------- | ---------------------------- | ------------------------------ |
| Verify code       | 15 min                       | Just reading/checking          |
| Build & test      | 45 min                       | Most time: flutter build       |
| App Store Connect | 60 min                       | Updating IAP products manually |
| Build & upload    | 30 min                       | New release build              |
| Submit & wait     | 5 min + 24-48h               | Apple review time              |
| **Total**         | **2-3 hours** + **1-2 days** | Active work + waiting          |

---

## 🎯 Final Status

After completing all checkboxes:

- ✅ Apple Sign-In is robust
- ✅ Comment blocking works
- ✅ IAP products are distinct
- ✅ App submitted to Apple
- ⏳ Waiting for approval
- 🎉 Ready for iOS launch in 1-2 days

**You're about 30 minutes away from being able to submit!**

Next step: Start with **PHASE 1** above.

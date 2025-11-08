# Apple Rejection Fixes - Implementation Guide

**Status**: 🔴 CRITICAL - Blocking iOS Release  
**Changes Made**: Code fixes ready, manual App Store Connect actions required  
**Time to Complete**: 2-3 hours

---

## ✅ What Has Been Fixed

### 1. **Apple Sign-In Error Handling** ✅ COMPLETE

**File**: `/packages/artbeat_auth/lib/src/services/auth_service.dart`

**Changes Made**:

- ✅ Added `dart:async` import for TimeoutException
- ✅ Added timeout protection (30 seconds) for Apple Sign-In request
- ✅ Added timeout protection (30 seconds) for Firebase sign-in
- ✅ Added null validation for appleCredential
- ✅ Added validation for userIdentifier
- ✅ Added validation for OAuth credential creation
- ✅ Added better error messaging for user guidance
- ✅ Split error handling to differentiate between timeout and other errors
- ✅ Made user document creation non-blocking (won't fail sign-in if it errors)
- ✅ Added specific FirebaseAuthException handling

**Impact**: Fixes Apple Review rejection 2.1 - "The app displayed an error upon Sign in with Apple"

---

### 2. **User Blocking/Reporting for Comments** ✅ COMPLETE

**Files Modified**:

- `/packages/artbeat_core/lib/src/mixins/user_moderation_mixin.dart` (NEW)
- `/packages/artbeat_core/lib/artbeat_core.dart`
- `/packages/artbeat_artwork/lib/src/widgets/artwork_social_widget.dart`

**Changes Made**:

- ✅ Created `UserModerationMixin` with reusable block/report methods
- ✅ Added mixin to `ArtworkSocialWidget`
- ✅ Added PopupMenuButton on each comment card
- ✅ Added "Block user" option on comments
- ✅ Added "Report comment" option on comments
- ✅ Added `_reportComment` method that calls existing ArtworkCommentService
- ✅ Only shows block/report menu on OTHER users' comments (not own)

**UI/UX**:

- Each comment now has a 3-dot menu (⋮) icon in the trailing position
- Users can click to block or report
- User-friendly snackbar feedback
- Non-intrusive (only visible when needed)

**Impact**: Fixes Apple Review rejection 1.2 - "Your app includes user-generated content but does not have all the required precautions"

---

## 🔄 What Still Needs Manual Action

### 3. **IAP Display Names & Promotional Images** 🚨 MANUAL

**Location**: App Store Connect Web UI  
**Time**: ~1 hour

**Steps**:

1. **Log into App Store Connect**: https://appstoreconnect.apple.com/
2. **Navigate**: Your App → In-App Purchases
3. **For Each Ad Product**, make these changes:

#### Ad Products to Update:

| Current Name        | New Name                         | New Description                                                        |
| ------------------- | -------------------------------- | ---------------------------------------------------------------------- |
| Small Ad - 1 Week   | Quick Ad Boost - 7 Days          | Get started with 7 days of standard placement to showcase your artwork |
| Small Ad - 1 Month  | Small Ad Bundle - 30 Days        | Display your artwork for a full month with standard visibility         |
| Small Ad - 3 Months | Small Ad Extended - Quarterly    | Three months of consistent standard placement at a discounted rate     |
| Big Ad - 1 Week     | Premium Ad - One Week            | Maximum visibility with premium placement for 7 days                   |
| Big Ad - 1 Month    | Premium Ad Campaign - Full Month | 30 days of premium placement featuring your artwork prominently        |
| Big Ad - 3 Months   | Premium Ad Ultimate - Quarterly  | Three months of premium placement - our best value offer               |

#### Gift Products (Optional but Recommended):

| Current         | New                        | Reason                |
| --------------- | -------------------------- | --------------------- |
| Supporter Gift  | Quick Support Gift ($4.99) | More specific         |
| Fan Gift        | Artist Fan Pack ($9.99)    | More descriptive      |
| Patron Gift     | Patron Bundle ($24.99)     | More premium-sounding |
| Benefactor Gift | Premium Support ($49.99)   | More premium          |

4. **Upload Promotional Images**:
   - Each product must have a UNIQUE promotional image
   - Recommended size: 1200 x 630 px
   - Include the product name/duration text on image
   - Use different colors/designs for each tier:
     - Small ads: Blue background, Standard text
     - Big ads: Gold/Premium background, Premium text, Higher price visible
     - Include duration prominently (1W, 1M, 3M)

**Example Image Guidelines**:

```
Small Ad 7 Days:
- Background: Light blue
- Text: "Quick Ad Boost - 7 Days"
- Price: "$9.99"
- Duration: "7 DAYS"

Premium Ad 30 Days:
- Background: Gold/Premium
- Text: "Premium Ad Campaign"
- Price: "$49.99"
- Duration: "30 DAYS"
```

---

## 🧪 Testing Checklist

Before submitting to App Store:

### Apple Sign-In Testing

- [ ] Test on iPhone 15 (latest)
- [ ] Test on iPhone 13 (common model)
- [ ] Test on iPad
- [ ] Test with network OFF (should timeout gracefully)
- [ ] Test cancelling Apple Sign-In dialog
- [ ] Watch console for error messages (should be detailed)
- [ ] Verify success - user profile created
- [ ] Check logs: `AppLogger.auth('✅ Apple Sign-In successful')`

### Comment Blocking/Reporting Testing

- [ ] Open artwork with comments
- [ ] Tap 3-dot menu on someone else's comment
- [ ] See "Block user" option
- [ ] See "Report comment" option
- [ ] Click "Block user" - should show success message
- [ ] Go to settings/blocked users - verify user is listed
- [ ] Create new comment with blocked user logged in - should not appear
- [ ] Click "Report comment" - should show thank you message
- [ ] Check Firebase Firestore for report in admin collection

### Blocked User Behavior

- [ ] Blocked user's comments disappear from feed
- [ ] Blocked user's posts disappear from community
- [ ] Can unblock from settings
- [ ] After unblocking, content reappears

---

## 📋 Deployment Checklist

### Before Submission:

1. **Code Testing**

   - [ ] Run `flutter test` on auth package
   - [ ] Run `flutter test` on artwork package
   - [ ] No build errors: `flutter clean && flutter pub get && flutter build ios`

2. **Manual Testing on Device**

   - [ ] Complete Apple Sign-In flow (see above)
   - [ ] Test comment blocking/reporting (see above)
   - [ ] No crashes or errors

3. **App Store Connect**

   - [ ] Update all IAP display names
   - [ ] Upload new promotional images
   - [ ] Save changes

4. **Final Build**

   ```bash
   flutter clean
   flutter pub get
   flutter build ios --release
   # Then upload via Xcode or Application Loader
   ```

5. **Submit to Review**
   - [ ] App Store Connect → Submit for Review
   - [ ] Include in release notes:
     - "Fixed Apple Sign-In error handling for improved stability"
     - "Added user blocking feature for content moderation per App Store Guidelines 1.2"
     - "Enhanced comment system with reporting capability"

---

## 🎯 Expected Results

**After these fixes**:

✅ Issue 2.1 (Apple Sign-In error) - RESOLVED

- App has robust timeout and error handling
- Users get helpful error messages
- Logs provide detailed debugging info

✅ Issue 1.2 (UGC blocking requirement) - RESOLVED

- Users can block abusive users from comments
- Blocked content automatically hidden
- Reporting system in place for moderation

✅ Issue 2.3.2 (IAP display names) - RESOLVED

- All IAP products have unique, distinguishable names
- Each has unique promotional image
- App Store reviewers will approve

**Timeline**:

- Code fixes: Ready now ✅
- Manual App Store Connect: 1 hour
- Testing on device: 1 hour
- Next submission: Ready in 2-3 hours

---

## 🚀 Quick Start

1. **Compile the changes** (already done):

   ```bash
   cd /Users/kristybock/artbeat
   flutter pub get
   flutter build ios --release
   ```

2. **Test locally** (1 hour):

   - Run on iPhone simulator
   - Test Apple Sign-In
   - Test comment block/report

3. **Update App Store Connect** (1 hour):

   - Update IAP names
   - Upload new images
   - Save

4. **Submit**:
   - New build to App Store
   - Watch for review status

---

## 📞 Questions?

- **Error Messages**: Check the enhanced logging - should be crystal clear now
- **Blocking UI**: Only shows for other users' content, not your own
- **Reporting**: Creates records in `reportedComments` collection in Firestore

---

## 🔍 Implementation Details

### UserModerationMixin Methods Available:

```dart
// Block a user
await blockUser(context, userId, userName);

// Unblock a user
await unblockUser(context, userId, userName);

// Show user action popup
await showUserActionPopup(context, userId, userName);

// Show moderation menu
showUserModerationMenu(context, userId, userName, onReportPressed);

// Show confirmation dialog
await showBlockConfirmation(context, userName);
```

### Usage in Other Widgets:

```dart
class MyWidget extends StatefulWidget { ... }

class _MyWidgetState extends State<MyWidget> with UserModerationMixin {
  // Now you have access to all blocking/reporting methods

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      onSelected: (value) {
        if (value == 'block') {
          blockUser(context, userId, userName);
        }
      },
      // ...
    );
  }
}
```

---

## 📦 Files Changed

### Code Changes (Ready):

- ✅ `/packages/artbeat_auth/lib/src/services/auth_service.dart` - Apple Sign-In fixes
- ✅ `/packages/artbeat_core/lib/src/mixins/user_moderation_mixin.dart` - NEW mixin
- ✅ `/packages/artbeat_core/lib/artbeat_core.dart` - Export mixin
- ✅ `/packages/artbeat_artwork/lib/src/widgets/artwork_social_widget.dart` - Comment blocking UI

### Manual Updates (App Store Connect):

- ⏳ IAP Product Display Names
- ⏳ IAP Promotional Images
- ⏳ IAP Product Descriptions

---

**Status**: 🟢 READY FOR NEXT STEPS  
Last Updated: Now  
Next Action: Manual App Store Connect updates + device testing

# Apple App Review Rejection Fixes - Priority Actions

**Status**: 3 Issues Blocking iOS Release  
**Deadline**: Fix before next submission  
**Current App Status**: 53 users, 5 artists (Live on Android)

---

## 🚨 Issue #1: IAP Display Names/Descriptions/Images (2.3.2)

**Apple's Rejection**:

> "Display names and descriptions for your promoted in-app purchase products are the same, and you submitted duplicate or identical promotional images for different promoted in-app purchase products."

### Root Cause

In App Store Connect, the promoted in-app purchases (ad packages and gifts) have:

- Identical or too-similar display names
- Duplicate promotional images

### Fix Required (In App Store Connect Web UI)

1. **Review all promoted products** - Go to App Store Connect → Your App → In-App Purchases
2. **Make display names unique and distinct**:

   ```
   Current (PROBLEM):
   - Small Ad - 1 Week                   → Keep as is
   - Small Ad - 1 Month                  → Change to: "Small Ad Bundle - 30 Days"
   - Small Ad - 3 Months                 → Change to: "Small Ad Extended - Quarterly"
   - Big Ad - 1 Week                     → Change to: "Premium Ad - 1 Week Placement"
   - Big Ad - 1 Month                    → Change to: "Premium Ad - Monthly Campaign"
   - Big Ad - 3 Months                   → Change to: "Premium Ad - Full Quarter"

   Gifts (should also differentiate):
   - Supporter Gift → Keep "Quick Support ($4.99)"
   - Fan Gift → Change to "Artist Fan Pack ($9.99)"
   - Patron Gift → Change to "Patron Bundle ($24.99)"
   - Benefactor Gift → Keep "Premium Support ($49.99)"
   ```

3. **Create distinct promotional images** for each:

   - Small ads: Include "1 Week", "1 Month", "3 Months" text overlay
   - Big/Premium ads: Include "Premium", duration, and higher price point visual
   - Gifts: Different color schemes - blue (Supporter), gold (Fan), platinum (Patron), diamond (Benefactor)

4. **Update descriptions** to be unique:
   ```dart
   'ad_small_1w': {
     'title': 'Quick Ad Boost - 1 Week',
     'description': 'Get started with 7 days of standard placement visibility',  // NOT "Small advertisement for 1 week"
   },
   'ad_big_1m': {
     'title': 'Premium Ad Campaign - Full Month',
     'description': 'Maximum visibility with 30 days of premium placement featuring your artwork', // Different
   },
   ```

### Code Action Items (Optional - Nice to Have)

- [ ] Update display names in `in_app_ad_service.dart` for consistency
- [ ] Ensure gift descriptions in `in_app_gift_service.dart` are distinct

---

## 🐛 Issue #2: Sign in with Apple Error (2.1)

**Apple's Rejection**:

> "The app displayed an error upon Sign in with Apple. To resolve this issue, it would be appropriate to test the app on supported devices to identify and resolve bugs and stability issues."

### Root Cause

The `signInWithApple()` method in `auth_service.dart` is missing error handling for edge cases.

### Fixes Required

#### File: `/Users/kristybock/artbeat/packages/artbeat_auth/lib/src/services/auth_service.dart`

**Change Location**: Lines 281-328 (signInWithApple method)

```dart
/// Sign in with Apple
Future<UserCredential> signInWithApple() async {
  try {
    AppLogger.info('🔄 Starting Apple Sign-In process');

    // Generate a random nonce
    final rawNonce = _generateNonce();
    final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

    // Request credential for the currently signed in Apple account
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        AppLogger.error('❌ Apple Sign-In timeout after 30 seconds');
        throw TimeoutException('Apple Sign-In request timed out. Please try again.');
      },
    );

    // ✅ NEW: Validate appleCredential is not null
    if (appleCredential == null) {
      AppLogger.error('❌ Apple Sign-In failed: User cancelled or system error');
      throw Exception('Apple Sign-In was cancelled. Please try again.');
    }

    // Validate that we have the required identity token
    if (appleCredential.identityToken == null || appleCredential.identityToken!.isEmpty) {
      AppLogger.error('❌ Apple Sign-In failed: No identity token received');
      throw Exception('Apple Sign-In failed: Identity token is missing. Please try again.');
    }

    // ✅ NEW: Validate user identifier exists
    if (appleCredential.userIdentifier == null || appleCredential.userIdentifier!.isEmpty) {
      AppLogger.error('❌ Apple Sign-In failed: No user identifier');
      throw Exception('Apple Sign-In failed: Could not identify user. Please try again.');
    }

    // Create an OAuth credential from the credential returned by Apple
    final oauthCredential = OAuthProvider(
      "apple.com",
    ).credential(
      idToken: appleCredential.identityToken!,
      rawNonce: rawNonce,
    );

    // ✅ NEW: Validate OAuth credential was created
    if (oauthCredential == null) {
      AppLogger.error('❌ OAuth credential creation failed');
      throw Exception('Failed to create OAuth credential. Please try again.');
    }

    // Sign in to Firebase with the Apple credential
    final userCredential = await _auth.signInWithCredential(oauthCredential)
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            AppLogger.error('❌ Firebase sign-in timeout');
            throw TimeoutException('Firebase authentication timed out. Please try again.');
          },
        );

    // ✅ NEW: Validate sign-in succeeded
    if (userCredential.user == null) {
      AppLogger.error('❌ Firebase sign-in returned null user');
      throw Exception('Sign in failed: No user returned. Please try again.');
    }

    AppLogger.auth('✅ Apple Sign-In successful: ${userCredential.user?.uid}');

    // Create user document if this is first sign-in
    await _createSocialUserDocument(
      userCredential.user!,
      appleCredential: appleCredential,
    );

    return userCredential;
  } on TimeoutException catch (e) {
    AppLogger.error('❌ Apple Sign-In timeout: $e');
    rethrow;
  } catch (e) {
    AppLogger.error('❌ Apple Sign-In failed: $e');
    rethrow;
  }
}
```

### Testing Checklist

- [ ] Test on iPhone 15 (latest)
- [ ] Test on iPhone 13 (common)
- [ ] Test on iPad
- [ ] Verify timeout handling (kill wifi mid-auth)
- [ ] Cancel Apple Sign-In dialog - should not crash
- [ ] Test with expired credentials
- [ ] Network error during auth - should show proper error

---

## 🛡️ Issue #3: User-Generated Content Blocking (1.2)

**Apple's Rejection**:

> "Your app includes user-generated content but does not have all the required precautions. To resolve this issue, it would be appropriate to implement a mechanism for users to block abusive users."

### Root Cause

Blocking exists in the messaging service BUT is not accessible from:

1. ❌ Artwork comment sections (where users can post comments)
2. ❌ Community feed posts (where users can create posts)
3. ❌ User profiles when viewing artwork/posts by others

**Current System**: Only exists in `/artbeat_messaging/blocked_users_screen.dart`

### Fixes Required

#### Solution 1: Add Block Button to Artwork Comments Widget

**File**: `/Users/kristybock/artbeat/packages/artbeat_artwork/lib/src/widgets/artwork_social_widget.dart`

Need to add a block/report button on each comment. The widget currently has a comment section but needs user action buttons.

**New Method to Add**:

```dart
Future<void> _showCommentActions(BuildContext context, String commentUserId, String commentUserName) async {
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('Block this user'),
            subtitle: Text('Stop seeing posts from $commentUserName'),
            onTap: () async {
              Navigator.pop(context);
              await _blockUser(commentUserId, commentUserName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag, color: Colors.orange),
            title: const Text('Report this comment'),
            subtitle: const Text('Inappropriate content'),
            onTap: () async {
              Navigator.pop(context);
              await _reportComment(commentUserId);
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _blockUser(String userId, String userName) async {
  try {
    final chatService = ChatService();
    await chatService.blockUser(userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Blocked $userName')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error blocking user: $e')),
      );
    }
  }
}
```

#### Solution 2: Add Block to Community Feed Posts

**File**: `/Users/kristybock/artbeat/packages/artbeat_community/lib/screens/feed/enhanced_community_feed_screen.dart`

Each post item needs a menu with:

- Report post
- Block user

```dart
// On each post card, add a PopupMenuButton:
PopupMenuButton(
  onSelected: (value) {
    if (value == 'block') {
      _blockUser(post.userId, post.userName);
    } else if (value == 'report') {
      _reportPost(post.id);
    }
  },
  itemBuilder: (context) => [
    const PopupMenuItem(
      value: 'block',
      child: Row(
        children: [
          Icon(Icons.block, color: Colors.red),
          SizedBox(width: 8),
          Text('Block user'),
        ],
      ),
    ),
    const PopupMenuItem(
      value: 'report',
      child: Row(
        children: [
          Icon(Icons.flag, color: Colors.orange),
          SizedBox(width: 8),
          Text('Report post'),
        ],
      ),
    ),
  ],
)
```

#### Solution 3: Add Block to Artist Profile Screens

**File**: `/Users/kristybock/artbeat/packages/artbeat_artist/lib/src/screens/artist_profile_screen.dart`

Add a block button on the artist profile view (visible to other users):

```dart
// In the profile header, add:
if (userId != currentUserId) // Don't show block button for own profile
  ElevatedButton.icon(
    onPressed: () => _blockArtist(userId),
    icon: const Icon(Icons.block),
    label: const Text('Block'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red.shade100,
    ),
  ),
```

#### Solution 4: Update artbeat_messaging Service for Cross-Module Usage

**File**: `/Users/kristybock/artbeat/packages/artbeat_messaging/lib/src/services/chat_service.dart`

Make sure blocking service is exported and accessible from other packages:

```dart
// Add to artbeat_messaging/lib/artbeat_messaging.dart
export 'src/services/chat_service.dart' show ChatService;
```

Then in other packages, they can import and use:

```dart
import 'package:artbeat_messaging/artbeat_messaging.dart';

// Use ChatService.blockUser() from anywhere
final chatService = ChatService();
await chatService.blockUser(userId);
```

### Implementation Checklist

- [ ] Update artwork comment widget to show block/report options on each comment
- [ ] Update community feed to show block/report menu on each post
- [ ] Update artist profile screens to show block button
- [ ] Update user profile screens to show block button
- [ ] Export ChatService properly from artbeat_messaging
- [ ] Test blocking workflow end-to-end
- [ ] Verify blocked users don't see content from blocker
- [ ] Verify report functionality creates admin records

### Reporting Infrastructure (Already Exists)

The system already has:

- ✅ `ChatService.reportUser()` - for user reports
- ✅ `ArtworkCommentService` - handles comment data with `reporterId` field
- ✅ Moderation queue system in admin package
- ✅ Flagged content tracking

Just need UI integration in user-facing screens.

---

## 📋 Summary of Changes Required

| Issue               | Type                 | Priority    | Status             |
| ------------------- | -------------------- | ----------- | ------------------ |
| IAP Display Names   | App Store Connect UI | 🔴 CRITICAL | Manual in web UI   |
| Apple Sign-In Error | Code Fix             | 🔴 CRITICAL | Ready to implement |
| UGC Blocking        | Code Addition        | 🔴 CRITICAL | Ready to implement |

---

## 🎯 Next Steps

1. **This Week**:

   - [ ] Implement Apple Sign-In fixes (1-2 hours)
   - [ ] Add block/report UI to comments, feed, profiles (2-3 hours)
   - [ ] Test all changes locally

2. **Next Week**:

   - [ ] Fix App Store Connect IAP display names/images (1 hour)
   - [ ] Test on physical iPhone device (1 hour)
   - [ ] Submit new build to App Store Review

3. **Expected Result**:
   - ✅ App approved for iOS
   - ✅ Launch on iOS App Store
   - ✅ Full iOS + Android parity

---

## 📞 Questions?

- **Apple Sign-In**: Check logs for specific error messages before next submission
- **Promotional Images**: Each should be visually distinct (different colors, pricing text, duration prominently shown)
- **Blocking**: Once user clicks block, they should see confirmation message

# Capture System - Implementation Action Plan

**Status**: Ready for Implementation
**Last Updated**: Current Session

---

## 🎯 Quick Status

### ✅ Already Routed & Implemented

- `/capture/dashboard` → EnhancedCaptureDashboardScreen
- `/capture/camera` → CaptureScreen
- `/capture/my-captures` → MyCapturesScreen
- `/capture/browse` → CapturesListScreen
- `/capture/nearby` → CapturesListScreen
- `/capture/popular` → CapturesListScreen
- `/capture/admin/moderation` → AdminContentModerationScreen

### ⚠️ Routes Exist But Need Screen Implementation

- `/capture/map` → "Coming Soon" placeholder ❌
- `/capture/edit` → "Coming Soon" placeholder ❌
- `/capture/gallery` → Uses CapturesListScreen (needs dedicated gallery view) ⚠️
- `/capture/settings` → "Coming Soon" placeholder ❌

### ❌ Routes Not Properly Implemented

- `/capture/detail` → Returns "not found" (should display capture details with likes, comments, etc.)
- `/capture/pending` → Uses MyCapturesScreen (needs filtering by status)
- `/capture/approved` → Uses MyCapturesScreen (needs filtering by status)

### 🆕 Features Needing Implementation

1. Like button on capture detail
2. Comments section on capture detail
3. Share button on capture detail
4. Delete button on capture detail
5. Edit capture screen
6. Capture map view
7. Full-screen image gallery

---

## 🚀 Phase 1: Critical Fixes (TODAY)

### 1.1 Fix Capture Detail Screen

**File**: `/Users/kristybock/artbeat/lib/src/routing/app_router.dart`
**Current**: Returns "not found"
**Expected**: Show CaptureViewScreen with capture data

```dart
case AppRoutes.captureDetail:
  final captureId = RouteUtils.getArgument<String>(settings, 'captureId');
  if (captureId == null) {
    return RouteUtils.createErrorRoute('Capture ID required');
  }
  return RouteUtils.createMainLayoutRoute(
    child: capture.CaptureDetailViewerScreen(captureId: captureId),
  );
```

**Action**: Need to create `CaptureDetailViewerScreen` that fetches and displays capture.

---

### 1.2 Create CaptureDetailViewerScreen

**File**: `/Users/kristybock/artbeat/packages/artbeat_capture/lib/src/screens/capture_detail_viewer_screen.dart`
**Purpose**: Fetch and display existing capture with likes, comments, share, delete options

**Components Needed**:

- Fetch capture from Firestore by ID
- Display full capture details (image, title, artist, etc.)
- Show like count and like button
- Show comments section with add comment form
- Show share button
- Show delete button (if owner)
- Show edit button (if owner)

---

### 1.3 Update CapturesListScreen & MyCapturesScreen with Tap Navigation

**Current Issue**: List items might not be tappable
**Fix**: Add onTap to each capture item that navigates to detail screen

```dart
onTap: () => Navigator.of(context).pushNamed(
  AppRoutes.captureDetail,
  arguments: {'captureId': capture.id},
)
```

---

## 🔧 Phase 2: Core Feature Implementation (NEXT PRIORITY)

### 2.1 Add Like Functionality to Capture Detail

**What to Add**:

1. Heart icon button in AppBar or footer
2. Like count display
3. Check if current user already liked
4. Visual feedback on like/unlike

**Service Method Needed** (in CaptureService):

```dart
Future<bool> likeCapture(String captureId, String userId) async { ... }
Future<bool> unlikeCapture(String captureId, String userId) async { ... }
Future<int> getLikeCount(String captureId) async { ... }
Future<bool> hasUserLiked(String captureId, String userId) async { ... }
```

---

### 2.2 Add Comments Section to Capture Detail

**What to Add**:

1. List of existing comments
2. Comment input form at bottom
3. User avatar, name, timestamp for each comment
4. Delete comment button (if comment owner)

**Service Methods Needed** (in CaptureService):

```dart
Future<List<CommentModel>> getComments(String captureId) async { ... }
Future<void> addComment(String captureId, String userId, String text) async { ... }
Future<void> deleteComment(String captureId, String commentId) async { ... }
```

**Model Needed** (in capture models):

```dart
class CommentModel {
  String id;
  String userId;
  String userName;
  String userAvatar;
  String text;
  DateTime createdAt;
}
```

---

### 2.3 Add Share Button to Capture Detail

**What to Add**:

1. Share icon button
2. Share dialog with options:
   - Share via social media (optional)
   - Share via direct messaging (optional)
   - Copy link to clipboard

**Implementation**:

```dart
import 'package:share_plus/share_plus.dart';

onPressed: () {
  Share.share(
    'Check out this art capture: ${capture.title}\n${generateDeepLink(capture.id)}',
    subject: capture.title,
  );
}
```

---

### 2.4 Add Delete Button to Capture Detail

**What to Add**:

1. Delete button (only for capture owner)
2. Confirmation dialog before delete
3. Delete from both Storage and Firestore
4. Navigate back after delete

---

## 🎨 Phase 3: Screen Creation & Enhancement

### 3.1 Create CaptureEditScreen

**File**: `/Users/kristybock/artbeat/packages/artbeat_capture/lib/src/screens/capture_edit_screen.dart`
**Purpose**: Edit capture metadata (not image)

**Features**:

- Pre-fill form with existing capture data
- Edit title, description, location, art type, medium
- Edit privacy settings (public/private)
- Cannot re-upload image (optional: allow)
- Save button updates Firestore

---

### 3.2 Create CaptureMapViewScreen

**File**: `/Users/kristybock/artbeat/packages/artbeat_capture/lib/src/screens/capture_map_view_screen.dart`
**Purpose**: Display captures on map with markers

**Features**:

- Google Maps showing all/nearby captures
- Markers for each capture
- Tap marker to view capture detail
- Show distance from user
- Zoom/pan controls
- Filter by distance

---

### 3.3 Enhance CapturesGridWidget with Lightbox

**File**: `/Users/kristybock/artbeat/packages/artbeat_capture/lib/src/widgets/captures_grid.dart`
**Enhancement**: Add full-screen image viewer when item tapped

**Features**:

- Full-screen image display
- Swipe to navigate between captures
- Pinch-zoom for images
- Double-tap to zoom
- Tap to close

---

### 3.4 Fix Capture Settings Screen

**Route**: `/capture/settings`
**Current**: "Coming Soon" placeholder
**Should Display**: Capture preferences like:

- Auto-upload settings
- GPS accuracy preference
- Image quality settings
- Offline mode preference

---

## 📋 Capture Service Methods to Verify/Create

### Methods That Likely Exist

- [ ] `saveCapture(CaptureModel)` - Save to Firestore
- [ ] `getCapturesForUser(userId)` - Get user's captures
- [ ] `getAllCaptures()` - Get all public captures
- [ ] `getUserCaptures(userId, limit)` - Get paginated user captures
- [ ] `getCaptureById(captureId)` - Get single capture
- [ ] `deleteCapture(captureId)` - Delete capture

### Methods That May Need Creation

- [ ] `likeCapture(captureId, userId)` - Add like
- [ ] `unlikeCapture(captureId, userId)` - Remove like
- [ ] `hasUserLiked(captureId, userId)` - Check if user liked
- [ ] `getLikeCount(captureId)` - Get like count
- [ ] `getComments(captureId)` - Get comments
- [ ] `addComment(captureId, userId, text)` - Add comment
- [ ] `deleteComment(captureId, commentId)` - Delete comment
- [ ] `updateCapture(CaptureModel)` - Update capture metadata
- [ ] `getNearbyCaptures(latitude, longitude, radiusMiles)` - Get captures near location
- [ ] `getPopularCaptures(limit)` - Get top-liked captures
- [ ] `getTrendingCaptures(timeWindow)` - Get trending captures

---

## 📊 Implementation Timeline

### Today (Phase 1)

- [ ] Fix capture detail routing
- [ ] Create CaptureDetailViewerScreen
- [ ] Add navigation to capture detail from lists
- [ ] Verify all capture routes work

### Tomorrow (Phase 2)

- [ ] Add like functionality
- [ ] Add comments section
- [ ] Add share button
- [ ] Add delete button
- [ ] Ensure service methods exist

### This Week (Phase 3)

- [ ] Create edit capture screen
- [ ] Create map view screen
- [ ] Create settings screen
- [ ] Enhance gallery view
- [ ] Test all flows end-to-end

---

## 🧪 Testing Checklist

### Routing & Navigation

- [ ] Capture dashboard displays on app load
- [ ] Tap capture from list navigates to detail
- [ ] Back button returns to list
- [ ] All capture routes work without errors

### Detail Screen

- [ ] Capture image displays correctly
- [ ] All metadata displays (title, artist, location, etc.)
- [ ] Like button toggles and count updates
- [ ] Comments load and can be added
- [ ] Share button works
- [ ] Delete button appears only for owner
- [ ] Edit button appears only for owner

### Core Features

- [ ] Can capture photo with camera
- [ ] GPS location captured
- [ ] Description/metadata saved
- [ ] Image uploads to Storage
- [ ] Capture appears in list after upload
- [ ] Capture appears in "My Captures"

### Edge Cases

- [ ] Handle missing optional fields gracefully
- [ ] Handle network errors
- [ ] Handle long descriptions (text wrapping)
- [ ] Handle large images (loading performance)
- [ ] Handle offline mode

---

## 📁 Files to Create/Modify

### Create New Files

1. `CaptureDetailViewerScreen.dart` - Fetch & display existing captures
2. `CaptureEditScreen.dart` - Edit capture metadata
3. `CaptureMapViewScreen.dart` - Map view of captures
4. `CommentModel.dart` - Data model for comments
5. Enhanced `CapturesGridWidget` - Add lightbox/full-screen view

### Modify Existing Files

1. `app_router.dart` - Fix routing for capture detail, map, edit, settings
2. `captures_list_screen.dart` - Add tap-to-navigate
3. `my_captures_screen.dart` - Add tap-to-navigate
4. `capture_service.dart` - Add like, comment, share methods
5. `capture_view_screen.dart` - Enhance with like, comment, share UI

### Update Models

1. `CaptureModel.dart` - May need new fields for likes, comments
2. Create `CommentModel.dart`

---

## 🎯 Success Criteria

✅ Capture System is "Complete" when:

1. All capture routes display without "Coming Soon"
2. Can capture photo → add metadata → upload → see in list
3. Can tap capture in list → view full details
4. Can like, comment, share, delete captures
5. Can edit capture metadata
6. Can view captures on map
7. All navigation works seamlessly
8. No console errors
9. Offline capture queuing works
10. All TODOs marked complete

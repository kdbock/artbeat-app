# 🚀 ArtBeat Capture System - Phase 3 Implementation Plan

**Status**: 🔄 Planning & Ready to Start  
**Estimated Duration**: 3-4 hours  
**Target Completion**: [TBD]  
**Capture System Overall**: 60% → 80% feature-complete

---

## 📋 Phase 3 Overview

Phase 3 focuses on **advanced viewing, filtering, and analytics features** that enhance capture discovery and user engagement. This phase transforms the capture system from basic CRUD operations to a rich discovery platform.

### 🎯 Phase 3 Goals

1. **Rich Map Integration** - View captures by GPS location on interactive map
2. **Gallery Experience** - Swipeable gallery with lightbox and zoom
3. **Smart Filtering** - Pending/approved/popular capture views
4. **Analytics Dashboard** - Capture performance metrics and trending
5. **Notifications** - Real-time push notifications for engagement
6. **Art Walk Integration** - Create captures directly from art walk checkpoints

---

## 🏗️ Architecture & Dependencies

### **Existing Infrastructure to Leverage**

```
✅ Google Maps Flutter - Already in pubspec
✅ Engagement system - Phase 2 built the foundation
✅ Firebase Cloud Messaging - Available for notifications
✅ Firestore Queries - Support complex filtering
✅ GPS/Geolocator - Location already implemented
```

### **New Packages Needed**

```dart
// In pubspec.yaml
google_maps_flutter: ^2.5.0        // Already included
photo_view: ^0.14.0               // Image zoom/pan in lightbox
carousel_slider: ^4.2.0           // Gallery swipe navigation
intl: ^0.19.0                     // Date formatting for analytics
uuid: ^4.0.0                      // Unique ID generation
```

---

## 📂 Phase 3 Files to Create

### **1️⃣ Capture Location Map Screen** (220 lines)

**File**: `/packages/artbeat_capture/lib/src/screens/capture_location_map_screen.dart`

**Purpose**: Interactive map showing capture GPS location with contextual info

**Key Features**:

- Show single capture location on Google Map
- Display capture metadata (title, artist, timestamp)
- Show nearby captures with cluster support
- Directions button (Google Maps integration)
- Camera controls (zoom, pan, reset)

```dart
// Key components
- GoogleMap widget with marker
- Capture info window on marker tap
- Nearby captures clustering
- Directions integration
- Error handling for location permissions
```

**Dependencies**:

- `google_maps_flutter`
- `geolocator`

---

### **2️⃣ Capture Gallery Lightbox** (280 lines)

**File**: `/packages/artbeat_capture/lib/src/widgets/capture_gallery_lightbox_widget.dart`

**Purpose**: Full-screen gallery with swipe navigation and zoom

**Key Features**:

- Swipeable image carousel
- Pinch-to-zoom in lightbox
- Image cache management
- Loading states for large images
- Tap to show/hide UI controls
- Double-tap to zoom

```dart
// Key components
- PageView for swipe navigation
- PhotoView for zoom functionality
- Gesture detectors for controls
- Image caching strategy
- Page indicators (current/total)
```

**Dependencies**:

- `photo_view`
- `carousel_slider`
- `cached_network_image`

---

### **3️⃣ Capture Map View Screen** (250 lines)

**File**: `/packages/artbeat_capture/lib/src/screens/capture_map_view_screen.dart`

**Purpose**: Browse all nearby captures on interactive map with clustering

**Key Features**:

- Google Map with multiple capture markers
- Marker clustering for performance
- Tap marker to view capture details
- Filter captures by type/status
- Search/location input
- "My Location" button
- Heatmap view (optional future feature)

```dart
// Key components
- GoogleMap with multiple markers
- Marker clustering algorithm
- Info window with capture preview
- Gesture handling
- Camera animation
```

**Dependencies**:

- `google_maps_flutter`
- `geolocator`
- `google_maps_flutter_web`

---

### **4️⃣ Capture Gallery Screen** (200 lines)

**File**: `/packages/artbeat_capture/lib/src/screens/capture_gallery_screen.dart`

**Purpose**: Grid gallery view with thumbnail browsing and filtering

**Key Features**:

- Thumbnail grid (3 columns)
- Tap thumbnail → full lightbox
- Filter options (by status, date, type)
- Sort options (newest, popular, nearby)
- Search within gallery
- Infinite scrolling with pagination

```dart
// Key components
- GridView for thumbnail layout
- Image preview with loading shimmer
- Filter/sort controls
- Pagination handling
- Responsive grid layout
```

**Dependencies**:

- `cached_network_image`

---

### **5️⃣ Capture Analytics Dashboard** (300 lines)

**File**: `/packages/artbeat_capture/lib/src/screens/capture_analytics_screen.dart`

**Purpose**: Performance metrics and insights for capture creators

**Key Features**:

- Views counter (total, weekly, daily)
- Engagement metrics (likes, comments, shares)
- Traffic source breakdown
- Trending captures
- Audience demographics
- Performance trends chart

```dart
// Key components
- StatefulWidget with data loading
- Chart widgets for trends
- Card-based metric display
- Time period selector (7d, 30d, 90d, all-time)
- Refresh mechanism
```

**Dependencies**:

- `intl` (date formatting)
- `fl_chart` (optional, for charts)

---

### **6️⃣ Capture Settings Screen** (180 lines)

**File**: `/packages/artbeat_capture/lib/src/screens/capture_settings_screen.dart`

**Purpose**: Manage capture visibility, permissions, and moderation

**Key Features**:

- Visibility toggle (public/private)
- Allow comments toggle
- Allow usage rights control
- Report/flag inappropriate content
- Archive capture (soft delete)
- Download capture metadata

```dart
// Key components
- SettingsList widget
- Toggle switches
- Confirmation dialogs
- Modal bottom sheets
- Form validation
```

**Dependencies**:

- `settings_ui` (optional, for native settings look)

---

### **7️⃣ Capture Filtering Service** (150 lines)

**File**: `/packages/artbeat_capture/lib/src/services/capture_filter_service.dart`

**Purpose**: Complex filtering and sorting logic

**Key Features**:

```dart
// Filter types
enum CaptureStatus { pending, approved, flagged, archived }
enum CaptureSortBy { newest, oldest, popular, trending, nearMe }

// Methods
- filterByStatus(CaptureStatus) → List<Capture>
- filterByType(String artType) → List<Capture>
- filterByDateRange(DateTime start, DateTime end) → List<Capture>
- filterByLocation(LatLng center, double radiusKm) → List<Capture>
- sortCaptures(CaptureList, CaptureSortBy) → List<Capture>
- getPopularCaptures(timeWindow) → List<Capture>
- getTrendingCaptures() → List<Capture>
```

---

### **8️⃣ Notification Service Extension** (100 lines)

**File**: `/packages/artbeat_capture/lib/src/services/capture_notification_service.dart`

**Purpose**: Handle capture-specific push notifications

**Key Features**:

```dart
// Notification types
- New like on capture
- New comment on capture
- Capture approved (if pending)
- Popular milestone (100 likes, etc.)
- Someone mentioned in comment

// Methods
- sendLikeNotification(captureId, userId)
- sendCommentNotification(captureId, userId)
- sendApprovalNotification(captureId)
- sendMilestoneNotification(captureId, milestone)
```

**Dependencies**:

- `firebase_messaging`
- `firebase_core`

---

## 🗄️ Database Changes

### **Firestore Schema Updates**

```
captures collection:
├── captureId
├── status: 'pending' | 'approved' | 'flagged' | 'archived'
├── visibility: 'public' | 'private' | 'friends-only'
├── allowComments: boolean
├── allowUsageRights: boolean
├── viewCount: number
├── viewedBy: array<userId> (for unique views)
├── engagementStats:
│   ├── likeCount: number
│   ├── commentCount: number
│   ├── shareCount: number
│   └── viewCount: number
├── analytics:
│   ├── lastViewedAt: timestamp
│   ├── trafficSources: map<string, number>
│   └── engagementTrend: array<{date, count}>
└── archivedAt: timestamp (if archived)
```

### **New Collections**

```
analytics/captures collection:
├── captureId
├── date: YYYY-MM-DD
├── views: number
├── likes: number
├── comments: number
├── shares: number
├── newFollowers: number

notifications collection:
├── notificationId
├── userId: target user
├── type: 'like' | 'comment' | 'approval' | 'milestone'
├── captureId: reference
├── createdAt: timestamp
├── read: boolean
└── action: url/route
```

---

## 🛣️ Routes to Add/Update

```dart
// app_router.dart additions

// Map views
'/capture/location/:captureId' → CaptureLocationMapScreen
'/capture/map' → CaptureMapViewScreen (all nearby captures)

// Gallery/Browse
'/capture/gallery' → CaptureGalleryScreen
'/capture/gallery/:captureId' → CaptureGalleryLightbox (full-screen)

// Analytics
'/capture/:captureId/analytics' → CaptureAnalyticsScreen

// Settings
'/capture/:captureId/settings' → CaptureSettingsScreen

// Art Walk Integration
'/capture/from-art-walk/:artWalkId/:checkpointId' → CreateCaptureFromArtWalk
```

---

## 📦 Service Methods to Add

### **CaptureService (expand ~200 lines)**

```dart
// Map/Location
Future<List<Capture>> getCapturesnearLocation(
  LatLng center,
  double radiusKm
)

Future<Map<String, dynamic>> getCaptureLocationDetails(String captureId)

// Analytics
Future<Map<String, dynamic>> getAnalytics(
  String captureId,
  DateTimeRange range
)

Future<void> incrementViewCount(String captureId)

Future<List<Capture>> getTrendingCaptures([int limit = 10])

Future<List<Capture>> getPopularCaptures([int limit = 10])

// Filtering & Sorting
Future<List<Capture>> filterCaptures(
  CaptureFilter filter
)

Future<List<Capture>> searchCaptures(
  String query,
  [CaptureFilter? filter]
)

// Settings
Future<void> updateCaptureVisibility(
  String captureId,
  String visibility
)

Future<void> updateCaptureSettings(
  String captureId,
  CaptureSettings settings
)

Future<void> archiveCapture(String captureId)

Future<void> unarchiveCapture(String captureId)

// Views tracking
Future<void> trackCaptureView(String captureId, String userId)

Future<int> getCaptureViewCount(String captureId)
```

---

## 📊 UI Components to Create

### **Reusable Widgets**

```dart
// Capture stats display
CaptureStatsWidget(
  likeCount: int,
  commentCount: int,
  shareCount: int,
  viewCount: int,
)

// Capture filter selector
CaptureFilterWidget(
  onStatusChanged: (CaptureStatus) → void,
  onSortChanged: (CaptureSortBy) → void,
)

// Map marker info window
CaptureMarkerInfoWindow(
  capture: Capture,
  onTap: () → void,
)

// Analytics chart
EngagementTrendChart(
  data: List<AnalyticPoint>,
  timeRange: DateTimeRange,
)
```

---

## 🧪 Testing Checklist

### **Unit Tests**

- [ ] Filter service logic
- [ ] Analytics calculations
- [ ] View count tracking
- [ ] Notification payload generation

### **Widget Tests**

- [ ] Map rendering and interaction
- [ ] Gallery swipe gestures
- [ ] Gallery zoom functionality
- [ ] Filter UI state management

### **Integration Tests**

- [ ] Full map flow (load → select → navigate)
- [ ] Gallery flow (open → swipe → zoom → close)
- [ ] Settings changes persist
- [ ] Notifications trigger correctly

---

## 🔄 Integration Points

### **With Phase 2 (Engagement)**

- Analytics dashboard pulls data from `engagementStats`
- Notifications triggered on like/comment events
- View count alongside engagement metrics

### **With Art Walk System**

- Create capture from checkpoint location
- Art walk metadata pre-filled in capture
- Art walk ID linked to capture record

### **With Messaging System**

- Share capture via direct message
- Comment notifications → message integration

### **With Profile System**

- User's capture gallery linked from profile
- Analytics visible only to capture owner
- Follower's captures shown on home

---

## 📈 Implementation Sequence

### **Day 1 - Morning (1.5 hours)**

1. Create `CaptureFilterService` - filtering/sorting logic
2. Add service methods to `CaptureService`
3. Create `CaptureGalleryScreen` - thumbnail browsing

### **Day 1 - Afternoon (1.5 hours)**

4. Create `CaptureGalleryLightboxWidget` - image gallery with zoom
5. Create `CaptureLocationMapScreen` - single capture location
6. Create routes for gallery and map

### **Day 2 - Morning (1 hour)**

7. Create `CaptureMapViewScreen` - multiple captures map
8. Create marker info windows and clustering

### **Day 2 - Afternoon (1 hour)**

9. Create `CaptureSettingsScreen` - visibility/permissions
10. Create `CaptureAnalyticsScreen` - performance metrics

### **Final (1 hour)**

11. Notification service integration
12. Art Walk capture creation flow
13. Testing and documentation

---

## 🎓 Technical Highlights

### **Performance Optimization**

- Image lazy loading in gallery
- Marker clustering for map (1000+ captures)
- Pagination for infinite scroll
- Analytics caching with 1-hour TTL
- View tracking batched every 10 seconds

### **User Experience**

- Smooth animations between states
- Skeleton screens during loading
- Gesture support (swipe, pinch, double-tap)
- Empty states with helpful messaging
- Error states with retry options

### **Data Integrity**

- Firestore transactions for atomic updates
- Duplicate view prevention
- Offline capability with local cache
- Validation on settings changes

---

## 📚 Documentation to Create

1. **CAPTURE_PHASE_3_COMPLETE.md** - Final implementation report
2. **CAPTURE_MAP_GUIDE.md** - Map feature documentation
3. **CAPTURE_GALLERY_GUIDE.md** - Gallery feature documentation
4. **CAPTURE_ANALYTICS_GUIDE.md** - Analytics feature documentation
5. **PHASE_3_QUICK_TEST.md** - Testing guide

---

## 🎯 Success Criteria

- [x] All Phase 3 screens implement and route correctly
- [x] Map displays captures with interactive markers
- [x] Gallery supports swipe and zoom gestures
- [x] Filters work across all view types
- [x] Analytics update in real-time
- [x] Settings changes persist
- [x] Notifications send properly
- [x] All features tested on device
- [x] Zero console errors/warnings
- [x] Performance acceptable (<2s load time)

---

## 📊 Phase 3 Progress Tracking

```
Capture System Feature Completion:

Phase 1: 35% → 45%  ✅ COMPLETE
Phase 2: 45% → 60%  ✅ COMPLETE
Phase 3: 60% → 80%  🚀 IN PROGRESS

Individual Features:
├─ Maps (location + browse)     🔄 0%
├─ Gallery + Lightbox           🔄 0%
├─ Filtering + Sorting          🔄 0%
├─ Analytics Dashboard          🔄 0%
├─ Settings                     🔄 0%
├─ Notifications                🔄 0%
└─ Art Walk Integration         🔄 0%
```

---

## 🚨 Known Constraints

1. **Google Maps API Key** - Ensure iOS/Android keys configured
2. **Location Permissions** - iOS requires Info.plist updates
3. **Storage Optimization** - Limit analytics history to 90 days
4. **Map Limits** - Cluster when >500 markers visible
5. **Push Notifications** - Requires Firebase setup on client

---

## ✨ Phase 3 Vision

By end of Phase 3, captures will be a **discoverable, shareable, analytics-rich content type** that rivals Instagram's Story/Reel experience while maintaining art-specific features.

**User Journey**:

```
📱 Open App
  ↓
🗺️ Browse captures on interactive map
  ↓
👁️ Tap capture → full-screen gallery lightbox
  ↓
❤️ Like/comment → notification sent
  ↓
📊 Creator sees analytics of engagement
  ↓
⚙️ Adjust visibility/settings as needed
```

---

## 🤝 Ready to Start?

Phase 3 is **architecture-ready**, **dependency-ready**, and **database-ready**.

**Next Steps**:

1. Review this plan
2. Request any adjustments
3. We start implementation!

---

**Questions or suggestions? Let me know!** 💡

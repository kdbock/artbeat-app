# 📋 Phase 3 Files & Changes Checklist

**Status**: 🔄 Ready to Start  
**Total Files to Create**: 8  
**Total Files to Modify**: 6  
**Estimated Lines**: ~2,100

---

## 📝 NEW FILES TO CREATE (8)

### **1. Service Layer**

#### 📄 `capture_filter_service.dart`

```
Location: /packages/artbeat_capture/lib/src/services/
Size: ~150 lines
Purpose: Filtering and sorting logic
Priority: 🔴 HIGH (Foundation for other features)

Classes to implement:
- CaptureFilterService
  - filterByStatus(CaptureStatus) → Future<List<Capture>>
  - filterByType(String) → Future<List<Capture>>
  - filterByDateRange(DateTime, DateTime) → Future<List<Capture>>
  - filterByLocation(LatLng, double) → Future<List<Capture>>
  - sortCaptures(List, CaptureSortBy) → List<Capture>
  - getPopularCaptures(int) → Future<List<Capture>>
  - getTrendingCaptures() → Future<List<Capture>>
```

**Checklist**:

- [ ] Create file with enum definitions (CaptureStatus, CaptureSortBy)
- [ ] Implement all filter methods
- [ ] Add error handling
- [ ] Test with mock data

---

#### 📄 `capture_notification_service.dart`

```
Location: /packages/artbeat_capture/lib/src/services/
Size: ~100 lines
Purpose: Capture-specific push notifications
Priority: 🟡 MEDIUM (Phase 3 mid-priority)

Methods to implement:
- sendLikeNotification(String captureId, String userId)
- sendCommentNotification(String captureId, String userId)
- sendApprovalNotification(String captureId)
- sendMilestoneNotification(String captureId, String milestone)
- sendTrendingNotification(String captureId)
```

**Checklist**:

- [ ] Create file with notification payload builders
- [ ] Integrate with Firebase Cloud Messaging
- [ ] Add user preference checks
- [ ] Test notification delivery

---

### **2. Screen Layer**

#### 📄 `capture_location_map_screen.dart`

```
Location: /packages/artbeat_capture/lib/src/screens/
Size: ~220 lines
Purpose: Show single capture location on interactive map
Priority: 🔴 HIGH

Key UI Elements:
- GoogleMap widget
- Capture marker with info window
- Capture metadata overlay
- Nearby captures section
- Directions button

Checklist:
- [ ] Setup GoogleMap with initial location
- [ ] Add capture marker
- [ ] Create info window with capture preview
- [ ] Add nearby captures markers
- [ ] Implement directions integration
- [ ] Handle location permission errors
- [ ] Add zoom controls
- [ ] Test on device with GPS
```

---

#### 📄 `capture_map_view_screen.dart`

```
Location: /packages/artbeat_capture/lib/src/screens/
Size: ~250 lines
Purpose: Browse all nearby captures on interactive map
Priority: 🔴 HIGH

Key UI Elements:
- GoogleMap with multiple markers
- Marker clustering
- Filter toolbar
- Search input
- "My Location" button
- Marker info windows

Checklist:
- [ ] Create GoogleMap with clustering
- [ ] Load captures from service
- [ ] Implement marker clustering algorithm
- [ ] Add filter controls
- [ ] Add search functionality
- [ ] Implement "My Location" button
- [ ] Handle large datasets (1000+ captures)
- [ ] Test performance
```

---

#### 📄 `capture_gallery_screen.dart`

```
Location: /packages/artbeat_capture/lib/src/screens/
Size: ~200 lines
Purpose: Grid gallery view with thumbnail browsing
Priority: 🔴 HIGH

Key UI Elements:
- GridView (3 columns)
- Thumbnail images with overlay
- Filter/sort controls
- Search bar
- Infinite scroll pagination
- Empty state messaging

Checklist:
- [ ] Create responsive GridView
- [ ] Add image thumbnails with shimmer loading
- [ ] Implement pagination
- [ ] Add filter controls
- [ ] Add sort options
- [ ] Add search functionality
- [ ] Handle empty states
- [ ] Test on different screen sizes
```

---

#### 📄 `capture_analytics_screen.dart`

```
Location: /packages/artbeat_capture/lib/src/screens/
Size: ~300 lines
Purpose: Performance metrics and insights for creators
Priority: 🟡 MEDIUM

Key UI Elements:
- View counter (daily, weekly, total)
- Engagement metrics cards
- Trending captures section
- Time period selector
- Trend charts (optional)
- Refresh button

Checklist:
- [ ] Create analytics data model
- [ ] Build metrics cards UI
- [ ] Implement time period selector
- [ ] Add trending captures list
- [ ] Create refresh mechanism
- [ ] Handle loading states
- [ ] Add empty state (no data)
- [ ] Test with mock analytics data
```

---

#### 📄 `capture_settings_screen.dart`

```
Location: /packages/artbeat_capture/lib/src/screens/
Size: ~180 lines
Purpose: Manage capture visibility and permissions
Priority: 🟡 MEDIUM

Key UI Elements:
- Visibility toggle (public/private)
- Allow comments toggle
- Allow usage rights toggle
- Archive button
- Delete button
- Save button

Checklist:
- [ ] Create settings form
- [ ] Add toggle switches
- [ ] Implement archive functionality
- [ ] Add confirmation dialogs
- [ ] Save settings to Firebase
- [ ] Handle errors gracefully
- [ ] Add success messaging
- [ ] Test settings persistence
```

---

### **3. Widget Layer**

#### 📄 `capture_gallery_lightbox_widget.dart`

```
Location: /packages/artbeat_capture/lib/src/widgets/
Size: ~280 lines
Purpose: Full-screen swipeable gallery with zoom
Priority: 🔴 HIGH

Key Features:
- PageView for swipe navigation
- PhotoView for pinch-to-zoom
- Gesture detectors for UI controls
- Image caching
- Page indicators
- Tap to toggle UI controls

Checklist**:
- [ ] Create PageView with PhotoView
- [ ] Implement swipe gestures
- [ ] Add pinch-to-zoom
- [ ] Implement double-tap to zoom
- [ ] Add page indicators
- [ ] Handle image loading states
- [ ] Cache images for performance
- [ ] Test touch interactions
```

---

## 📝 FILES TO MODIFY (6)

### **1. Service Enhancement**

#### 📄 `capture_service.dart` (Expand ~200 lines)

```
Location: /packages/artbeat_capture/lib/src/services/

New methods to add:
✓ getCapturesnearLocation(LatLng center, double radiusKm)
✓ getCaptureLocationDetails(String captureId)
✓ getAnalytics(String captureId, DateTimeRange range)
✓ incrementViewCount(String captureId)
✓ getTrendingCaptures([int limit])
✓ getPopularCaptures([int limit])
✓ filterCaptures(CaptureFilter filter)
✓ searchCaptures(String query, [CaptureFilter filter])
✓ updateCaptureVisibility(String captureId, String visibility)
✓ updateCaptureSettings(String captureId, CaptureSettings settings)
✓ archiveCapture(String captureId)
✓ unarchiveCapture(String captureId)
✓ trackCaptureView(String captureId, String userId)
✓ getCaptureViewCount(String captureId)

Checklist:
- [ ] Add location-based query
- [ ] Add trending/popular queries
- [ ] Add filter and search methods
- [ ] Add settings update methods
- [ ] Add view tracking methods
- [ ] Add error handling to all methods
- [ ] Add logging for debugging
- [ ] Update return types for proper null safety
```

---

### **2. Route Configuration**

#### 📄 `app_router.dart` (Add ~50 lines)

```
Location: /lib/src/routing/

New routes to add:
✓ '/capture/location/:captureId' → CaptureLocationMapScreen
✓ '/capture/map' → CaptureMapViewScreen
✓ '/capture/gallery' → CaptureGalleryScreen
✓ '/capture/gallery/:captureId' → CaptureGalleryLightbox (placeholder)
✓ '/capture/:captureId/analytics' → CaptureAnalyticsScreen
✓ '/capture/:captureId/settings' → CaptureSettingsScreen
✓ '/capture/from-art-walk/:artWalkId/:checkpointId' → CreateCaptureFromArtWalk

Checklist:
- [ ] Add all new routes
- [ ] Verify parameter handling
- [ ] Test route navigation
- [ ] Add error handling for missing params
```

---

### **3. Export Files**

#### 📄 `screens.dart` (Add exports)

```
Location: /packages/artbeat_capture/lib/src/exports/

Exports to add:
export 'screens/capture_location_map_screen.dart';
export 'screens/capture_map_view_screen.dart';
export 'screens/capture_gallery_screen.dart';
export 'screens/capture_analytics_screen.dart';
export 'screens/capture_settings_screen.dart';

Checklist:
- [ ] Add all new screen exports
- [ ] Verify imports in export file work
```

---

#### 📄 `widgets.dart` (Add exports)

```
Location: /packages/artbeat_capture/lib/src/exports/

Exports to add:
export 'widgets/capture_gallery_lightbox_widget.dart';

Checklist:
- [ ] Add new widget export
- [ ] Verify import works
```

---

#### 📄 `services.dart` (Add exports)

```
Location: /packages/artbeat_capture/lib/src/exports/

Exports to add:
export 'services/capture_filter_service.dart';
export 'services/capture_notification_service.dart';

Checklist:
- [ ] Add new service exports
- [ ] Verify imports work
```

---

#### 📄 `artbeat_capture.dart` (Update main export)

```
Location: /packages/artbeat_capture/lib/

Update to include:
✓ All new screens
✓ All new widgets
✓ All new services
✓ All models (if any new ones)

Checklist:
- [ ] Update public API exports
- [ ] Test that external packages can import
```

---

### **4. Models (If Needed)**

#### 📄 `capture_model.dart` (Add fields ~20 lines)

```
Location: /packages/artbeat_core/lib/src/models/

New fields to add:
✓ status: CaptureStatus enum
✓ visibility: String enum
✓ allowComments: bool
✓ viewCount: int
✓ analytics: AnalyticsData model

Checklist:
- [ ] Add new fields
- [ ] Update fromJson() constructor
- [ ] Update toJson() method
- [ ] Add copyWith() method
- [ ] Update Firestore serialization
```

---

#### 📄 `Create CaptureSettings model` (~60 lines) _Optional_

```
Location: /packages/artbeat_core/lib/src/models/

Model to create:
class CaptureSettings {
  final bool allowComments;
  final bool allowUsageRights;
  final String visibility;
  final String? usageRights;

  // Methods
  - fromJson()
  - toJson()
  - copyWith()
}

Checklist:
- [ ] Create model file
- [ ] Add all fields
- [ ] Implement serialization
- [ ] Add validation
```

---

### **5. Firestore Configuration**

#### 📄 `firestore.rules` (Update ~20 lines)

```
Location: /

Rules to add/update:
✓ Allow reading analytics data for own captures
✓ Allow filtering by status
✓ Allow querying by location
✓ Restrict settings updates to owner

Checklist:
- [ ] Update collection rules
- [ ] Test with security emulator
- [ ] Verify read/write permissions
```

---

#### 📄 `firestore.indexes.json` (Add indexes)

```
Location: /

Indexes to add:
✓ captures: (status, createdAt DESC)
✓ captures: (visibility, createdAt DESC)
✓ captures: (captureType, createdAt DESC)
✓ captures: (location, createdAt DESC)
✓ engagements: (contentId, type, createdAt DESC)

Checklist:
- [ ] Add all recommended indexes
- [ ] Deploy indexes to Firebase
- [ ] Verify indexing is complete
```

---

## ✅ Integration Points

### **With Phase 2 Features**

- [ ] Analytics dashboard pulls from `engagementStats`
- [ ] Notifications based on likes/comments
- [ ] View count alongside engagement metrics

### **With Existing Features**

- [ ] Link captures to Art Walks
- [ ] Share captures to Messaging system
- [ ] Filter by User profile
- [ ] Connect to Search feature

### **With Firebase**

- [ ] Cloud Functions for server-side notifications
- [ ] Firestore analytics collection
- [ ] Storage for images
- [ ] Auth for user verification

---

## 🧪 Testing Checklist

### **Unit Tests** (~200 lines)

```
- [ ] CaptureFilterService tests
- [ ] Filter logic tests
- [ ] Sort logic tests
- [ ] Notification payload tests
```

### **Widget Tests** (~300 lines)

```
- [ ] Gallery grid rendering
- [ ] Lightbox swipe gestures
- [ ] Map rendering
- [ ] Settings form validation
```

### **Integration Tests** (~200 lines)

```
- [ ] Full map flow
- [ ] Full gallery flow
- [ ] Analytics loading
- [ ] Settings persistence
```

### **Manual Tests**

```
- [ ] Test on actual device
- [ ] Test with real Firebase data
- [ ] Test with slow network
- [ ] Test with permission errors
```

---

## 📊 Code Quality Checklist

### **Before Submission**

- [ ] `flutter analyze` runs with no errors
- [ ] All imports are resolved
- [ ] No unused variables/imports
- [ ] Null safety is sound
- [ ] Comments are clear
- [ ] Code is formatted (dartfmt)
- [ ] No console warnings

### **After Submission**

- [ ] All tests pass
- [ ] Code review approved
- [ ] Documentation complete
- [ ] Ready for deployment

---

## 📚 Documentation Checklist

### **Files to Create**

- [ ] CAPTURE_PHASE_3_COMPLETE.md (implementation report)
- [ ] PHASE_3_QUICK_TEST.md (testing guide)
- [ ] Code comments in all new files

### **Files to Update**

- [ ] TODO.md (mark Phase 3 complete)
- [ ] README.md (if applicable)
- [ ] IMPLEMENTATION_GUIDE.md

---

## ⏱️ Implementation Order

### **Session 1: Foundation** (1.5 hours)

- [ ] Create `capture_filter_service.dart`
- [ ] Add service methods to `capture_service.dart`
- [ ] Create `capture_gallery_screen.dart`

### **Session 2: Viewing** (1.5 hours)

- [ ] Create `capture_gallery_lightbox_widget.dart`
- [ ] Create `capture_location_map_screen.dart`
- [ ] Add gallery routes

### **Session 3: Multi-Map** (1 hour)

- [ ] Create `capture_map_view_screen.dart`
- [ ] Implement marker clustering
- [ ] Test performance

### **Session 4: Analytics & Settings** (1 hour)

- [ ] Create `capture_analytics_screen.dart`
- [ ] Create `capture_settings_screen.dart`
- [ ] Add all routes

### **Final: Integration** (30 mins)

- [ ] Create `capture_notification_service.dart`
- [ ] Update all exports
- [ ] Testing & docs

---

## 🚀 Launch Readiness

### **Pre-Launch Checklist**

- [ ] All 8 new files created
- [ ] All 6 files modified
- [ ] All routes added
- [ ] All exports updated
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Performance acceptable
- [ ] Zero console errors

### **Launch Steps**

```
1. Code review
2. Final testing
3. Deploy to staging
4. Test on real device
5. Deploy to production
6. Monitor analytics
```

---

## 💡 Tips for Success

### **File Creation**

- Create files in order listed (services → screens → widgets)
- Follow existing code patterns from Phase 1 & 2
- Reuse components where possible

### **Testing**

- Test each new file independently
- Then test integration with others
- Finally test with real Firebase data

### **Documentation**

- Add comments as you code
- Document complex logic
- Update related documentation

### **Version Control**

- Commit after each logical unit
- Clear commit messages
- Test before committing

---

## 📞 Reference Files

- **CAPTURE_PHASE_3_PLAN.md** - Detailed implementation plan
- **CAPTURE_PHASE_3_QUICK_REFERENCE.md** - Quick reference
- **CAPTURE_PHASE_2_COMPLETE.md** - Phase 2 patterns to follow
- **.zencoder/rules/repo.md** - Architecture overview
- **TODO.md** - Overall project status

---

## ✨ Summary

**8 Files to Create**: ~1,700 lines  
**6 Files to Modify**: ~300 lines  
**Total Addition**: ~2,000 lines  
**Estimated Time**: 4 hours  
**Complexity**: 🔴 HIGH (but well-documented)

**Result**: Capture system at 80% feature-complete with full discovery and analytics!

---

**Ready? Let's build Phase 3! 🚀**

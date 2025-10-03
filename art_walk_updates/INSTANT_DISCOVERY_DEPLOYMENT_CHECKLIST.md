# 🚀 Instant Discovery Mode - Deployment Checklist

## Pre-Deployment Verification

### ✅ Code Quality

- [x] All files created and exported
- [x] All tests passing (20/20)
- [x] No compilation errors
- [x] No linting warnings
- [x] Code reviewed and documented
- [x] Error handling implemented
- [x] Null safety enforced

### ✅ Dependencies

- [x] `geoflutterfire_plus: ^0.0.3` added to pubspec.yaml
- [x] `flutter pub get` executed successfully
- [x] No dependency conflicts
- [x] All imports resolved

### ✅ Testing

- [x] Unit tests passing (20/20)
- [ ] Integration tests (manual)
- [ ] UI tests (manual)
- [ ] Performance tests (manual)
- [ ] Device compatibility tests (manual)

---

## Database Migration

### Step 1: Backup Existing Data

```bash
# Export publicArt collection (via Firebase Console)
# 1. Go to Firestore Database
# 2. Select publicArt collection
# 3. Click "Export" button
# 4. Save backup to safe location
```

**Status:** [ ] Complete

### Step 2: Run Migration Script

```bash
cd /Users/kristybock/artbeat
dart scripts/migrate_public_art_geo.dart
```

**Expected Output:**

```
🚀 Starting publicArt geo field migration...
✅ Firebase initialized

📥 Fetching publicArt documents...
Found X documents

✅ Updated doc1 - Art Title 1
   Location: (37.7749, -122.4194)
   Geohash: 9q8yy9mf8

✅ Updated doc2 - Art Title 2
   ...

==================================================
📊 Migration Summary
==================================================
Total documents: X
✅ Updated: X
⏭️  Skipped: 0
❌ Errors: 0
==================================================

🎉 Migration completed successfully!
Instant Discovery Mode is now ready to use.
```

**Status:** [ ] Complete

### Step 3: Verify Migration

```bash
# Check Firestore Console
# 1. Open publicArt collection
# 2. Select a random document
# 3. Verify "geo" field exists with:
#    - geo.geohash (string, 9 characters)
#    - geo.geopoint (GeoPoint)
```

**Status:** [ ] Complete

---

## Testing Checklist

### Functional Testing

#### Dashboard Integration

- [ ] Dashboard loads without errors
- [ ] "Instant Discovery" card appears
- [ ] Nearby art count badge displays correctly
- [ ] Badge updates when location changes
- [ ] Tapping card opens radar screen

#### Radar Screen

- [ ] Radar screen loads without errors
- [ ] Animated sweep effect works smoothly
- [ ] User pin appears at center and pulses
- [ ] Art pins appear at correct positions
- [ ] Close art (<100m) pulses orange
- [ ] Far art (>100m) pulses teal
- [ ] Distance rings visible (100m, 250m, 500m)
- [ ] Bottom sheet shows list of nearby art
- [ ] Distances are accurate
- [ ] Proximity messages are correct

#### Capture Flow

- [ ] Tapping art pin opens capture modal
- [ ] Art details display correctly (image, title, artist)
- [ ] Distance indicator shows correct value
- [ ] Proximity message matches distance
- [ ] "Capture Discovery" button disabled when >50m
- [ ] "Capture Discovery" button enabled when <50m
- [ ] Tapping button triggers capture
- [ ] Confetti animation plays
- [ ] XP reward displays (+20 XP)
- [ ] Modal closes after capture
- [ ] Art removed from radar
- [ ] Discovery saved to Firestore

#### XP Rewards

- [ ] Base discovery awards +20 XP
- [ ] First discovery of day awards +50 XP bonus
- [ ] 3-day streak awards +30 XP bonus
- [ ] 7-day streak awards +70 XP bonus
- [ ] Maximum XP (140) awarded correctly
- [ ] XP updates in user profile

#### Re-Discovery Prevention

- [ ] Discovered art doesn't appear on radar
- [ ] Cache invalidates after new discovery
- [ ] Cache refreshes after 5 minutes
- [ ] Multiple users can discover same art

### Edge Cases

#### Location Handling

- [ ] Location permission denied → Shows permission dialog
- [ ] GPS disabled → Shows "Enable GPS" message
- [ ] Location unavailable → Shows "Searching..." message
- [ ] Location accuracy low → Still works (with warning?)
- [ ] User moves while radar open → Updates correctly

#### Network Handling

- [ ] No internet → Shows "No internet" message
- [ ] Firestore timeout → Shows retry button
- [ ] Slow connection → Shows loading indicator
- [ ] Connection restored → Resumes normally

#### Data Handling

- [ ] No nearby art → Shows empty state
- [ ] All nearby art discovered → Shows empty state
- [ ] Invalid art data → Skips invalid art
- [ ] Missing geo field → Logs error, continues
- [ ] Null location → Handles gracefully

#### UI/UX

- [ ] Animations run at 60fps
- [ ] No UI jank or stuttering
- [ ] Smooth transitions between screens
- [ ] Proper back button handling
- [ ] Screen rotation handled correctly
- [ ] Keyboard doesn't overlap content

### Performance Testing

#### Firestore Queries

- [ ] Nearby art query completes in <1s
- [ ] Discovered art query completes in <1s
- [ ] Cache reduces read count by ~80%
- [ ] No unnecessary queries on screen load

#### Animation Performance

- [ ] Radar sweep runs at 60fps
- [ ] User pin pulse runs at 60fps
- [ ] Art pin pulses run at 60fps
- [ ] Confetti animation runs smoothly
- [ ] No dropped frames during animations

#### Battery Usage

- [ ] Location updates only when radar active
- [ ] No background location tracking
- [ ] Animations stop when screen closed
- [ ] Reasonable battery drain (<5% per 10 min)

#### Memory Usage

- [ ] No memory leaks from animations
- [ ] No memory leaks from streams
- [ ] Proper disposal of controllers
- [ ] Memory usage stable over time

### Device Compatibility

#### iOS Testing

- [ ] iPhone 12 Pro (iOS 15+)
- [ ] iPhone 13 (iOS 16+)
- [ ] iPhone 14 (iOS 17+)
- [ ] iPad Pro (iOS 15+)

#### Android Testing

- [ ] Pixel 6 (Android 12+)
- [ ] Samsung Galaxy S21 (Android 12+)
- [ ] OnePlus 9 (Android 12+)
- [ ] Budget device (Android 10+)

---

## Deployment Steps

### Step 1: Staging Deployment

#### Build for Staging

```bash
# Android
flutter build apk --release --flavor staging

# iOS
flutter build ios --release --flavor staging
```

**Status:** [ ] Complete

#### Deploy to Staging

- [ ] Upload to Firebase App Distribution
- [ ] Share with internal testers
- [ ] Collect feedback
- [ ] Fix any issues

### Step 2: Production Deployment

#### Final Checks

- [ ] All staging tests passed
- [ ] No critical bugs reported
- [ ] Performance metrics acceptable
- [ ] User feedback positive

#### Build for Production

```bash
# Android
flutter build appbundle --release

# iOS
flutter build ios --release
```

**Status:** [ ] Complete

#### Submit to Stores

- [ ] Upload to Google Play Console
- [ ] Upload to App Store Connect
- [ ] Update release notes
- [ ] Submit for review

### Step 3: Post-Deployment Monitoring

#### Analytics Setup

- [ ] Track "instant_discovery_opened" event
- [ ] Track "art_discovered" event
- [ ] Track "discovery_xp_awarded" event
- [ ] Track "discovery_streak_achieved" event

#### Metrics to Monitor

- [ ] Firestore read/write counts
- [ ] User engagement rates (DAU, MAU)
- [ ] Discovery completion rates
- [ ] Average discoveries per user
- [ ] XP distribution
- [ ] Streak distribution
- [ ] Error rates
- [ ] Crash rates
- [ ] Performance metrics (query time, FPS)

#### Alerts Setup

- [ ] Alert if error rate > 5%
- [ ] Alert if crash rate > 1%
- [ ] Alert if query time > 3s
- [ ] Alert if Firestore costs spike

---

## Rollback Plan

### If Critical Issues Found

#### Step 1: Disable Feature

```dart
// In art_walk_dashboard_screen.dart
// Comment out Instant Discovery card
// OR add feature flag:
if (FeatureFlags.instantDiscoveryEnabled) {
  _buildInstantDiscoveryCard(),
}
```

#### Step 2: Hotfix Deployment

```bash
# Fix the issue
# Build hotfix version
flutter build appbundle --release

# Deploy to stores with expedited review
```

#### Step 3: Rollback Database (if needed)

```bash
# Restore from backup (via Firebase Console)
# 1. Go to Firestore Database
# 2. Click "Import"
# 3. Select backup file
# 4. Confirm import
```

---

## Success Criteria

### Launch Day (Day 1)

- [ ] No critical bugs reported
- [ ] Error rate < 5%
- [ ] Crash rate < 1%
- [ ] At least 10% of users try feature
- [ ] Average 2+ discoveries per user

### Week 1

- [ ] Error rate < 2%
- [ ] Crash rate < 0.5%
- [ ] At least 25% of users try feature
- [ ] Average 5+ discoveries per user
- [ ] Positive user feedback (>4 stars)

### Month 1

- [ ] +20% increase in DAU
- [ ] +30% increase in art captures
- [ ] +40% increase in session length
- [ ] +25% increase in retention
- [ ] Feature used by 50%+ of active users

---

## Documentation Updates

### User-Facing Documentation

- [ ] Add "Instant Discovery" to help center
- [ ] Create tutorial video
- [ ] Update FAQ with common questions
- [ ] Add to onboarding flow (optional)

### Developer Documentation

- [ ] Update API documentation
- [ ] Add architecture diagrams to wiki
- [ ] Document migration process
- [ ] Add troubleshooting guide

---

## Communication Plan

### Internal Team

- [ ] Notify team of deployment schedule
- [ ] Share testing results
- [ ] Provide demo/walkthrough
- [ ] Set up monitoring dashboard

### Users

- [ ] Announce feature in app (banner/modal)
- [ ] Post on social media
- [ ] Send push notification (optional)
- [ ] Update app store description

### Support Team

- [ ] Train on new feature
- [ ] Provide FAQ document
- [ ] Set up support tickets category
- [ ] Monitor user feedback channels

---

## Post-Launch Tasks

### Week 1

- [ ] Review analytics daily
- [ ] Monitor error logs
- [ ] Respond to user feedback
- [ ] Fix any minor bugs
- [ ] Optimize performance if needed

### Week 2-4

- [ ] Analyze user behavior patterns
- [ ] Identify improvement opportunities
- [ ] Plan iteration/enhancements
- [ ] Gather feature requests
- [ ] Measure impact on key metrics

### Month 2+

- [ ] Implement Phase 2 features (haptic, AR, etc.)
- [ ] A/B test variations
- [ ] Optimize XP rewards based on data
- [ ] Add discovery challenges
- [ ] Build leaderboards

---

## Sign-Off

### Development Team

- [ ] Lead Developer: ********\_******** Date: **\_\_\_**
- [ ] QA Engineer: ********\_******** Date: **\_\_\_**
- [ ] DevOps: ********\_******** Date: **\_\_\_**

### Product Team

- [ ] Product Manager: ********\_******** Date: **\_\_\_**
- [ ] Designer: ********\_******** Date: **\_\_\_**

### Business Team

- [ ] CEO/Founder: ********\_******** Date: **\_\_\_**
- [ ] Marketing: ********\_******** Date: **\_\_\_**

---

## Notes

### Known Issues

- None at this time

### Future Enhancements

1. Haptic feedback when getting close to art
2. AR camera view with art markers
3. Discovery challenges ("Find 5 murals this week")
4. Leaderboards (top discoverers)
5. Offline radar mode
6. Discovery sharing to social media
7. Art hints for hard-to-find pieces
8. Discovery streak UI on dashboard
9. Push notifications for nearby art
10. Multiplayer radar (see other users)

---

_Generated: Instant Discovery Mode Deployment Checklist_  
_Status: Ready for Deployment_  
_Last Updated: October 1, 2025_

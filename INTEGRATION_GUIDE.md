# ArtBeat Profile Enhancement - Integration Guide

## Quick Start

This guide helps you integrate the new gamification features with real user data and backend services.

## Overview of New Features

### 1. Enhanced Profile Header

- **Level Progress Bar:** Shows user's current level and XP progress
- **Streak Display:** Shows login, challenge, and category streaks
- **Recent Badges Carousel:** Displays recently earned badges
- **Enhanced Stats Grid:** Shows 8 metrics (posts, captures, walks, likes, shares, comments, followers, following)

### 2. Dynamic Achievements Tab

- Loads all 50+ badges from RewardsService
- Category filters (All, Quest, Explorer, Social, Creator, Level)
- Progress tracking for locked badges
- Rarity indicators (Common, Rare, Epic, Legendary)
- Badge detail modal

### 3. Progress Tab

- Today's challenge with progress tracking
- Weekly goals with completion percentages
- Streak calendar showing daily activity
- Level progress with next level preview

### 4. Celebration Modals

- Badge earned modal with confetti
- Level up modal with fireworks
- Streak milestone modal with shake animation

## Integration Checklist

### Phase 1: Data Connection (1-2 days)

#### 1.1 Update UserModel

Add streak tracking fields to `UserModel`:

```dart
// In artbeat_core/lib/src/models/user_model.dart
class UserModel {
  // ... existing fields ...

  final Map<String, int> streaks;
  final DateTime? lastLoginDate;
  final int weeklyXP;
  final int monthlyXP;
  final int profileViews;

  const UserModel({
    // ... existing parameters ...
    this.streaks = const {'login': 0, 'challenge': 0},
    this.lastLoginDate,
    this.weeklyXP = 0,
    this.monthlyXP = 0,
    this.profileViews = 0,
  });

  // Update fromMap and toMap methods
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      // ... existing fields ...
      streaks: Map<String, int>.from(map['streaks'] ?? {'login': 0, 'challenge': 0}),
      lastLoginDate: (map['lastLoginDate'] as Timestamp?)?.toDate(),
      weeklyXP: map['weeklyXP'] as int? ?? 0,
      monthlyXP: map['monthlyXP'] as int? ?? 0,
      profileViews: map['profileViews'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // ... existing fields ...
      'streaks': streaks,
      'lastLoginDate': lastLoginDate != null ? Timestamp.fromDate(lastLoginDate!) : null,
      'weeklyXP': weeklyXP,
      'monthlyXP': monthlyXP,
      'profileViews': profileViews,
    };
  }
}
```

#### 1.2 Update Profile Screen Data Binding

Replace placeholder data in `profile_view_screen.dart`:

```dart
// Replace this:
StreakDisplay(
  loginStreak: 5, // TODO: Get from user data
  challengeStreak: 3, // TODO: Get from user data
  categoryStreak: 7, // TODO: Get from user data
  categoryName: 'Street Art',
),

// With this:
StreakDisplay(
  loginStreak: _userModel?.streaks['login'] ?? 0,
  challengeStreak: _userModel?.streaks['challenge'] ?? 0,
  categoryStreak: _userModel?.streaks['streetArt'] ?? 0,
  categoryName: 'Street Art',
),
```

#### 1.3 Connect Recent Badges

Update `_getRecentBadges()` method to fetch real data:

```dart
Future<List<BadgeData>> _getRecentBadges() async {
  final userId = widget.userId;
  final badgesSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('badges')
      .orderBy('earnedAt', descending: true)
      .limit(5)
      .get();

  return badgesSnapshot.docs.map((doc) {
    final data = doc.data();
    final badgeId = data['badgeId'] as String;
    final badgeInfo = RewardsService.badges[badgeId];

    return BadgeData(
      id: badgeId,
      name: badgeInfo?['name'] as String? ?? 'Unknown',
      description: badgeInfo?['description'] as String? ?? '',
      icon: badgeInfo?['icon'] as String? ?? '🏆',
      earnedAt: (data['earnedAt'] as Timestamp).toDate(),
      category: _getBadgeCategory(badgeId),
    );
  }).toList();
}
```

### Phase 2: Badge Tracking Service (2-3 days)

#### 2.1 Create UserBadgeService

Create new file: `artbeat_art_walk/lib/src/services/user_badge_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'rewards_service.dart';

class UserBadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if user has earned a specific badge
  Future<bool> hasBadge(String badgeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .doc(badgeId)
        .get();

    return doc.exists;
  }

  /// Get badge progress (0.0 to 1.0)
  Future<double> getBadgeProgress(String badgeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0.0;

    // Check if already earned
    if (await hasBadge(badgeId)) return 1.0;

    // Get progress from badgeProgress document
    final progressDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('badgeProgress')
        .doc(badgeId)
        .get();

    if (!progressDoc.exists) return 0.0;

    final data = progressDoc.data()!;
    final current = data['current'] as int? ?? 0;
    final target = data['target'] as int? ?? 1;

    return (current / target).clamp(0.0, 1.0);
  }

  /// Award a badge to the user
  Future<void> awardBadge(String badgeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Check if already earned
    if (await hasBadge(badgeId)) return;

    final badgeInfo = RewardsService.badges[badgeId];
    if (badgeInfo == null) return;

    final xpReward = badgeInfo['xpReward'] as int? ?? 0;

    // Add badge to user's collection
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .doc(badgeId)
        .set({
      'badgeId': badgeId,
      'earnedAt': FieldValue.serverTimestamp(),
      'xpAwarded': xpReward,
    });

    // Update user's XP
    await _firestore.collection('users').doc(userId).update({
      'experiencePoints': FieldValue.increment(xpReward),
      'lastBadgeEarned': FieldValue.serverTimestamp(),
    });

    // Remove from progress tracking
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('badgeProgress')
        .doc(badgeId)
        .delete();
  }

  /// Update badge progress
  Future<void> updateBadgeProgress(String badgeId, int current, int target) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('badgeProgress')
        .doc(badgeId)
        .set({
      'current': current,
      'target': target,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Check if badge should be awarded
    if (current >= target) {
      await awardBadge(badgeId);
    }
  }

  /// Get all earned badges
  Stream<List<String>> getEarnedBadges() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }
}
```

#### 2.2 Update DynamicAchievementsTab

Replace mock methods with real data:

```dart
// In dynamic_achievements_tab.dart
class _DynamicAchievementsTabState extends State<DynamicAchievementsTab> {
  final UserBadgeService _badgeService = UserBadgeService();
  List<String> _earnedBadges = [];

  @override
  void initState() {
    super.initState();
    _loadEarnedBadges();
  }

  void _loadEarnedBadges() {
    _badgeService.getEarnedBadges().listen((badges) {
      setState(() {
        _earnedBadges = badges;
      });
    });
  }

  bool _isBadgeEarned(String badgeId) {
    return _earnedBadges.contains(badgeId);
  }

  Future<double> _getBadgeProgress(String badgeId) async {
    return await _badgeService.getBadgeProgress(badgeId);
  }
}
```

### Phase 3: Streak Tracking (1-2 days)

#### 3.1 Create StreakService

Create new file: `artbeat_art_walk/lib/src/services/streak_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Update login streak
  Future<void> updateLoginStreak() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data();
    if (data == null) return;

    final lastLoginDate = (data['lastLoginDate'] as Timestamp?)?.toDate();
    final currentStreak = (data['streaks'] as Map?)?['login'] as int? ?? 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int newStreak = currentStreak;

    if (lastLoginDate == null) {
      // First login
      newStreak = 1;
    } else {
      final lastLogin = DateTime(
        lastLoginDate.year,
        lastLoginDate.month,
        lastLoginDate.day,
      );

      final daysDifference = today.difference(lastLogin).inDays;

      if (daysDifference == 0) {
        // Already logged in today, no change
        return;
      } else if (daysDifference == 1) {
        // Consecutive day, increment streak
        newStreak = currentStreak + 1;
      } else {
        // Streak broken, reset to 1
        newStreak = 1;
      }
    }

    // Update Firestore
    await _firestore.collection('users').doc(userId).update({
      'streaks.login': newStreak,
      'lastLoginDate': FieldValue.serverTimestamp(),
    });
  }

  /// Update challenge streak
  Future<void> updateChallengeStreak() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data();
    if (data == null) return;

    final currentStreak = (data['streaks'] as Map?)?['challenge'] as int? ?? 0;

    await _firestore.collection('users').doc(userId).update({
      'streaks.challenge': currentStreak + 1,
    });
  }

  /// Update category streak
  Future<void> updateCategoryStreak(String category) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data();
    if (data == null) return;

    final currentStreak = (data['streaks'] as Map?)?[category] as int? ?? 0;

    await _firestore.collection('users').doc(userId).update({
      'streaks.$category': currentStreak + 1,
    });
  }

  /// Reset streak (called when user misses a day)
  Future<void> resetStreak(String streakType) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).update({
      'streaks.$streakType': 0,
    });
  }
}
```

#### 3.2 Call StreakService on App Launch

In your main app initialization:

```dart
// In main.dart or app initialization
class _MyAppState extends State<MyApp> {
  final StreakService _streakService = StreakService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Update login streak when app launches
    await _streakService.updateLoginStreak();
  }
}
```

#### 3.3 Create Cloud Function for Streak Reset

Create a Cloud Function to reset streaks at midnight:

```javascript
// functions/src/index.ts
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const resetStreaks = functions.pubsub
  .schedule("0 0 * * *") // Run at midnight UTC
  .timeZone("UTC")
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = new Date();
    const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);

    // Find users who haven't logged in today
    const usersSnapshot = await db
      .collection("users")
      .where("lastLoginDate", "<", yesterday)
      .get();

    const batch = db.batch();

    usersSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        "streaks.login": 0,
      });
    });

    await batch.commit();

    console.log(`Reset streaks for ${usersSnapshot.size} users`);
  });
```

### Phase 4: Celebration Trigger System (2-3 days)

#### 4.1 Create CelebrationService

Create new file: `artbeat_profile/lib/src/services/celebration_service.dart`

```dart
import 'package:flutter/material.dart';
import '../widgets/celebration_modals.dart';

class CelebrationService {
  static final CelebrationService _instance = CelebrationService._internal();
  factory CelebrationService() => _instance;
  CelebrationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final List<Function> _celebrationQueue = [];
  bool _isShowingCelebration = false;

  /// Show badge earned celebration
  void showBadgeEarned({
    required String badgeName,
    required String badgeIcon,
    required int xpReward,
  }) {
    _queueCelebration(() {
      _showBadgeEarnedModal(
        badgeName: badgeName,
        badgeIcon: badgeIcon,
        xpReward: xpReward,
      );
    });
  }

  /// Show level up celebration
  void showLevelUp({
    required int newLevel,
    required String levelTitle,
    required List<String> unlockedPerks,
  }) {
    _queueCelebration(() {
      _showLevelUpModal(
        newLevel: newLevel,
        levelTitle: levelTitle,
        unlockedPerks: unlockedPerks,
      );
    });
  }

  /// Show streak milestone celebration
  void showStreakMilestone({
    required int streakCount,
    required String streakType,
  }) {
    _queueCelebration(() {
      _showStreakMilestoneModal(
        streakCount: streakCount,
        streakType: streakType,
      );
    });
  }

  void _queueCelebration(Function celebration) {
    _celebrationQueue.add(celebration);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isShowingCelebration || _celebrationQueue.isEmpty) return;

    _isShowingCelebration = true;
    final celebration = _celebrationQueue.removeAt(0);
    await celebration();
    _isShowingCelebration = false;

    // Process next celebration after a delay
    if (_celebrationQueue.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      _processQueue();
    }
  }

  Future<void> _showBadgeEarnedModal({
    required String badgeName,
    required String badgeIcon,
    required int xpReward,
  }) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BadgeEarnedModal(
        badgeName: badgeName,
        badgeIcon: badgeIcon,
        xpReward: xpReward,
      ),
    );
  }

  Future<void> _showLevelUpModal({
    required int newLevel,
    required String levelTitle,
    required List<String> unlockedPerks,
  }) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LevelUpModal(
        newLevel: newLevel,
        levelTitle: levelTitle,
        unlockedPerks: unlockedPerks,
      ),
    );
  }

  Future<void> _showStreakMilestoneModal({
    required int streakCount,
    required String streakType,
  }) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreakMilestoneModal(
        streakCount: streakCount,
        streakType: streakType,
      ),
    );
  }
}
```

#### 4.2 Update Main App

Add navigator key to MaterialApp:

```dart
// In main.dart
class MyApp extends StatelessWidget {
  final CelebrationService _celebrationService = CelebrationService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _celebrationService.navigatorKey,
      // ... rest of app configuration
    );
  }
}
```

#### 4.3 Trigger Celebrations

Call celebration service when achievements are earned:

```dart
// In UserBadgeService.awardBadge()
Future<void> awardBadge(String badgeId) async {
  // ... existing code to award badge ...

  // Trigger celebration
  final badgeInfo = RewardsService.badges[badgeId];
  CelebrationService().showBadgeEarned(
    badgeName: badgeInfo?['name'] as String? ?? 'Achievement',
    badgeIcon: badgeInfo?['icon'] as String? ?? '🏆',
    xpReward: badgeInfo?['xpReward'] as int? ?? 0,
  );

  // Check for level up
  final userDoc = await _firestore.collection('users').doc(userId).get();
  final newXP = userDoc.data()?['experiencePoints'] as int? ?? 0;
  final newLevel = RewardsService.getLevelForXP(newXP);
  final oldLevel = RewardsService.getLevelForXP(newXP - xpReward);

  if (newLevel > oldLevel) {
    final levelInfo = RewardsService.levelSystem[newLevel];
    CelebrationService().showLevelUp(
      newLevel: newLevel,
      levelTitle: levelInfo?['title'] as String? ?? 'Level $newLevel',
      unlockedPerks: (levelInfo?['perks'] as List?)?.cast<String>() ?? [],
    );
  }
}
```

### Phase 5: Weekly Goals (2-3 days)

#### 5.1 Create WeeklyGoalsService

Create new file: `artbeat_art_walk/lib/src/services/weekly_goals_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/weekly_goal_model.dart';

class WeeklyGoalsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current week's goals
  Future<List<WeeklyGoalModel>> getCurrentWeekGoals() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    final weekEnd = weekStart.add(const Duration(days: 7));

    final goalsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('weeklyGoals')
        .where('weekStart', isEqualTo: Timestamp.fromDate(weekStart))
        .get();

    if (goalsSnapshot.docs.isEmpty) {
      // Generate new goals for this week
      return await _generateWeeklyGoals(weekStart, weekEnd);
    }

    return goalsSnapshot.docs
        .map((doc) => WeeklyGoalModel.fromMap(doc.data()))
        .toList();
  }

  /// Generate personalized weekly goals
  Future<List<WeeklyGoalModel>> _generateWeeklyGoals(
    DateTime weekStart,
    DateTime weekEnd,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    // Get user's activity history to personalize goals
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();

    final goals = <WeeklyGoalModel>[
      WeeklyGoalModel(
        id: 'capture_5',
        title: 'Capture 5 artworks',
        description: 'Take photos of 5 different artworks',
        targetCount: 5,
        currentCount: 0,
        rewardXP: 100,
        weekStart: weekStart,
        weekEnd: weekEnd,
      ),
      WeeklyGoalModel(
        id: 'walk_2',
        title: 'Complete 2 art walks',
        description: 'Finish 2 guided art walks',
        targetCount: 2,
        currentCount: 0,
        rewardXP: 150,
        weekStart: weekStart,
        weekEnd: weekEnd,
      ),
      WeeklyGoalModel(
        id: 'social_10',
        title: 'Engage 10 times',
        description: 'Like, comment, or share 10 times',
        targetCount: 10,
        currentCount: 0,
        rewardXP: 75,
        weekStart: weekStart,
        weekEnd: weekEnd,
      ),
    ];

    // Save goals to Firestore
    final batch = _firestore.batch();
    for (final goal in goals) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('weeklyGoals')
          .doc(goal.id);
      batch.set(docRef, goal.toMap());
    }
    await batch.commit();

    return goals;
  }

  /// Update goal progress
  Future<void> updateGoalProgress(String goalId, int increment) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('weeklyGoals')
        .doc(goalId)
        .update({
      'currentCount': FieldValue.increment(increment),
    });
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }
}
```

#### 5.2 Update ProgressTab

Replace placeholder data with real goals:

```dart
// In progress_tab.dart
class _ProgressTabState extends State<ProgressTab> {
  final WeeklyGoalsService _goalsService = WeeklyGoalsService();
  List<WeeklyGoalModel> _weeklyGoals = [];

  @override
  void initState() {
    super.initState();
    _loadWeeklyGoals();
  }

  Future<void> _loadWeeklyGoals() async {
    final goals = await _goalsService.getCurrentWeekGoals();
    setState(() {
      _weeklyGoals = goals;
    });
  }

  Widget _buildWeeklyGoalsSection() {
    return Column(
      children: _weeklyGoals.map((goal) {
        return _buildGoalItem(
          goal.title,
          goal.description,
          goal.currentCount / goal.targetCount,
        );
      }).toList(),
    );
  }
}
```

## Testing Checklist

### Manual Testing

- [ ] Profile loads with all new widgets
- [ ] Level progress bar shows correct XP and level
- [ ] Streaks display correctly
- [ ] Recent badges carousel scrolls smoothly
- [ ] Stats grid shows all 8 metrics
- [ ] Achievements tab loads all badges
- [ ] Category filters work correctly
- [ ] Badge progress shows for locked badges
- [ ] Badge detail modal opens on tap
- [ ] Progress tab shows today's challenge
- [ ] Weekly goals display with progress
- [ ] Streak calendar shows correct days
- [ ] Level progress section accurate
- [ ] Badge earned modal shows with confetti
- [ ] Level up modal shows with correct info
- [ ] Streak milestone modal shows correctly

### Integration Testing

- [ ] Earning a badge triggers celebration
- [ ] Leveling up triggers celebration
- [ ] Streak milestones trigger celebration
- [ ] Badge progress updates in real-time
- [ ] Streaks update on login
- [ ] Weekly goals reset on Sunday
- [ ] XP updates reflect in level progress
- [ ] Recent badges update when new badge earned

### Performance Testing

- [ ] Profile loads in < 2 seconds
- [ ] Achievements tab loads in < 1 second
- [ ] Animations run at 60fps
- [ ] No memory leaks from animations
- [ ] Smooth scrolling in all tabs

## Troubleshooting

### Issue: Badges not showing as earned

**Solution:** Check that badges are being saved to Firestore correctly:

```dart
// Verify in Firebase Console:
// users/{userId}/badges/{badgeId}
```

### Issue: Streaks not updating

**Solution:** Ensure StreakService is called on app launch and lastLoginDate is being updated

### Issue: Celebration modals not showing

**Solution:** Verify navigatorKey is set in MaterialApp and CelebrationService is initialized

### Issue: Progress tab shows no data

**Solution:** Check that ChallengeService and WeeklyGoalsService are returning data

### Issue: Performance issues with animations

**Solution:** Reduce confetti particle count or use RepaintBoundary widgets

## Support

For questions or issues:

1. Check this integration guide
2. Review IMPLEMENTATION_COMPLETE.md for architecture details
3. Check TODO comments in code for specific integration points
4. Review existing services (RewardsService, ChallengeService) for data structures

## Next Steps

After completing integration:

1. Run comprehensive testing
2. Monitor analytics for engagement metrics
3. Gather user feedback
4. Iterate based on data
5. Plan Phase 5 (Social Features) implementation

---

_Last updated: June 1, 2025_

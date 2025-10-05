# ✅ Profile Enhancement Implementation Checklist

**Date:** January 2025  
**Purpose:** Step-by-step implementation guide for development team

---

## 🎯 PHASE 1: ENHANCED PROFILE HEADER (Week 1-2)

### Task 1.1: Level Progress Display

**Priority:** HIGH | **Effort:** 2 days | **Dependencies:** None

- [ ] Create `LevelProgressCard` widget
- [ ] Fetch user level and XP from `UserModel`
- [ ] Use `RewardsService.getLevelProgress()` for progress calculation
- [ ] Use `RewardsService.getLevelTitle()` for level title
- [ ] Add animated progress bar
- [ ] Display XP needed for next level
- [ ] Add gradient background (purple to green)
- [ ] Test with different level ranges

**Files to Modify:**

- `/packages/artbeat_profile/lib/src/screens/profile_view_screen.dart`

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/widgets/level_progress_card.dart`

---

### Task 1.2: Active Streaks Display

**Priority:** HIGH | **Effort:** 2 days | **Dependencies:** None

- [ ] Create `ActiveStreaksCard` widget
- [ ] Fetch login streak from Firestore (`users/{userId}/stats/loginStreak`)
- [ ] Fetch challenge streak from Firestore (`users/{userId}/stats/challengeStreak`)
- [ ] Fetch category streaks using `RewardsService.getCategoryStreaks()`
- [ ] Display top 3 active streaks
- [ ] Add fire emoji indicators (🔥)
- [ ] Add streak at-risk warning (if not completed today)
- [ ] Test with various streak lengths

**Files to Modify:**

- `/packages/artbeat_profile/lib/src/screens/profile_view_screen.dart`

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/widgets/active_streaks_card.dart`

---

### Task 1.3: Enhanced Stats Grid

**Priority:** HIGH | **Effort:** 1 day | **Dependencies:** None

- [ ] Expand stats from 3 to 8+ metrics
- [ ] Add Total XP stat
- [ ] Add Badges Earned stat (X/50)
- [ ] Add Quests Completed stat
- [ ] Add Level stat with title
- [ ] Use color-coded icons for each stat
- [ ] Make stats tappable for detailed view
- [ ] Add loading states

**Files to Modify:**

- `/packages/artbeat_profile/lib/src/screens/profile_view_screen.dart` (lines 281-288)

**Data Sources:**

- `UserModel.experiencePoints`
- `UserModel.level`
- Firestore: `users/{userId}/badges` (count)
- Firestore: `users/{userId}/stats/challengesCompleted`
- Firestore: `users/{userId}/stats/weeklyGoalsCompleted`

---

### Task 1.4: Recent Badges Carousel

**Priority:** MEDIUM | **Effort:** 1 day | **Dependencies:** None

- [ ] Create `RecentBadgesCarousel` widget
- [ ] Fetch last 5 earned badges from Firestore
- [ ] Sort badges by `earnedAt` timestamp
- [ ] Display in horizontal scroll view
- [ ] Add badge icons and names
- [ ] Make badges tappable (show detail modal)
- [ ] Add "NEW" indicator for unviewed badges
- [ ] Test with 0, 1, and 5+ badges

**Files to Modify:**

- `/packages/artbeat_profile/lib/src/screens/profile_view_screen.dart`

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/widgets/recent_badges_carousel.dart`

---

## 🎯 PHASE 2: ACHIEVEMENTS TAB REDESIGN (Week 3-4)

### Task 2.1: Dynamic Badge Loading

**Priority:** HIGH | **Effort:** 2 days | **Dependencies:** None

- [ ] Remove hardcoded achievement cards (lines 523-551)
- [ ] Fetch all badges from `RewardsService.badges`
- [ ] Fetch user's earned badges from Firestore
- [ ] Calculate progress for each badge
- [ ] Display all 50+ badges dynamically
- [ ] Show earned vs. locked state
- [ ] Add badge rarity calculation
- [ ] Test with various badge states

**Files to Modify:**

- `/packages/artbeat_profile/lib/src/screens/profile_view_screen.dart` (lines 494-557)

**Data Sources:**

- `RewardsService.badges` (static badge definitions)
- Firestore: `users/{userId}/badges` (earned badges)
- Firestore: `users/{userId}/stats/*` (progress data)

---

### Task 2.2: Achievement Categories

**Priority:** HIGH | **Effort:** 2 days | **Dependencies:** Task 2.1

- [ ] Create category filter tabs
- [ ] Categories: All, Quest, Explorer, Social, Creator, Level
- [ ] Filter badges by category
- [ ] Add category icons and colors
- [ ] Show badge count per category
- [ ] Persist selected category
- [ ] Add smooth transition animations
- [ ] Test category switching

**Files to Modify:**

- `/packages/artbeat_profile/lib/src/screens/profile_view_screen.dart`

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/widgets/achievement_category_tabs.dart`

---

### Task 2.3: Badge Detail Modal

**Priority:** MEDIUM | **Effort:** 2 days | **Dependencies:** Task 2.1

- [ ] Create `BadgeDetailModal` widget
- [ ] Show badge icon, name, description
- [ ] Show unlock requirements
- [ ] Show progress bar (if in progress)
- [ ] Show unlock date (if earned)
- [ ] Calculate and show rarity percentage
- [ ] Show related badges
- [ ] Add share button
- [ ] Test with earned and locked badges

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/widgets/badge_detail_modal.dart`

---

### Task 2.4: Achievement Summary Card

**Priority:** MEDIUM | **Effort:** 1 day | **Dependencies:** Task 2.1

- [ ] Create `AchievementSummaryCard` widget
- [ ] Show total badges earned (X/50)
- [ ] Show progress bar
- [ ] Show user's rank percentile
- [ ] Add motivational message
- [ ] Use gradient background
- [ ] Test with various completion levels

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/widgets/achievement_summary_card.dart`

---

### Task 2.5: Upcoming Badges Section

**Priority:** MEDIUM | **Effort:** 1 day | **Dependencies:** Task 2.1

- [ ] Create `UpcomingBadgesSection` widget
- [ ] Filter badges with 50%+ progress
- [ ] Sort by progress percentage (descending)
- [ ] Show top 3 closest badges
- [ ] Display progress bars
- [ ] Show requirements remaining
- [ ] Add "Complete now" action button
- [ ] Test with various progress states

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/widgets/upcoming_badges_section.dart`

---

## 🎯 PHASE 3: PROGRESS TAB (Week 5)

### Task 3.1: Add Progress Tab

**Priority:** HIGH | **Effort:** 1 day | **Dependencies:** None

- [ ] Update `TabController` length from 2 to 3
- [ ] Add "Progress" tab to TabBar
- [ ] Create `_buildProgressTab()` method
- [ ] Add tab icon (Icons.trending_up)
- [ ] Test tab switching
- [ ] Ensure proper state management

**Files to Modify:**

- `/packages/artbeat_profile/lib/src/screens/profile_view_screen.dart` (line 37, 327-331)

---

### Task 3.2: Today's Challenge Card

**Priority:** HIGH | **Effort:** 2 days | **Dependencies:** Task 3.1

- [ ] Create `TodaysChallengeCard` widget
- [ ] Fetch today's challenge using `ChallengeService.getTodaysChallenge()`
- [ ] Display challenge title and description
- [ ] Show progress bar (current/target)
- [ ] Show XP reward
- [ ] Show time remaining (countdown)
- [ ] Add "Complete now" button
- [ ] Handle no challenge state
- [ ] Test with completed and incomplete challenges

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/widgets/todays_challenge_card.dart`

**Data Sources:**

- `ChallengeService.getTodaysChallenge()`
- Firestore: `users/{userId}/dailyChallenges/{date}`

---

### Task 3.3: Weekly Goals Progress Card

**Priority:** HIGH | **Effort:** 2 days | **Dependencies:** Task 3.1

- [ ] Create `WeeklyGoalsProgressCard` widget
- [ ] Fetch weekly goals using `WeeklyGoalsService`
- [ ] Display all 3 weekly goals
- [ ] Show completion status (✅ or ⏳)
- [ ] Show progress bars for incomplete goals
- [ ] Show time until reset
- [ ] Add "View details" button
- [ ] Test with various completion states

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/widgets/weekly_goals_progress_card.dart`

**Data Sources:**

- `WeeklyGoalsService` (to be imported)
- Firestore: `users/{userId}/weeklyGoals/{weekKey}`

---

### Task 3.4: Streaks Overview Card

**Priority:** MEDIUM | **Effort:** 2 days | **Dependencies:** Task 3.1

- [ ] Create `StreaksOverviewCard` widget
- [ ] Display login streak with calendar
- [ ] Display challenge streak with calendar
- [ ] Show next milestone for each streak
- [ ] Show days remaining to milestone
- [ ] Add visual streak calendar (last 7 days)
- [ ] Add fire emoji indicators
- [ ] Test with various streak lengths

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/widgets/streaks_overview_card.dart`

---

### Task 3.5: Level Progress Card

**Priority:** MEDIUM | **Effort:** 1 day | **Dependencies:** Task 3.1

- [ ] Create `LevelProgressDetailCard` widget
- [ ] Show current level → next level
- [ ] Show XP progress bar
- [ ] Show XP needed
- [ ] List perks unlocked at next level
- [ ] Use `RewardsService.levelPerks` for perks
- [ ] Add visual level ladder
- [ ] Test with various levels

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/widgets/level_progress_detail_card.dart`

---

### Task 3.6: Category Streaks Card

**Priority:** LOW | **Effort:** 1 day | **Dependencies:** Task 3.1

- [ ] Create `CategoryStreaksCard` widget
- [ ] Fetch category streaks using `RewardsService.getCategoryStreaks()`
- [ ] Display all 4 categories (Photography, Exploration, Social, Walking)
- [ ] Show current streak for each
- [ ] Add fire emoji for active streaks (3+ days)
- [ ] Add category icons
- [ ] Test with various streak states

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/widgets/category_streaks_card.dart`

---

## 🎯 PHASE 4: CELEBRATION ANIMATIONS (Week 6)

### Task 4.1: Badge Earned Modal

**Priority:** HIGH | **Effort:** 2 days | **Dependencies:** None

- [ ] Create `BadgeCelebrationModal` widget
- [ ] Add confetti animation
- [ ] Add badge zoom-in animation
- [ ] Display badge icon, name, description
- [ ] Show XP earned
- [ ] Show rarity percentage
- [ ] Add share button
- [ ] Add sound effect (optional)
- [ ] Test with various badges

**New Files to Create:**

- `/packages/artbeat_core/lib/src/widgets/badge_celebration_modal.dart`

**Integration Points:**

- Call from `RewardsService.awardBadge()`
- Call from `ChallengeService.completeChallenge()`
- Call from `WeeklyGoalsService.completeGoal()`

---

### Task 4.2: Level Up Modal

**Priority:** HIGH | **Effort:** 2 days | **Dependencies:** None

- [ ] Create `LevelUpCelebrationModal` widget
- [ ] Add fireworks animation
- [ ] Add level number reveal animation
- [ ] Display level title
- [ ] List perks unlocked
- [ ] Add share button
- [ ] Add sound effect (optional)
- [ ] Test with various levels

**New Files to Create:**

- `/packages/artbeat_core/lib/src/widgets/level_up_celebration_modal.dart`

**Integration Points:**

- Call from `RewardsService.awardXP()` when level increases

---

### Task 4.3: Streak Milestone Modal

**Priority:** MEDIUM | **Effort:** 1 day | **Dependencies:** None

- [ ] Create `StreakMilestoneCelebrationModal` widget
- [ ] Add fire animation
- [ ] Display streak count
- [ ] Show bonus XP earned
- [ ] Show next milestone
- [ ] Add share button
- [ ] Test with various milestones

**New Files to Create:**

- `/packages/artbeat_core/lib/src/widgets/streak_milestone_celebration_modal.dart`

**Integration Points:**

- Call from `RewardsService.processDailyLogin()` at milestones
- Call from challenge completion at streak milestones

---

### Task 4.4: XP Counter Animation

**Priority:** LOW | **Effort:** 1 day | **Dependencies:** None

- [ ] Create `AnimatedXPCounter` widget
- [ ] Add number increment animation
- [ ] Add sparkle effect
- [ ] Add sound effect (optional)
- [ ] Test with various XP amounts

**New Files to Create:**

- `/packages/artbeat_core/lib/src/widgets/animated_xp_counter.dart`

---

## 🎯 PHASE 5: SOCIAL FEATURES (Week 7-8)

### Task 5.1: Leaderboard Screen

**Priority:** HIGH | **Effort:** 3 days | **Dependencies:** None

- [ ] Create `LeaderboardScreen` widget
- [ ] Add tab filters (Global, Friends, Local)
- [ ] Add time filters (Weekly, Monthly, All-Time)
- [ ] Fetch top users from Firestore
- [ ] Display user rank, name, level, XP
- [ ] Highlight current user's position
- [ ] Add "View Profile" button for each user
- [ ] Implement pagination (load more)
- [ ] Add pull-to-refresh
- [ ] Test with various user counts

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/screens/leaderboard_screen.dart`

**Firestore Queries:**

```dart
// Global leaderboard
FirebaseFirestore.instance
  .collection('users')
  .orderBy('experiencePoints', descending: true)
  .limit(100)
  .get();

// Weekly leaderboard (requires new field)
FirebaseFirestore.instance
  .collection('users')
  .orderBy('weeklyXP', descending: true)
  .limit(100)
  .get();
```

---

### Task 5.2: User Discovery Screen

**Priority:** HIGH | **Effort:** 3 days | **Dependencies:** None

- [ ] Create `UserDiscoveryScreen` widget
- [ ] Add search functionality
- [ ] Add filter options (level, location, badges)
- [ ] Implement "Suggested for You" algorithm
- [ ] Display user cards with key stats
- [ ] Add "Follow" button
- [ ] Add "View Profile" button
- [ ] Show mutual connections
- [ ] Test with various user types

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/screens/user_discovery_screen.dart`

**Suggestion Algorithm:**

- Same location (weight: 0.3)
- Similar badges (weight: 0.2)
- Mutual connections (weight: 0.3)
- Similar activity level (weight: 0.2)

---

### Task 5.3: Followers/Following Lists

**Priority:** MEDIUM | **Effort:** 2 days | **Dependencies:** None

- [ ] Create `FollowersListScreen` widget
- [ ] Create `FollowingListScreen` widget
- [ ] Fetch followers from Firestore
- [ ] Fetch following from Firestore
- [ ] Display user cards
- [ ] Add "Follow Back" button (followers)
- [ ] Add "Unfollow" button (following)
- [ ] Show mutual connections
- [ ] Implement pagination
- [ ] Test with various list sizes

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/screens/followers_list_screen.dart`
- `/packages/artbeat_profile/lib/src/screens/following_list_screen.dart`

---

### Task 5.4: Follow Suggestions Widget

**Priority:** MEDIUM | **Effort:** 2 days | **Dependencies:** Task 5.2

- [ ] Create `FollowSuggestionsWidget` widget
- [ ] Display on profile screen
- [ ] Show 3-5 suggested users
- [ ] Use same algorithm as User Discovery
- [ ] Add "Follow" button
- [ ] Add "View Profile" button
- [ ] Add "Dismiss" button
- [ ] Test with various user types

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/widgets/follow_suggestions_widget.dart`

---

## 🎯 PHASE 6: NOTIFICATIONS (Week 9)

### Task 6.1: Smart Notification Service

**Priority:** HIGH | **Effort:** 3 days | **Dependencies:** None

- [ ] Create `SmartNotificationService` class
- [ ] Implement daily challenge notification
- [ ] Implement streak at-risk notification
- [ ] Implement badge almost unlocked notification
- [ ] Implement weekly goals reminder
- [ ] Implement level up soon notification
- [ ] Add notification scheduling
- [ ] Add user preferences for notification times
- [ ] Test with various scenarios

**New Files to Create:**

- `/packages/artbeat_core/lib/src/services/smart_notification_service.dart`

**Notification Triggers:**

- Daily challenge: 9 AM (user's preferred time)
- Streak at risk: 10 PM (2 hours before day ends)
- Badge almost unlocked: When 90%+ progress
- Weekly goals: Wednesday + Sunday
- Level up soon: When within 10% of next level

---

### Task 6.2: In-App Notification Center

**Priority:** MEDIUM | **Effort:** 2 days | **Dependencies:** Task 6.1

- [ ] Create `NotificationCenterScreen` widget
- [ ] Display all notifications
- [ ] Group by type (achievements, social, system)
- [ ] Mark as read functionality
- [ ] Add notification actions (view, dismiss)
- [ ] Add notification badge count
- [ ] Test with various notification types

**New Files to Create:**

- `/packages/artbeat_core/lib/src/screens/notification_center_screen.dart`

---

## 🎯 PHASE 7: PERSONALIZATION (Week 10)

### Task 7.1: User Insights Service

**Priority:** MEDIUM | **Effort:** 3 days | **Dependencies:** None

- [ ] Create `UserInsightsService` class
- [ ] Calculate most active day
- [ ] Calculate favorite category
- [ ] Calculate weekly XP growth
- [ ] Calculate user rank percentile
- [ ] Generate personalized recommendations
- [ ] Cache insights (update daily)
- [ ] Test with various user patterns

**New Files to Create:**

- `/packages/artbeat_core/lib/src/services/user_insights_service.dart`

---

### Task 7.2: Insights Screen

**Priority:** MEDIUM | **Effort:** 2 days | **Dependencies:** Task 7.1

- [ ] Create `UserInsightsScreen` widget
- [ ] Display activity summary
- [ ] Display strengths
- [ ] Display recommendations
- [ ] Display rank information
- [ ] Add weekly/monthly toggle
- [ ] Add share button
- [ ] Test with various user types

**New Files to Create:**

- `/packages/artbeat_profile/lib/src/screens/user_insights_screen.dart`

---

## 🎯 TESTING CHECKLIST

### Unit Tests

- [ ] Test `RewardsService` methods
- [ ] Test `ChallengeService` methods
- [ ] Test `UserInsightsService` methods
- [ ] Test badge calculation logic
- [ ] Test streak calculation logic
- [ ] Test level progression logic

### Widget Tests

- [ ] Test `LevelProgressCard` widget
- [ ] Test `ActiveStreaksCard` widget
- [ ] Test `BadgeCelebrationModal` widget
- [ ] Test `LeaderboardScreen` widget
- [ ] Test all new profile widgets

### Integration Tests

- [ ] Test profile screen loading
- [ ] Test tab switching
- [ ] Test badge earning flow
- [ ] Test level up flow
- [ ] Test streak maintenance flow
- [ ] Test social features flow

### Performance Tests

- [ ] Test with 0 badges
- [ ] Test with 50+ badges
- [ ] Test with large follower counts
- [ ] Test with slow network
- [ ] Test with offline mode

---

## 🎯 DATABASE SCHEMA UPDATES

### New Firestore Fields:

```javascript
users/{userId}/
  // Weekly XP tracking (for leaderboards)
  weeklyXP: 450
  monthlyXP: 1850

  // Profile views
  profileViews: 234

  // Insights cache
  insights/
    mostActiveDay: "saturday"
    favoriteCategory: "photography"
    weeklyGrowth: 55.5
    rankPercentile: 15
    lastCalculated: Timestamp

  // Notification preferences
  notificationPreferences/
    dailyChallengeTime: "09:00"
    streakReminders: true
    badgeAlerts: true
    socialNotifications: true
```

### New Firestore Collections:

```javascript
// Leaderboards (cached, updated every 5 minutes)
leaderboards/
  global_weekly/
    users: [{userId, xp, level, rank}, ...]
    lastUpdated: Timestamp

  global_monthly/
    users: [{userId, xp, level, rank}, ...]
    lastUpdated: Timestamp

  global_alltime/
    users: [{userId, xp, level, rank}, ...]
    lastUpdated: Timestamp

// Follow relationships
follows/
  {followId}/
    followerId: "user123"
    followingId: "user456"
    createdAt: Timestamp

// Notifications
notifications/
  {notificationId}/
    userId: "user123"
    type: "badge_earned"
    title: "Badge Unlocked!"
    message: "You earned Quest Master badge"
    data: {badgeId: "quest_master"}
    read: false
    createdAt: Timestamp
```

### Firestore Indexes Required:

```javascript
// For leaderboards
users: experiencePoints DESC, level DESC

// For weekly leaderboards
users: weeklyXP DESC

// For user discovery
users: location ASC, level ASC

// For follow relationships
follows: followerId ASC, createdAt DESC
follows: followingId ASC, createdAt DESC

// For notifications
notifications: userId ASC, read ASC, createdAt DESC
```

---

## 🎯 DEPLOYMENT CHECKLIST

### Pre-Deployment

- [ ] All unit tests passing
- [ ] All widget tests passing
- [ ] All integration tests passing
- [ ] Code review completed
- [ ] Design review completed
- [ ] Performance testing completed
- [ ] Accessibility testing completed
- [ ] Documentation updated

### Deployment Steps

1. [ ] Deploy Firestore schema updates
2. [ ] Deploy Firestore security rules
3. [ ] Deploy Firestore indexes
4. [ ] Deploy backend functions (if any)
5. [ ] Deploy app update to staging
6. [ ] Test on staging environment
7. [ ] Deploy to production (gradual rollout)
8. [ ] Monitor error rates
9. [ ] Monitor performance metrics
10. [ ] Gather user feedback

### Post-Deployment

- [ ] Monitor crash reports
- [ ] Monitor analytics
- [ ] Track KPIs (DAU, retention, engagement)
- [ ] Gather user feedback
- [ ] Plan iteration based on data

---

## 🎯 ESTIMATED TIMELINE

### Phase 1: Enhanced Profile Header

**Duration:** 2 weeks  
**Team Size:** 1-2 developers

### Phase 2: Achievements Tab Redesign

**Duration:** 2 weeks  
**Team Size:** 1-2 developers

### Phase 3: Progress Tab

**Duration:** 1 week  
**Team Size:** 1 developer

### Phase 4: Celebration Animations

**Duration:** 1 week  
**Team Size:** 1 developer

### Phase 5: Social Features

**Duration:** 2 weeks  
**Team Size:** 2 developers

### Phase 6: Notifications

**Duration:** 1 week  
**Team Size:** 1 developer

### Phase 7: Personalization

**Duration:** 1 week  
**Team Size:** 1 developer

**Total Duration:** 10 weeks (2.5 months)  
**Total Effort:** ~15 developer-weeks

---

## 🎯 QUICK WINS (Can Start Immediately)

### Week 0: Quick Wins (3-5 days)

- [ ] Add level progress bar to profile header
- [ ] Display active streaks on profile
- [ ] Show recent badges carousel
- [ ] Expand stats grid to 8 metrics
- [ ] Add badge rarity indicators

**Impact:** Immediate visual improvement, no backend changes needed

---

## 📝 NOTES

### Code Style Guidelines

- Follow existing Flutter/Dart style guide
- Use meaningful variable names
- Add comments for complex logic
- Keep widgets small and focused
- Use const constructors where possible
- Implement proper error handling

### Performance Considerations

- Lazy load images
- Implement pagination for lists
- Cache frequently accessed data
- Use Firestore indexes
- Optimize queries
- Minimize widget rebuilds

### Accessibility Considerations

- Add semantic labels
- Ensure proper contrast ratios
- Support screen readers
- Add haptic feedback
- Support font scaling
- Test with accessibility tools

---

**Document Version:** 1.0  
**Last Updated:** January 2025  
**Next Review:** After each phase completion

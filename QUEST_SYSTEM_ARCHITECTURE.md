# Quest System Architecture & Integration

## 🏗️ System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER ACTIONS                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │   Complete Daily Challenge / Weekly Goal │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │      QUEST SERVICES LAYER                │
        │  ┌────────────────┐  ┌────────────────┐ │
        │  │ Challenge      │  │ Weekly Goals   │ │
        │  │ Service        │  │ Service        │ │
        │  └────────────────┘  └────────────────┘ │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │         REWARDS SERVICE                  │
        │  ┌────────────────────────────────────┐ │
        │  │  awardXP()                         │ │
        │  │  - Award XP                        │ │
        │  │  - Track Stats                     │ │
        │  │  - Calculate Level                 │ │
        │  │  - Check Badges                    │ │
        │  └────────────────────────────────────┘ │
        └─────────────────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                ▼                           ▼
    ┌───────────────────┐       ┌───────────────────┐
    │ checkStreakBadges │       │ checkPerfectWeek  │
    │ (Daily Challenges)│       │ (Weekly Goals)    │
    └───────────────────┘       └───────────────────┘
                │                           │
                └─────────────┬─────────────┘
                              ▼
        ┌─────────────────────────────────────────┐
        │         FIRESTORE DATABASE               │
        │  ┌────────────────────────────────────┐ │
        │  │ users/{userId}/                    │ │
        │  │   experiencePoints: number         │ │
        │  │   level: number                    │ │
        │  │   stats/                           │ │
        │  │     challengesCompleted: number    │ │
        │  │     weeklyGoalsCompleted: number   │ │
        │  │   badges/                          │ │
        │  │     quest_starter: {...}           │ │
        │  │     streak_master: {...}           │ │
        │  │     perfect_week: {...}            │ │
        │  └────────────────────────────────────┘ │
        └─────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │      NOTIFICATION SERVICE                │
        │  - Badge earned notifications            │
        │  - Level up notifications                │
        │  - Quest completion notifications        │
        └─────────────────────────────────────────┘
```

---

## 🔄 Data Flow Diagrams

### Daily Challenge Completion Flow

```
User Completes Challenge
         │
         ▼
┌────────────────────────┐
│ ChallengeService       │
│ updateChallengeProgress│
└────────────────────────┘
         │
         ▼
┌────────────────────────┐
│ RewardsService.awardXP │
│ ('challenge_completed')│
└────────────────────────┘
         │
         ├─────────────────────────────┐
         ▼                             ▼
┌──────────────────┐         ┌──────────────────┐
│ Firestore Update │         │ Badge Checks     │
│ - Add XP         │         │ - Quest badges   │
│ - Increment stat │         │ - XP badges      │
│ - Update level   │         │ - Streak badges  │
└──────────────────┘         └──────────────────┘
         │                             │
         └─────────────┬───────────────┘
                       ▼
         ┌──────────────────────┐
         │ Notification Sent    │
         │ - XP gained          │
         │ - Badges earned      │
         │ - Level up (if any)  │
         └──────────────────────┘
```

### Weekly Goal Completion Flow

```
User Completes Weekly Goal
         │
         ▼
┌────────────────────────────┐
│ WeeklyGoalsService         │
│ updateWeeklyGoalProgress   │
└────────────────────────────┘
         │
         ▼
┌────────────────────────────┐
│ RewardsService.awardXP     │
│ ('weekly_goal_completed')  │
└────────────────────────────┘
         │
         ├─────────────────────────────┐
         ▼                             ▼
┌──────────────────┐         ┌──────────────────┐
│ Firestore Update │         │ Badge Checks     │
│ - Add XP         │         │ - Weekly badges  │
│ - Increment stat │         │ - XP badges      │
│ - Update level   │         │ - Perfect week   │
└──────────────────┘         └──────────────────┘
         │                             │
         └─────────────┬───────────────┘
                       ▼
         ┌──────────────────────┐
         │ Check Perfect Week   │
         │ (All 3 goals done?)  │
         └──────────────────────┘
                       │
                       ▼
         ┌──────────────────────┐
         │ Notification Sent    │
         │ - XP gained          │
         │ - Badges earned      │
         │ - Perfect week bonus │
         └──────────────────────┘
```

---

## 🎯 Badge Award Logic

### Quest Badge Triggers

```
stats.challengesCompleted
    │
    ├─ == 1   → Award: Quest Starter 🎯
    ├─ == 10  → Award: Quest Enthusiast 🎲
    ├─ == 50  → Award: Quest Master 🏅
    └─ == 100 → Award: Quest Legend 🎖️

stats.weeklyGoalsCompleted
    │
    ├─ == 1  → Award: Weekly Warrior ⚔️
    ├─ == 10 → Award: Weekly Champion 🏆
    └─ == 25 → Award: Weekly Legend 👑
```

### Streak Badge Triggers

```
currentStreak (days)
    │
    ├─ >= 3   → Award: Streak Starter 🔥
    ├─ >= 7   → Award: Streak Master 🔥🔥
    ├─ >= 30  → Award: Streak Legend 🔥🔥🔥
    └─ >= 100 → Award: Unstoppable ⚡
```

### Perfect Week Badge Trigger

```
Weekly Goals for Current Week
    │
    ├─ Goal 1: isCompleted == true
    ├─ Goal 2: isCompleted == true
    └─ Goal 3: isCompleted == true
         │
         └─ All true? → Award: Perfect Week 💎
```

---

## 🗄️ Database Schema

### User Document Structure

```javascript
users/{userId}
├── experiencePoints: number
├── level: number
├── lastXPGain: timestamp
├── stats: {
│   ├── challengesCompleted: number      // NEW
│   ├── weeklyGoalsCompleted: number     // NEW
│   ├── walksCompleted: number
│   ├── capturesApproved: number
│   ├── reviewsSubmitted: number
│   └── helpfulVotes: number
│   }
└── badges: {
    ├── quest_starter: {                 // NEW
    │   ├── earnedAt: timestamp
    │   └── viewed: boolean
    │   }
    ├── quest_enthusiast: {...}          // NEW
    ├── quest_master: {...}              // NEW
    ├── quest_legend: {...}              // NEW
    ├── weekly_warrior: {...}            // NEW
    ├── weekly_champion: {...}           // NEW
    ├── weekly_legend: {...}             // NEW
    ├── perfect_week: {...}              // NEW
    ├── streak_starter: {...}            // NEW
    ├── streak_master: {...}             // NEW
    ├── streak_legend: {...}             // NEW
    └── unstoppable: {...}               // NEW
    }
```

### Daily Challenge Document Structure

```javascript
users/{userId}/dailyChallenges/{challengeId}
├── id: string
├── userId: string
├── title: string
├── description: string
├── type: string
├── targetCount: number
├── currentCount: number
├── rewardXP: number
├── rewardDescription: string
├── isCompleted: boolean
├── createdAt: timestamp
├── expiresAt: timestamp
└── updatedAt: timestamp
```

### Weekly Goal Document Structure

```javascript
users/{userId}/weeklyGoals/{weekKey}_{goalId}
├── id: string
├── userId: string
├── title: string
├── description: string
├── category: string
├── targetCount: number
├── currentCount: number
├── rewardXP: number
├── rewardDescription: string
├── isCompleted: boolean
├── completedAt: timestamp (optional)
├── createdAt: timestamp
├── expiresAt: timestamp
├── weekNumber: number
├── year: number
├── iconEmoji: string
└── milestones: array<string>
```

---

## 🔐 Transaction Safety

### XP Award Transaction

```dart
await _firestore.runTransaction((transaction) async {
  // 1. Read current user data
  final userDoc = await transaction.get(userRef);
  final userData = userDoc.data() ?? {};

  // 2. Calculate new values
  final currentXP = userData['experiencePoints'] ?? 0;
  final newXP = currentXP + xpAmount;
  final newLevel = _calculateLevel(newXP);

  // 3. Prepare updates
  final updates = {
    'experiencePoints': newXP,
    'level': newLevel,
    'lastXPGain': FieldValue.serverTimestamp(),
    'stats.challengesCompleted': FieldValue.increment(1), // Atomic
  };

  // 4. Write atomically
  transaction.update(userRef, updates);
});

// 5. Check badges (after transaction commits)
await _checkActionAchievements(userId, action, userData);
await checkStreakBadges(userId, currentStreak);
```

**Benefits:**

- ✅ Atomic updates (all or nothing)
- ✅ No race conditions
- ✅ Consistent data state
- ✅ Badge checks happen after commit

---

## 📊 Performance Considerations

### Optimizations Implemented:

1. **Lazy Badge Checks**

   - Badges only checked when relevant action occurs
   - No unnecessary database reads

2. **Efficient Queries**

   - Indexed fields: `weekNumber`, `year`, `isCompleted`
   - Compound queries for perfect week detection

3. **Cached Badge Definitions**

   - Badge metadata stored as static constants
   - No database reads for badge info

4. **Transaction Batching**

   - XP, stats, and level updated in single transaction
   - Reduces write operations

5. **Conditional Badge Awards**
   - Check if badge already exists before awarding
   - Prevents duplicate writes

---

## 🧪 Testing Scenarios

### Test Case 1: First Daily Challenge

```
Given: User has never completed a challenge
When: User completes first daily challenge
Then:
  ✅ XP is awarded
  ✅ stats.challengesCompleted = 1
  ✅ Quest Starter badge is awarded
  ✅ Streak Starter badge is awarded (if 3-day streak)
  ✅ Notification is sent
```

### Test Case 2: 10th Daily Challenge

```
Given: User has completed 9 challenges
When: User completes 10th daily challenge
Then:
  ✅ XP is awarded
  ✅ stats.challengesCompleted = 10
  ✅ Quest Enthusiast badge is awarded
  ✅ Previous badges remain unchanged
  ✅ Notification is sent
```

### Test Case 3: Perfect Week

```
Given: User has completed 2 weekly goals this week
When: User completes 3rd weekly goal this week
Then:
  ✅ XP is awarded
  ✅ stats.weeklyGoalsCompleted incremented
  ✅ Weekly goal badge awarded (if milestone)
  ✅ Perfect Week badge is awarded
  ✅ Notification is sent
```

### Test Case 4: Streak Break

```
Given: User has 6-day streak
When: User misses a day
Then:
  ✅ Streak resets to 0
  ✅ No new streak badges awarded
  ✅ Previously earned streak badges remain
```

---

## 🚀 Deployment Steps

1. **Pre-Deployment**

   - ✅ Code review complete
   - ✅ Syntax validation passed
   - ✅ Integration tests passed
   - ✅ Documentation complete

2. **Deployment**

   - Deploy updated service files
   - No database migration needed
   - No breaking changes

3. **Post-Deployment**

   - Monitor badge award rates
   - Check for any errors in logs
   - Verify notifications are sent
   - Collect user feedback

4. **Rollback Plan**
   - Revert to previous service versions
   - No data cleanup needed (badges are additive)

---

## 📈 Monitoring & Analytics

### Key Metrics to Track:

1. **Badge Earning Rates**

   - Average time to earn each badge
   - Most/least earned badges
   - Badge earning distribution

2. **Quest Completion Rates**

   - Daily challenge completion rate
   - Weekly goal completion rate
   - Perfect week achievement rate

3. **Streak Statistics**

   - Average streak length
   - Longest streaks
   - Streak break patterns

4. **User Engagement**
   - Quest participation rate
   - Badge collection rate
   - Retention impact

---

## 🎯 Success Criteria

### Implementation Success:

- ✅ All 12 badges implemented
- ✅ Stats tracking functional
- ✅ Badge awards automatic
- ✅ No syntax errors
- ✅ Backward compatible

### User Success:

- Users earn badges for quest completion
- Badge notifications appear correctly
- Stats update in real-time
- No duplicate badge awards
- Streak tracking accurate

---

**Architecture Version:** 1.0  
**Last Updated:** January 2025  
**Status:** Production Ready ✅

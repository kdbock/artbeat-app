# Quest Enhancements - Quick Reference Guide

## 🚀 Quick Start

### 1. Daily Login Rewards

**When to call:** App startup / Home screen initialization

```dart
final rewardsService = RewardsService();
final result = await rewardsService.processDailyLogin(userId);

// Result contains:
// - alreadyLoggedIn: bool (true if already logged in today)
// - streak: int (current login streak)
// - xpAwarded: int (XP earned from this login)
// - isNewStreak: bool (true if streak was broken)
```

**XP Rewards:**

- Days 1: 10 XP
- Days 2: 15 XP
- Days 3-6: 25 XP
- Days 7+: 50 XP
- Day 7 bonus: +50 XP
- Day 30 bonus: +100 XP
- Day 100 bonus: +500 XP

---

### 2. Quest Combo Multipliers

**Automatic:** Already integrated into challenge and weekly goal completion

**Multipliers:**

- 2 quests/day: 1.25x (+25%)
- 3+ quests/day: 1.5x (+50%)
- Daily + Weekly same day: +0.25x additional

**Manual usage (if needed):**

```dart
await rewardsService.awardXPWithCombo(
  'challenge_completed',
  baseXP: 100,
  isDailyChallenge: true,
  isWeeklyGoal: false,
);
```

---

### 3. Quest Milestones

**Automatic:** Checked after every quest completion

**Manual check (if needed):**

```dart
await rewardsService.checkQuestMilestones(userId);
```

**Milestones:**

- 100 quests: Century Quester 💯
- 250 quests: Quest Veteran 🎯
- 500 quests: Quest Grandmaster 👑
- 4 perfect weeks: Perfect Month 🌟

---

### 4. Category Streaks

**Automatic:** Tracked when challenges are completed

**Get category streaks:**

```dart
final streaks = await rewardsService.getCategoryStreaks(userId);

// Returns:
// {
//   'photography': {currentStreak: 5, longestStreak: 12, totalCompleted: 45, lastDate: '2025-01-15'},
//   'exploration': {currentStreak: 3, longestStreak: 8, totalCompleted: 28, lastDate: '2025-01-15'},
//   'social': {...},
//   'walking': {...}
// }
```

**Categories:**

- 📸 photography
- 🗺️ exploration
- 👥 social
- 🚶 walking

---

## 📊 New Stats Reference

### User Document Fields:

```javascript
{
  // Login tracking
  "lastLoginDate": "2025-01-15",

  "stats": {
    // Login stats
    "loginStreak": 7,
    "longestLoginStreak": 15,
    "totalLogins": 45,

    // Quest stats
    "challengesCompleted": 50,
    "weeklyGoalsCompleted": 12,
    "comboCompletions": 3,
    "consecutivePerfectWeeks": 2
  },

  // Daily quest tracking
  "dailyQuestStats": {
    "2025-01-15": {
      "questsCompleted": 2,
      "lastUpdated": Timestamp
    }
  },

  // Category streaks
  "categoryStreaks": {
    "photography": {
      "currentStreak": 5,
      "longestStreak": 12,
      "totalCompleted": 45,
      "lastDate": "2025-01-15"
    }
  }
}
```

---

## 🏆 New Badges Reference

| Badge ID             | Name               | Icon | Requirement              |
| -------------------- | ------------------ | ---- | ------------------------ |
| `daily_devotee`      | Daily Devotee      | 📅   | 7-day login streak       |
| `weekly_regular`     | Weekly Regular     | 🗓️   | 30-day login streak      |
| `dedicated_explorer` | Dedicated Explorer | 🎖️   | 100-day login streak     |
| `century_quester`    | Century Quester    | 💯   | 100 total quests         |
| `quest_veteran`      | Quest Veteran      | 🎯   | 250 total quests         |
| `quest_grandmaster`  | Quest Grandmaster  | 👑   | 500 total quests         |
| `perfect_month`      | Perfect Month      | 🌟   | 4 perfect weeks in a row |
| `combo_master`       | Combo Master       | ⚡   | 10 combo completions     |

---

## 🔧 Helper Methods

### Get Today's Quest Count:

```dart
final count = await rewardsService.getTodayQuestCount(userId);
print('Quests completed today: $count');
```

### Calculate XP with Multiplier:

```dart
final finalXP = rewardsService.calculateXPWithMultiplier(
  baseXP: 100,
  isDailyChallenge: true,
  isWeeklyGoal: false,
  questsCompletedToday: 2,
);
// Returns: 125 (100 * 1.25)
```

### Track Category Streak Manually:

```dart
await rewardsService.trackCategoryStreak(userId, 'photography');
```

---

## 🎨 UI Integration Examples

### Login Streak Display:

```dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return SizedBox();

    final data = snapshot.data!.data() as Map<String, dynamic>;
    final streak = data['stats']?['loginStreak'] ?? 0;

    return Row(
      children: [
        Text('🔥'),
        Text('$streak day streak'),
      ],
    );
  },
)
```

### Combo Multiplier Indicator:

```dart
FutureBuilder<int>(
  future: rewardsService.getTodayQuestCount(userId),
  builder: (context, snapshot) {
    final count = snapshot.data ?? 0;
    final multiplier = count >= 3 ? 1.5 : count >= 2 ? 1.25 : 1.0;

    if (multiplier > 1.0) {
      return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${((multiplier - 1) * 100).round()}% COMBO BONUS!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }
    return SizedBox();
  },
)
```

### Milestone Progress:

```dart
FutureBuilder<DocumentSnapshot>(
  future: FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return SizedBox();

    final data = snapshot.data!.data() as Map<String, dynamic>;
    final challenges = data['stats']?['challengesCompleted'] ?? 0;
    final weekly = data['stats']?['weeklyGoalsCompleted'] ?? 0;
    final total = challenges + weekly;

    final nextMilestone = total < 100 ? 100 : total < 250 ? 250 : 500;
    final progress = total / nextMilestone;

    return Column(
      children: [
        Text('Quest Progress: $total / $nextMilestone'),
        LinearProgressIndicator(value: progress),
      ],
    );
  },
)
```

---

## ⚠️ Important Notes

### Transaction Safety:

- All stat updates use Firestore transactions
- XP and stats are updated atomically
- Badge checks happen after transaction commits

### Backward Compatibility:

- All new fields are optional
- Existing users start with default values (0 or empty)
- No migration required

### Performance:

- Login check happens once per day (cached)
- Combo calculations are lightweight
- Category streaks use transactions (safe but slightly slower)

### Error Handling:

- All methods have try-catch blocks
- Errors are logged but don't crash the app
- Failed operations return safe defaults

---

## 🐛 Troubleshooting

### Login rewards not working?

- Check if `processDailyLogin()` is called on app startup
- Verify user is authenticated
- Check Firestore permissions

### Combo multipliers not applying?

- Ensure `awardXPWithCombo()` is used instead of `awardXP()`
- Check if `dailyQuestStats` field exists
- Verify date format is correct (YYYY-MM-DD)

### Badges not awarded?

- Check if stat thresholds are met
- Verify badge IDs match exactly
- Check Firestore rules allow badge writes

### Category streaks not tracking?

- Verify challenge titles contain category keywords
- Check if `_extractChallengeCategory()` returns correct category
- Ensure transaction completes successfully

---

## 📞 Support

For questions or issues:

1. Check this quick reference first
2. Review full documentation: `QUEST_ENHANCEMENTS_IMPLEMENTATION.md`
3. Check code comments in service files
4. Review Firestore console for data structure

---

**Last Updated:** January 2025  
**Version:** 1.0.0  
**Status:** Production Ready ✅

# ArtBeat Quest System - Visual Guide

## 🎯 **COMPLETE SYSTEM FLOW**

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER OPENS APP                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   DAILY LOGIN REWARDS                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  • Check if already logged in today                       │  │
│  │  • Calculate login streak                                 │  │
│  │  • Award XP (10-50 base + milestone bonuses)            │  │
│  │  • Update stats: loginStreak, totalLogins               │  │
│  │  • Check for login badges (7, 30, 100 days)            │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   USER VIEWS QUESTS                              │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Daily Challenges:                                        │  │
│  │  • 1 challenge per day                                    │  │
│  │  • Auto-generated based on user level                     │  │
│  │  • Categories: Discovery, Photography, Social, Walking    │  │
│  │                                                            │  │
│  │  Weekly Goals:                                            │  │
│  │  • 3 goals per week                                       │  │
│  │  • Higher XP rewards                                      │  │
│  │  • Longer-term objectives                                 │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                USER COMPLETES QUEST                              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   QUEST COMPLETION FLOW                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  1. Get today's quest count                               │  │
│  │  2. Calculate combo multiplier:                           │  │
│  │     • 1 quest: 1.0x (no bonus)                           │  │
│  │     • 2 quests: 1.25x (+25%)                             │  │
│  │     • 3+ quests: 1.5x (+50%)                             │  │
│  │     • Daily + Weekly: +0.25x additional                   │  │
│  │  3. Calculate final XP with multiplier                    │  │
│  │  4. Award XP to user                                      │  │
│  │  5. Update quest stats                                    │  │
│  │  6. Update daily quest count                              │  │
│  │  7. Track category streak                                 │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   XP & LEVEL UPDATE                              │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  • Add XP to user's total                                 │  │
│  │  • Recalculate level (if needed)                          │  │
│  │  • Update lastXPGain timestamp                            │  │
│  │  • Increment quest completion stats                       │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   BADGE CHECKING SYSTEM                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Check for Quest Badges:                                  │  │
│  │  • Quest Starter (1), Enthusiast (10), Master (50),      │  │
│  │    Legend (100)                                           │  │
│  │  • Weekly Warrior (1), Champion (10), Legend (25)        │  │
│  │                                                            │  │
│  │  Check for Streak Badges:                                 │  │
│  │  • Challenge streaks: 3, 7, 30, 100 days                 │  │
│  │  • Login streaks: 7, 30, 100 days                        │  │
│  │                                                            │  │
│  │  Check for Milestone Badges:                              │  │
│  │  • Century Quester (100), Veteran (250),                  │  │
│  │    Grandmaster (500)                                      │  │
│  │  • Perfect Week (3 goals), Perfect Month (4 weeks)       │  │
│  │                                                            │  │
│  │  Check for Combo Badge:                                   │  │
│  │  • Combo Master (10 daily+weekly combos)                 │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   NOTIFICATION SYSTEM                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  • Quest completion notification                          │  │
│  │  • XP gained (with multiplier if applicable)             │  │
│  │  • New badges earned                                      │  │
│  │  • Level up notification (if leveled up)                 │  │
│  │  • Streak milestones                                      │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🏆 **BADGE PROGRESSION PATHS**

### **Daily Challenge Path:**

```
🎯 Quest Starter (1)
    ↓ Complete 9 more
🎲 Quest Enthusiast (10)
    ↓ Complete 40 more
🏅 Quest Master (50)
    ↓ Complete 50 more
🎖️ Quest Legend (100)
```

### **Weekly Goal Path:**

```
⚔️ Weekly Warrior (1)
    ↓ Complete 9 more
🏆 Weekly Champion (10)
    ↓ Complete 15 more
👑 Weekly Legend (25)

💎 Perfect Week (Complete all 3 in one week)
    ↓ Do it 4 weeks in a row
🌟 Perfect Month (4 perfect weeks)
```

### **Challenge Streak Path:**

```
🔥 Streak Starter (3 days)
    ↓ Continue 4 more days
🔥🔥 Streak Master (7 days)
    ↓ Continue 23 more days
🔥🔥🔥 Streak Legend (30 days)
    ↓ Continue 70 more days
⚡ Unstoppable (100 days)
```

### **Login Streak Path:**

```
📅 Daily Devotee (7 days)
    ↓ Continue 23 more days
🗓️ Weekly Regular (30 days)
    ↓ Continue 70 more days
🎖️ Dedicated Explorer (100 days)
```

### **Quest Milestone Path:**

```
💯 Century Quester (100 total quests)
    ↓ Complete 150 more
🎯 Quest Veteran (250 total quests)
    ↓ Complete 250 more
👑 Quest Grandmaster (500 total quests)
```

### **Combo Path:**

```
Complete daily challenge + weekly goal on same day
    ↓ Do it 10 times
⚡ Combo Master (10 combos)
```

---

## 📊 **XP CALCULATION EXAMPLES**

### **Example 1: First Quest of the Day**

```
Base XP: 100
Quests completed today: 0 (this is the first)
Multiplier: 1.0x (no bonus yet)
Final XP: 100
```

### **Example 2: Second Quest of the Day**

```
Base XP: 100
Quests completed today: 1 (second quest)
Multiplier: 1.25x (+25% combo bonus)
Final XP: 125
```

### **Example 3: Third Quest of the Day**

```
Base XP: 100
Quests completed today: 2 (third quest)
Multiplier: 1.5x (+50% combo bonus)
Final XP: 150
```

### **Example 4: Daily + Weekly Combo**

```
Base XP: 100
Quests completed today: 1 (second quest)
Quest types: Daily challenge + Weekly goal
Multiplier: 1.25x (2 quests) + 0.25x (combo) = 1.5x
Final XP: 150
```

### **Example 5: Maximum Combo**

```
Base XP: 100
Quests completed today: 2 (third quest)
Quest types: Daily challenge + Weekly goal
Multiplier: 1.5x (3 quests) + 0.25x (combo) = 1.75x
Final XP: 175
```

---

## 🔄 **STREAK TRACKING SYSTEM**

### **Challenge Streaks:**

```
Day 1: Complete challenge ✅ → Streak: 1
Day 2: Complete challenge ✅ → Streak: 2
Day 3: Complete challenge ✅ → Streak: 3 → 🔥 Streak Starter badge!
Day 4: Complete challenge ✅ → Streak: 4
Day 5: Complete challenge ✅ → Streak: 5
Day 6: Complete challenge ✅ → Streak: 6
Day 7: Complete challenge ✅ → Streak: 7 → 🔥🔥 Streak Master badge!
Day 8: Miss challenge ❌ → Streak: 0 (reset)
```

### **Login Streaks:**

```
Day 1: Open app ✅ → Streak: 1 → +10 XP
Day 2: Open app ✅ → Streak: 2 → +15 XP
Day 3: Open app ✅ → Streak: 3 → +25 XP
Day 4: Open app ✅ → Streak: 4 → +25 XP
Day 5: Open app ✅ → Streak: 5 → +25 XP
Day 6: Open app ✅ → Streak: 6 → +25 XP
Day 7: Open app ✅ → Streak: 7 → +50 XP + 50 bonus = 100 XP!
                                → 📅 Daily Devotee badge!
```

### **Category Streaks:**

```
Photography Streak:
Day 1: Photo challenge ✅ → Streak: 1
Day 2: Photo challenge ✅ → Streak: 2
Day 3: Discovery challenge ✅ → Photography streak unchanged: 2
Day 4: Photo challenge ✅ → Streak: 3

Exploration Streak:
Day 1: Discovery challenge ✅ → Streak: 1
Day 2: Photo challenge ✅ → Exploration streak unchanged: 1
Day 3: Discovery challenge ✅ → Streak: 2
```

---

## 🎮 **USER JOURNEY EXAMPLES**

### **New User (Day 1):**

```
1. Opens app → +10 XP (first login)
2. Completes first daily challenge → +50 XP
   → 🎯 Quest Starter badge!
3. Total: 60 XP, Level 1, 1 badge
```

### **Active User (Day 7):**

```
1. Opens app → +100 XP (7-day streak + bonus)
   → 📅 Daily Devotee badge!
2. Completes daily challenge → +50 XP
   → 🔥🔥 Streak Master badge! (7-day challenge streak)
3. Completes weekly goal → +500 XP × 1.25 = 625 XP (combo bonus!)
4. Total: 775 XP gained, 3 new badges
```

### **Dedicated User (Day 30):**

```
1. Opens app → +150 XP (30-day streak + bonus)
   → 🗓️ Weekly Regular badge!
2. Completes daily challenge → +50 XP × 1.25 = 62 XP (2nd quest)
3. Completes weekly goal → +500 XP × 1.5 = 750 XP (3rd quest + combo!)
4. Completes 3rd weekly goal → +500 XP × 1.75 = 875 XP (max combo!)
   → 💎 Perfect Week badge!
5. Total: 1,837 XP gained, 2 new badges
```

### **Elite User (Day 100):**

```
1. Opens app → +550 XP (100-day streak + massive bonus)
   → 🎖️ Dedicated Explorer badge!
2. Completes 100th daily challenge → +50 XP × 1.25 = 62 XP
   → 🎖️ Quest Legend badge!
   → ⚡ Unstoppable badge! (100-day challenge streak)
3. Completes 100th total quest → 💯 Century Quester badge!
4. Total: 612 XP gained, 4 new badges
```

---

## 📈 **PROGRESSION TIMELINE**

### **Week 1:**

```
✅ Daily Devotee (7-day login)
✅ Streak Starter (3-day challenge)
✅ Streak Master (7-day challenge)
✅ Quest Starter (1 challenge)
✅ Weekly Warrior (1 weekly goal)
Possible: Quest Enthusiast (10 challenges)
```

### **Month 1:**

```
✅ Weekly Regular (30-day login)
✅ Streak Legend (30-day challenge)
✅ Quest Enthusiast (10 challenges)
✅ Weekly Champion (10 weekly goals)
✅ Perfect Week (all 3 goals)
Possible: Quest Master (50 challenges)
Possible: Century Quester (100 quests)
```

### **Month 3:**

```
✅ Dedicated Explorer (100-day login)
✅ Unstoppable (100-day challenge)
✅ Quest Master (50 challenges)
✅ Weekly Legend (25 weekly goals)
✅ Century Quester (100 quests)
✅ Combo Master (10 combos)
✅ Perfect Month (4 perfect weeks)
Possible: Quest Legend (100 challenges)
Possible: Quest Veteran (250 quests)
```

### **Year 1:**

```
✅ Quest Legend (100 challenges)
✅ Quest Veteran (250 quests)
Possible: Quest Grandmaster (500 quests)
```

---

## 🎯 **OPTIMIZATION STRATEGIES**

### **For Maximum XP:**

```
1. Log in every day (up to 550 XP on day 100)
2. Complete 3+ quests per day (1.5x multiplier)
3. Mix daily challenges and weekly goals (additional 0.25x)
4. Focus on high-XP weekly goals (500+ XP each)
5. Maintain challenge streaks (no direct XP, but badges)
```

### **For Maximum Badges:**

```
1. Never miss a day (login + challenge streaks)
2. Complete all 3 weekly goals every week (Perfect Week)
3. Do 4 perfect weeks in a row (Perfect Month)
4. Complete daily + weekly on same day 10 times (Combo Master)
5. Reach quest milestones (100, 250, 500)
```

### **For Category Mastery:**

```
1. Focus on one category per day
2. Track your category streaks
3. Build longest streaks in preferred categories
4. Diversify to unlock all category achievements
```

---

## 🎨 **VISUAL BADGE HIERARCHY**

```
RARITY LEVELS:

Common (Easy to get):
🎯 Quest Starter, ⚔️ Weekly Warrior, 🔥 Streak Starter, 📅 Daily Devotee

Uncommon (Moderate effort):
🎲 Quest Enthusiast, 🏆 Weekly Champion, 🔥🔥 Streak Master, 💎 Perfect Week

Rare (Significant commitment):
🏅 Quest Master, 👑 Weekly Legend, 🔥🔥🔥 Streak Legend, 🗓️ Weekly Regular,
💯 Century Quester

Epic (Long-term dedication):
🎖️ Quest Legend, ⚡ Unstoppable, 🎖️ Dedicated Explorer, 🌟 Perfect Month,
⚡ Combo Master, 🎯 Quest Veteran

Legendary (Elite achievement):
👑 Quest Grandmaster
```

---

## 🎊 **CELEBRATION MOMENTS**

### **Small Wins (Daily):**

- ✨ Daily login reward
- ✨ Quest completion
- ✨ Combo multiplier activation
- ✨ Category streak extension

### **Medium Wins (Weekly):**

- 🎉 Perfect Week achievement
- 🎉 Weekly goal completion
- 🎉 7-day streak milestone
- 🎉 New badge earned

### **Big Wins (Monthly):**

- 🎊 30-day streak milestone
- 🎊 Perfect Month achievement
- 🎊 Quest milestone reached
- 🎊 Multiple badges earned

### **Epic Wins (Long-term):**

- 🏆 100-day streak milestone
- 🏆 Quest Grandmaster achievement
- 🏆 All badges in category
- 🏆 Max level reached

---

**This visual guide provides a clear understanding of how all quest system features work together to create an engaging, rewarding user experience!** 🚀

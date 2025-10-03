# 🎯 ArtBeat Daily Quests System

## Overview

The Daily Quests system is a gamification feature that encourages users to engage with the ArtBeat app through daily challenges. Users complete quests to earn XP, build streaks, and unlock achievements.

## Features

### ✨ Core Features

1. **Daily Quest Generation**

   - One new quest per day
   - Personalized based on user level and history
   - Smart selection based on day of week (weekends favor exploration)
   - Difficulty scales with user progression

2. **Quest Types** (13 Different Types)

   - **Discovery Quests**: Find and explore new art
   - **Photography Quests**: Capture artworks with your camera
   - **Social Quests**: Share and engage with the community
   - **Walking Quests**: Stay active while exploring
   - **Time-Based Quests**: Complete activities at specific times
   - **Engagement Quests**: Write reviews and collect styles
   - **Streak Quests**: Maintain daily activity streaks

3. **Progression System**

   - XP rewards scale with user level
   - Quest difficulty increases as users level up
   - Streak bonuses for consistent completion
   - Milestone achievements

4. **Visual Design**
   - Beautiful gradient cards with animations
   - Real-time progress tracking
   - Completion celebrations
   - Quest history and statistics

## Quest Types Details

### 🔍 Discovery Quests

#### Art Explorer

- **Description**: Discover new pieces of public art
- **Base Target**: 3 artworks
- **Base Reward**: 50 XP
- **Tracking**: `recordArtDiscovery()`

#### Neighborhood Scout

- **Description**: Find art in different neighborhoods
- **Base Target**: 2 neighborhoods
- **Base Reward**: 65 XP
- **Tracking**: `recordNeighborhoodDiscovery(neighborhood)`

### 📸 Photography Quests

#### Photo Hunter

- **Description**: Take photos of different artworks
- **Base Target**: 5 photos
- **Base Reward**: 75 XP
- **Tracking**: `recordPhotoCapture()`

#### Golden Hour Artist

- **Description**: Capture artworks during sunrise or sunset
- **Base Target**: 3 photos
- **Base Reward**: 90 XP
- **Tracking**: `recordTimeBasedDiscovery()`
- **Time Window**: 5-7 AM or 5-7 PM

### 🤝 Social Quests

#### Art Sharer

- **Description**: Share art discoveries with friends
- **Base Target**: 2 shares
- **Base Reward**: 40 XP
- **Tracking**: `recordSocialShare()`

#### Community Connector

- **Description**: Comment on other users' discoveries
- **Base Target**: 3 comments
- **Base Reward**: 45 XP
- **Tracking**: `recordComment()`

### 🚶 Walking Quests

#### Urban Wanderer

- **Description**: Walk while exploring art
- **Base Target**: 2 km (2000 meters)
- **Base Reward**: 60 XP
- **Tracking**: `recordWalkDistance(meters)`

#### Step Master

- **Description**: Take steps on your art journey
- **Base Target**: 5000 steps
- **Base Reward**: 70 XP
- **Tracking**: `recordSteps(steps)`

### ⏰ Time-Based Quests

#### Early Bird Explorer

- **Description**: Discover art before 9 AM
- **Base Target**: 2 discoveries
- **Base Reward**: 55 XP
- **Tracking**: `recordTimeBasedDiscovery()`
- **Time Window**: Before 9 AM

#### Night Owl Artist

- **Description**: Capture illuminated artworks after sunset
- **Base Target**: 3 captures
- **Base Reward**: 80 XP
- **Tracking**: `recordTimeBasedDiscovery()`
- **Time Window**: After 6 PM

### 📝 Engagement Quests

#### Art Critic

- **Description**: Write detailed descriptions for artworks
- **Base Target**: 3 descriptions
- **Base Reward**: 50 XP
- **Tracking**: `recordDetailedDescription(description)`
- **Requirement**: Minimum 50 characters

#### Style Collector

- **Description**: Find art in different styles
- **Base Target**: 3 styles
- **Base Reward**: 85 XP
- **Tracking**: `recordStyleDiscovery(artStyle)`

### 🔥 Streak Quests

#### Streak Warrior

- **Description**: Complete any art activities to maintain streak
- **Base Target**: 2 activities
- **Base Reward**: 100 XP
- **Tracking**: `recordAnyActivity()`
- **Unlock**: Available after 7 completed challenges

## Difficulty Scaling

### Target Scaling by Level

- **Level 1-5**: Base targets (e.g., 3 artworks)
- **Level 6-10**: 1.2x targets (e.g., 4 artworks)
- **Level 11-20**: 1.5x targets (e.g., 5 artworks)
- **Level 21+**: 2x targets (e.g., 6 artworks)

### Reward Scaling by Level

- **Level 1-5**: Base rewards (e.g., 50 XP)
- **Level 6-10**: 1.3x rewards (e.g., 65 XP)
- **Level 11-20**: 1.6x rewards (e.g., 80 XP)
- **Level 21+**: 2x rewards (e.g., 100 XP)

## Implementation Guide

### 1. Service Layer

The `ChallengeService` handles all quest logic:

```dart
final challengeService = ChallengeService();

// Get today's quest
final quest = await challengeService.getTodaysChallenge();

// Update progress
await challengeService.recordArtDiscovery();
await challengeService.recordPhotoCapture();
await challengeService.recordWalkDistance(500.0); // 500 meters

// Get statistics
final stats = await challengeService.getChallengeStats();
final completionRate = await challengeService.getChallengeCompletionRate();
```

### 2. UI Components

#### DailyQuestCard Widget

Displays the current quest with progress and rewards:

```dart
DailyQuestCard(
  challenge: todaysChallenge,
  showTimeRemaining: true,
  showRewardPreview: true,
  onTap: () {
    // Navigate to quest history
  },
)
```

#### QuestHistoryScreen

Full-screen view of quest history and statistics:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const QuestHistoryScreen(),
  ),
);
```

### 3. Integration Points

#### When User Discovers Art

```dart
// In your art discovery logic
await challengeService.recordArtDiscovery();
await challengeService.recordTimeBasedDiscovery();
await challengeService.recordAnyActivity();
```

#### When User Takes Photo

```dart
// In your photo capture logic
await challengeService.recordPhotoCapture();
await challengeService.recordTimeBasedDiscovery();
```

#### When User Shares

```dart
// In your sharing logic
await challengeService.recordSocialShare();
await challengeService.recordAnyActivity();
```

#### When User Comments

```dart
// In your comment logic
await challengeService.recordComment();
await challengeService.recordAnyActivity();
```

#### When User Walks

```dart
// In your location tracking logic
await challengeService.recordWalkDistance(distanceInMeters);
await challengeService.recordSteps(stepCount);
```

## Database Structure

### Firestore Collections

```
users/{userId}/dailyChallenges/{dateKey}
  - id: string
  - userId: string
  - title: string
  - description: string
  - type: string (daily, weekly, monthly, special)
  - targetCount: number
  - currentCount: number
  - rewardXP: number
  - rewardDescription: string
  - isCompleted: boolean
  - createdAt: timestamp
  - expiresAt: timestamp
  - completedAt: timestamp (optional)
  - updatedAt: timestamp
```

### Date Key Format

```dart
final dateKey = '${year}-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';
// Example: '2025-06-01'
```

## Notifications

When a quest is completed, users receive a notification:

```dart
NotificationService().sendNotification(
  userId: userId,
  title: '🎉 Challenge Complete!',
  message: 'Art Explorer: 50 XP for exploring art!',
  type: NotificationType.achievement,
  data: {
    'challengeId': challengeId,
    'xpAwarded': 50,
  },
);
```

## Statistics & Analytics

### Available Stats

- Total quests completed
- Total XP earned from quests
- Current streak (consecutive days)
- Completion rate (percentage)
- Quest master level (Novice → Legend)

### Quest Master Levels

- **Novice**: 0-6 quests
- **Apprentice**: 7-29 quests
- **Expert**: 30-99 quests
- **Master**: 100-364 quests
- **Legend**: 365+ quests

### Milestones

- 🚩 First Quest (1 quest)
- 📅 Week Warrior (7 quests)
- 📆 Month Master (30 quests)
- 🏆 Century Club (100 quests)
- ⭐ Year Legend (365 quests)

## Best Practices

### 1. Quest Tracking

- Always call tracking methods after successful actions
- Handle errors gracefully (tracking failures shouldn't break user flow)
- Track multiple quest types when applicable

### 2. User Experience

- Show quest progress prominently on dashboard
- Celebrate completions with animations
- Provide clear instructions for each quest type
- Display time remaining for daily quests

### 3. Performance

- Cache today's quest to avoid repeated Firestore reads
- Use transactions for progress updates to prevent race conditions
- Batch multiple tracking calls when possible

### 4. Testing

```dart
// Test quest generation
final quest = await challengeService.getTodaysChallenge();
expect(quest, isNotNull);
expect(quest!.targetCount, greaterThan(0));

// Test progress tracking
await challengeService.recordArtDiscovery();
final updatedQuest = await challengeService.getTodaysChallenge();
expect(updatedQuest!.currentCount, equals(1));
```

## Future Enhancements

### Potential Features

1. **Weekly Quests**: Longer-term challenges with bigger rewards
2. **Special Events**: Limited-time quests for holidays/events
3. **Team Quests**: Collaborative challenges with friends
4. **Quest Chains**: Multi-step quests that unlock progressively
5. **Custom Quests**: User-created challenges
6. **Quest Marketplace**: Trade or gift quests with other users
7. **Seasonal Themes**: Quest types that change with seasons
8. **Location-Based Quests**: Quests specific to certain cities/regions

### Analytics to Track

- Most popular quest types
- Average completion time
- Drop-off points
- Quest difficulty balance
- User engagement correlation

## Troubleshooting

### Quest Not Appearing

- Check user authentication
- Verify Firestore permissions
- Check date key generation
- Review error logs

### Progress Not Updating

- Ensure tracking methods are called
- Check Firestore transaction success
- Verify challenge ID matches
- Check for race conditions

### Incorrect Difficulty

- Verify user level is correctly stored
- Check scaling calculations
- Review user stats retrieval

## Support

For questions or issues with the Daily Quests system:

1. Check the error logs in `AppLogger`
2. Review Firestore console for data issues
3. Test with different user levels
4. Verify all tracking methods are properly integrated

---

**Version**: 1.0.0  
**Last Updated**: June 2025  
**Maintainer**: ArtBeat Development Team

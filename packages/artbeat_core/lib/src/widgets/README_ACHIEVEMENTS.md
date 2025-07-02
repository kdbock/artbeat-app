# Achievement System Widgets

This document describes the new themed achievement system widgets added to enhance the dashboard experience.

## Components

### 1. AchievementRunner
A visually appealing, animated progress bar that displays user level progression with ARTbeat's themed colors.

**Features:**
- Animated progress with smooth transitions
- Pulsing animation for active progress
- Sparkle effects for visual appeal
- Themed gradient colors (Purple to Green to Teal)
- Progress indicator dot that moves along the bar
- Shine effect animation
- Level information display
- Next level preview

**Usage:**
```dart
AchievementRunner(
  progress: 0.7, // 0.0 to 1.0
  currentLevel: 3,
  experiencePoints: 350,
  levelTitle: 'Art Connoisseur',
  showAnimations: true,
  height: 40.0,
)
```

### 2. AchievementBadge
Individual achievement cards that can be unlocked or in progress.

**Features:**
- Unlocked/locked states with different visual treatments
- Progress tracking for partial achievements
- Interactive tap animations (scale and slight rotation)
- Themed colors and gradients
- Progress text display
- Custom icons and descriptions

**Usage:**
```dart
AchievementBadge(
  title: 'Art Hunter',
  description: 'Capture 5 artworks',
  icon: Icons.camera_alt,
  isUnlocked: false,
  progress: 0.6,
  showProgress: true,
  progressText: '3/5',
  customColor: ArtbeatColors.secondaryTeal,
)
```

### 3. AchievementBadgeList
A horizontal scrollable container for multiple achievement badges.

**Features:**
- Horizontal scrolling list
- Achievement counter (unlocked/total)
- Empty state handling
- Customizable padding and title

**Usage:**
```dart
AchievementBadgeList(
  achievements: achievementDataList,
  title: 'Recent Achievements',
  padding: EdgeInsets.all(16),
)
```

## Integration

### Dashboard Implementation
The achievement system has been integrated into the dashboard screen (`dashboard_screen.dart`) with:

1. **Enhanced Progress Bar**: Replaced the plain XP progress bar with the new `AchievementRunner` widget
2. **Achievement Section**: Added a new section displaying recent achievements using `AchievementBadgeList`
3. **Dynamic Achievement Generation**: Implemented `_getSampleAchievements()` method that creates achievements based on user activity

### Theme Integration
All components use the ARTbeat color scheme:
- **Primary Purple** (`#8C52FF`)
- **Primary Green** (`#00BF63`) 
- **Secondary Teal** (`#00BFA5`)
- **Accent Yellow** (`#FFD700`)
- **Success Green** for unlocked badges
- **Gradient combinations** for visual appeal

## Sample Achievements
The system includes several predefined achievements:
- **First Steps**: Create account (always unlocked)
- **Art Hunter**: Capture artworks (progress-based)
- **Art Enthusiast**: Reach specific level (level-based)
- **Explorer**: Discover artists (count-based)
- **Experience Master**: Earn XP (XP-based)
- **Community Member**: Join community (always unlocked)

## Animations
The system includes several animation types:
- **Progress Animation**: Smooth filling of progress bars
- **Pulse Animation**: Rhythmic scaling for active elements
- **Sparkle Animation**: Moving light effects on progress bars
- **Interaction Animation**: Scale and rotation on tap
- **Shine Effect**: Moving highlight across progress bars

## Customization
All components are highly customizable:
- Colors can be overridden per achievement
- Animation speeds and effects can be modified
- Heights and dimensions are configurable
- Custom icons and text are supported
- Progress calculation can be customized

This achievement system transforms the previously bland dashboard opening into an engaging, visually appealing experience that motivates users to interact more with the app.
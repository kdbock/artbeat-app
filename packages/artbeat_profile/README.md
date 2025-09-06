# ARTbeat Profile Module - User Guide

## Overview

The `artbeat_profile` module is the comprehensive user profile management system for the ARTbeat Flutter application. It handles all aspects of user profile functionality including creation, editing, viewing, social features, achievements, discovery, and advanced profile customization. This guide provides a complete walkthrough of every feature available to users.

> **Implementation Status**: This guide documents both implemented features (✅) and planned features (🚧). Recent major updates include new profile models and services for customization, activity tracking, and analytics.

## Table of Contents

1. [Implementation Status](#implementation-status)
2. [Core Profile Features](#core-profile-features)
3. [Profile Services](#profile-services)
4. [User Interface Components](#user-interface-components)
5. [Models & Data Structures](#models--data-structures)
6. [Social & Discovery Features](#social--discovery-features)
7. [Achievement System](#achievement-system)
8. [Advanced Profile Features](#advanced-profile-features)
9. [Architecture & Integration](#architecture--integration)
10. [Usage Examples](#usage-examples)

---

## Implementation Status

**Current Implementation: ~75% Complete** (Recently updated with new models and services)

### Legend

- ✅ **Fully Implemented** - Feature is complete and functional
- ⚠️ **Partially Implemented** - Core functionality exists but some methods missing
- 🚧 **Planned** - Feature documented but not yet implemented
- 📋 **In Development** - Currently being worked on
- 🔄 **Implemented in Other Module** - Feature exists in different package

### Quick Status Overview

- **Core Profile Management**: ✅ 95% implemented
- **Profile Models**: ✅ 100% implemented (5 new models added)
- **Profile Services**: ⚠️ 60% implemented (2 of 5 services complete)
- **UI Screens**: ✅ 85% implemented (12 screens functional)
- **Social Features**: ✅ 90% implemented
- **Achievement System**: ✅ 100% implemented
- **Advanced Customization**: 🚧 40% implemented (models ready, screens needed)
- **Privacy & Settings**: 🔄 Exists in artbeat_settings package

---

## Core Profile Features

### 1. Profile Creation & Management ✅

**Purpose**: Complete profile lifecycle from creation to advanced editing

**Screens Available**:

- ✅ `CreateProfileScreen` - Initial profile setup for new users (389 lines)
- ✅ `EditProfileScreen` - Comprehensive profile editing (565 lines)
- ✅ `ProfileViewScreen` - Profile viewing with tabbed content (647 lines)
- ✅ `ProfilePictureViewerScreen` - Full-screen profile image viewer

**Key Features**:

- ✅ Profile image upload and management
- ✅ Real-time profile updates
- ✅ Profile completeness tracking
- ✅ User data validation
- ✅ Cross-platform image optimization

**Available to**: All user types

### 2. Social & Discovery System ✅

**Purpose**: User discovery, following, and social interactions

**Screens Available**:

- ✅ `DiscoverScreen` - Advanced user discovery (945 lines - very comprehensive)
- ✅ `FollowersListScreen` - Followers management (199 lines)
- ✅ `FollowingListScreen` - Following management
- ✅ `ProfileTab` - Main profile interface

**Key Features**:

- ✅ Location-based user discovery
- ✅ Follow/unfollow functionality
- ✅ User search and filtering
- ✅ Featured content display
- ✅ Mutual connections tracking

**Available to**: All user types

### 3. Favorites Management ✅

**Purpose**: Content favoriting and collection management

**Screens Available**:

- ✅ `FavoritesScreen` - Favorites viewing (262 lines)
- ✅ `FavoriteDetailScreen` - Detailed favorite item view
- ❌ `UserFavoritesScreen` - **REMOVED** (was empty file)

**Key Features**:

- ✅ Favorite content across all types
- ✅ Organized favorites display
- ✅ Real-time favorite updates
- ✅ Cross-module favorite support

**Available to**: All user types

### 4. Achievement System ✅

**Purpose**: User achievement tracking and gamification

**Screens Available**:

- ✅ `AchievementsScreen` - Achievement display (487 lines - comprehensive)
- ✅ `AchievementInfoScreen` - Detailed achievement information

**Key Features**:

- ✅ Categorized achievements (Art Walk, Community, Capture, Profile)
- ✅ Achievement progress visualization
- ✅ Real-time achievement updates
- ✅ Achievement badge display

**Available to**: All user types

---

## Profile Services

### 1. Profile Customization Service ✅ **NEW**

**Purpose**: Manages profile themes, layout, and visual customization

**Key Functions**:

- ✅ `getCustomizationSettings(String userId)` - Get current settings
- ✅ `createDefaultSettings(String userId)` - Create default configuration
- ✅ `updateCustomizationSettings(ProfileCustomizationModel settings)` - Update settings
- ✅ `updateTheme(String userId, String theme, String primaryColor, String secondaryColor)` - Change theme
- ✅ `updateVisibilitySettings(String userId, Map<String, bool> settings)` - Privacy controls
- ✅ `updateCoverPhoto(String userId, String? coverPhotoUrl)` - Cover photo management
- ✅ `resetToDefaults(String userId)` - Reset customization

**Available to**: All user types

### 2. Profile Activity Service ✅ **NEW**

**Purpose**: Tracks profile interactions and activity feed

**Key Functions**:

- ✅ `recordActivity({required String userId, required String activityType, ...})` - Log activity
- ✅ `getProfileActivities(String userId, {int limit = 50, ...})` - Get activity history
- ✅ `getUnreadActivityCount(String userId)` - Unread activity count
- ✅ `markActivitiesAsRead(List<String> activityIds)` - Mark activities as read
- ✅ `markAllActivitiesAsRead(String userId)` - Mark all as read
- ✅ `deleteOldActivities(String userId, {int daysOld = 30})` - Cleanup old activities
- ✅ `streamProfileActivities(String userId, {int limit = 20, ...})` - Real-time stream

**Convenience Methods**:

- ✅ `recordProfileView(String viewedUserId, String viewerUserId, ...)` - Log profile views
- ✅ `recordFollow(String followedUserId, String followerUserId, ...)` - Log follow actions
- ✅ `recordUnfollow(String unfollowedUserId, String unfollowerUserId, ...)` - Log unfollow actions

**Available to**: All user types

### 3. Profile Analytics Service 🚧 **PLANNED**

**Purpose**: Personal profile analytics and insights for regular users

**Planned Functions**:

- 🚧 `getProfileAnalytics(String userId)` - Get profile insights
- 🚧 `getProfileViewStats(String userId)` - View statistics
- 🚧 `getEngagementMetrics(String userId)` - Engagement analytics
- 🚧 `getFollowerGrowth(String userId)` - Follower growth tracking

**Available to**: All user types (different from artist analytics)

### 4. Profile Connection Service 🚧 **PLANNED**

**Purpose**: Manages mutual connections and friend suggestions

**Planned Functions**:

- 🚧 `getMutualConnections(String userId1, String userId2)` - Find mutual connections
- 🚧 `getFriendSuggestions(String userId)` - Generate friend suggestions
- 🚧 `updateConnectionScore(String userId, String connectedUserId, double score)` - Update recommendation score

**Available to**: All user types

### 5. Legacy User Service (Profile-specific) ⚠️

**Purpose**: Profile-specific user operations (currently placeholder)

**Current Status**: Basic placeholder - most functionality delegated to `artbeat_core` UserService

**Available to**: All user types

---

## Models & Data Structures

### 1. ProfileCustomizationModel ✅ **NEW**

**Purpose**: Stores user profile customization preferences

**Key Properties**:

- ✅ `selectedTheme` - Selected theme name
- ✅ `primaryColor` / `secondaryColor` - Custom color scheme
- ✅ `coverPhotoUrl` - Cover photo URL
- ✅ `showBio` / `showLocation` / `showAchievements` / `showActivity` - Visibility toggles
- ✅ `layoutStyle` - Profile layout preference
- ✅ `visibilitySettings` - Granular privacy controls

### 2. ProfileActivityModel ✅ **NEW**

**Purpose**: Tracks all profile-related activities and interactions

**Key Properties**:

- ✅ `activityType` - Type of activity (follow, view, mention, etc.)
- ✅ `targetUserId` / `targetUserName` / `targetUserAvatar` - Who performed the action
- ✅ `description` - Human-readable activity description
- ✅ `metadata` - Additional activity context
- ✅ `isRead` - Read status for activity feed

### 3. ProfileAnalyticsModel ✅ **NEW**

**Purpose**: Personal profile analytics data (different from artist analytics)

**Key Properties**:

- ✅ `profileViews` - Total profile views
- ✅ `totalFollowers` / `totalFollowing` - Social stats
- ✅ `totalLikes` / `totalComments` / `totalShares` - Engagement stats
- ✅ `dailyViews` - Daily view breakdown
- ✅ `weeklyEngagement` - Weekly engagement metrics
- ✅ `topViewers` - Top profile viewers
- ✅ `engagementRate` (computed) - Engagement percentage

### 4. ProfileMentionModel ✅ **NEW**

**Purpose**: Tracks where users are mentioned across the platform

**Key Properties**:

- ✅ `mentionType` - Type of mention (post, comment, caption, bio)
- ✅ `mentionedByUserId` / `mentionedByUserName` - Who mentioned the user
- ✅ `contextId` - Reference to the content containing the mention
- ✅ `contextPreview` - Preview of the mention context
- ✅ `isRead` / `isDeleted` - Status flags
- ✅ `displayText` (computed) - Formatted mention description

### 5. ProfileConnectionModel ✅ **NEW**

**Purpose**: Manages profile connections and friend suggestions

**Key Properties**:

- ✅ `connectionType` - Type of connection (mutual_follower, suggestion, recent_interaction)
- ✅ `mutualFollowersCount` - Number of mutual followers
- ✅ `mutualFollowerIds` - List of mutual follower IDs
- ✅ `connectionScore` - Algorithm-based recommendation strength
- ✅ `connectionReason` - Why this connection is suggested
- ✅ `isHighPriority` (computed) - High-priority connection flag

---

## User Interface Components

### 1. ProfileHeader Widget ✅

**Purpose**: Custom profile-themed app bar

**Features**:

- ✅ Custom color scheme: Primary #00fd8a, Text/Icons #8c52ff
- ✅ Limelight font integration
- ✅ Customizable actions and navigation
- ✅ Search, chat, and developer mode options
- ✅ Responsive design

### 2. Screen Components ✅

**Current Screens** (12 total):

1. ✅ `ProfileTab` - Main profile interface
2. ✅ `ProfileViewScreen` - Profile viewing with tabs (647 lines)
3. ✅ `EditProfileScreen` - Profile editing interface (565 lines)
4. ✅ `CreateProfileScreen` - New user profile creation (389 lines)
5. ✅ `ProfilePictureViewerScreen` - Full-screen image viewer
6. ✅ `DiscoverScreen` - User discovery interface (945 lines)
7. ✅ `FollowersListScreen` - Followers management (199 lines)
8. ✅ `FollowingListScreen` - Following management
9. ✅ `FavoritesScreen` - Favorites viewing (262 lines)
10. ✅ `FavoriteDetailScreen` - Detailed favorite view
11. ✅ `AchievementsScreen` - Achievement display (487 lines)
12. ✅ `AchievementInfoScreen` - Achievement details

### 3. Missing Screens 🚧 **PLANNED**

**Priority 1 - Advanced Profile Features**:

1. 🚧 `ProfileCustomizationScreen` - Theme selection, layout options, personal branding
2. 🚧 `ProfileActivityScreen` - Activity feed and interaction history
3. 🚧 `ProfileAnalyticsScreen` - Personal profile insights and analytics

**Priority 2 - Social Enhancement**: 4. 🚧 `ProfileConnectionsScreen` - Mutual connections and friend suggestions 5. 🚧 `ProfileMentionsScreen` - Where user has been mentioned 6. 🚧 `ProfileHistoryScreen` - Profile view history and interaction tracking

**Priority 3 - Data Management**: 7. 🚧 `ProfileBackupScreen` - Data export/import and account backup

---

## Advanced Profile Features

### 1. Profile Customization System 🚧

**Status**: Models implemented ✅, Services implemented ✅, Screens needed 🚧

**Features**:

- ✅ Theme selection with custom color schemes
- ✅ Profile layout customization
- ✅ Cover photo management
- ✅ Visibility controls for profile sections
- 🚧 Real-time preview of customizations
- 🚧 Theme marketplace and sharing

### 2. Profile Analytics & Insights 🚧

**Status**: Models implemented ✅, Services needed 🚧, Screens needed 🚧

**Features**:

- ✅ Profile view tracking
- ✅ Engagement rate calculations
- ✅ Follower growth metrics
- 🚧 Analytics dashboard
- 🚧 Performance recommendations
- 🚧 Comparison with similar profiles

### 3. Activity Feed System ✅/🚧

**Status**: Models implemented ✅, Services implemented ✅, Screens needed 🚧

**Features**:

- ✅ Real-time activity tracking
- ✅ Activity categorization
- ✅ Read/unread status management
- ✅ Batch operations for activities
- 🚧 Activity feed UI
- 🚧 Activity filtering and search

### 4. Connection & Mention System 🚧

**Status**: Models implemented ✅, Services needed 🚧, Screens needed 🚧

**Features**:

- ✅ Mention tracking across platform
- ✅ Connection scoring algorithm
- ✅ Mutual connection detection
- 🚧 Friend suggestion engine
- 🚧 Mention notifications
- 🚧 Connection management UI

---

## Architecture & Integration

### Package Structure

```
lib/
├── artbeat_profile.dart         # Main entry point
├── src/
│   ├── models/                  # Profile-specific models (5 new models)
│   │   ├── profile_customization_model.dart  ✅
│   │   ├── profile_activity_model.dart       ✅
│   │   ├── profile_analytics_model.dart      ✅
│   │   ├── profile_mention_model.dart        ✅
│   │   └── profile_connection_model.dart     ✅
│   ├── services/                # Profile-specific services
│   │   ├── user_service.dart                 ⚠️ (placeholder)
│   │   ├── profile_customization_service.dart ✅
│   │   ├── profile_activity_service.dart      ✅
│   │   ├── profile_analytics_service.dart     🚧
│   │   └── profile_connection_service.dart    🚧
│   ├── screens/                 # UI screens (12 implemented)
│   │   ├── [existing 12 screens]             ✅
│   │   ├── profile_customization_screen.dart 🚧
│   │   ├── profile_activity_screen.dart      🚧
│   │   ├── profile_analytics_screen.dart     🚧
│   │   ├── profile_connections_screen.dart   🚧
│   │   ├── profile_mentions_screen.dart      🚧
│   │   └── profile_backup_screen.dart        🚧
│   └── widgets/                 # Reusable UI components
│       └── profile_header.dart              ✅
```

### Integration Points

#### With Other Packages

- ✅ **artbeat_core** - Uses core UserService, models, and utilities
- ✅ **artbeat_auth** - Post-authentication profile creation flow
- ✅ **artbeat_capture** - Profile integration with capture features
- ✅ **artbeat_artwork** - Artist profile artwork integration
- ✅ **artbeat_community** - Social features and community integration
- 🔄 **artbeat_settings** - Settings screens exist there (privacy, security, notifications)

#### Avoiding Duplication

**Existing in artbeat_settings** (don't recreate):

- ❌ Profile Settings Screen (exists as stub)
- ❌ Privacy Settings Screen (exists as stub)
- ❌ Security Settings Screen (exists as stub)
- ❌ Account Settings Screen (exists as stub)
- ❌ Notification Settings Screen (exists as stub)

**Existing in artbeat_messaging**:

- ❌ Blocked Users Screen (fully implemented - 332 lines)

---

## Usage Examples

### Basic Profile Operations

```dart
import 'package:artbeat_profile/artbeat_profile.dart';

// Navigate to profile view
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProfileViewScreen(
      userId: 'user_id_here',
      isCurrentUser: false,
    ),
  ),
);

// Navigate to profile editing
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EditProfileScreen(
      userId: currentUserId,
      onProfileUpdated: () {
        // Handle profile update
      },
    ),
  ),
);
```

### Profile Customization

```dart
// Get customization service
final customizationService = ProfileCustomizationService();

// Update user theme
await customizationService.updateTheme(
  userId,
  'dark_mode',
  '#ff6b35',  // Custom primary color
  '#004643',  // Custom secondary color
);

// Update visibility settings
await customizationService.updateVisibilitySettings(userId, {
  'showEmail': false,
  'showPhone': false,
  'showLocation': true,
  'showBirthdate': false,
});
```

### Activity Tracking

```dart
// Get activity service
final activityService = ProfileActivityService();

// Record profile view
await activityService.recordProfileView(
  viewedUserId: 'target_user_id',
  viewerUserId: 'current_user_id',
  viewerName: 'John Doe',
  viewerAvatar: 'https://example.com/avatar.jpg',
);

// Get activity feed
final activities = await activityService.getProfileActivities(
  userId,
  limit: 20,
  unreadOnly: false,
);

// Stream real-time activities
StreamBuilder<List<ProfileActivityModel>>(
  stream: activityService.streamProfileActivities(userId),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return ListView.builder(
        itemCount: snapshot.data!.length,
        itemBuilder: (context, index) {
          final activity = snapshot.data![index];
          return ListTile(
            title: Text(activity.description ?? ''),
            subtitle: Text(activity.createdAt.toString()),
          );
        },
      );
    }
    return CircularProgressIndicator();
  },
)
```

---

## Performance Considerations

### Optimizations Implemented ✅

- Cached network images for profile pictures
- Lazy loading of user lists and activities
- Efficient Firestore queries with proper indexing
- State management with Provider pattern
- Pagination for large datasets

### Best Practices ✅

- Image optimization and compression
- Real-time data streaming where appropriate
- Error handling with user feedback
- Loading states for better UX
- Memory management for large lists

---

## Security & Privacy

### Data Protection ✅

- Secure user data handling with proper validation
- Profile privacy controls through customization service
- Image upload validation and security
- Authentication verification for all operations

### Access Control ✅

- User-specific data access with proper authorization
- Profile visibility settings through customization model
- Following/followers privacy controls
- Achievement privacy options

---

## Testing

### Test Coverage

**Implemented**:

- ✅ Unit tests for profile services
- ✅ Widget tests for key screens
- ✅ Mock services for testing isolation

**Test Focus Areas**:

- Profile creation and editing flows
- Social feature functionality (follow/unfollow)
- Achievement system integration
- Data validation and error handling
- Real-time activity tracking
- Profile customization operations

---

## Recent Updates (September 2025)

### ✅ Major Additions

1. **5 New Profile Models** - Complete data structures for advanced features
2. **2 New Services** - ProfileCustomizationService and ProfileActivityService
3. **Removed Redundant File** - Eliminated empty user_favorites_screen.dart
4. **Updated Documentation** - Comprehensive README following core module format

### 🚧 Next Priorities

1. Complete remaining 2 services (Analytics and Connection)
2. Implement 6 missing screens for advanced features
3. Integration testing with other modules
4. Performance optimization for large datasets

---

_This package is part of the ARTbeat application ecosystem and is designed to work seamlessly with other ARTbeat packages. For questions about feature availability or integration, refer to the main ARTbeat documentation._

#### Discovery & Search

- ✅ User and artist discovery
- ✅ Location-based discovery
- ✅ Search functionality
- ✅ Featured content display

## Dependencies

### Core Dependencies

- `artbeat_core` - Core models, services, and utilities
- `artbeat_auth` - Authentication services
- `artbeat_capture` - Capture-related functionality
- `artbeat_artwork` - Artwork models and services
- `artbeat_artist` - Artist profiles and features
- `artbeat_community` - Community features

### External Dependencies

- `firebase_auth` - User authentication
- `firebase_storage` - Profile image storage
- `cloud_firestore` - Data persistence
- `image_picker` - Profile image selection
- `cached_network_image` - Optimized image loading
- `provider` - State management
- `geolocator` - Location services
- `url_launcher` - External link handling

## Architecture

### Package Structure

```
lib/
├── artbeat_profile.dart         # Main entry point
├── src/
│   ├── models/                  # Data models (currently empty - uses core models)
│   ├── services/                # Profile-specific services
│   │   └── user_service.dart    # Profile user service operations
│   ├── screens/                 # UI screens
│   │   ├── profile_tab.dart
│   │   ├── profile_view_screen.dart
│   │   ├── edit_profile_screen.dart
│   │   ├── create_profile_screen.dart
│   │   ├── profile_picture_viewer_screen.dart
│   │   ├── discover_screen.dart
│   │   ├── followers_list_screen.dart
│   │   ├── following_list_screen.dart
│   │   ├── favorites_screen.dart
│   │   ├── user_favorites_screen.dart
│   │   ├── favorite_detail_screen.dart
│   │   ├── achievements_screen.dart
│   │   └── achievement_info_screen.dart
│   └── widgets/                 # Reusable UI components
│       └── profile_header.dart
```

## Integration Points

### Authentication Integration

- Seamless integration with `artbeat_auth` package
- Post-authentication profile creation flow
- User session management

### Core Service Integration

- Uses `UserService` from `artbeat_core` for data operations
- Integrates with achievement system
- Capture and artwork integration

### Navigation Integration

- Profile tab in main navigation
- Deep linking to specific profiles
- Cross-package navigation support

## Current Status

### ✅ Implemented Features

- Complete profile management lifecycle
- Social following system
- Favorites management
- Achievement display system
- User discovery and search
- Location-based features
- Profile image management
- Custom UI theming

### 🔄 Areas for Enhancement

- Profile analytics and insights
- Advanced privacy controls
- Profile verification system
- Enhanced social features
- Profile customization options
- Import/export functionality

## Usage Example

```dart
import 'package:artbeat_profile/artbeat_profile.dart';

// Navigate to profile view
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProfileViewScreen(
      userId: 'user_id_here',
      isCurrentUser: false,
    ),
  ),
);

// Navigate to profile editing
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EditProfileScreen(
      userId: currentUserId,
      onProfileUpdated: () {
        // Handle profile update
      },
    ),
  ),
);
```

## Testing

The package includes:

- Unit tests for profile services
- Widget tests for key screens
- Mock services for testing

Test coverage focuses on:

- Profile creation and editing flows
- Social feature functionality
- Achievement system integration
- Data validation and error handling

## Performance Considerations

### Optimizations Implemented

- Cached network images for profile pictures
- Lazy loading of user lists
- Efficient Firestore queries
- State management with Provider

### Best Practices

- Image optimization for profile pictures
- Pagination for large datasets
- Error handling with user feedback
- Loading states for better UX

## Security & Privacy

### Data Protection

- Secure user data handling
- Profile privacy controls
- Image upload validation
- Authentication verification

### Access Control

- User-specific data access
- Profile visibility settings
- Following/followers privacy
- Achievement privacy options

---

_This package is part of the ARTbeat application ecosystem and is designed to work seamlessly with other ARTbeat packages._

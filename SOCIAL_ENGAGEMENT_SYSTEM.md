# ARTbeat Social Engagement System

## Overview

This document outlines the comprehensive social engagement system implemented for the ARTbeat platform. The system provides content-specific engagement options that enhance user interaction and community building.

## Engagement Types by Content

### 1. Captures (Street Art, Public Art)

**Primary Engagement Options:**

- ❤️ **Like** - Express appreciation for the capture
- 💬 **Comment** - Share thoughts about the artwork
- 📤 **Share** - Share the capture with others
- 👁️ **Seen** - Track views and discovery

**Secondary Engagement Options:**

- ⭐ **Rate** - Rate the quality of the capture
- 📝 **Review** - Write detailed reviews

### 2. Artworks (Original Art Pieces)

**Primary Engagement Options:**

- ❤️ **Like** - Show appreciation for the artwork
- 💬 **Comment** - Discuss the artwork
- 📤 **Share** - Share with the community
- 🎁 **Gift** - Send virtual gifts to the artist

**Secondary Engagement Options:**

- ↩️ **Reply** - Reply to comments
- ⭐ **Rate** - Rate the artwork
- 📝 **Review** - Write detailed reviews
- 👁️ **Seen** - Track artwork views

### 3. Artists (Artist Profiles)

**Primary Engagement Options:**

- ❤️ **Like** - Like the artist's profile
- 👤 **Follow** - Follow the artist for updates
- 🎁 **Gift** - Send gifts to support the artist
- 💬 **Message** - Direct message the artist

**Secondary Engagement Options:**

- 🤝 **Sponsor** - Become a patron/sponsor
- 🎨 **Commission** - Request commissioned work

### 4. Events (Art Events, Exhibitions)

**Primary Engagement Options:**

- ❤️ **Like** - Show interest in the event
- 💬 **Comment** - Discuss the event
- 📤 **Share** - Share event details
- 👁️ **Seen** - Track event views

**Secondary Engagement Options:**

- ↩️ **Reply** - Reply to event comments
- ⭐ **Rate** - Rate the event (after attendance)
- 📝 **Review** - Write event reviews

### 5. Posts (Community Posts)

**Primary Engagement Options:**

- ❤️ **Like** - Like the post
- 💬 **Comment** - Comment on the post
- ↩️ **Reply** - Reply to comments
- 📤 **Share** - Share the post

### 6. Comments (Individual Comments)

**Primary Engagement Options:**

- ❤️ **Like** - Like the comment
- 💬 **Comment** - Comment on the comment
- ↩️ **Reply** - Reply to the comment

## Technical Implementation

### Core Components

#### 1. EngagementModel (`artbeat_core/models/engagement_model.dart`)

- Defines all engagement types and their properties
- Handles serialization to/from Firestore
- Provides display names, icons, and past tense forms

#### 2. EngagementStats (`artbeat_core/models/engagement_model.dart`)

- Tracks counts for all engagement types
- Supports backward compatibility with legacy fields
- Includes monetary values for gifts and sponsorships

#### 3. EngagementConfigService (`artbeat_core/services/engagement_config_service.dart`)

- Configures which engagement types are available for each content type
- Separates primary and secondary engagement options
- Handles special engagement types that require custom dialogs

#### 4. ContentEngagementBar (`artbeat_core/widgets/content_engagement_bar.dart`)

- Universal engagement widget that adapts to content type
- Supports both compact and full display modes
- Handles user interactions and state management

### Enhanced Screens

#### 1. SocialEngagementDemoScreen

**Location:** `packages/artbeat_community/lib/screens/feed/social_engagement_demo_screen.dart`

- Demonstrates all engagement types for each content type
- Interactive examples with real engagement bars
- Educational overview of the system

#### 2. EnhancedCommunityFeedScreen

**Location:** `packages/artbeat_community/lib/screens/feed/enhanced_community_feed_screen.dart`

- Comprehensive feed showing all content types
- Tabbed interface for filtering by content type
- Real engagement interactions for each content type

#### 3. Enhanced Artist Community Feed

**Location:** `packages/artbeat_community/lib/screens/feed/artist_community_feed_screen.dart`

- Updated with modern engagement buttons for artist profiles
- Includes Like, Follow, Gift, Sponsor, Message, and Commission options
- Enhanced UI with better visual hierarchy

#### 4. EnhancedArtworkCard

**Location:** `packages/artbeat_community/lib/widgets/enhanced_artwork_card.dart`

- Modern artwork card with full engagement system
- Displays artwork details, pricing, and tags
- Integrated ContentEngagementBar for artwork-specific interactions

## Key Features

### 1. Content-Aware Engagement

- Each content type has its own set of appropriate engagement options
- Primary actions are prominently displayed
- Secondary actions are available but less prominent

### 2. Visual Design

- Consistent iconography using basic, recognizable icons
- Color-coded engagement types for better UX
- Responsive design that works in compact and full modes

### 3. Special Engagement Handling

- Gift system with emoji-based virtual gifts
- Sponsorship tiers (Bronze, Silver, Gold)
- Commission request system
- Direct messaging integration

### 4. Analytics & Tracking

- Comprehensive engagement statistics
- Monetary value tracking for gifts and sponsorships
- View count and engagement rate metrics

### 5. Backward Compatibility

- Supports legacy engagement field names
- Smooth migration from old applause/appreciate system
- Maintains existing data while adding new features

## Usage Examples

### Basic Engagement Bar

```dart
ContentEngagementBar(
  contentId: 'artwork_123',
  contentType: 'artwork',
  initialStats: artworkStats,
  showSecondaryActions: true,
)
```

### Compact Mode

```dart
ContentEngagementBar(
  contentId: 'comment_456',
  contentType: 'comment',
  initialStats: commentStats,
  isCompact: true,
)
```

### Custom Handlers

```dart
ContentEngagementBar(
  contentId: 'artist_789',
  contentType: 'artist',
  initialStats: artistStats,
  customHandlers: {
    EngagementType.message: () => openDirectMessage(),
    EngagementType.commission: () => showCommissionForm(),
  },
)
```

## Benefits

1. **Enhanced User Engagement** - More ways for users to interact with content
2. **Artist Support** - Direct monetization through gifts and sponsorships
3. **Community Building** - Encourages meaningful interactions and connections
4. **Content Discovery** - Better engagement leads to improved content visibility
5. **Platform Growth** - More engaging platform attracts and retains users

## Future Enhancements

1. **Engagement Analytics Dashboard** - For artists to track their engagement metrics
2. **Engagement Notifications** - Real-time notifications for new engagements
3. **Engagement Rewards** - Gamification system for active community members
4. **Advanced Filtering** - Filter content by engagement levels
5. **Engagement API** - External integrations for engagement data

This social engagement system transforms ARTbeat from a simple art sharing platform into a vibrant, interactive community where artists and art enthusiasts can meaningfully connect and support each other.

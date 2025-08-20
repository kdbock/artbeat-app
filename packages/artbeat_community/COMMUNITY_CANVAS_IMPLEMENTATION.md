# Community Canvas Implementation

## Overview

Community Canvas is a comprehensive redesign of the ARTbeat community dashboard, transforming it into a group-based social media platform for artists and art enthusiasts.

## Features Implemented

### 1. Group-Based Architecture

The platform is organized into four main groups:

#### Artist Groups

- **Purpose**: Browse and discover community artists, then view their individual feeds
- **Features**:
  - Artist directory with profiles, locations, and specialties
  - Individual artist community feeds showing their posts
  - Artist verification badges and featured status
  - Medium and style tags for easy discovery
  - Direct navigation to artist-specific content

#### Event Groups

- **Purpose**: Discover and share art events and exhibitions
- **Features**:
  - Event hosting and attending posts
  - Event details (date, location, type)
  - Ticket information and attendee management
  - Event photo sharing

#### Art Walk Adventure Group

- **Purpose**: Share public art discoveries and walking routes
- **Features**:
  - Up to 5 photos per art walk post
  - Route information (distance, duration, difficulty)
  - Landmark tracking
  - Location-based discoveries

#### Artist Wanted Group

- **Purpose**: Connect artists with project opportunities
- **Features**:
  - Project requests with budget and deadline
  - Required skills and experience level
  - Application system for artists
  - Urgent project flagging

### 2. Post Types and Interactions

#### Universal Post Features

- User avatar, name, verification status
- Post creation date and location
- Content with hashtag support
- Image galleries (scrollable)
- Interaction buttons: Appreciate, Comment, Share

#### Specialized Post Content

Each group type has specialized fields and display formats:

- **Artist Posts**: Artwork details, pricing, techniques
- **Event Posts**: Event information, attendance tracking
- **Art Walk Posts**: Route details, difficulty ratings
- **Artist Wanted Posts**: Project requirements, application system

### 3. User Interface Components

#### Dashboard Structure

- **Header**: "Community Canvas" with search, chat, and developer tools
- **Tab Navigation**: Four tabs for each group type with appropriate icons
- **Group Headers**: Dynamic headers showing current group information
- **Floating Action Button**: Context-aware post creation

#### Post Cards

- **Responsive Design**: Cards adapt to different post types
- **Visual Hierarchy**: Clear information organization
- **Action Buttons**: Appreciate, Comment, Share with counters
- **Group Badges**: Color-coded badges indicating post type

#### Create Post Interface

- **Modal Selection**: Bottom sheet with post type options
- **Specialized Forms**: Different forms for each post type
- **Image Support**: Photo upload capabilities
- **Validation**: Form validation for required fields

### 4. Data Models

#### Base Group Post Model

```dart
abstract class BaseGroupPost {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String content;
  final List<String> imageUrls;
  final List<String> hashtags;
  final String location;
  final DateTime createdAt;
  final int appreciateCount;
  final int commentCount;
  final int shareCount;
  final bool isPublic;
  final bool isUserVerified;
}
```

#### Specialized Models

- **ArtistGroupPost**: Extends base with artwork-specific fields
- **EventGroupPost**: Extends base with event-specific fields
- **ArtWalkAdventurePost**: Extends base with route-specific fields
- **ArtistWantedPost**: Extends base with project-specific fields

### 5. Firebase Integration

#### Collections Structure

- `group_posts`: Main collection for all group posts
- `group_posts/{postId}/appreciations`: User appreciations
- `group_posts/{postId}/comments`: Post comments
- `users`: User profile information

#### Query Patterns

- Posts filtered by `groupType` field
- Public posts only (`isPublic: true`)
- Ordered by creation date (newest first)
- Paginated loading (10 posts per page)

### 6. Navigation and UX

#### Tab-Based Navigation

- Scrollable tabs for four group types
- Visual indicators for active group
- Smooth transitions between groups

#### Search Integration

- Group-specific search options
- Artist, artwork, event, and project search
- Modal search interface

#### Responsive Design

- Gradient backgrounds
- Loading states and error handling
- Empty state messaging
- Pull-to-refresh functionality

## Technical Implementation

### Key Files Created/Modified

1. **Models**
   - `lib/models/group_models.dart` - All group post models
2. **Widgets**
   - `lib/widgets/group_feed_widget.dart` - Feed display for each group
   - `lib/widgets/group_post_card.dart` - Individual post cards
   - `lib/widgets/create_post_fab.dart` - Floating action button
   - `lib/widgets/artist_list_widget.dart` - Artist directory listing
3. **Screens**
   - `lib/screens/community_dashboard_screen.dart` - Main dashboard (redesigned)
   - `lib/screens/feed/create_group_post_screen.dart` - Post creation
   - `lib/screens/feed/artist_community_feed_screen.dart` - Individual artist feeds

### Dependencies Used

- `cloud_firestore` - Database operations
- `firebase_auth` - User authentication
- `intl` - Date formatting
- `artbeat_core` - Shared components and theming

## Future Enhancements

### Phase 1 (Immediate)

- Complete post creation forms for each group type
- Implement comment system
- Add image upload functionality
- User profile integration

### Phase 2 (Short-term)

- Push notifications for interactions
- Advanced search and filtering
- Moderation tools
- Analytics and insights

### Phase 3 (Long-term)

- AI-powered content recommendations
- Advanced matching for Artist Wanted posts
- Integration with ARTbeat's other modules
- Social features (following, direct messaging)

## Usage

The Community Canvas is now integrated into the ARTbeat app as the main community dashboard. Users can:

1. Navigate between different group types using the tab interface
2. View posts specific to each group with specialized content
3. Create new posts using the floating action button
4. Interact with posts through appreciate, comment, and share actions
5. Search for specific content using the enhanced search modal

The implementation maintains consistency with ARTbeat's design system while providing a rich, group-based social media experience tailored for the art community.

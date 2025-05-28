<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# ARTbeat Flutter App

This is a Flutter application called "ARTbeat" (formerly "WordNerd") that implements a complete authentication flow using Firebase Authentication. The app follows a specific screen sequence:

## Application Flow
- Loading Screen → Splash Screen → Login/Registration → Dashboard

## Project Structure
- `lib/main.dart`: Entry point of the application, initializes Firebase
- `lib/firebase_options.dart`: Generated Firebase configuration options
- `lib/models/`: Contains data models
  - `user_model.dart`: Model for user profile data
  - `artist_profile_model.dart`: Model for artist profiles with subscription tier data
  - `artwork_model.dart`: Model for artist artwork metadata
  - `art_walk_model.dart`: Model for collections of public art organized as walks
  - `public_art_model.dart`: Model for public art pieces with location data
  - `comment_model.dart`: Model for comments on posts and artwork
  - `commission_model.dart`: Model for commission agreements between galleries and artists
  - `event_model.dart`: Model for artist events and gallery exhibitions
  - `favorite_model.dart`: Model for user favorites
  - `gallery_invitation_model.dart`: Model for gallery invitations to artists
  - `notification_model.dart`: Model for user notifications
  - `payment_method_model.dart`: Model for Stripe payment methods
  - `post_model.dart`: Model for social posts
  - `subscription_model.dart`: Model for artist and gallery subscriptions
- `lib/services/`: Contains service classes
  - `analytics_service.dart`: Service for tracking and retrieving analytics data
  - `artwork_service.dart`: Service for artwork management
  - `art_walk_service.dart`: Service for managing public art and art walks
  - `commission_service.dart`: Service for managing gallery-artist commissions
  - `community_service.dart`: Service for social features and interactions
  - `event_service.dart`: Service for event management
  - `gallery_invitation_service.dart`: Service for artist invitation management
  - `notification_service.dart`: Service for notification management
  - `payment_service.dart`: Service for Stripe payment integrations
  - `subscription_service.dart`: Service for managing artist subscriptions
  - `user_service.dart`: Service for user-related operations
- `lib/widgets/`: Contains reusable widget components
  - `art_walk_info_card.dart`: Onboarding card for first-time Art Walk users
  - `local_artists_row_widget.dart`: Displays local artists in a horizontal scrollable row
  - `local_artwork_row_widget.dart`: Shows artwork with images, titles, and prices
  - `local_art_walk_preview_widget.dart`: Shows a Google Maps preview of art walks
  - `artist_subscription_cta_widget.dart`: Displays a promotional card for artists
  - `upcoming_events_row_widget.dart`: Displays upcoming events filtered by location
  - `featured_content_row_widget.dart`: Shows featured articles and content
  - `local_galleries_widget.dart`: Displays galleries and museums in a grid
- `lib/screens/`: Contains all screen implementations
  - `loading_screen.dart`: Initial loading screen with circular progress indicator
  - `splash_screen.dart`: Branded splash screen that checks authentication status
  - `authentication/`: Authentication-related screens
    - `login_screen.dart`: Email/password login form with Firebase Auth
    - `register_screen.dart`: User registration form with Firebase Auth
    - `forgot_password_screen.dart`: Password recovery using Firebase Auth
  - `dashboard_screen.dart`: Main app dashboard showing user info
  - `discover_screen.dart`: User discovery and search functionality
  - `artist/`: Artist and Gallery related screens
    - `analytics_dashboard_screen.dart`: Analytics for artist performance
    - `artist_browse_screen.dart`: Browse artists in the platform
    - `artist_dashboard_screen.dart`: Dashboard for artist and gallery business accounts
    - `artist_public_profile_screen.dart`: Public-facing artist profile
    - `artist_profile_edit_screen.dart`: Edit artist profile details
    - `artwork_detail_screen.dart`: Detailed view of artwork with metadata
    - `artwork_upload_screen.dart`: Upload and manage artwork
    - `artwork_browse_screen.dart`: Browse artwork with filtering options
    - `event_creation_screen.dart`: Create and manage gallery events
    - `gallery_analytics_dashboard_screen.dart`: Analytics dashboard for gallery performance metrics
    - `gallery_artists_management_screen.dart`: Gallery owner tools for managing artists with bulk invitation
    - `payment_methods_screen.dart`: Manage Stripe payment methods
    - `payment_screen.dart`: Process payments for subscriptions
    - `refund_request_screen.dart`: Submit and manage subscription refund requests
    - `subscription_analytics_screen.dart`: Analytics for subscription performance
    - `subscription_comparison_screen.dart`: Compare subscription tiers side by side
    - `subscription_screen.dart`: Subscription plan selection and management
  - `art_walk/`: Art Walk related screens
    - `art_walk_map_screen.dart`: Shows public art on an interactive Google map
    - `art_walk_list_screen.dart`: Browse created and popular art walks
    - `art_walk_detail_screen.dart`: View details of a specific art walk
    - `create_art_walk_screen.dart`: Create and edit custom art walks
  - `capture/`: Content capture-related screens
    - `camera_screen.dart`: Camera interface for capturing text from images
    - `capture_list_screen.dart`: List of all user's captured content
    - `capture_detail_screen.dart`: Detailed view of captured content with editing options
    - `capture_edit_screen.dart`: Form for editing captured content
  - `profile/`: Profile-related screens
    - `profile_view_screen.dart`: User profile view with photo, bio, stats, and posts
    - `edit_profile_screen.dart`: Form for editing profile information
    - `profile_picture_viewer_screen.dart`: Full-screen profile picture viewer
    - `followers_list_screen.dart`: List of users following the current user
    - `following_list_screen.dart`: List of users followed by the current user
    - `favorites_screen.dart`: Collection of items the user has favorited
  - `settings/`: Settings-related screens
    - `settings_screen.dart`: Main settings hub with navigation to all settings pages
    - `account_settings_screen.dart`: Username, email, phone, and password management
    - `privacy_settings_screen.dart`: Profile visibility and interaction permissions
    - `notification_settings_screen.dart`: Email, push, and in-app notification preferences
    - `security_settings_screen.dart`: Login alerts and device activity management
    - `blocked_users_screen.dart`: Management of blocked users with unblock capability

## Firebase Implementation
The app uses Firebase services with the following features:
- Firebase Authentication
  - Email/Password authentication
  - Password reset functionality
  - Persistent authentication across app restarts
  - User profile management (display name)
  - Error handling for various authentication scenarios
- Cloud Firestore
  - User profile data storage
  - Follow/following relationships
  - Favorites collection management
  - Realtime data updates
- Firebase Storage
  - Profile and cover photo storage
  - Image upload functionality integrated with the app

## Firebase Configuration Details
- Project name: ARTbeat
- Project ID: wordnerd-artbeat
- Project number: 665020451634
- Web API Key: AIzaSyAWORLK8SxG6IKkaA5CaY2s3J2OIJ_36TA
- Android App ID: 1:665020451634:android:70aaba9b305fa17b78652b
- App nickname: ARTbeat
- Package name: com.wordnerd.artbeat

## Stripe Integration
- Stripe Publishable Key: pk_live_51QpJ6iAO5ulTKoALLtQFut6aQIyhLvrcUWRgA8RINvB6xwa37NeKymcV5lM96Yg6oOXvMQuwjPzP5LbE6I5ktHWG00Xk24gmn2
- Payment processing for subscriptions and artwork purchases
- Customer management and recurring billing
- Secure payment method storage
- Webhook integration for payment events

## Profile Features
The app includes a complete user profile system with:
- Profile viewing with stats (posts, followers, following)
- Profile editing capabilities (name, bio, location, etc.)
- Profile and cover photo management using image_picker
- Followers and following lists with follow/unfollow functionality
- Photo viewing with zoom functionality
- Favorites collection to save and manage items of interest
- Profile actions for quick access to user-specific features

## Settings Features
The app includes comprehensive user settings with:
- Account management (username, email, phone number, password)
- Two-factor authentication options
- Privacy controls (profile visibility, follower permissions)
- Notification preferences for various interaction types
- Security settings with login alerts and device management
- Blocked users management with unblocking capability

## Social and Discovery Features
The app includes user discovery and social features:
- User search functionality by username and name
- Suggested users to follow
- Follow/unfollow mechanisms with real-time updates
- Real-time follower and following counts
- Favorites system for saving items of interest
- Profile action buttons for quick access to key features

## Technical Configurations
- Android configuration: minSdkVersion 23, ndkVersion 27.0.12077973
- iOS configuration: Minimum deployment target iOS 13.0
- Firebase project ID: wordnerd-artbeat
- Package name: com.wordnerd.artbeat

## Dependencies
- firebase_core: For Firebase initialization
- firebase_auth: For authentication functionality
- cloud_firestore: For database operations
- firebase_storage: For image and file storage
- image_picker: For selecting profile and cover images
- flutter: For the UI framework
- flutter_stripe: For payment processing integration
- http: For API calls to cloud functions
- intl: For date and number formatting
- provider: For state management
- shared_preferences: For local storage
- google_maps_flutter: For displaying interactive maps in Art Walk feature
- geolocator: For getting the user's current location
- geocoding: For converting coordinates to human-readable addresses
- share_plus: For sharing art walks with others

## Progress So Far

- Added `FavoritesScreen` and `FavoriteDetailScreen` with navigation flow, favorites feature now working.
- Implemented `getUserFavorites` and `getFavoriteById` in `UserService`, and fixed related compile errors.
- Switched Firestore writes in `updateDisplayName` and `updateUserProfile` to use `set(..., SetOptions(merge: true))` to prevent not-found errors.
- Added `assets/default_profile.png` to `pubspec.yaml` to fix image loading errors.
- Suggested Firestore emulator setup for testing and updated security rules guidance.
- Updated Firestore security rules to include support for user favorites and captures.
- Fixed the issue with `UserModel` property names by standardizing to use `fullName` instead of `name`.
- Created a new "capture" branch for implementing the content capture feature.

## Progress Update (May 2025)
- Added complete payment methods management with Stripe integration:
  - Created PaymentMethodModel for simplified representation of Stripe payment methods
  - Implemented PaymentMethodsScreen for listing, adding, and removing payment methods
  - Added cloud functions for Stripe operations (createSetupIntent, getPaymentMethods, etc.)
  - Updated Firestore security rules to support payment and subscription operations
- Added artist and gallery subscription functionality:
  - Implemented subscription tier management (Artist Basic, Artist Pro, Gallery)
  - Created event management system for galleries to create and manage exhibitions
  - Updated ArtistDashboardScreen with conditional premium features based on subscription tier
  - Added analytics for subscription performance
- Added comprehensive test files for gallery management functionality

## Firestore & Storage Rules Update (May 2025)
- Firestore rules now allow authenticated users to comment on posts (read, create, update, delete their own comments).
- Ensure all post and capture documents include a `userId` field matching the authenticated user for successful writes.
- Firebase Storage rules require proper path structures:
  - Profile images: `/profile_images/{userId}/{fileName}`
  - Capture images: `/capture_images/{userId}/{fileName}`
  - Post images: `/post_images/{fileName}`
  - Artwork images: `/artwork_images/{userId}/{artworkId}/{fileName}`
- All image upload code must match these path structures to prevent permission errors.

## Community Features (May 2025)
- Added modern inline commenting system for posts with collapsible comment sections.
- Fixed post likes functionality with proper error handling in `CommunityService`.
- Added required indexes for comment queries (parentCommentId + createdAt).
- Improved batch transaction handling for likes to ensure atomic updates.
- All comment UI is handled through `CommentInputWidget` and `CommentListWidget` components.

## Artist Subscription Features (May 2025)
The app now includes a subscription-based model for artists with the following features:

### User Types
- Regular User (existing)
- Artist (new)
- Gallery Business (new)

### Subscription Tiers
- **Artist Basic Plan (Free)**:
  - Artist profile page
  - Up to 5 artwork listings
  - Basic analytics
  - Community features

- **Artist Pro Plan ($9.99/month)**:
  - Unlimited artwork listings
  - Featured in discover section
  - Advanced analytics
  - Priority support
  - Event creation and promotion

- **Gallery Plan ($49.99/month)**:
  - Multiple artist management
  - Business profile for galleries
  - Advanced analytics dashboard
  - Dedicated support
  - All Pro features

### Artist Dashboard Screens
- Internal profile management
- External public profile
- Edit profile functionality
- Gallery for artwork uploads with metadata
- Storefront with external links (Etsy, personal sites)
- Social media feed integration
- Personal calendar for exhibits and events
- Subscription settings and analytics

## Progress Update (May 18, 2025)
- Completed user notification system for subscription events:
  - Implemented comprehensive notification handling for subscription renewals and payment issues
  - Added notification preferences specific to artist and gallery accounts in notification settings
  - Enhanced notification settings UI to show subscription-related options based on user type
  - Created scheduled cloud functions to check for subscription expiration and send timely reminders
  - Added notification support for approaching artwork limits to improve user experience
  - Updated Firebase webhook handlers to respect user notification preferences

## Progress Update (May 19, 2025)
- Enhanced gallery management features:
  - Added bulk artist invitation system in gallery artists management screen:
    - Added functionality to search and select multiple artists
    - Implemented batch invitation sending with custom messages
    - Created invitation tracking and cancellation capabilities
  - Implemented commission tracking between galleries and artists:
    - Created `CommissionModel` with support for variable commission rates
    - Built `CommissionService` with CRUD operations for commissions
    - Added UI for setting and managing commission rates for each artist
    - Implemented commission status tracking (pending, active, cancelled)
  - Created advanced analytics dashboard for gallery performance metrics:
    - Developed `GalleryAnalyticsDashboardScreen` with multiple visualization components
    - Implemented overview metrics showing KPIs (sales, revenue, commissions)
    - Created time-based revenue trend charts with filtering options
    - Added artist performance comparison table for identifying top performers
    - Built commission summary section with pending/paid breakdowns
  - Enhanced `AnalyticsService` with gallery-specific methods:
    - Added support for gallery metrics aggregation
    - Implemented artist performance comparison data
    - Created time-series data generation for visualizations
    - Added commission metrics calculations

## Progress Update (May 19, 2025 - Afternoon)
- Implemented complete Art Walk feature:
  - Created `PublicArtModel` and `ArtWalkModel` to store art and walk data
  - Implemented `ArtWalkService` with methods for creating, viewing, and managing art walks
  - Developed UI screens for exploring public art on maps (`ArtWalkMapScreen`)
  - Added screens for browsing, creating and viewing art walks
  - Enhanced existing capture functionality to support public art with location data
  - Added Google Maps integration for displaying art on interactive maps
  - Added route generation between art pieces with distance and time estimation
  - Created onboarding card (`ArtWalkInfoCard`) for first-time users
  - Integrated Art Walk into main dashboard and discover screens
  - Added proper navigation flows between capture and Art Walk features
  - Updated permissions in AndroidManifest.xml and iOS Info.plist for location services
  - Created comprehensive documentation (ART_WALK_README.md and ART_WALK_SUMMARY.md)

## Progress Update (May 20, 2025)
- Implemented Achievement Badges for Art Walk completion:
  - Added "Complete Art Walk" button to Art Walk detail screen
  - Created visual feedback to show walk completion status
  - Implemented proper achievement awarding and tracking
  - Added achievements navigation in the profile screen
  - Created notification system to alert users of new achievements
  - Enhanced achievement display with animations and proper feedback
  - Connected achievements to the user profile system
  - Added a direct navigation option from achievement notifications
  - Implemented badge display with proper categorization by type
  - Created visual distinction between bronze, silver, and gold tier achievements

## Progress Update (May 24-26, 2025)
- Enhanced Dashboard UI components:
  - Created a complete redesigned dashboard with location-aware data
  - Improved `LocalArtistsRowWidget` with better error handling and visual design:
    - Added verified badges for certified artists with blue borders
    - Added featured artist indicators with amber borders
    - Improved empty states with helpful messaging
    - Enhanced error handling with descriptive UI feedback
    - Optimized image loading with fallback placeholder support
  - Enhanced `LocalArtworkRowWidget` with proper cards and item details:
    - Implemented card-based design with elevation and rounded corners
    - Added price display for artwork with proper formatting
    - Added "SOLD" badge for artwork that is no longer for sale
    - Improved image error handling with placeholder support
    - Added artist name fetching with proper error handling
  - Implemented `LocalGalleriesWidget` with better UI for gallery display:
    - Created responsive grid layout for galleries and museums
    - Added featured and verified badges for trusted galleries
    - Implemented location display with map icon
    - Added truncation for long descriptions with ellipsis
    - Enhanced empty state with browse all galleries option
  - Created `ArtworkBrowseScreen` with filtering by location and medium:
    - Implemented dual dropdown filters for location and medium
    - Added location-aware filtering based on user's ZIP code
    - Created searchable artwork title functionality
    - Implemented responsive grid layout with consistent styling
    - Added proper loading, error, and empty states
  - Added proper route definitions for browse screens in main.dart
  - Fixed permission issues and Firebase configuration
  - Enhanced artist profile displays with verified and featured badges
  - Added proper Firestore queries with error handling and empty states
  - Updated widget designs across the app for more consistent UI
  - Fixed navigation between dashboard sections and detail screens

## Firestore Indexes Update (May 26, 2025)
- Successfully implemented the following Firestore indexes:
  - ✅ artWalks: userId + createdAt (for user art walks)
  - ✅ artWalks: isPublic + viewCount (for popular art walks)
  - ✅ artwork: location + createdAt (for local artwork by creation date)
  - ✅ artwork: location + medium (for filtered artwork searches)
  - ✅ artistProfiles: location + userType (for local galleries)
  - ✅ events: location + startDate (for upcoming events in a location)
  - ✅ posts: userId + createdAt (for user's posts in profile)
  - ✅ posts: trending + createdAt (for trending content)
  - ✅ comments: parentCommentId + createdAt (for comment threads)
  - ✅ artwork: title + createdAt (for artwork title search)
  - ✅ artwork: medium + createdAt (for artwork medium filtering)
  - ✅ featuredContent: isActive + publishedAt (for featured content display)
  - ✅ artistProfiles: userType + displayName (for gallery/artist sorting)
  - ✅ commissions: galleryId + status + createdAt (for gallery commission tracking)
  - ✅ commissions: artistId + status + createdAt (for artist commission tracking)

- Added new indexes for performance optimization:
  - Commission filtering by status
  - Artwork filtering by title (for search functionality) 
  - Artist sorting by name
  - Feature content display with active status

## Next Steps

1. Enhance Art Walk feature:
   - Improve route creation with real walking directions from Google Directions API
   - Add social features like comments and ratings on art walks
   - ✅ Create achievement badges for users who complete art walks
   - Implement backend validation for uploaded public art
   - Add caching for offline art walk viewing
   - Replace placeholder Google Maps API keys with real ones for production

2. Finalize the artist and gallery subscription management:
   - Optimize subscription upgrade/downgrade flows with proper UI feedback
   - Enhance refund request management system with approval workflows
   - Add subscription usage metrics to help users track their consumption
   - Implement tiered pricing discounts for longer subscription commitments

3. Expand gallery management capabilities:
   - Add inventory management system for physical artwork tracking
   - Implement sales target tracking and forecasting for galleries
   - Create exhibition planning tools with timeline visualization
   - Add artist royalty distribution tracking for ongoing sales
   - Integrate art walk creation into gallery event promotion

4. Establish user types as admin, basic user, artist, gallery, and investor:
   - Implement role-based access control for different features
   - Create admin dashboard for managing users and content
   - Implement user reporting and moderation tools
   - Add user feedback and rating system for artists and galleries
   - Develop investor-specific features for art investment tracking

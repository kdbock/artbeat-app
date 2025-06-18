# ARTbeat Community Module

The Community Module provides social features for ARTbeat app users, allowing artists to share their work, engage with the community, receive feedback, and discover other artists.

## Features

### Feed
- **Community Feed**: View and interact with posts from the community
- **Social Feed**: Personalized feed based on the user's interests and follows
- **Create Post**: Create new posts with images, text, location, and tags
- **Trending Content**: Discover trending content with filters by time frame and category
- **Comments**: Comment on posts with structured feedback types (Critique, Appreciation, Question, Tip)

### Moderation
- **Moderation Queue**: Review flagged posts and comments for content that violates community guidelines

### Other Features
- **Gifts**: Send themed gifts that carry real monetary value to artists
- **Portfolios**: View artist portfolios with collections of artworks
- **Studios**: Join topic-based or location-based real-time chat rooms
- **Commissions**: Browse and create custom art requests with budget specifications
- **Sponsorships**: Brands and patrons can sponsor artists or events

## Architecture

This module follows a clean architecture approach with the following structure:
- `models`: Data models representing entities in the application
- `services`: Business logic and data access
- `controllers`: State management
- `screens`: UI components for each feature
- `widgets`: Reusable UI components

## Running as a Standalone App

The Community Module can be run as a standalone app for development and testing:

```bash
# From the root directory of the ARTbeat project
cd packages/artbeat_community
flutter run -t lib/bin/main.dart
```

## Key Components

### Applause System
Instead of traditional likes, ARTbeat uses an Applause system that allows users to tap up to 5 times per post to show different levels of appreciation.

### Feedback Threads
Comments are structured into feedback threads that can be categorized by type:
- Critique: Constructive feedback to improve the artwork
- Appreciation: Positive comments about the artwork
- Question: Questions about technique, materials, etc.
- Tip: Helpful suggestions for improvement

### Palette Gifts
Artists can receive themed gifts that carry real value:
- Mini Palette ($1)
- Brush Pack ($5)
- Gallery Frame ($20)
- Golden Canvas ($50+)

## Dependencies
- Flutter & Dart
- Firebase (Auth, Firestore, Storage)
- Provider for state management
- Stripe for payment processing
- Google Maps for location features
- Various UI and utility packages

## Development Notes
- All API keys in the code are for development only and should be replaced in production
- Some features may require configuration of Firebase and other external services

## Related Modules
- artbeat_core: Core functionality and shared resources
- artbeat_auth: Authentication features
- artbeat_artist: Artist-specific features
- artbeat_artwork: Artwork management features

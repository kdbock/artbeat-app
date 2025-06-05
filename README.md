# ARTbeat - Creative Content Discovery Platform

ARTbeat is a comprehensive Flutter application that serves as a platform for creative content discovery, artist showcasing, and community engagement. The app features robust authentication, social networking, and specialized features for artists, galleries, and art enthusiasts.

![ARTbeat Logo](assets/default_profile.png)

> **⚠️ SECURITY NOTICE:** This application requires configuration of sensitive Firebase and Google Maps API keys. For security:
> 1. Never commit `firebase_options.dart` to version control
> 2. Use `firebase_options.template.dart` as a template
> 3. Store sensitive keys in environment variables
> 4. See [Firebase Configuration](#firebase-configuration) section below for secure setup instructions

## Table of Contents

- [Features](#features)
  - [Authentication Flow](#authentication-flow)
  - [Profile System](#profile-system)
  - [Artist Subscription Tiers](#artist-subscription-tiers)
  - [Gallery Management](#gallery-management)
  - [Art Walk Feature](#art-walk-feature)
  - [Social Features](#social-features)
  - [Settings & Preferences](#settings--preferences)
  - [Notification System](#notification-system)
  - [Payment Integration](#payment-integration)
  - [Offline Support](#offline-support)
- [Technical Architecture](#technical-architecture)
  - [Project Structure](#project-structure)
  - [Data Models](#data-models)
  - [Services](#services)
- [Firebase Implementation](#firebase-implementation)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Running the App](#running-the-app)
- [Development](#development)
  - [Code Conventions](#code-conventions)
  - [Testing](#testing)
  - [Continuous Integration](#continuous-integration)
- [Contributing](#contributing)
- [License](#license)

## Features

### Authentication Flow
The app follows a specific screen sequence:
- Loading Screen → Splash Screen → Login/Registration → Dashboard
- Complete Firebase Authentication with email/password login, registration, and password recovery
- Persistent authentication across app restarts

### Profile System
- User profiles with stats (posts, followers, following)
- Profile editing capabilities (name, bio, location)
- Profile and cover photo management
- Followers and following lists
- Photo viewing with zoom functionality
- Favorites system for saving content

### Artist Subscription Tiers
The app supports three subscription tiers for artists:

**Artist Basic Plan (Free)**
- Artist profile page
- Up to 5 artwork listings
- Basic analytics
- Community features

**Artist Pro Plan ($9.99/month)**
- Unlimited artwork listings
- Featured in discover section
- Advanced analytics
- Priority support
- Event creation and promotion

**Gallery Plan ($49.99/month)**
- Multiple artist management
- Business profile for galleries
- Advanced analytics dashboard
- Dedicated support
- All Pro features

### Gallery Management
- Bulk artist invitation system
- Commission tracking between galleries and artists
- Advanced analytics dashboard for gallery performance metrics
- Event creation and management for exhibitions

### Art Walk Feature
The Art Walk feature allows users to discover, document, and share public art throughout their city.

**Key Components:**
1. **Public Art Capture**
   - Photo capture with metadata like artist name and description
   - Automatic location tagging

2. **Art Discovery**
   - Interactive map interface for browsing public art
   - Location-based filtering and discovery

3. **Custom Art Walks**
   - Create personalized art walking routes
   - Add multiple art pieces to a single walk
   - Public and private sharing options

4. **Walking Directions**
   - Real walking directions via Google Directions API
   - Distance and time estimates
   - Turn-by-turn route display

### Social Features
- User search functionality
- Follow/unfollow mechanisms
- Real-time updates for social interactions
- Modern inline commenting system for posts
- Like functionality with proper error handling
- Content sharing capabilities

### Settings & Preferences
- Account management (username, email, phone, password)
- Two-factor authentication options
- Privacy controls for profile visibility
- Notification preferences
- Security settings and device management
- Blocked users management

### Notification System
- Comprehensive notification handling for various events
- Subscription-related notifications:
  - Renewal reminders
  - Payment confirmations
  - Subscription expiration warnings
  - Artwork limit notifications
- Fine-grained user control over notification preferences

### Payment Integration
- Complete Stripe integration for subscription management
- Multiple payment methods support
- Secure payment processing
- Subscription management interface

### Offline Support
- Firebase offline persistence
- Local data caching
- Graceful handling of network interruptions
- Offline-friendly UI indicators

## Technical Architecture

### Project Structure
```
lib/
├── firebase_options.dart  # Firebase configuration
├── main.dart              # App entry point
├── models/                # Data models
├── screens/               # UI screens
│   ├── loading_screen.dart
│   ├── splash_screen.dart
│   ├── authentication/    # Auth screens
│   ├── dashboard_screen.dart
│   ├── discover_screen.dart
│   ├── artist/            # Artist related screens
│   ├── art_walk/          # Art Walk related screens
│   ├── capture/           # Content capture screens
│   ├── profile/           # Profile related screens
│   └── settings/          # Settings screens
├── services/              # Business logic services
├── utils/                 # Utility functions
└── widgets/               # Reusable UI components
```

### Data Models
- User profiles and authentication data
- Artist profiles with subscription information
- Artwork metadata
- Public art and art walks
- Social interactions (comments, likes)
- Gallery and commission data
- Subscription and payment information

### Services
- Authentication and user management
- Artwork and artist management
- Art walk and discovery services
- Payment processing with Stripe
- Social interaction handling
- Analytics tracking
- Notification management
- Offline data caching

## Firebase Implementation
The app leverages multiple Firebase services:
- **Firebase Authentication** for user management
- **Cloud Firestore** for data storage and real-time updates
- **Firebase Storage** for media storage
- **Firebase Functions** for server-side logic
- **Firebase Analytics** for usage tracking
- **Firestore Security Rules** for data protection

## Getting Started

### Prerequisites
- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Android Studio / Xcode for native development
- Firebase project with Authentication, Firestore, and Storage enabled
- Google Maps API key (for Art Walk feature)
- Stripe account (for payment processing)

### Installation
1. Clone this repository
   ```
   git clone https://github.com/your-username/artbeat-app.git
   ```
2. Navigate to the project directory
   ```
   cd artbeat-app
   ```
3. Install dependencies
   ```
   flutter pub get
   ```
4. Set up Firebase:
   - Create a Firebase project
   - Add Android and iOS apps with the package name `com.example.emptytemplate`
   - Download and place the configuration files
   - Enable Authentication, Firestore, and Storage

5. Configure Google Maps (for Art Walk):
   - Get a Google Maps API key
   - Enable Directions API
   - Replace placeholder API keys in the Android and iOS configurations

6. Configure Stripe (for payments):
   - Set up a Stripe account
   - Follow the instructions in STRIPE_SETUP_GUIDE.md

### Running the App
```
flutter run
```

## Development

### Code Conventions
- Follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use the provider pattern for state management
- Keep UI and business logic separate
- Document public APIs and complex functionality

### Testing
```
flutter test
```

### Continuous Integration
The project uses GitHub Actions for CI/CD.

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

# Firebase Configuration

For security reasons, Firebase configuration details should not be committed to version control. Follow these steps to set up Firebase securely:

1. Copy the template file:
   ```bash
   cp lib/firebase_options.template.dart lib/firebase_options.dart
   ```

2. Get your Firebase configuration:
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Select your project
   - Go to Project Settings
   - Add your app if not already added
   - Get the configuration details

3. Update `lib/firebase_options.dart` with your Firebase details:
   ```dart
   static const FirebaseOptions currentPlatform = FirebaseOptions(
     apiKey: 'YOUR_API_KEY',             // ⚠️ From Firebase Console
     appId: 'YOUR_APP_ID',               // ⚠️ From Firebase Console
     messagingSenderId: 'YOUR_SENDER_ID', // ⚠️ From Firebase Console
     projectId: 'YOUR_PROJECT_ID',        // ⚠️ From Firebase Console
   );
   ```

4. Add `lib/firebase_options.dart` to `.gitignore`:
   ```bash
   echo "lib/firebase_options.dart" >> .gitignore
   ```

> **🔒 Security Best Practices:**
> - Never commit `firebase_options.dart` to version control
> - Consider using environment variables for production deployments
> - Regularly rotate API keys
> - Use Firebase Security Rules to protect your data
> - Enable only the Firebase services you need
> - Monitor Firebase Console for unusual activity

For CI/CD environments, use environment variables or secure secret storage to manage these keys.

# ARTbeat Flutter App — Copilot & Contributor Guide

## Overview
ARTbeat is a modular Flutter application for artists, galleries, and art lovers. It provides artist and gallery management, artwork discovery, social community, public art walks, and more. The codebase is organized into feature-based packages for maintainability, scalability, and parallel development.

---

## Modular Architecture
Each feature is a standalone Flutter package in `packages/`. All modules depend on `artbeat_core` for shared models, services, and utilities. Cross-dependencies are explicit in each module's `pubspec.yaml`.

### Main Modules
- **artbeat_core**: Shared models, services, and utilities
- **artbeat_auth**: Authentication (login, registration, password recovery)
- **artbeat_profile**: User profiles, followers, favorites, achievements
- **artbeat_artist**: Artist & gallery dashboards, subscriptions, analytics, commissions
- **artbeat_artwork**: Artwork upload, management, browsing, moderation, sales
- **artbeat_art_walk**: Public art walks, Google Maps, location-based discovery, achievements
- **artbeat_community**: Social feed, posts, comments, engagement, moderation
- **artbeat_settings**: Account, privacy, notification, and security settings

---

## What Each Module Does

### artbeat_core
- Models: User, artist, artwork, event, commission, notification, etc.
- Services: User, notification, payment, analytics, subscription, etc.
- Utilities: Common helpers, Firebase config

### artbeat_auth
- Login, registration, password reset screens
- Firebase Auth integration
- Secure token management

### artbeat_profile
- Profile view/edit, followers/following, photo management
- Favorites collection, achievements display
- Widgets: Local artists/artwork rows, galleries grid, featured content

### artbeat_artist
- Artist/galleries dashboards, analytics, event management
- Subscription tiers (Basic, Pro, Gallery)
- Commission tracking, artist invitation, payment methods

### artbeat_artwork
- Artwork upload, browse, filter (location, medium, title)
- Image moderation, sales, commission tracking
- Responsive grid UI, price display, sold status

### artbeat_art_walk
- Art walk creation, browsing, and detail
- Google Maps integration, route generation
- Achievement badges for walk completion
- Location-aware onboarding and navigation

### artbeat_community
- Social feed, posts, inline comments, likes
- Moderation tools, batch transactions for likes
- Widgets: Post cards, comment input/list, applause button

### artbeat_settings
- Account, privacy, notification, and security settings
- Blocked users management
- Preferences for artists/galleries

---

## Key Features & Flows
- **Authentication**: Email/password, persistent login, error handling
- **Profile**: View/edit, followers, favorites, achievements, photo upload
- **Artist/Gallery**: Dashboards, analytics, event & commission management, subscription plans
- **Artwork**: Upload, browse, filter, sales, moderation
- **Art Walk**: Map-based discovery, route planning, achievements
- **Community**: Social feed, comments, likes, moderation
- **Settings**: Account, privacy, notification, security
- **Payments**: Stripe integration for subscriptions, purchases, payment methods

---

## How to Use & Extend
- Each module exports its public API via its main Dart file
- Add new features in the correct module, update exports, and route tables
- Use relative imports within modules
- Unit tests go in each module; integration tests in the main app
- See `docs/` for detailed guides on modularization, API, and features

---

## Upcoming Features & Roadmap
- Complete profile editing and followers system
- Biometric authentication
- Advanced analytics for artists/galleries
- More artwork filters and search
- Enhanced moderation and reporting tools
- Community engagement features (badges, trending posts)
- Gallery bulk artist invitation and commission management
- More achievement badges and onboarding flows
- Improved settings and notification preferences

---

## Contribution Guidelines
- Follow modular structure and update exports
- Write clear, maintainable code and tests
- Document new features in the appropriate module and in `docs/`
- Use Firestore and Storage paths as per security rules
- Keep dependencies up to date in each module's `pubspec.yaml`

---

For more, see the `docs/` folder and each module's README. This file is always up to date with the latest architecture and features.

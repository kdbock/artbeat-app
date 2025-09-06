# Package Responsibility Matrix

## Phase 2 Integration Improvements - Clear Responsibilities

This document clarifies the responsibilities between `artbeat_core` and `artbeat_artist` packages to resolve conflicts and improve integration.

## 📦 Package Responsibilities

### `artbeat_core` Package

**Primary Role**: Foundation services and shared functionality

#### Responsibilities:

- ✅ **Basic User Management** - UserModel, UserService
- ✅ **Basic Subscription Plans** - SubscriptionTier, SubscriptionService
- ✅ **Artist Discovery** - Enhanced ArtistService with search and profiles
- ✅ **Payment Processing** - Stripe integration, PaymentService
- ✅ **Authentication** - Firebase Auth integration
- ✅ **Storage & Media** - File uploads, image optimization
- ✅ **Theme & UI Components** - Shared design system

#### Models:

- `UserModel` - Core user data
- `ArtistProfileModel` - **Primary artist profile model**
- `SubscriptionModel` - Core subscription data
- `SubscriptionTier` - Subscription tier definitions

#### Services:

- `ArtistService` - **Primary artist service** (enhanced with search)
- `UserService` - User management
- `SubscriptionService` - Basic subscription management
- `PaymentService` - Payment processing

---

### `artbeat_artist` Package

**Primary Role**: Artist-specific features and workflows

#### Responsibilities:

- ✅ **Artist Dashboard & Analytics** - Specialized artist UI and analytics
- ✅ **Gallery Management** - Gallery invitations, events, exhibitions
- ✅ **Earnings & Payouts** - Artist financial tracking and payments
- ✅ **Artist Workflows** - Onboarding, profile editing, portfolio management
- ✅ **Artist Subscription Features** - Enhanced subscription functionality for artists
- ✅ **Cross-Package Integration** - IntegrationService for unified data

#### Models:

- `EarningsModel` - Artist earnings and financial data
- `GalleryInvitationModel` - Gallery invitation system
- `PayoutModel` - Artist payout management
- `EventModel` - Artist events and exhibitions
- `SubscriptionModel` - **Artist-specific subscription data** (extends core)

#### Services:

- `AnalyticsService` - Artist-specific analytics
- `EarningsService` - Artist financial management
- `SubscriptionService` - **Artist-enhanced subscription features**
- `GalleryInvitationService` - Gallery management
- `EventService` - Artist event management
- `IntegrationService` - **Cross-package data unification**

---

## 🔄 Integration Strategy

### Resolved Conflicts:

#### 1. ✅ ArtistService Consolidation

**Problem**: Duplicate ArtistService implementations
**Solution**:

- `artbeat_core.ArtistService` → **Primary service** (enhanced with search)
- `artbeat_artist.ArtistService` → **Deprecated** (migration guide provided)

#### 2. ✅ ArtistProfileModel Usage

**Problem**: Two different ArtistProfileModel implementations
**Solution**:

- `artbeat_core.ArtistProfileModel` → **Primary model** (comprehensive)
- `artbeat_artist.ArtistProfileModel` → **Hidden from exports** (internal use only)

#### 3. ✅ Subscription Responsibilities

**Problem**: Overlapping subscription functionality
**Solution**:

- `artbeat_core.SubscriptionService` → **Basic subscription management**
- `artbeat_artist.SubscriptionService` → **Artist-enhanced features**
- `IntegrationService` → **Unified subscription capabilities**

#### 4. ✅ Cross-Package Communication

**Problem**: Difficult to coordinate between packages
**Solution**:

- `IntegrationService` → **Single point for cross-package operations**
- `UnifiedArtistData` → **Combined data from both packages**
- `SubscriptionCapabilities` → **Unified feature access logic**

---

## 📋 Migration Guide

### For ArtistService Usage:

```dart
// OLD (artbeat_artist) - DEPRECATED
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
final service = artist.ArtistService();
final artists = await service.getFeaturedArtists();

// NEW (artbeat_core) - RECOMMENDED
import 'package:artbeat_core/artbeat_core.dart';
final service = ArtistService();
final artists = await service.getFeaturedArtistProfiles(); // Enhanced with search
```

### For Cross-Package Operations:

```dart
// NEW - Unified Integration
import 'package:artbeat_artist/artbeat_artist.dart';

final integration = IntegrationService.instance;
final unifiedData = await integration.getUnifiedArtistData(userId);
final capabilities = await integration.getSubscriptionCapabilities(userId);

if (capabilities.canAccessAnalytics) {
  // User has analytics access from either package
}
```

### For Subscription Management:

```dart
// Core subscription (basic plans)
final coreService = SubscriptionService(); // from artbeat_core
final basicSub = await coreService.getUserSubscription();

// Artist subscription (enhanced features)
final artistService = artist.SubscriptionService(); // from artbeat_artist
final artistSub = await artistService.getCurrentSubscription(userId);

// Unified approach (recommended)
final integration = IntegrationService.instance;
final capabilities = await integration.getSubscriptionCapabilities(userId);
```

---

## 🎯 Implementation Status

### Phase 2 Completed ✅

- [x] Consolidated ArtistService implementations
- [x] Resolved ArtistProfileModel conflicts
- [x] Created IntegrationService for cross-package coordination
- [x] Clarified subscription responsibilities
- [x] Added migration guides and deprecation notices
- [x] Updated package exports and documentation

### Next Phase (Phase 3) 🚧

- [ ] Advanced collaboration tools
- [ ] Enhanced marketing features
- [ ] Inventory management system
- [ ] Predictive analytics implementation

---

## 🏗️ Architecture Benefits

### Clear Separation of Concerns

- **Core**: Foundation and shared functionality
- **Artist**: Specialized artist workflows and features
- **Integration**: Unified access and coordination

### Backwards Compatibility

- Deprecated services maintain functionality
- Migration guides provided for all changes
- Gradual transition path available

### Enhanced Functionality

- Improved artist search and discovery
- Unified subscription capability management
- Cross-package data coordination
- Better error handling and validation

### Developer Experience

- Clear responsibility boundaries
- Comprehensive documentation
- Type-safe integration points
- Consistent API patterns

---

_This document represents the completed Phase 2 integration improvements for the ARTbeat artist package architecture._

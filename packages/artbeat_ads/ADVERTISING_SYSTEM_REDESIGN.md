# ArtBeat Advertising System Redesign

## Overview

This document outlines the new advertising system for ArtBeat, featuring:

1. **Title Sponsorship** - Premium $5,000/month app-wide sponsorship
2. **Simplified Ad Zones** - 5 strategic zones instead of 9 locations
3. **Better Ad Placement** - Clear, behavior-based targeting

---

## 1. Title Sponsorship System

### What is Title Sponsorship?

A premium, exclusive sponsorship that gives one organization prominent branding throughout the ArtBeat app.

### Pricing

- **Monthly**: $5,000/month
- **Quarterly**: $15,000 (no discount - exclusive positioning)
- **Annual**: $60,000/year (no discount - exclusive positioning)

### Features

- **Exclusive Status**: Only one title sponsor at a time
- **App-Wide Presence**:
  - Logo on splash screen (below ArtBeat logo)
  - Badge in drawer header
  - Subtle presence on loading screens
- **Analytics Dashboard**: Track impressions across all placements
- **Priority Support**: Direct communication with ArtBeat team

### Placement Locations

1. **Splash Screen** - 60x60px logo with "Sponsored by" text
2. **Drawer Header** - Compact badge at bottom of header
3. **Loading Screens** - "Powered by" with small logo

### Technical Implementation

**Model**: `TitleSponsorshipModel`

- Fields: sponsorId, sponsorName, logoUrl, websiteUrl, description
- Status: active, pending, expired, cancelled
- Analytics: impression tracking by location

**Service**: `TitleSponsorshipService`

- `getActiveSponsor()` - Get current active sponsor
- `watchActiveSponsor()` - Stream of active sponsor
- `createSponsorship()` - Create new sponsorship request
- `approveSponorship()` - Admin approval
- `trackImpression()` - Track views

**Widgets**:

- `TitleSponsorBadge` - Main badge for splash screen
- `CompactSponsorBadge` - Horizontal badge for drawer
- `LoadingSponsorBadge` - Minimal badge for loading states

### Usage Example

```dart
// In splash screen
TitleSponsorBadge(
  location: 'splash_screen',
  size: 60,
  showText: true,
  isClickable: false,
)

// In drawer header
CompactSponsorBadge()

// In loading screens
LoadingSponsorBadge()
```

---

## 2. Simplified Ad Zone System

### Old System (9 Locations)

1. fluidDashboard
2. artWalkDashboard
3. captureDashboard
4. unifiedCommunityHub
5. eventDashboard
6. artisticMessagingDashboard
7. artistPublicProfile
8. artistInFeed
9. communityInFeed

**Problem**: Too many options, confusing for advertisers

### New System (5 Zones)

#### Zone 1: Home & Discovery

- **Price**: $25/day (Premium)
- **Locations**: Dashboard, Browse screens
- **Audience**: High traffic, general users
- **Best For**: General promotions, new artists, brand awareness
- **Expected Impressions**: 5,000-10,000/day

#### Zone 2: Art & Walks

- **Price**: $15/day (Targeted)
- **Locations**: Art Walk Dashboard, Capture screens
- **Audience**: Art-focused users, active explorers
- **Best For**: Art supplies, galleries, local attractions
- **Expected Impressions**: 2,000-5,000/day

#### Zone 3: Community & Social

- **Price**: $20/day (High Traffic)
- **Locations**: Community Hub, Messaging, In-Feed placements
- **Audience**: Engaged community members
- **Best For**: Artist services, workshops, community events
- **Expected Impressions**: 3,000-7,000/day

#### Zone 4: Events & Experiences

- **Price**: $15/day (Targeted)
- **Locations**: Event Dashboard
- **Audience**: Event-goers, ticket buyers
- **Best For**: Venues, restaurants, event promotions
- **Expected Impressions**: 1,500-4,000/day

#### Zone 5: Artist Profiles

- **Price**: $10/day (Niche)
- **Locations**: Artist Public Profile pages
- **Audience**: Specific artist followers
- **Best For**: Art supplies, professional services, galleries
- **Expected Impressions**: 1,000-3,000/day

### Migration Mapping

The system automatically migrates old locations to new zones:

```dart
fluidDashboard → homeDiscovery
artWalkDashboard → artWalks
captureDashboard → artWalks
unifiedCommunityHub → communitySocial
eventDashboard → events
artisticMessagingDashboard → communitySocial
artistPublicProfile → artistProfiles
artistInFeed → communitySocial
communityInFeed → communitySocial
```

### Technical Implementation

**Enum**: `AdZone`

```dart
enum AdZone {
  homeDiscovery,
  artWalks,
  communitySocial,
  events,
  artistProfiles,
}
```

**Extension**: `AdZoneExtension`

- `displayName` - User-friendly name
- `description` - Detailed description
- `pricePerDay` - Zone-specific pricing
- `icon` - Emoji icon for UI
- `expectedImpressions` - Daily impression range
- `bestFor` - List of recommended use cases

**Migration**: `AdZoneMigration`

- `migrateFromLocationIndex()` - Convert old location index to zone
- `migrateFromLocationName()` - Convert old location name to zone

### Updated AdModel

The `AdModel` now supports both systems:

```dart
class AdModel {
  final AdLocation location; // Legacy - kept for backward compatibility
  final AdZone? zone; // New zone system

  // Get effective zone (migrates from location if zone is null)
  AdZone get effectiveZone => zone ?? AdZoneMigration.migrateFromLocationIndex(location.index);

  // Price per day uses zone pricing if available
  double get pricePerDay => zone?.pricePerDay ?? size.pricePerDay;
}
```

---

## 3. Ad Placement Guidelines

### Where to Place Ads

#### Home & Discovery Zone

- **Fluid Dashboard**: Top banner, mid-feed placements
- **Browse Screen**: Between content sections

#### Art & Walks Zone

- **Art Walk Dashboard**: Top banner, between walk cards
- **Art Walk Map**: Bottom banner (non-intrusive)
- **Capture Dashboard**: Between capture grids

#### Community & Social Zone

- **Community Hub**: In-feed ads (every 5-7 posts)
- **Messaging Dashboard**: Top banner
- **Artist Feed**: In-feed ads (every 5-7 posts)

#### Events & Experiences Zone

- **Event Dashboard**: Top banner, between event cards
- **Event Detail**: Bottom banner

#### Artist Profiles Zone

- **Artist Public Profile**: Bottom banner or sidebar
- **Artist Portfolio**: Between artwork sections

### Ad Widget Usage

```dart
// Simple placement
SimpleAdPlacementWidget(
  location: AdLocation.fluidDashboard, // Will auto-migrate to zone
  height: 100,
)

// Rotating ads
RotatingAdPlacementWidget(
  location: AdLocation.unifiedCommunityHub,
  height: 120,
  rotationInterval: Duration(seconds: 10),
)
```

---

## 4. Admin Management

### Title Sponsorship Management

Admins can:

- View pending sponsorship requests
- Approve/reject sponsorships
- View analytics (impressions by location)
- Manage active sponsorships
- Check for scheduling conflicts

### Regular Ad Management

Admins can:

- View ads by zone
- See zone performance metrics
- Approve/reject ads
- Monitor ad spend and revenue

---

## 5. Migration Plan

### Phase 1: ✅ Complete

- Created `TitleSponsorshipModel` and service
- Created `AdZone` enum and migration logic
- Updated `AdModel` to support both systems
- Added sponsor badges to splash screen and drawer

### Phase 2: In Progress

- Update ad creation UI to use zones
- Add zone selection dropdown
- Update ad statistics to show zone performance

### Phase 3: Future

- Migrate existing ads to new zone system
- Update admin dashboard with zone analytics
- Create title sponsorship purchase flow
- Add zone-based ad recommendations

---

## 6. Firestore Collections

### title_sponsorships

```
{
  sponsorId: string,
  sponsorName: string,
  logoUrl: string,
  websiteUrl: string?,
  description: string?,
  startDate: timestamp,
  endDate: timestamp,
  status: number (0=active, 1=pending, 2=expired, 3=cancelled),
  monthlyPrice: number (5000),
  durationMonths: number,
  totalPrice: number,
  createdAt: timestamp,
  approvedAt: timestamp?,
  approvedBy: string?,
  analytics: {
    totalImpressions: number,
    locations: {
      splash_screen: number,
      drawer_header: number,
      loading_screen: number,
    },
    lastImpressionAt: timestamp,
  }
}
```

### ads (updated)

```
{
  // ... existing fields ...
  location: number, // Legacy field (kept for backward compatibility)
  zone: number?, // New field (0-4 for AdZone enum)
  // ... rest of fields ...
}
```

---

## 7. Benefits of New System

### For Advertisers

- **Clearer Targeting**: 5 zones vs 9 locations
- **Better ROI**: Zone-based pricing reflects actual value
- **Easier Decisions**: Clear descriptions and use cases
- **Performance Data**: Zone-specific analytics

### For ArtBeat

- **Premium Revenue**: $5,000/month title sponsorships
- **Better UX**: Less cluttered, more strategic ad placement
- **Easier Management**: Simplified zone system
- **Scalability**: Easy to add new zones if needed

### For Users

- **Less Intrusive**: Strategic placement in high-value zones
- **Relevant Ads**: Better targeting = more relevant content
- **Premium Experience**: Title sponsor adds credibility

---

## 8. Next Steps

1. **Update Ad Creation Screen**: Add zone selection dropdown
2. **Update Ad Statistics**: Show zone performance metrics
3. **Create Title Sponsorship Purchase Flow**: Allow users to request sponsorships
4. **Admin Dashboard**: Add title sponsorship management
5. **Migration Script**: Migrate existing ads to new zone system
6. **Documentation**: Update user-facing documentation

---

## Contact

For questions about the new advertising system, contact the ArtBeat development team.

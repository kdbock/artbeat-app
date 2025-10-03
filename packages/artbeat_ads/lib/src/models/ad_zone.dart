import 'package:flutter/material.dart';

/// Simplified Ad Zone system - 5 strategic zones for better targeting
/// Replaces the previous 9-location system with clearer, behavior-based zones
enum AdZone {
  homeDiscovery, // High traffic, general audience (Dashboard, Browse)
  artWalks, // Art-focused users, active explorers (Art Walk, Capture)
  communitySocial, // Engaged community members (Community Hub, Messaging, Feeds)
  events, // Event-goers, ticket buyers (Event Dashboard)
  artistProfiles, // Targeted to specific artist followers (Artist Profiles)
}

extension AdZoneExtension on AdZone {
  /// Get display name for this ad zone
  String get displayName {
    switch (this) {
      case AdZone.homeDiscovery:
        return 'Home & Discovery';
      case AdZone.artWalks:
        return 'Art & Walks';
      case AdZone.communitySocial:
        return 'Community & Social';
      case AdZone.events:
        return 'Events & Experiences';
      case AdZone.artistProfiles:
        return 'Artist Profiles';
    }
  }

  /// Get description for this ad zone
  String get description {
    switch (this) {
      case AdZone.homeDiscovery:
        return 'High traffic area - Dashboard and Browse screens. Best for general promotions, events, and new artists.';
      case AdZone.artWalks:
        return 'Art-focused users and active explorers. Best for art supplies, galleries, and local attractions.';
      case AdZone.communitySocial:
        return 'Engaged community members in feeds and messaging. Best for artist services, workshops, and community events.';
      case AdZone.events:
        return 'Event-goers and ticket buyers. Best for venues, restaurants, and event promotions.';
      case AdZone.artistProfiles:
        return 'Targeted to specific artist followers. Best for art supplies, professional services, and galleries.';
    }
  }

  /// Get price per day for this zone
  double get pricePerDay {
    switch (this) {
      case AdZone.homeDiscovery:
        return 25.0; // Premium zone - highest traffic
      case AdZone.communitySocial:
        return 20.0; // High traffic zone
      case AdZone.artWalks:
        return 15.0; // Targeted zone
      case AdZone.events:
        return 15.0; // Targeted zone
      case AdZone.artistProfiles:
        return 10.0; // Niche zone
    }
  }

  /// Get icon emoji for this zone
  String get icon {
    switch (this) {
      case AdZone.homeDiscovery:
        return '🏠';
      case AdZone.artWalks:
        return '🎨';
      case AdZone.communitySocial:
        return '👥';
      case AdZone.events:
        return '🎭';
      case AdZone.artistProfiles:
        return '👤';
    }
  }

  /// Get IconData for this zone
  IconData get iconData {
    switch (this) {
      case AdZone.homeDiscovery:
        return Icons.home;
      case AdZone.artWalks:
        return Icons.palette;
      case AdZone.communitySocial:
        return Icons.people;
      case AdZone.events:
        return Icons.event;
      case AdZone.artistProfiles:
        return Icons.person;
    }
  }

  /// Get expected daily impressions for this zone
  String get expectedImpressions {
    switch (this) {
      case AdZone.homeDiscovery:
        return '5,000-10,000';
      case AdZone.communitySocial:
        return '3,000-7,000';
      case AdZone.artWalks:
        return '2,000-5,000';
      case AdZone.events:
        return '1,500-4,000';
      case AdZone.artistProfiles:
        return '1,000-3,000';
    }
  }

  /// Get best use cases for this zone
  List<String> get bestFor {
    switch (this) {
      case AdZone.homeDiscovery:
        return [
          'General promotions',
          'New artist announcements',
          'App-wide events',
          'Brand awareness',
        ];
      case AdZone.artWalks:
        return [
          'Art supplies',
          'Local galleries',
          'Art attractions',
          'Photography services',
        ];
      case AdZone.communitySocial:
        return [
          'Artist services',
          'Workshops & classes',
          'Community events',
          'Collaboration opportunities',
        ];
      case AdZone.events:
        return ['Venues', 'Restaurants', 'Event promotions', 'Ticket sales'];
      case AdZone.artistProfiles:
        return [
          'Art supplies',
          'Professional services',
          'Gallery representation',
          'Artist tools',
        ];
    }
  }
}

/// Helper class to migrate old AdLocation to new AdZone
class AdZoneMigration {
  /// Map old location index to new zone
  static AdZone migrateFromLocationIndex(int locationIndex) {
    // Old AdLocation enum order:
    // 0: fluidDashboard
    // 1: artWalkDashboard
    // 2: captureDashboard
    // 3: unifiedCommunityHub
    // 4: eventDashboard
    // 5: artisticMessagingDashboard
    // 6: artistPublicProfile
    // 7: artistInFeed
    // 8: communityInFeed

    switch (locationIndex) {
      case 0: // fluidDashboard
        return AdZone.homeDiscovery;
      case 1: // artWalkDashboard
        return AdZone.artWalks;
      case 2: // captureDashboard
        return AdZone.artWalks;
      case 3: // unifiedCommunityHub
        return AdZone.communitySocial;
      case 4: // eventDashboard
        return AdZone.events;
      case 5: // artisticMessagingDashboard
        return AdZone.communitySocial;
      case 6: // artistPublicProfile
        return AdZone.artistProfiles;
      case 7: // artistInFeed
        return AdZone.communitySocial;
      case 8: // communityInFeed
        return AdZone.communitySocial;
      default:
        return AdZone.homeDiscovery; // Default fallback
    }
  }

  /// Get zone from old location name
  static AdZone migrateFromLocationName(String locationName) {
    switch (locationName.toLowerCase()) {
      case 'fluiddashboard':
      case 'fluid_dashboard':
        return AdZone.homeDiscovery;
      case 'artwalkdashboard':
      case 'art_walk_dashboard':
        return AdZone.artWalks;
      case 'capturedashboard':
      case 'capture_dashboard':
        return AdZone.artWalks;
      case 'unifiedcommunityhub':
      case 'unified_community_hub':
        return AdZone.communitySocial;
      case 'eventdashboard':
      case 'event_dashboard':
        return AdZone.events;
      case 'artisticmessagingdashboard':
      case 'artistic_messaging_dashboard':
        return AdZone.communitySocial;
      case 'artistpublicprofile':
      case 'artist_public_profile':
        return AdZone.artistProfiles;
      case 'artistinfeed':
      case 'artist_in_feed':
        return AdZone.communitySocial;
      case 'communityinfeed':
      case 'community_in_feed':
        return AdZone.communitySocial;
      default:
        return AdZone.homeDiscovery;
    }
  }
}

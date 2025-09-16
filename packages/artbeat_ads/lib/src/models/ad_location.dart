/// AdLocation for where the ad will be displayed in the app
enum AdLocation {
  fluidDashboard, // fluid dashboard screen
  artWalkDashboard, // art walk dashboard
  captureDashboard, // capture dashboard
  unifiedCommunityHub, // unified community hub
  eventDashboard, // event dashboard
  artisticMessagingDashboard, // artistic messaging dashboard
  artistPublicProfile, // artist public profile
  artistInFeed, // artist_in_feed
  communityInFeed, // community_in_feed
}

extension AdLocationExtension on AdLocation {
  /// Get display name for this ad location
  String get displayName {
    switch (this) {
      case AdLocation.fluidDashboard:
        return 'Fluid Dashboard';
      case AdLocation.artWalkDashboard:
        return 'Art Walk Dashboard';
      case AdLocation.captureDashboard:
        return 'Capture Dashboard';
      case AdLocation.unifiedCommunityHub:
        return 'Unified Community Hub';
      case AdLocation.eventDashboard:
        return 'Event Dashboard';
      case AdLocation.artisticMessagingDashboard:
        return 'Artistic Messaging Dashboard';
      case AdLocation.artistPublicProfile:
        return 'Artist Public Profile';
      case AdLocation.artistInFeed:
        return 'Artist in Feed';
      case AdLocation.communityInFeed:
        return 'Community in Feed';
    }
  }

  /// Get description for this ad location
  String get description {
    switch (this) {
      case AdLocation.fluidDashboard:
        return 'Main fluid dashboard screen with dynamic content';
      case AdLocation.artWalkDashboard:
        return 'Art walk discovery and exploration screen';
      case AdLocation.captureDashboard:
        return 'Photo capture and content creation screen';
      case AdLocation.unifiedCommunityHub:
        return 'Central community hub for social interactions';
      case AdLocation.eventDashboard:
        return 'Events listing and discovery screen';
      case AdLocation.artisticMessagingDashboard:
        return 'Artistic messaging and communication screen';
      case AdLocation.artistPublicProfile:
        return 'Public artist profile pages';
      case AdLocation.artistInFeed:
        return 'Artist content within social feeds';
      case AdLocation.communityInFeed:
        return 'Community content within social feeds';
    }
  }
}

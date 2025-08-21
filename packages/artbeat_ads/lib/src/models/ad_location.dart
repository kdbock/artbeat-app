/// AdLocation for where the ad will be displayed in the app
enum AdLocation {
  dashboard, // fluid_dashboard_screen
  artWalkDashboard, // art_walk_dashboard
  captureDashboard, // capture_dashboard
  communityDashboard, // community_dashboard
  eventsDashboard, // events_dashboard
  communityFeed, // community_feed
}

extension AdLocationExtension on AdLocation {
  /// Get display name for this ad location
  String get displayName {
    switch (this) {
      case AdLocation.dashboard:
        return 'Main Dashboard';
      case AdLocation.artWalkDashboard:
        return 'Art Walk Dashboard';
      case AdLocation.captureDashboard:
        return 'Capture Dashboard';
      case AdLocation.communityDashboard:
        return 'Community Dashboard';
      case AdLocation.eventsDashboard:
        return 'Events Dashboard';
      case AdLocation.communityFeed:
        return 'Community Feed';
    }
  }

  /// Get description for this ad location
  String get description {
    switch (this) {
      case AdLocation.dashboard:
        return 'Main app dashboard screen';
      case AdLocation.artWalkDashboard:
        return 'Art walk discovery screen';
      case AdLocation.captureDashboard:
        return 'Photo capture screen';
      case AdLocation.communityDashboard:
        return 'Community overview screen';
      case AdLocation.eventsDashboard:
        return 'Events listing screen';
      case AdLocation.communityFeed:
        return 'Community activity feed';
    }
  }
}

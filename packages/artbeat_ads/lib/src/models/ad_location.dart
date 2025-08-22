/// AdLocation for where the ad will be displayed in the app
enum AdLocation {
  dashboard, // fluid_dashboard_screen
  artWalkDashboard, // art_walk_dashboard
  captureDashboard, // capture_dashboard
  communityDashboard, // community_dashboard
  eventsDashboard, // events_dashboard
  communityFeed, // community_feed
  artworkGallery, // artwork gallery section in dashboard
  preArtistCTA, // before artist CTA section
  postArtistCTA1, // after artist CTA section (first ad)
  postArtistCTA2, // after artist CTA section (second ad)
  artWalkMap, // beneath local art map section in art walk dashboard
  artWalkCaptures, // beneath local art captures section in art walk dashboard
  artWalkAchievements, // beneath art walk achievements section in art walk dashboard
  captureStats, // beneath stats section in capture dashboard
  captureRecent, // beneath recent captures section in capture dashboard
  captureCommunity, // beneath community inspiration section in capture dashboard
  communityOnlineArtists, // beneath online artists section in community dashboard
  communityRecentPosts, // beneath recent posts section in community dashboard
  communityFeaturedArtists, // beneath featured artists section in community dashboard
  communityVerifiedArtists, // beneath verified artists section in community dashboard
  eventsHero, // beneath hero section in events dashboard
  eventsFeatured, // beneath featured events section in events dashboard
  eventsAll, // beneath all events section in events dashboard
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
      case AdLocation.artworkGallery:
        return 'Artwork Gallery';
      case AdLocation.preArtistCTA:
        return 'Pre-Artist CTA';
      case AdLocation.postArtistCTA1:
        return 'Post-Artist CTA 1';
      case AdLocation.postArtistCTA2:
        return 'Post-Artist CTA 2';
      case AdLocation.artWalkMap:
        return 'Art Walk Map';
      case AdLocation.artWalkCaptures:
        return 'Art Walk Captures';
      case AdLocation.artWalkAchievements:
        return 'Art Walk Achievements';
      case AdLocation.captureStats:
        return 'Capture Stats';
      case AdLocation.captureRecent:
        return 'Capture Recent';
      case AdLocation.captureCommunity:
        return 'Capture Community';
      case AdLocation.communityOnlineArtists:
        return 'Community Online Artists';
      case AdLocation.communityRecentPosts:
        return 'Community Recent Posts';
      case AdLocation.communityFeaturedArtists:
        return 'Community Featured Artists';
      case AdLocation.communityVerifiedArtists:
        return 'Community Verified Artists';
      case AdLocation.eventsHero:
        return 'Events Hero';
      case AdLocation.eventsFeatured:
        return 'Events Featured';
      case AdLocation.eventsAll:
        return 'Events All';
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
      case AdLocation.artworkGallery:
        return 'Artwork gallery section in dashboard';
      case AdLocation.preArtistCTA:
        return 'Before artist call-to-action section';
      case AdLocation.postArtistCTA1:
        return 'After artist CTA section (first placement)';
      case AdLocation.postArtistCTA2:
        return 'After artist CTA section (second placement)';
      case AdLocation.artWalkMap:
        return 'Beneath local art map section in art walk dashboard';
      case AdLocation.artWalkCaptures:
        return 'Beneath local art captures section in art walk dashboard';
      case AdLocation.artWalkAchievements:
        return 'Beneath art walk achievements section in art walk dashboard';
      case AdLocation.captureStats:
        return 'Beneath stats section in capture dashboard';
      case AdLocation.captureRecent:
        return 'Beneath recent captures section in capture dashboard';
      case AdLocation.captureCommunity:
        return 'Beneath community inspiration section in capture dashboard';
      case AdLocation.communityOnlineArtists:
        return 'Beneath online artists section in community dashboard';
      case AdLocation.communityRecentPosts:
        return 'Beneath recent posts section in community dashboard';
      case AdLocation.communityFeaturedArtists:
        return 'Beneath featured artists section in community dashboard';
      case AdLocation.communityVerifiedArtists:
        return 'Beneath verified artists section in community dashboard';
      case AdLocation.eventsHero:
        return 'Beneath hero section in events dashboard';
      case AdLocation.eventsFeatured:
        return 'Beneath featured events section in events dashboard';
      case AdLocation.eventsAll:
        return 'Beneath all events section in events dashboard';
    }
  }
}

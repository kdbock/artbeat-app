// Core definition of subscription tier that should be used across all modules

/// Represents the different subscription tiers available in the application
enum SubscriptionTier {
  free('free', 'Free'),
  artistBasic('artist_basic', 'Artist Basic'),
  artistPro('artist_pro', 'Artist Pro'),
  gallery('gallery', 'Gallery');

  final String apiName;
  final String displayName;

  const SubscriptionTier(this.apiName, this.displayName);

  /// Returns the monthly price in dollars
  double get monthlyPrice {
    switch (this) {
      case SubscriptionTier.free:
      case SubscriptionTier.artistBasic:
        return 0.0;
      case SubscriptionTier.artistPro:
        return 9.99;
      case SubscriptionTier.gallery:
        return 49.99;
    }
  }

  /// Returns a list of features included in this subscription tier
  List<String> get features {
    switch (this) {
      case SubscriptionTier.free:
        return [
          'Artist profile page',
          'Community features',
          'Basic analytics',
        ];
      case SubscriptionTier.artistBasic:
        return [
          'Artist profile page',
          'Up to 5 artwork listings',
          'Basic analytics',
          'Community features',
        ];
      case SubscriptionTier.artistPro:
        return [
          'Unlimited artwork listings',
          'Featured in discover section',
          'Advanced analytics',
          'Priority support',
          'Event creation',
          'All Basic features',
        ];
      case SubscriptionTier.gallery:
        return [
          'Multiple artist management',
          'Business profile',
          'Advanced analytics dashboard',
          'Commission tracking',
          'Event creation',
          'Dedicated support',
          'All Pro features',
        ];
    }
  }

  /// Convert from legacy name
  static SubscriptionTier fromLegacyName(String name) {
    switch (name.toLowerCase()) {
      case 'free':
      case 'none':
        return SubscriptionTier.free;
      case 'artist_basic':
      case 'artistbasic':
      case 'basic':
        return SubscriptionTier.artistBasic;
      case 'artist_pro':
      case 'artistpro':
      case 'pro':
      case 'standard':
        return SubscriptionTier.artistPro;
      case 'gallery':
      case 'gallery_business':
      case 'premium':
        return SubscriptionTier.gallery;
      default:
        return SubscriptionTier.free;
    }
  }

  /// Get price display string
  String get priceString {
    final price = monthlyPrice;
    return price > 0 ? '\$${price.toStringAsFixed(2)}/month' : 'Free';
  }
}

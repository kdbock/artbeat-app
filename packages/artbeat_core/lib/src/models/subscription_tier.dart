// Core definition of subscription tier that should be used across all modules

/// Subscription tiers for the application
enum SubscriptionTier {
  basic('free', 'Artist Basic'),
  standard('standard', 'Artist Pro'),
  premium('premium', 'Gallery'),
  none('none', 'None');

  final String apiName;
  final String displayName;

  const SubscriptionTier(this.apiName, this.displayName);

  /// Get monthly price in dollars
  double get monthlyPrice {
    switch (this) {
      case SubscriptionTier.basic:
        return 0.0;
      case SubscriptionTier.standard:
        return 9.99;
      case SubscriptionTier.premium:
        return 49.99;
      case SubscriptionTier.none:
        return 0.0;
    }
  }

  /// Get features for this tier
  List<String> get features {
    switch (this) {
      case SubscriptionTier.basic:
        return [
          'Artist profile page',
          'Up to 5 artwork listings',
          'Basic analytics',
          'Community features',
        ];
      case SubscriptionTier.standard:
        return [
          'Unlimited artwork listings',
          'Featured in discover section',
          'Advanced analytics',
          'Priority support',
          'Event creation and promotion',
          'Commission handling tools',
        ];
      case SubscriptionTier.premium:
        return [
          'Multiple artist management',
          'Business profile for galleries',
          'Advanced analytics dashboard',
          'Dedicated support',
          'Event ticketing and sales',
          'Commission management',
          'Marketing tools',
          'Bulk uploads',
        ];
      case SubscriptionTier.none:
        return [];
    }
  }

  /// Convert from legacy name
  static SubscriptionTier fromLegacyName(String name) {
    switch (name) {
      case 'artistBasic':
      case 'free':
        return SubscriptionTier.basic;
      case 'artistPro':
      case 'standard':
        return SubscriptionTier.standard;
      case 'gallery':
      case 'premium':
        return SubscriptionTier.premium;
      default:
        return SubscriptionTier.none;
    }
  }

  /// Get price display string
  String get priceString {
    final price = monthlyPrice;
    return price > 0 ? '\$${price.toStringAsFixed(2)}/month' : 'Free';
  }
}

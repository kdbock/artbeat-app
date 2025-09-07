// Core definition of subscription tier that should be used across all modules

/// Represents the different subscription tiers available in the application
/// Updated to 2025 industry standards with competitive pricing
enum SubscriptionTier {
  free('free', 'Free'),
  starter('starter', 'Starter'),
  creator('creator', 'Creator'),
  business('business', 'Business'),
  enterprise('enterprise', 'Enterprise');

  final String apiName;
  final String displayName;

  const SubscriptionTier(this.apiName, this.displayName);

  /// Returns the monthly price in dollars (2025 industry-standard pricing)
  double get monthlyPrice {
    switch (this) {
      case SubscriptionTier.free:
        return 0.0;
      case SubscriptionTier.starter:
        return 4.99; // Entry-level creators
      case SubscriptionTier.creator:
        return 12.99; // Matches Canva Pro pricing
      case SubscriptionTier.business:
        return 29.99; // Small businesses (matches Shopify)
      case SubscriptionTier.enterprise:
        return 79.99; // Galleries/institutions
    }
  }

  /// Returns a list of features included in this subscription tier
  /// Updated with 2025 usage-based limits and modern features
  List<String> get features {
    switch (this) {
      case SubscriptionTier.free:
        return [
          'Up to 3 artworks',
          '0.5GB storage',
          '5 AI credits/month',
          'Basic analytics',
          'Community features',
        ];
      case SubscriptionTier.starter:
        return [
          'Up to 25 artworks',
          '5GB storage',
          '50 AI credits/month',
          'Basic analytics',
          'Community features',
          'Email support',
        ];
      case SubscriptionTier.creator:
        return [
          'Up to 100 artworks',
          '25GB storage',
          '200 AI credits/month',
          'Advanced analytics',
          'Featured placement',
          'Event creation',
          'Priority support',
          'All Starter features',
        ];
      case SubscriptionTier.business:
        return [
          'Unlimited artworks',
          '100GB storage',
          '500 AI credits/month',
          'Team collaboration (up to 5 users)',
          'Custom branding',
          'API access',
          'Advanced reporting',
          'Dedicated support',
          'All Creator features',
        ];
      case SubscriptionTier.enterprise:
        return [
          'Unlimited everything',
          'Unlimited storage',
          'Unlimited AI credits',
          'Unlimited team members',
          'Custom integrations',
          'White-label options',
          'Enterprise security',
          'Dedicated account manager',
          'All Business features',
        ];
    }
  }

  /// Convert from legacy name and new names
  static SubscriptionTier fromLegacyName(String name) {
    switch (name.toLowerCase()) {
      // Free tier
      case 'free':
      case 'none':
        return SubscriptionTier.free;

      // Starter tier (new) / Basic tier (legacy)
      case 'starter':
      case 'artist_basic':
      case 'artistbasic':
      case 'basic':
        return SubscriptionTier.starter;

      // Creator tier (new) / Pro tier (legacy)
      case 'creator':
      case 'artist_pro':
      case 'artistpro':
      case 'pro':
      case 'standard':
        return SubscriptionTier.creator;

      // Business tier (new) / Gallery tier (legacy)
      case 'business':
      case 'gallery_business':
      case 'premium':
        return SubscriptionTier.business;

      // Enterprise tier (new)
      case 'enterprise':
      case 'enterprise_plus':
        return SubscriptionTier.enterprise;

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

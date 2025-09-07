/// Import the subscription tier enum
import 'subscription_tier.dart';

/// Feature limits model implementing 2025 industry standards with soft limits
/// and overage pricing for modern usage-based billing
class FeatureLimits {
  final int artworks;
  final double storageGB;
  final int aiCredits;
  final int teamMembers;
  final bool hasAdvancedAnalytics;
  final bool hasFeaturedPlacement;
  final bool hasCustomBranding;
  final bool hasAPIAccess;
  final bool hasUnlimitedSupport;

  const FeatureLimits({
    required this.artworks,
    required this.storageGB,
    required this.aiCredits,
    this.teamMembers = 1,
    this.hasAdvancedAnalytics = false,
    this.hasFeaturedPlacement = false,
    this.hasCustomBranding = false,
    this.hasAPIAccess = false,
    this.hasUnlimitedSupport = false,
  });

  /// Get feature limits for a specific subscription tier
  factory FeatureLimits.forTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return const FeatureLimits(
          artworks: 3,
          storageGB: 0.5,
          aiCredits: 5,
          teamMembers: 1,
        );

      case SubscriptionTier.starter:
        return const FeatureLimits(
          artworks: 25,
          storageGB: 5,
          aiCredits: 50,
          teamMembers: 1,
        );

      case SubscriptionTier.creator:
        return const FeatureLimits(
          artworks: 100,
          storageGB: 25,
          aiCredits: 200,
          teamMembers: 1,
          hasAdvancedAnalytics: true,
          hasFeaturedPlacement: true,
        );

      case SubscriptionTier.business:
        return const FeatureLimits(
          artworks: -1, // Unlimited
          storageGB: 100,
          aiCredits: 500,
          teamMembers: 5,
          hasAdvancedAnalytics: true,
          hasFeaturedPlacement: true,
          hasCustomBranding: true,
          hasAPIAccess: true,
        );

      case SubscriptionTier.enterprise:
        return const FeatureLimits(
          artworks: -1, // Unlimited
          storageGB: -1, // Unlimited
          aiCredits: -1, // Unlimited
          teamMembers: -1, // Unlimited
          hasAdvancedAnalytics: true,
          hasFeaturedPlacement: true,
          hasCustomBranding: true,
          hasAPIAccess: true,
          hasUnlimitedSupport: true,
        );
    }
  }

  /// Check if a specific feature is available
  bool get hasUnlimitedArtworks => artworks == -1;
  bool get hasUnlimitedStorage => storageGB == -1;
  bool get hasUnlimitedAICredits => aiCredits == -1;
  bool get hasUnlimitedTeamMembers => teamMembers == -1;

  /// Get overage pricing (per unit) for soft limits
  static const Map<String, double> overagePricing = {
    'artwork': 0.99, // $0.99 per additional artwork
    'storageGB': 0.49, // $0.49 per additional GB
    'aiCredit': 0.05, // $0.05 per additional AI credit
    'teamMember': 9.99, // $9.99 per additional team member
  };

  /// Calculate monthly cost for overages
  double calculateOverageCost({
    int additionalArtworks = 0,
    double additionalStorageGB = 0,
    int additionalAICredits = 0,
    int additionalTeamMembers = 0,
  }) {
    double cost = 0.0;

    // Only charge overages if not unlimited
    if (!hasUnlimitedArtworks && additionalArtworks > 0) {
      cost += additionalArtworks * overagePricing['artwork']!;
    }

    if (!hasUnlimitedStorage && additionalStorageGB > 0) {
      cost += additionalStorageGB * overagePricing['storageGB']!;
    }

    if (!hasUnlimitedAICredits && additionalAICredits > 0) {
      cost += additionalAICredits * overagePricing['aiCredit']!;
    }

    if (!hasUnlimitedTeamMembers && additionalTeamMembers > 0) {
      cost += additionalTeamMembers * overagePricing['teamMember']!;
    }

    return cost;
  }

  /// Get remaining quota for a specific feature
  int getRemainingQuota(String feature, int currentUsage) {
    switch (feature) {
      case 'artworks':
        return hasUnlimitedArtworks
            ? -1
            : (artworks - currentUsage).clamp(0, artworks);
      case 'storage':
        return hasUnlimitedStorage
            ? -1
            : ((storageGB - currentUsage).clamp(0, storageGB)).toInt();
      case 'aiCredits':
      case 'ai_credits':
        return hasUnlimitedAICredits
            ? -1
            : (aiCredits - currentUsage).clamp(0, aiCredits);
      case 'teamMembers':
      case 'team_members':
        return hasUnlimitedTeamMembers
            ? -1
            : (teamMembers - currentUsage).clamp(0, teamMembers);
      default:
        return 0;
    }
  }

  /// Check if user is approaching limit (80% threshold)
  bool isApproachingLimit(String feature, int currentUsage) {
    switch (feature) {
      case 'artworks':
        return !hasUnlimitedArtworks && currentUsage >= (artworks * 0.8);
      case 'storage':
        return !hasUnlimitedStorage && currentUsage >= (storageGB * 0.8);
      case 'aiCredits':
      case 'ai_credits':
        return !hasUnlimitedAICredits && currentUsage >= (aiCredits * 0.8);
      case 'teamMembers':
      case 'team_members':
        return !hasUnlimitedTeamMembers && currentUsage >= (teamMembers * 0.8);
      default:
        return false;
    }
  }

  /// Get percentage used for progress bars
  double getUsagePercentage(String feature, int currentUsage) {
    switch (feature) {
      case 'artworks':
        return hasUnlimitedArtworks
            ? 0.0
            : (currentUsage / artworks).clamp(0.0, 1.0);
      case 'storage':
        return hasUnlimitedStorage
            ? 0.0
            : (currentUsage / storageGB).clamp(0.0, 1.0);
      case 'aiCredits':
      case 'ai_credits':
        return hasUnlimitedAICredits
            ? 0.0
            : (currentUsage / aiCredits).clamp(0.0, 1.0);
      case 'teamMembers':
      case 'team_members':
        return hasUnlimitedTeamMembers
            ? 0.0
            : (currentUsage / teamMembers).clamp(0.0, 1.0);
      default:
        return 0.0;
    }
  }
}

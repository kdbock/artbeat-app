import 'package:artbeat_core/src/models/subscription_tier.dart';

/// Model representing an available subscription plan for selection
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final SubscriptionTier tier;
  final double monthlyPrice;
  final double? annualPrice;
  final List<String> features;
  final List<String> highlights;
  final bool isPopular;
  final bool isRecommended;
  final String? badgeText;
  final int maxArtworks;
  final int storageGB;
  final int aiCreditsPerMonth;
  final bool hasAnalytics;
  final bool hasPrioritySupport;
  final bool hasApiAccess;
  final bool hasCustomBranding;
  final bool hasTeamCollaboration;
  final int? maxTeamMembers;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.monthlyPrice,
    this.annualPrice,
    required this.features,
    required this.highlights,
    this.isPopular = false,
    this.isRecommended = false,
    this.badgeText,
    required this.maxArtworks,
    required this.storageGB,
    required this.aiCreditsPerMonth,
    required this.hasAnalytics,
    required this.hasPrioritySupport,
    this.hasApiAccess = false,
    this.hasCustomBranding = false,
    this.hasTeamCollaboration = false,
    this.maxTeamMembers,
  });

  /// Create a SubscriptionPlan from SubscriptionTier
  factory SubscriptionPlan.fromTier(SubscriptionTier tier) {
    return SubscriptionPlan(
      id: tier.apiName,
      name: tier.displayName,
      description: _getTierDescription(tier),
      tier: tier,
      monthlyPrice: tier.monthlyPrice,
      annualPrice: tier.monthlyPrice * 12 * 0.8, // 20% discount for annual
      features: tier.features,
      highlights: _getTierHighlights(tier),
      isPopular: tier == SubscriptionTier.creator,
      isRecommended: tier == SubscriptionTier.creator,
      badgeText: tier == SubscriptionTier.creator ? 'Most Popular' : null,
      maxArtworks: _getMaxArtworks(tier),
      storageGB: _getStorageGB(tier),
      aiCreditsPerMonth: _getAiCredits(tier),
      hasAnalytics: tier != SubscriptionTier.free,
      hasPrioritySupport:
          tier == SubscriptionTier.creator ||
          tier == SubscriptionTier.business ||
          tier == SubscriptionTier.enterprise,
      hasApiAccess:
          tier == SubscriptionTier.business ||
          tier == SubscriptionTier.enterprise,
      hasCustomBranding:
          tier == SubscriptionTier.business ||
          tier == SubscriptionTier.enterprise,
      hasTeamCollaboration:
          tier == SubscriptionTier.business ||
          tier == SubscriptionTier.enterprise,
      maxTeamMembers: tier == SubscriptionTier.business
          ? 5
          : (tier == SubscriptionTier.enterprise ? null : null),
    );
  }

  /// Get description for a tier
  static String _getTierDescription(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Perfect for getting started with ARTbeat. Create your profile and explore the community.';
      case SubscriptionTier.starter:
        return 'Ideal for emerging artists ready to showcase their work professionally.';
      case SubscriptionTier.creator:
        return 'For serious artists who want to grow their presence and monetize their art.';
      case SubscriptionTier.business:
        return 'Complete solution for galleries, studios, and small art businesses.';
      case SubscriptionTier.enterprise:
        return 'Enterprise-grade features for institutions and large art organizations.';
    }
  }

  /// Get highlights for a tier
  static List<String> _getTierHighlights(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return ['Basic profile', 'Community access', 'Limited storage'];
      case SubscriptionTier.starter:
        return ['Professional profile', 'Analytics dashboard', 'Email support'];
      case SubscriptionTier.creator:
        return ['Unlimited potential', 'Priority features', 'Advanced tools'];
      case SubscriptionTier.business:
        return ['Team collaboration', 'Custom branding', 'API access'];
      case SubscriptionTier.enterprise:
        return [
          'White-label solution',
          'Dedicated support',
          'Custom integrations',
        ];
    }
  }

  /// Get max artworks for a tier
  static int _getMaxArtworks(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 3;
      case SubscriptionTier.starter:
        return 25;
      case SubscriptionTier.creator:
        return 100;
      case SubscriptionTier.business:
        return -1; // Unlimited
      case SubscriptionTier.enterprise:
        return -1; // Unlimited
    }
  }

  /// Get storage GB for a tier
  static int _getStorageGB(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 1; // 0.5GB, but we'll round up for display
      case SubscriptionTier.starter:
        return 5;
      case SubscriptionTier.creator:
        return 25;
      case SubscriptionTier.business:
        return 100;
      case SubscriptionTier.enterprise:
        return -1; // Unlimited
    }
  }

  /// Get AI credits per month for a tier
  static int _getAiCredits(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 5;
      case SubscriptionTier.starter:
        return 50;
      case SubscriptionTier.creator:
        return 200;
      case SubscriptionTier.business:
        return 500;
      case SubscriptionTier.enterprise:
        return -1; // Unlimited
    }
  }

  /// Get formatted price string
  String get priceString {
    if (monthlyPrice == 0) return 'Free';
    return '\$${monthlyPrice.toStringAsFixed(0)}/month';
  }

  /// Get formatted annual price string
  String? get annualPriceString {
    if (annualPrice == null || annualPrice == 0) return null;
    return '\$${annualPrice!.toStringAsFixed(0)}/year';
  }

  /// Get savings percentage for annual billing
  String? get savingsString {
    if (annualPrice == null || monthlyPrice == 0) return null;
    final monthlyTotal = monthlyPrice * 12;
    final savings = ((monthlyTotal - annualPrice!) / monthlyTotal * 100)
        .round();
    return 'Save ${savings}%';
  }

  /// Check if plan has unlimited features
  bool get hasUnlimitedArtworks => maxArtworks == -1;
  bool get hasUnlimitedStorage => storageGB == -1;
  bool get hasUnlimitedAiCredits => aiCreditsPerMonth == -1;

  /// Create a copy with modified fields
  SubscriptionPlan copyWith({
    String? id,
    String? name,
    String? description,
    SubscriptionTier? tier,
    double? monthlyPrice,
    double? annualPrice,
    List<String>? features,
    List<String>? highlights,
    bool? isPopular,
    bool? isRecommended,
    String? badgeText,
    int? maxArtworks,
    int? storageGB,
    int? aiCreditsPerMonth,
    bool? hasAnalytics,
    bool? hasPrioritySupport,
    bool? hasApiAccess,
    bool? hasCustomBranding,
    bool? hasTeamCollaboration,
    int? maxTeamMembers,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tier: tier ?? this.tier,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      annualPrice: annualPrice ?? this.annualPrice,
      features: features ?? this.features,
      highlights: highlights ?? this.highlights,
      isPopular: isPopular ?? this.isPopular,
      isRecommended: isRecommended ?? this.isRecommended,
      badgeText: badgeText ?? this.badgeText,
      maxArtworks: maxArtworks ?? this.maxArtworks,
      storageGB: storageGB ?? this.storageGB,
      aiCreditsPerMonth: aiCreditsPerMonth ?? this.aiCreditsPerMonth,
      hasAnalytics: hasAnalytics ?? this.hasAnalytics,
      hasPrioritySupport: hasPrioritySupport ?? this.hasPrioritySupport,
      hasApiAccess: hasApiAccess ?? this.hasApiAccess,
      hasCustomBranding: hasCustomBranding ?? this.hasCustomBranding,
      hasTeamCollaboration: hasTeamCollaboration ?? this.hasTeamCollaboration,
      maxTeamMembers: maxTeamMembers ?? this.maxTeamMembers,
    );
  }
}

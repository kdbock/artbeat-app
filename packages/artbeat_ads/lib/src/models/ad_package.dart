import '../models/ad_zone.dart';
import '../models/ad_size.dart';

/// Predefined ad packages that combine zone + size + duration into fixed IAP products
enum AdPackage {
  // Basic Packages (7 days)
  basicPremiumSmall,
  basicPremiumMedium,
  basicPremiumLarge,
  basicStandardSmall,
  basicStandardMedium,
  basicStandardLarge,
  basicBudgetSmall,
  basicBudgetMedium,
  basicBudgetLarge,

  // Standard Packages (14 days)
  standardPremiumSmall,
  standardPremiumMedium,
  standardPremiumLarge,
  standardStandardSmall,
  standardStandardMedium,
  standardStandardLarge,
  standardBudgetSmall,
  standardBudgetMedium,
  standardBudgetLarge,

  // Premium Packages (30 days)
  premiumPremiumSmall,
  premiumPremiumMedium,
  premiumPremiumLarge,
  premiumStandardSmall,
  premiumStandardMedium,
  premiumStandardLarge,
  premiumBudgetSmall,
  premiumBudgetMedium,
  premiumBudgetLarge,
}

/// Zone groupings for simplified packages
enum AdZoneGroup {
  premium, // Home & Discovery, Community & Social
  standard, // Art & Walks, Events & Experiences
  budget, // Artist Profiles only
}

extension AdZoneGroupExtension on AdZoneGroup {
  String get displayName {
    switch (this) {
      case AdZoneGroup.premium:
        return 'Premium Zones';
      case AdZoneGroup.standard:
        return 'Standard Zones';
      case AdZoneGroup.budget:
        return 'Budget Zone';
    }
  }

  String get description {
    switch (this) {
      case AdZoneGroup.premium:
        return 'Home & Discovery, Community & Social - High traffic areas';
      case AdZoneGroup.standard:
        return 'Art & Walks, Events & Experiences - Targeted audiences';
      case AdZoneGroup.budget:
        return 'Artist Profiles - Niche targeting, cost-effective';
    }
  }

  List<AdZone> get zones {
    switch (this) {
      case AdZoneGroup.premium:
        return [AdZone.homeDiscovery, AdZone.communitySocial];
      case AdZoneGroup.standard:
        return [AdZone.artWalks, AdZone.events];
      case AdZoneGroup.budget:
        return [AdZone.artistProfiles];
    }
  }

  /// Get the primary zone for this group (used for ad placement)
  AdZone get primaryZone {
    switch (this) {
      case AdZoneGroup.premium:
        return AdZone.homeDiscovery; // Default to highest traffic
      case AdZoneGroup.standard:
        return AdZone.artWalks; // Default to art-focused
      case AdZoneGroup.budget:
        return AdZone.artistProfiles;
    }
  }
}

extension AdPackageExtension on AdPackage {
  /// Get the IAP product ID for this package
  String get productId {
    switch (this) {
      // Basic Packages (7 days)
      case AdPackage.basicPremiumSmall:
        return 'ad_basic_premium_small';
      case AdPackage.basicPremiumMedium:
        return 'ad_basic_premium_medium';
      case AdPackage.basicPremiumLarge:
        return 'ad_basic_premium_large';
      case AdPackage.basicStandardSmall:
        return 'ad_basic_standard_small';
      case AdPackage.basicStandardMedium:
        return 'ad_basic_standard_medium';
      case AdPackage.basicStandardLarge:
        return 'ad_basic_standard_large';
      case AdPackage.basicBudgetSmall:
        return 'ad_basic_budget_small';
      case AdPackage.basicBudgetMedium:
        return 'ad_basic_budget_medium';
      case AdPackage.basicBudgetLarge:
        return 'ad_basic_budget_large';

      // Standard Packages (14 days)
      case AdPackage.standardPremiumSmall:
        return 'ad_standard_premium_small';
      case AdPackage.standardPremiumMedium:
        return 'ad_standard_premium_medium';
      case AdPackage.standardPremiumLarge:
        return 'ad_standard_premium_large';
      case AdPackage.standardStandardSmall:
        return 'ad_standard_standard_small';
      case AdPackage.standardStandardMedium:
        return 'ad_standard_standard_medium';
      case AdPackage.standardStandardLarge:
        return 'ad_standard_standard_large';
      case AdPackage.standardBudgetSmall:
        return 'ad_standard_budget_small';
      case AdPackage.standardBudgetMedium:
        return 'ad_standard_budget_medium';
      case AdPackage.standardBudgetLarge:
        return 'ad_standard_budget_large';

      // Premium Packages (30 days)
      case AdPackage.premiumPremiumSmall:
        return 'ad_premium_premium_small';
      case AdPackage.premiumPremiumMedium:
        return 'ad_premium_premium_medium';
      case AdPackage.premiumPremiumLarge:
        return 'ad_premium_premium_large';
      case AdPackage.premiumStandardSmall:
        return 'ad_premium_standard_small';
      case AdPackage.premiumStandardMedium:
        return 'ad_premium_standard_medium';
      case AdPackage.premiumStandardLarge:
        return 'ad_premium_standard_large';
      case AdPackage.premiumBudgetSmall:
        return 'ad_premium_budget_small';
      case AdPackage.premiumBudgetMedium:
        return 'ad_premium_budget_medium';
      case AdPackage.premiumBudgetLarge:
        return 'ad_premium_budget_large';
    }
  }

  /// Get the fixed price for this package
  double get price {
    switch (this) {
      // Basic Packages (7 days)
      case AdPackage.basicPremiumSmall:
        return 14.99;
      case AdPackage.basicPremiumMedium:
        return 24.99;
      case AdPackage.basicPremiumLarge:
        return 34.99;
      case AdPackage.basicStandardSmall:
        return 9.99;
      case AdPackage.basicStandardMedium:
        return 19.99;
      case AdPackage.basicStandardLarge:
        return 29.99;
      case AdPackage.basicBudgetSmall:
        return 4.99;
      case AdPackage.basicBudgetMedium:
        return 14.99;
      case AdPackage.basicBudgetLarge:
        return 24.99;

      // Standard Packages (14 days)
      case AdPackage.standardPremiumSmall:
        return 29.99;
      case AdPackage.standardPremiumMedium:
        return 49.99;
      case AdPackage.standardPremiumLarge:
        return 69.99;
      case AdPackage.standardStandardSmall:
        return 19.99;
      case AdPackage.standardStandardMedium:
        return 39.99;
      case AdPackage.standardStandardLarge:
        return 59.99;
      case AdPackage.standardBudgetSmall:
        return 9.99;
      case AdPackage.standardBudgetMedium:
        return 29.99;
      case AdPackage.standardBudgetLarge:
        return 49.99;

      // Premium Packages (30 days)
      case AdPackage.premiumPremiumSmall:
        return 59.99;
      case AdPackage.premiumPremiumMedium:
        return 99.99;
      case AdPackage.premiumPremiumLarge:
        return 139.99;
      case AdPackage.premiumStandardSmall:
        return 39.99;
      case AdPackage.premiumStandardMedium:
        return 79.99;
      case AdPackage.premiumStandardLarge:
        return 119.99;
      case AdPackage.premiumBudgetSmall:
        return 19.99;
      case AdPackage.premiumBudgetMedium:
        return 59.99;
      case AdPackage.premiumBudgetLarge:
        return 99.99;
    }
  }

  /// Get the duration in days for this package
  int get durationDays {
    if (productId.contains('basic')) return 7;
    if (productId.contains('standard')) return 14;
    if (productId.contains('premium')) return 30;
    return 7; // Default fallback
  }

  /// Get the zone group for this package
  AdZoneGroup get zoneGroup {
    if (productId.contains('premium')) return AdZoneGroup.premium;
    if (productId.contains('standard')) return AdZoneGroup.standard;
    if (productId.contains('budget')) return AdZoneGroup.budget;
    return AdZoneGroup.budget; // Default fallback
  }

  /// Get the ad size for this package
  AdSize get adSize {
    if (productId.contains('small')) return AdSize.small;
    if (productId.contains('medium')) return AdSize.medium;
    if (productId.contains('large')) return AdSize.large;
    return AdSize.small; // Default fallback
  }

  /// Get display name for this package
  String get displayName {
    final tier = productId.contains('basic')
        ? 'Basic'
        : productId.contains('standard')
        ? 'Standard'
        : 'Premium';
    final zone = zoneGroup.displayName;
    final size = adSize.displayName.split(
      ' ',
    )[0]; // Get just "Small", "Medium", "Large"

    return '$tier - $size Ad in $zone';
  }

  /// Get detailed description for this package
  String get description {
    return '${adSize.displayName} advertisement in ${zoneGroup.description} for $durationDays days';
  }

  /// Get the tier name (Basic, Standard, Premium)
  String get tierName {
    if (productId.contains('basic')) return 'Basic';
    if (productId.contains('standard')) return 'Standard';
    if (productId.contains('premium')) return 'Premium';
    return 'Basic';
  }
}

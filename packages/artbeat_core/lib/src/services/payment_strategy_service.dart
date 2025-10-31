import 'package:artbeat_core/src/models/in_app_purchase_models.dart';
import 'package:artbeat_core/src/models/subscription_tier.dart';

/// Enum for different ARTbeat modules
enum ArtbeatModule {
  core, // artbeat_core - subscriptions, AI credits
  artist, // artbeat_artist - payouts, commissions
  ads, // artbeat_ads - advertising
  events, // artbeat_events - ticketing
  messaging, // artbeat_messaging - gifts, chat perks
  capture, // artbeat_capture - premium features
  artWalk, // artbeat_art_walk - premium features
  profile, // artbeat_profile - customization
  settings, // artbeat_settings - premium settings
}

/// Enum for payment methods
enum PaymentMethod {
  iap, // In-App Purchase (Apple/Google)
  stripe, // Stripe payment processing
}

/// Payment strategy service that routes payments to appropriate providers
/// based on ARTbeat's hybrid payment model
class PaymentStrategyService {
  static final PaymentStrategyService _instance =
      PaymentStrategyService._internal();
  factory PaymentStrategyService() => _instance;
  PaymentStrategyService._internal();

  /// Get the appropriate payment method for a purchase type in a specific module
  PaymentMethod getPaymentMethod(
    PurchaseType purchaseType,
    ArtbeatModule module,
  ) {
    switch (module) {
      case ArtbeatModule.core:
        return _getCorePaymentMethod(purchaseType);
      case ArtbeatModule.artist:
        return _getArtistPaymentMethod(purchaseType);
      case ArtbeatModule.ads:
        return _getAdsPaymentMethod(purchaseType);
      case ArtbeatModule.events:
        return _getEventsPaymentMethod(purchaseType);
      case ArtbeatModule.messaging:
        return _getMessagingPaymentMethod(purchaseType);
      case ArtbeatModule.capture:
      case ArtbeatModule.artWalk:
        return _getCaptureArtWalkPaymentMethod(purchaseType);
      case ArtbeatModule.profile:
      case ArtbeatModule.settings:
        return _getProfileSettingsPaymentMethod(purchaseType);
    }
  }

  /// Core module payment strategy
  PaymentMethod _getCorePaymentMethod(PurchaseType purchaseType) {
    switch (purchaseType) {
      case PurchaseType.subscription:
        return PaymentMethod.iap; // App Store requirement
      case PurchaseType.consumable:
        return PaymentMethod.iap; // AI credits, digital goods
      case PurchaseType.nonConsumable:
        return PaymentMethod.iap; // Premium features
    }
  }

  /// Artist module payment strategy - primarily Stripe for payouts
  PaymentMethod _getArtistPaymentMethod(PurchaseType purchaseType) {
    // Artist earnings require Stripe for payouts to bank accounts
    return PaymentMethod.stripe;
  }

  /// Ads module payment strategy - IAP required (Apple policy)
  PaymentMethod _getAdsPaymentMethod(PurchaseType purchaseType) {
    // Advertising purchases are digital goods and MUST use IAP (Apple Guideline 3.1.1)
    return PaymentMethod.iap;
  }

  /// Events module payment strategy - hybrid based on event type
  PaymentMethod _getEventsPaymentMethod(PurchaseType purchaseType) {
    // Physical events require Stripe for payouts to organizers
    // Virtual/digital events can use IAP
    return PaymentMethod.stripe; // Default to Stripe for safety
  }

  /// Messaging module payment strategy - hybrid for gifts vs digital perks
  PaymentMethod _getMessagingPaymentMethod(PurchaseType purchaseType) {
    switch (purchaseType) {
      case PurchaseType.consumable:
        // Digital-only perks (emoji packs, themes) can use IAP
        return PaymentMethod.iap;
      case PurchaseType.nonConsumable:
        // Gifts that may result in payouts should use Stripe
        return PaymentMethod.stripe;
      case PurchaseType.subscription:
        return PaymentMethod.iap;
    }
  }

  /// Capture/Art Walk payment strategy
  PaymentMethod _getCaptureArtWalkPaymentMethod(PurchaseType purchaseType) {
    // Premium features and digital unlocks use IAP
    return PaymentMethod.iap;
  }

  /// Profile/Settings payment strategy
  PaymentMethod _getProfileSettingsPaymentMethod(PurchaseType purchaseType) {
    // All profile customizations are digital goods
    return PaymentMethod.iap;
  }

  /// Check if a purchase requires payout processing
  bool requiresPayout(ArtbeatModule module, PurchaseType purchaseType) {
    final method = getPaymentMethod(purchaseType, module);
    return method == PaymentMethod.stripe;
  }

  /// Get payment method for subscription tier upgrades
  PaymentMethod getSubscriptionPaymentMethod(SubscriptionTier tier) {
    // All subscriptions must use IAP per App Store rules
    return PaymentMethod.iap;
  }

  /// Validate payment method for a specific use case
  bool isValidPaymentMethod(
    PaymentMethod method,
    PurchaseType purchaseType,
    ArtbeatModule module,
  ) {
    final requiredMethod = getPaymentMethod(purchaseType, module);
    return method == requiredMethod;
  }

  /// Get human-readable explanation for payment method choice
  String getPaymentMethodExplanation(
    PaymentMethod method,
    PurchaseType purchaseType,
    ArtbeatModule module,
  ) {
    if (method == PaymentMethod.iap) {
      switch (purchaseType) {
        case PurchaseType.subscription:
          return 'Subscriptions use In-App Purchases to comply with App Store policies';
        case PurchaseType.consumable:
          return 'Digital items use In-App Purchases for secure processing';
        case PurchaseType.nonConsumable:
          return 'Premium features use In-App Purchases for one-time unlocks';
      }
    } else {
      return 'This purchase requires Stripe for payout processing to artists/organizers';
    }
  }
}

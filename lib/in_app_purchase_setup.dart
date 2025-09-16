import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Setup and initialize in-app purchases for the app
class InAppPurchaseSetup {
  factory InAppPurchaseSetup() => _instance;
  InAppPurchaseSetup._internal();
  static final InAppPurchaseSetup _instance = InAppPurchaseSetup._internal();

  final InAppPurchaseManager _purchaseManager = InAppPurchaseManager();
  bool _isInitialized = false;

  /// Initialize in-app purchases
  Future<bool> initialize() async {
    if (_isInitialized) {
      AppLogger.info('In-app purchases already initialized');
      return true;
    }

    try {
      AppLogger.info('🚀 Setting up in-app purchases...');

      // Initialize the purchase manager
      final success = await _purchaseManager.initialize();

      if (success) {
        _isInitialized = true;
        AppLogger.info('✅ In-app purchases initialized successfully');

        // Set up purchase event listeners
        _setupPurchaseListeners();

        return true;
      } else {
        AppLogger.error('❌ Failed to initialize in-app purchases');
        return false;
      }
    } catch (e) {
      AppLogger.error('❌ Error initializing in-app purchases: $e');
      return false;
    }
  }

  /// Set up purchase event listeners
  void _setupPurchaseListeners() {
    _purchaseManager.purchaseEventStream.listen(
      (event) {
        switch (event.type) {
          case PurchaseEventType.completed:
            _handlePurchaseCompleted(event);
            break;
          case PurchaseEventType.error:
            _handlePurchaseError(event);
            break;
          case PurchaseEventType.cancelled:
            _handlePurchaseCancelled(event);
            break;
        }
      },
      onError: (Object error) {
        AppLogger.error('Purchase event stream error: $error');
      },
    );
  }

  /// Handle completed purchase
  void _handlePurchaseCompleted(PurchaseEvent event) {
    final purchase = event.purchase!;
    AppLogger.info('🎉 Purchase completed: ${purchase.productId}');

    // You can add additional handling here, such as:
    // - Showing success notifications
    // - Updating UI
    // - Analytics tracking
    // - etc.
  }

  /// Handle purchase error
  void _handlePurchaseError(PurchaseEvent event) {
    AppLogger.error('❌ Purchase error: ${event.error}');

    // You can add additional error handling here, such as:
    // - Showing error notifications
    // - Analytics tracking
    // - Error reporting
    // etc.
  }

  /// Handle purchase cancellation
  void _handlePurchaseCancelled(PurchaseEvent event) {
    AppLogger.info('❌ Purchase cancelled: ${event.productId}');

    // You can add additional handling here, such as:
    // - Analytics tracking
    // - UI updates
    // etc.
  }

  /// Get the purchase manager instance
  InAppPurchaseManager get purchaseManager => _purchaseManager;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _purchaseManager.dispose();
    _isInitialized = false;
  }
}

/// Helper class for common purchase operations
class PurchaseHelper {
  static final InAppPurchaseManager _purchaseManager = InAppPurchaseManager();

  /// Quick subscription purchase
  static Future<bool> subscribeToTier(
    SubscriptionTier tier, {
    bool isYearly = false,
  }) => _purchaseManager.subscribeToTier(tier, isYearly: isYearly);

  /// Quick gift purchase
  static Future<bool> sendGift({
    required String recipientId,
    required String giftProductId,
    required String message,
  }) => _purchaseManager.purchaseGift(
    recipientId: recipientId,
    giftProductId: giftProductId,
    message: message,
  );

  /// Quick ad purchase
  static Future<bool> promoteArtwork({
    required String artworkId,
    required String adPackageId,
    Map<String, dynamic>? targetingOptions,
  }) => _purchaseManager.purchaseAdPackage(
    adProductId: adPackageId,
    artworkId: artworkId,
    targetingOptions:
        targetingOptions ??
        {
          'ageRange': '18-65',
          'interests': ['Art'],
          'location': 'global',
          'deviceTypes': ['mobile', 'tablet'],
        },
  );

  /// Get user's subscription status
  static Future<Map<String, dynamic>> getSubscriptionStatus(String userId) =>
      _purchaseManager.getUserSubscriptionStatus(userId);

  /// Check if user can access a feature
  static Future<bool> canAccessFeature(String userId, String feature) =>
      _purchaseManager.canAccessFeature(userId, feature);

  /// Get available subscription tiers
  static List<Map<String, dynamic>> getSubscriptionTiers() =>
      _purchaseManager.getAllSubscriptionPricing();

  /// Get available gifts
  static List<Map<String, dynamic>> getAvailableGifts() =>
      _purchaseManager.getAvailableGifts();

  /// Get available ad packages
  static List<Map<String, dynamic>> getAvailableAdPackages() =>
      _purchaseManager.getAvailableAdPackages();

  /// Get user's purchase history
  static Future<List<CompletedPurchase>> getPurchaseHistory(String userId) =>
      _purchaseManager.getUserPurchaseHistory(userId);

  /// Get user's gift statistics
  static Future<Map<String, dynamic>> getGiftStatistics(String userId) =>
      _purchaseManager.getGiftStatistics(userId);

  /// Get user's ad statistics
  static Future<Map<String, dynamic>> getAdStatistics(String userId) =>
      _purchaseManager.getAdStatistics(userId);
}

/// Extension methods for easy access to purchase functionality
extension PurchaseExtensions on BuildContext {
  /// Show subscription purchase dialog
  Future<void> showSubscriptionPurchase() async {
    // This would show a subscription purchase dialog
    // Implementation depends on your UI framework
  }

  /// Show gift purchase dialog
  Future<void> showGiftPurchase({
    String? recipientId,
    String? recipientName,
  }) async {
    // This would show a gift purchase dialog
    // Implementation depends on your UI framework
  }

  /// Show ad purchase dialog
  Future<void> showAdPurchase({String? artworkId, String? artworkTitle}) async {
    // This would show an ad purchase dialog
    // Implementation depends on your UI framework
  }
}

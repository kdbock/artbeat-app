import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/in_app_purchase_models.dart';
import '../models/subscription_tier.dart';
import '../utils/logger.dart';

/// Service for handling in-app purchases across iOS and Android
class InAppPurchaseService {
  static final InAppPurchaseService _instance =
      InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  InAppPurchaseService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  // Product IDs for different purchase types
  static const Map<String, List<String>> _productIds = {
    'subscriptions': [
      'artbeat_starter_monthly',
      'artbeat_creator_monthly',
      'artbeat_business_monthly',
      'artbeat_enterprise_monthly',
      'artbeat_starter_yearly',
      'artbeat_creator_yearly',
      'artbeat_business_yearly',
      'artbeat_enterprise_yearly',
    ],
    'gifts': [
      'artbeat_gift_small', // $5
      'artbeat_gift_medium', // $10
      'artbeat_gift_large', // $25
      'artbeat_gift_premium', // $50
      'artbeat_gift_custom', // Custom amount
    ],
    'ads': [
      'artbeat_ad_basic', // Basic ad package
      'artbeat_ad_standard', // Standard ad package
      'artbeat_ad_premium', // Premium ad package
      'artbeat_ad_enterprise', // Enterprise ad package
    ],
  };

  // Callbacks for purchase events
  void Function(CompletedPurchase)? onPurchaseCompleted;
  void Function(String)? onPurchaseError;
  void Function(String)? onPurchaseCancelled;

  /// Initialize the in-app purchase service
  Future<bool> initialize() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();

      if (!_isAvailable) {
        AppLogger.warning('⚠️ In-app purchases not available on this device');
        return false;
      }

      // Set up purchase listener
      final Stream<List<PurchaseDetails>> purchaseUpdated =
          _inAppPurchase.purchaseStream;
      _subscription = purchaseUpdated.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) => AppLogger.error('Purchase stream error: $error'),
      );

      // Load products
      await _loadProducts();

      // Restore purchases
      await _restorePurchases();

      AppLogger.info('✅ In-app purchase service initialized successfully');
      return true;
    } catch (e) {
      AppLogger.error('❌ Failed to initialize in-app purchase service: $e');
      return false;
    }
  }

  /// Load available products from the stores
  Future<void> _loadProducts() async {
    try {
      final Set<String> allProductIds = {};
      _productIds.values.forEach((ids) => allProductIds.addAll(ids));

      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(allProductIds);

      if (response.error != null) {
        AppLogger.error('Error loading products: ${response.error}');
        return;
      }

      _products = response.productDetails;
      AppLogger.info('✅ Loaded ${_products.length} products');

      for (final product in _products) {
        AppLogger.info(
          'Product: ${product.id} - ${product.title} - ${product.price}',
        );
      }
    } catch (e) {
      AppLogger.error('Error loading products: $e');
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _handlePurchaseUpdate(purchaseDetails);
    }
  }

  /// Handle individual purchase update
  Future<void> _handlePurchaseUpdate(PurchaseDetails purchaseDetails) async {
    try {
      AppLogger.info(
        'Purchase update: ${purchaseDetails.productID} - ${purchaseDetails.status}',
      );

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          AppLogger.info('Purchase pending: ${purchaseDetails.productID}');
          break;

        case PurchaseStatus.purchased:
          await _handleSuccessfulPurchase(purchaseDetails);
          break;

        case PurchaseStatus.error:
          AppLogger.error('Purchase error: ${purchaseDetails.error}');
          onPurchaseError?.call(
            purchaseDetails.error?.message ?? 'Unknown error',
          );
          break;

        case PurchaseStatus.canceled:
          AppLogger.info('Purchase cancelled: ${purchaseDetails.productID}');
          onPurchaseCancelled?.call(purchaseDetails.productID);
          break;

        case PurchaseStatus.restored:
          await _handleRestoredPurchase(purchaseDetails);
          break;
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    } catch (e) {
      AppLogger.error('Error handling purchase update: ${e.toString()}');
    }
  }

  /// Handle successful purchase
  Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchaseDetails,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.error('User not authenticated for purchase');
        return;
      }

      // Verify purchase with server (important for security)
      final isValid = await _verifyPurchase(purchaseDetails);
      if (!isValid) {
        AppLogger.error('Purchase verification failed');
        return;
      }

      // Determine purchase type and category
      final purchaseType = _getPurchaseType(purchaseDetails.productID);
      final purchaseCategory = _getPurchaseCategory(purchaseDetails.productID);
      final product = _getProductDetails(purchaseDetails.productID);

      if (product == null) {
        AppLogger.error('Product not found: ${purchaseDetails.productID}');
        return;
      }

      // Create completed purchase record
      final completedPurchase = CompletedPurchase(
        purchaseId:
            purchaseDetails.purchaseID ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        productId: purchaseDetails.productID,
        userId: user.uid,
        purchaseDate: DateTime.now(),
        status: 'completed',
        type: purchaseType,
        category: purchaseCategory,
        amount: _getProductPrice(product),
        currency: _getProductCurrency(product),
        transactionId: purchaseDetails.purchaseID,
        metadata: {
          'platform': Platform.isIOS ? 'ios' : 'android',
          'verificationData':
              purchaseDetails.verificationData.localVerificationData,
        },
      );

      // Save to Firestore
      await _savePurchaseToFirestore(completedPurchase);

      // Handle specific purchase types
      await _processPurchaseByType(completedPurchase, purchaseDetails);

      // Notify listeners
      onPurchaseCompleted?.call(completedPurchase);

      AppLogger.info(
        '✅ Purchase completed successfully: ${purchaseDetails.productID}',
      );
    } catch (e) {
      AppLogger.error('Error handling successful purchase: $e');
    }
  }

  /// Handle restored purchase
  Future<void> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    try {
      AppLogger.info('Restoring purchase: ${purchaseDetails.productID}');

      // For non-consumable and subscription purchases, restore the benefits
      final purchaseType = _getPurchaseType(purchaseDetails.productID);
      if (purchaseType != PurchaseType.consumable) {
        await _handleSuccessfulPurchase(purchaseDetails);
      }
    } catch (e) {
      AppLogger.error('Error handling restored purchase: $e');
    }
  }

  /// Verify purchase with server (implement server-side verification)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // TODO: Implement server-side verification
      // For now, return true, but in production you should verify with Apple/Google servers
      return true;
    } catch (e) {
      AppLogger.error('Error verifying purchase: $e');
      return false;
    }
  }

  /// Save purchase to Firestore
  Future<void> _savePurchaseToFirestore(CompletedPurchase purchase) async {
    try {
      await _firestore
          .collection('purchases')
          .doc(purchase.purchaseId)
          .set(purchase.toFirestore());

      AppLogger.info('✅ Purchase saved to Firestore: ${purchase.purchaseId}');
    } catch (e) {
      AppLogger.error('Error saving purchase to Firestore: $e');
    }
  }

  /// Process purchase based on type
  Future<void> _processPurchaseByType(
    CompletedPurchase purchase,
    PurchaseDetails details,
  ) async {
    switch (purchase.category) {
      case PurchaseCategory.subscription:
        await _processSubscriptionPurchase(purchase, details);
        break;
      case PurchaseCategory.gifts:
        await _processGiftPurchase(purchase, details);
        break;
      case PurchaseCategory.ads:
        await _processAdPurchase(purchase, details);
        break;
      case PurchaseCategory.premium:
        await _processPremiumPurchase(purchase, details);
        break;
    }
  }

  /// Process subscription purchase
  Future<void> _processSubscriptionPurchase(
    CompletedPurchase purchase,
    PurchaseDetails details,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Determine subscription tier from product ID
      final tier = _getSubscriptionTierFromProductId(purchase.productId);
      final isYearly = purchase.productId.contains('yearly');

      // Calculate expiry date
      final expiryDate = DateTime.now().add(
        isYearly ? const Duration(days: 365) : const Duration(days: 30),
      );

      // Create subscription details
      final subscription = SubscriptionDetails(
        subscriptionId: purchase.purchaseId,
        productId: purchase.productId,
        userId: user.uid,
        startDate: purchase.purchaseDate,
        endDate: expiryDate,
        status: 'active',
        autoRenewing: true,
        price: purchase.amount,
        currency: purchase.currency,
        nextBillingDate: expiryDate,
      );

      // Save subscription
      await _firestore
          .collection('subscriptions')
          .doc(subscription.subscriptionId)
          .set(subscription.toFirestore());

      // Update user's subscription tier
      await _firestore.collection('users').doc(user.uid).update({
        'subscriptionTier': tier.apiName,
        'subscriptionStatus': 'active',
        'subscriptionExpiryDate': Timestamp.fromDate(expiryDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Subscription processed: ${tier.displayName}');
    } catch (e) {
      AppLogger.error('Error processing subscription purchase: $e');
    }
  }

  /// Process gift purchase
  Future<void> _processGiftPurchase(
    CompletedPurchase purchase,
    PurchaseDetails details,
  ) async {
    try {
      // Gift processing will be handled by the gift service
      // This is just to record the purchase
      AppLogger.info('✅ Gift purchase processed: ${purchase.productId}');
    } catch (e) {
      AppLogger.error('Error processing gift purchase: $e');
    }
  }

  /// Process ad purchase
  Future<void> _processAdPurchase(
    CompletedPurchase purchase,
    PurchaseDetails details,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Determine ad credits based on product
      final adCredits = _getAdCreditsFromProductId(purchase.productId);

      // Add ad credits to user account
      await _firestore.collection('users').doc(user.uid).update({
        'adCredits': FieldValue.increment(adCredits),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Ad purchase processed: $adCredits credits added');
    } catch (e) {
      AppLogger.error('Error processing ad purchase: $e');
    }
  }

  /// Process premium purchase
  Future<void> _processPremiumPurchase(
    CompletedPurchase purchase,
    PurchaseDetails details,
  ) async {
    try {
      // Handle premium feature unlocks
      AppLogger.info('✅ Premium purchase processed: ${purchase.productId}');
    } catch (e) {
      AppLogger.error('Error processing premium purchase: $e');
    }
  }

  /// Purchase a product
  Future<bool> purchaseProduct(
    String productId, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!_isAvailable) {
        AppLogger.error('In-app purchases not available');
        return false;
      }

      final product = _getProductDetails(productId);
      if (product == null) {
        AppLogger.error('Product not found: $productId');
        return false;
      }

      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.error('User not authenticated');
        return false;
      }

      // Create purchase param
      final purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: user.uid,
      );

      // Initiate purchase
      final purchaseType = _getPurchaseType(productId);
      bool result;

      if (purchaseType == PurchaseType.consumable) {
        result = await _inAppPurchase.buyConsumable(
          purchaseParam: purchaseParam,
        );
      } else {
        result = await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      }

      AppLogger.info('Purchase initiated: $productId - Result: $result');
      return result;
    } catch (e) {
      AppLogger.error('Error purchasing product: $e');
      return false;
    }
  }

  /// Restore purchases
  Future<void> _restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      AppLogger.info('✅ Purchases restored');
    } catch (e) {
      AppLogger.error('Error restoring purchases: $e');
    }
  }

  /// Get available products by category
  List<ProductDetails> getProductsByCategory(PurchaseCategory category) {
    final categoryProductIds = _productIds[category.name] ?? [];
    return _products
        .where((product) => categoryProductIds.contains(product.id))
        .toList();
  }

  /// Get subscription products
  List<ProductDetails> getSubscriptionProducts() {
    return getProductsByCategory(PurchaseCategory.subscription);
  }

  /// Get gift products
  List<ProductDetails> getGiftProducts() {
    return getProductsByCategory(PurchaseCategory.gifts);
  }

  /// Get ad products
  List<ProductDetails> getAdProducts() {
    return getProductsByCategory(PurchaseCategory.ads);
  }

  /// Helper methods
  PurchaseType _getPurchaseType(String productId) {
    if (_productIds['subscriptions']!.contains(productId)) {
      return PurchaseType.subscription;
    } else if (_productIds['gifts']!.contains(productId) ||
        _productIds['ads']!.contains(productId)) {
      return PurchaseType.consumable;
    }
    return PurchaseType.nonConsumable;
  }

  PurchaseCategory _getPurchaseCategory(String productId) {
    if (_productIds['subscriptions']!.contains(productId)) {
      return PurchaseCategory.subscription;
    } else if (_productIds['gifts']!.contains(productId)) {
      return PurchaseCategory.gifts;
    } else if (_productIds['ads']!.contains(productId)) {
      return PurchaseCategory.ads;
    }
    return PurchaseCategory.premium;
  }

  ProductDetails? _getProductDetails(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  double _getProductPrice(ProductDetails product) {
    return product.rawPrice;
  }

  String _getProductCurrency(ProductDetails product) {
    return product.currencyCode;
  }

  SubscriptionTier _getSubscriptionTierFromProductId(String productId) {
    if (productId.contains('starter')) return SubscriptionTier.starter;
    if (productId.contains('creator')) return SubscriptionTier.creator;
    if (productId.contains('business')) return SubscriptionTier.business;
    if (productId.contains('enterprise')) return SubscriptionTier.enterprise;
    return SubscriptionTier.free;
  }

  int _getAdCreditsFromProductId(String productId) {
    switch (productId) {
      case 'artbeat_ad_basic':
        return 100;
      case 'artbeat_ad_standard':
        return 500;
      case 'artbeat_ad_premium':
        return 1000;
      case 'artbeat_ad_enterprise':
        return 5000;
      default:
        return 0;
    }
  }

  /// Get user's active subscriptions
  Future<List<SubscriptionDetails>> getUserActiveSubscriptions(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs
          .map((doc) => SubscriptionDetails.fromFirestore(doc))
          .where((sub) => sub.isActive)
          .toList();
    } catch (e) {
      AppLogger.error('Error getting user subscriptions: $e');
      return [];
    }
  }

  /// Get user's purchase history
  Future<List<CompletedPurchase>> getUserPurchaseHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('purchases')
          .where('userId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CompletedPurchase.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting purchase history: $e');
      return [];
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription(String userId) async {
    final subscriptions = await getUserActiveSubscriptions(userId);
    return subscriptions.isNotEmpty;
  }

  /// Get user's current subscription tier
  Future<SubscriptionTier> getUserSubscriptionTier(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final tierName = data['subscriptionTier'] as String?;
        if (tierName != null) {
          return SubscriptionTier.fromLegacyName(tierName);
        }
      }
      return SubscriptionTier.free;
    } catch (e) {
      AppLogger.error('Error getting user subscription tier: $e');
      return SubscriptionTier.free;
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
  }

  /// Check if service is available
  bool get isAvailable => _isAvailable;

  /// Get all available products
  List<ProductDetails> get products => _products;
}

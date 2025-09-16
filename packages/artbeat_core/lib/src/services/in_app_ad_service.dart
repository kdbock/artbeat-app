import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/in_app_purchase_models.dart';
import '../utils/logger.dart';
import 'in_app_purchase_service.dart';

/// Service for handling ad-specific in-app purchases
class InAppAdService {
  static final InAppAdService _instance = InAppAdService._internal();
  factory InAppAdService() => _instance;
  InAppAdService._internal();

  final InAppPurchaseService _purchaseService = InAppPurchaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ad product configurations
  static const Map<String, Map<String, dynamic>> _adProducts = {
    'artbeat_ad_basic': {
      'amount': 9.99,
      'title': 'Basic Ad Package',
      'description': '100 ad impressions for your artwork',
      'impressions': 100,
      'duration_days': 7,
      'features': ['Basic targeting', 'Standard placement'],
    },
    'artbeat_ad_standard': {
      'amount': 24.99,
      'title': 'Standard Ad Package',
      'description': '500 ad impressions with better targeting',
      'impressions': 500,
      'duration_days': 14,
      'features': ['Advanced targeting', 'Priority placement', 'Analytics'],
    },
    'artbeat_ad_premium': {
      'amount': 49.99,
      'title': 'Premium Ad Package',
      'description': '1000 ad impressions with premium features',
      'impressions': 1000,
      'duration_days': 30,
      'features': [
        'Premium targeting',
        'Featured placement',
        'Detailed analytics',
        'A/B testing',
      ],
    },
    'artbeat_ad_enterprise': {
      'amount': 99.99,
      'title': 'Enterprise Ad Package',
      'description': '5000 ad impressions with enterprise features',
      'impressions': 5000,
      'duration_days': 60,
      'features': [
        'Enterprise targeting',
        'Top placement',
        'Advanced analytics',
        'Custom campaigns',
        'Dedicated support',
      ],
    },
  };

  /// Purchase an ad package
  Future<bool> purchaseAdPackage({
    required String adProductId,
    required String artworkId,
    required Map<String, dynamic> targetingOptions,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.error('User not authenticated for ad purchase');
        return false;
      }

      // Validate ad product
      if (!_adProducts.containsKey(adProductId)) {
        AppLogger.error('Invalid ad product: $adProductId');
        return false;
      }

      // Validate artwork exists and belongs to user
      final artworkExists = await _validateArtwork(artworkId, user.uid);
      if (!artworkExists) {
        AppLogger.error('Artwork not found or not owned by user: $artworkId');
        return false;
      }

      // Purchase the ad product
      final success = await _purchaseService.purchaseProduct(
        adProductId,
        metadata: {
          'type': 'ad',
          'userId': user.uid,
          'artworkId': artworkId,
          'targetingOptions': targetingOptions,
          ...?metadata,
        },
      );

      if (success) {
        AppLogger.info(
          '✅ Ad purchase initiated: $adProductId for artwork $artworkId',
        );

        // Create pending ad campaign
        await _createPendingAdCampaign(
          userId: user.uid,
          productId: adProductId,
          artworkId: artworkId,
          targetingOptions: targetingOptions,
        );
      } else {
        AppLogger.error('❌ Failed to initiate ad purchase');
      }

      return success;
    } catch (e) {
      AppLogger.error('Error purchasing ad package: $e');
      return false;
    }
  }

  /// Create a pending ad campaign
  Future<void> _createPendingAdCampaign({
    required String userId,
    required String productId,
    required String artworkId,
    required Map<String, dynamic> targetingOptions,
  }) async {
    try {
      final adData = _adProducts[productId]!;
      final expiryDate = DateTime.now().add(
        Duration(days: adData['duration_days'] as int),
      );

      final adPurchase = InAppAdPurchase(
        id: '', // Will be set by Firestore
        userId: userId,
        productId: productId,
        adType: 'artwork_promotion',
        quantity: adData['impressions'] as int,
        amount: adData['amount'] as double,
        currency: 'USD',
        purchaseDate: DateTime.now(),
        expiryDate: expiryDate,
        status: 'pending',
        metadata: {
          'artworkId': artworkId,
          'targetingOptions': targetingOptions,
          'features': adData['features'],
        },
      );

      await _firestore.collection('ad_purchases').add(adPurchase.toFirestore());

      AppLogger.info('✅ Pending ad campaign created');
    } catch (e) {
      AppLogger.error('Error creating pending ad campaign: $e');
    }
  }

  /// Complete ad purchase (called after successful payment)
  Future<void> completeAdPurchase({
    required String userId,
    required String productId,
    required String transactionId,
    required String artworkId,
    required Map<String, dynamic> targetingOptions,
  }) async {
    try {
      final adData = _adProducts[productId]!;
      final expiryDate = DateTime.now().add(
        Duration(days: adData['duration_days'] as int),
      );

      // Create completed ad purchase record
      final adPurchase = InAppAdPurchase(
        id: transactionId,
        userId: userId,
        productId: productId,
        adType: 'artwork_promotion',
        quantity: adData['impressions'] as int,
        amount: adData['amount'] as double,
        currency: 'USD',
        purchaseDate: DateTime.now(),
        expiryDate: expiryDate,
        status: 'active',
        transactionId: transactionId,
        metadata: {
          'artworkId': artworkId,
          'targetingOptions': targetingOptions,
          'features': adData['features'],
        },
      );

      // Save ad purchase to Firestore
      await _firestore
          .collection('ad_purchases')
          .doc(transactionId)
          .set(adPurchase.toFirestore());

      // Create active ad campaign
      await _createAdCampaign(adPurchase, artworkId, targetingOptions);

      // Update user's ad credits
      await _updateUserAdCredits(userId, adData['impressions'] as int);

      // Update pending ad campaigns
      await _updatePendingAdCampaigns(userId, productId, 'completed');

      AppLogger.info('✅ Ad purchase completed: $productId');
    } catch (e) {
      AppLogger.error('Error completing ad purchase: $e');
    }
  }

  /// Create active ad campaign
  Future<void> _createAdCampaign(
    InAppAdPurchase adPurchase,
    String artworkId,
    Map<String, dynamic> targetingOptions,
  ) async {
    try {
      final campaign = {
        'userId': adPurchase.userId,
        'adPurchaseId': adPurchase.id,
        'artworkId': artworkId,
        'campaignName':
            'Artwork Promotion - ${DateTime.now().toIso8601String()}',
        'status': 'active',
        'totalImpressions': adPurchase.quantity,
        'remainingImpressions': adPurchase.quantity,
        'impressionsUsed': 0,
        'clicks': 0,
        'conversions': 0,
        'startDate': Timestamp.fromDate(adPurchase.purchaseDate),
        'endDate': Timestamp.fromDate(adPurchase.expiryDate!),
        'targetingOptions': targetingOptions,
        'budget': adPurchase.amount,
        'budgetUsed': 0.0,
        'cpm':
            adPurchase.amount / (adPurchase.quantity / 1000), // Cost per mille
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('ad_campaigns')
          .doc(adPurchase.id)
          .set(campaign);

      AppLogger.info('✅ Ad campaign created: ${adPurchase.id}');
    } catch (e) {
      AppLogger.error('Error creating ad campaign: $e');
    }
  }

  /// Update user's ad credits
  Future<void> _updateUserAdCredits(String userId, int impressions) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'adCredits': FieldValue.increment(impressions),
        'totalAdCreditsPurchased': FieldValue.increment(impressions),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Added $impressions ad credits to user: $userId');
    } catch (e) {
      AppLogger.error('Error updating user ad credits: $e');
    }
  }

  /// Update pending ad campaigns status
  Future<void> _updatePendingAdCampaigns(
    String userId,
    String productId,
    String status,
  ) async {
    try {
      final pendingCampaigns = await _firestore
          .collection('ad_purchases')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in pendingCampaigns.docs) {
        await doc.reference.update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      AppLogger.error('Error updating pending ad campaigns: $e');
    }
  }

  /// Validate artwork exists and belongs to user
  Future<bool> _validateArtwork(String artworkId, String userId) async {
    try {
      final doc = await _firestore.collection('artworks').doc(artworkId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      return data['artistId'] == userId;
    } catch (e) {
      AppLogger.error('Error validating artwork: $e');
      return false;
    }
  }

  /// Get available ad packages
  List<Map<String, dynamic>> getAvailableAdPackages() {
    return _adProducts.entries.map((entry) {
      return {'productId': entry.key, ...entry.value};
    }).toList();
  }

  /// Get user's ad purchases
  Future<List<InAppAdPurchase>> getUserAdPurchases(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('ad_purchases')
          .where('userId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InAppAdPurchase.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting user ad purchases: $e');
      return [];
    }
  }

  /// Get user's active ad campaigns
  Future<List<Map<String, dynamic>>> getUserActiveCampaigns(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('ad_campaigns')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'campaignId': doc.id, ...data};
      }).toList();
    } catch (e) {
      AppLogger.error('Error getting active campaigns: $e');
      return [];
    }
  }

  /// Get user's ad credits balance
  Future<int> getAdCreditsBalance(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        return data['adCredits'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      AppLogger.error('Error getting ad credits balance: $e');
      return 0;
    }
  }

  /// Use ad credits for impressions
  Future<bool> useAdCredits(String userId, int impressions) async {
    try {
      final currentBalance = await getAdCreditsBalance(userId);
      if (currentBalance < impressions) {
        AppLogger.warning(
          'Insufficient ad credits: $currentBalance < $impressions',
        );
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'adCredits': FieldValue.increment(-impressions),
        'adCreditsUsed': FieldValue.increment(impressions),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Used $impressions ad credits for user: $userId');
      return true;
    } catch (e) {
      AppLogger.error('Error using ad credits: $e');
      return false;
    }
  }

  /// Get ad campaign analytics
  Future<Map<String, dynamic>> getCampaignAnalytics(String campaignId) async {
    try {
      final campaignDoc = await _firestore
          .collection('ad_campaigns')
          .doc(campaignId)
          .get();

      if (!campaignDoc.exists) {
        return {};
      }

      final data = campaignDoc.data()!;

      // Calculate metrics
      final impressionsUsed = data['impressionsUsed'] as int? ?? 0;
      final totalImpressions = data['totalImpressions'] as int? ?? 0;
      final clicks = data['clicks'] as int? ?? 0;
      final conversions = data['conversions'] as int? ?? 0;
      final budgetUsed = (data['budgetUsed'] as num?)?.toDouble() ?? 0.0;
      final totalBudget = (data['budget'] as num?)?.toDouble() ?? 0.0;

      final ctr = impressionsUsed > 0 ? (clicks / impressionsUsed) * 100 : 0.0;
      final conversionRate = clicks > 0 ? (conversions / clicks) * 100 : 0.0;
      final cpc = clicks > 0 ? budgetUsed / clicks : 0.0;
      final cpa = conversions > 0 ? budgetUsed / conversions : 0.0;

      return {
        'campaignId': campaignId,
        'impressionsUsed': impressionsUsed,
        'totalImpressions': totalImpressions,
        'impressionsRemaining': totalImpressions - impressionsUsed,
        'clicks': clicks,
        'conversions': conversions,
        'budgetUsed': budgetUsed,
        'totalBudget': totalBudget,
        'budgetRemaining': totalBudget - budgetUsed,
        'ctr': ctr, // Click-through rate
        'conversionRate': conversionRate,
        'cpc': cpc, // Cost per click
        'cpa': cpa, // Cost per acquisition
        'status': data['status'],
        'startDate': data['startDate'],
        'endDate': data['endDate'],
      };
    } catch (e) {
      AppLogger.error('Error getting campaign analytics: $e');
      return {};
    }
  }

  /// Get user's ad statistics
  Future<Map<String, dynamic>> getAdStatistics(String userId) async {
    try {
      final adPurchases = await getUserAdPurchases(userId);
      final activeCampaigns = await getUserActiveCampaigns(userId);
      final currentBalance = await getAdCreditsBalance(userId);

      final totalSpent = adPurchases.fold<double>(
        0,
        (sum, purchase) => sum + purchase.amount,
      );
      final totalImpressions = adPurchases.fold<int>(
        0,
        (sum, purchase) => sum + purchase.quantity,
      );

      // Get total clicks and conversions from campaigns
      int totalClicks = 0;
      int totalConversions = 0;
      for (final campaign in activeCampaigns) {
        totalClicks += campaign['clicks'] as int? ?? 0;
        totalConversions += campaign['conversions'] as int? ?? 0;
      }

      return {
        'totalPurchases': adPurchases.length,
        'activeCampaigns': activeCampaigns.length,
        'totalSpent': totalSpent,
        'totalImpressions': totalImpressions,
        'totalClicks': totalClicks,
        'totalConversions': totalConversions,
        'currentCreditsBalance': currentBalance,
        'averageCTR': totalImpressions > 0
            ? (totalClicks / totalImpressions) * 100
            : 0.0,
        'averageConversionRate': totalClicks > 0
            ? (totalConversions / totalClicks) * 100
            : 0.0,
        'recentPurchases': adPurchases.take(5).toList(),
        'activeCampaignsList': activeCampaigns.take(5).toList(),
      };
    } catch (e) {
      AppLogger.error('Error getting ad statistics: $e');
      return {
        'totalPurchases': 0,
        'activeCampaigns': 0,
        'totalSpent': 0.0,
        'totalImpressions': 0,
        'totalClicks': 0,
        'totalConversions': 0,
        'currentCreditsBalance': 0,
        'averageCTR': 0.0,
        'averageConversionRate': 0.0,
        'recentPurchases': <Map<String, dynamic>>[],
        'activeCampaignsList': <Map<String, dynamic>>[],
      };
    }
  }

  /// Pause ad campaign
  Future<bool> pauseCampaign(String campaignId) async {
    try {
      await _firestore.collection('ad_campaigns').doc(campaignId).update({
        'status': 'paused',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Campaign paused: $campaignId');
      return true;
    } catch (e) {
      AppLogger.error('Error pausing campaign: $e');
      return false;
    }
  }

  /// Resume ad campaign
  Future<bool> resumeCampaign(String campaignId) async {
    try {
      await _firestore.collection('ad_campaigns').doc(campaignId).update({
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Campaign resumed: $campaignId');
      return true;
    } catch (e) {
      AppLogger.error('Error resuming campaign: $e');
      return false;
    }
  }

  /// Get ad product details
  Map<String, dynamic>? getAdProductDetails(String productId) {
    return _adProducts[productId];
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/gift_model.dart';
import '../models/gift_campaign_model.dart';
import '../models/gift_subscription_model.dart';
import 'payment_service.dart';
import '../utils/logger.dart';

class EnhancedGiftService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PaymentService _paymentService = PaymentService();

  // Gift Campaigns
  Future<String> createGiftCampaign({
    required String title,
    required String description,
    required double goalAmount,
    DateTime? endDate,
    String? imageUrl,
    List<String> tags = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final campaign = GiftCampaignModel(
      id: '', // Will be set by Firestore
      artistId: user.uid,
      title: title,
      description: description,
      goalAmount: goalAmount,
      createdAt: Timestamp.now(),
      endDate: endDate != null ? Timestamp.fromDate(endDate) : null,
      imageUrl: imageUrl,
      tags: tags,
      metadata: metadata,
    );

    final docRef = await _firestore
        .collection('gift_campaigns')
        .add(campaign.toFirestore());
    return docRef.id;
  }

  Future<void> updateGiftCampaign(
    String campaignId,
    Map<String, dynamic> updates,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Verify ownership
    final campaignDoc = await _firestore
        .collection('gift_campaigns')
        .doc(campaignId)
        .get();
    if (!campaignDoc.exists) throw Exception('Campaign not found');

    final campaign = GiftCampaignModel.fromFirestore(campaignDoc);
    if (campaign.artistId != user.uid)
      throw Exception('Not authorized to update this campaign');

    updates['lastUpdated'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('gift_campaigns')
        .doc(campaignId)
        .update(updates);
  }

  Future<void> pauseCampaign(String campaignId) async {
    await updateGiftCampaign(campaignId, {
      'status': CampaignStatus.paused.name,
    });
  }

  Future<void> resumeCampaign(String campaignId) async {
    await updateGiftCampaign(campaignId, {
      'status': CampaignStatus.active.name,
    });
  }

  Future<void> completeCampaign(String campaignId) async {
    await updateGiftCampaign(campaignId, {
      'status': CampaignStatus.completed.name,
    });
  }

  Future<void> cancelCampaign(String campaignId) async {
    await updateGiftCampaign(campaignId, {
      'status': CampaignStatus.cancelled.name,
    });
  }

  Stream<List<GiftCampaignModel>> getArtistCampaigns(String artistId) {
    return _firestore
        .collection('gift_campaigns')
        .where('artistId', isEqualTo: artistId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GiftCampaignModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<GiftCampaignModel>> getActiveCampaigns({int limit = 20}) {
    return _firestore
        .collection('gift_campaigns')
        .where('status', isEqualTo: CampaignStatus.active.name)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GiftCampaignModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<GiftCampaignModel?> getCampaign(String campaignId) async {
    final doc = await _firestore
        .collection('gift_campaigns')
        .doc(campaignId)
        .get();
    if (!doc.exists) return null;
    return GiftCampaignModel.fromFirestore(doc);
  }

  // Gift Subscriptions
  Future<String> createGiftSubscription({
    required String recipientId,
    required double amount,
    required SubscriptionFrequency frequency,
    String? message,
    required String paymentMethodId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Create Stripe subscription for recurring payments
    final stripeResult = await _paymentService.createGiftSubscription(
      recipientId: recipientId,
      amount: amount,
      frequency: frequency,
      paymentMethodId: paymentMethodId,
    );

    final subscription = GiftSubscriptionModel(
      id: '', // Will be set by Firestore
      senderId: user.uid,
      recipientId: recipientId,
      amount: amount,
      frequency: frequency,
      createdAt: Timestamp.now(),
      nextPaymentDate: Timestamp.fromDate(
        DateTime.now().add(_getFrequencyDuration(frequency)),
      ),
      stripeSubscriptionId: stripeResult['subscriptionId'] as String?,
      message: message,
    );

    final docRef = await _firestore
        .collection('gift_subscriptions')
        .add(subscription.toFirestore());
    return docRef.id;
  }

  Future<void> pauseGiftSubscription(String subscriptionId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Verify ownership
    final subDoc = await _firestore
        .collection('gift_subscriptions')
        .doc(subscriptionId)
        .get();
    if (!subDoc.exists) throw Exception('Subscription not found');

    final subscription = GiftSubscriptionModel.fromFirestore(subDoc);
    if (subscription.senderId != user.uid) throw Exception('Not authorized');

    // Pause in Stripe
    if (subscription.stripeSubscriptionId != null) {
      await _paymentService.pauseGiftSubscription(
        subscription.stripeSubscriptionId!,
      );
    }

    // Update in Firestore
    await _firestore
        .collection('gift_subscriptions')
        .doc(subscriptionId)
        .update({
          'status': SubscriptionStatus.paused.name,
          'pausedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> resumeGiftSubscription(String subscriptionId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Verify ownership
    final subDoc = await _firestore
        .collection('gift_subscriptions')
        .doc(subscriptionId)
        .get();
    if (!subDoc.exists) throw Exception('Subscription not found');

    final subscription = GiftSubscriptionModel.fromFirestore(subDoc);
    if (subscription.senderId != user.uid) throw Exception('Not authorized');

    // Resume in Stripe
    if (subscription.stripeSubscriptionId != null) {
      await _paymentService.resumeGiftSubscription(
        subscription.stripeSubscriptionId!,
      );
    }

    // Update in Firestore
    await _firestore
        .collection('gift_subscriptions')
        .doc(subscriptionId)
        .update({
          'status': SubscriptionStatus.active.name,
          'pausedAt': FieldValue.delete(),
          'nextPaymentDate': Timestamp.fromDate(
            DateTime.now().add(_getFrequencyDuration(subscription.frequency)),
          ),
        });
  }

  Future<void> cancelGiftSubscription(String subscriptionId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Verify ownership
    final subDoc = await _firestore
        .collection('gift_subscriptions')
        .doc(subscriptionId)
        .get();
    if (!subDoc.exists) throw Exception('Subscription not found');

    final subscription = GiftSubscriptionModel.fromFirestore(subDoc);
    if (subscription.senderId != user.uid) throw Exception('Not authorized');

    // Cancel in Stripe
    if (subscription.stripeSubscriptionId != null) {
      await _paymentService.cancelGiftSubscription(
        subscription.stripeSubscriptionId!,
      );
    }

    // Update in Firestore
    await _firestore
        .collection('gift_subscriptions')
        .doc(subscriptionId)
        .update({
          'status': SubscriptionStatus.cancelled.name,
          'cancelledAt': FieldValue.serverTimestamp(),
        });
  }

  Stream<List<GiftSubscriptionModel>> getUserGiftSubscriptions(String userId) {
    return _firestore
        .collection('gift_subscriptions')
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GiftSubscriptionModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<GiftSubscriptionModel>> getReceivedGiftSubscriptions(
    String userId,
  ) {
    return _firestore
        .collection('gift_subscriptions')
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GiftSubscriptionModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Enhanced Gift Processing
  Future<Map<String, dynamic>> sendCustomGift({
    required String recipientId,
    required double amount,
    required String paymentMethodId,
    String? message,
    String? campaignId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Validate custom amount (minimum $1, maximum $1000)
    if (amount < 1.0 || amount > 1000.0) {
      throw Exception(
        'Custom gift amount must be between \$1.00 and \$1,000.00',
      );
    }

    // Process payment
    final paymentResult = await _paymentService.processCustomGiftPayment(
      recipientId: recipientId,
      amount: amount,
      paymentMethodId: paymentMethodId,
      message: message,
    );

    // Create gift record
    final gift = GiftModel(
      id: '', // Will be set by Firestore
      senderId: user.uid,
      recipientId: recipientId,
      giftType: 'Custom Gift',
      amount: amount,
      createdAt: Timestamp.now(),
      type: GiftType.custom,
      message: message,
      campaignId: campaignId,
      paymentIntentId: paymentResult['paymentIntentId'] as String?,
      status: paymentResult['status'] == 'succeeded' ? 'completed' : 'pending',
    );

    await _firestore.collection('gifts').add(gift.toFirestore());

    // Update campaign if this is a campaign gift
    if (campaignId != null) {
      await _updateCampaignProgress(campaignId, amount);
    }

    return paymentResult;
  }

  Future<void> _updateCampaignProgress(String campaignId, double amount) async {
    await _firestore.runTransaction((transaction) async {
      final campaignRef = _firestore
          .collection('gift_campaigns')
          .doc(campaignId);
      final campaignDoc = await transaction.get(campaignRef);

      if (!campaignDoc.exists) return;

      final campaign = GiftCampaignModel.fromFirestore(campaignDoc);
      final newAmount = campaign.currentAmount + amount;
      final newSupporterCount = campaign.supporterCount + 1;

      transaction.update(campaignRef, {
        'currentAmount': newAmount,
        'supporterCount': newSupporterCount,
        'lastUpdated': FieldValue.serverTimestamp(),
        // Auto-complete campaign if goal is reached
        if (newAmount >= campaign.goalAmount &&
            campaign.status == CampaignStatus.active)
          'status': CampaignStatus.completed.name,
      });
    });
  }

  // Analytics and Insights
  Future<Map<String, dynamic>> getGiftAnalytics(String userId) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Get gifts sent in last 30 days
    final sentGiftsQuery = await _firestore
        .collection('gifts')
        .where('senderId', isEqualTo: userId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
        .get();

    // Get gifts received in last 30 days
    final receivedGiftsQuery = await _firestore
        .collection('gifts')
        .where('recipientId', isEqualTo: userId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
        .get();

    final int giftsSent = sentGiftsQuery.docs.length;
    final int giftsReceived = receivedGiftsQuery.docs.length;

    final totalSent = sentGiftsQuery.docs.fold<double>(0.0, (sum, doc) {
      final gift = GiftModel.fromFirestore(doc);
      return sum + gift.amount;
    });

    final totalReceived = receivedGiftsQuery.docs.fold<double>(0.0, (sum, doc) {
      final gift = GiftModel.fromFirestore(doc);
      return sum + gift.amount;
    });

    return {
      'totalSent': totalSent,
      'totalReceived': totalReceived,
      'giftsSent': giftsSent,
      'giftsReceived': giftsReceived,
      'averageGiftSent': giftsSent > 0 ? totalSent / giftsSent : 0.0,
      'averageGiftReceived': giftsReceived > 0
          ? totalReceived / giftsReceived
          : 0.0,
    };
  }

  // Helper methods
  Duration _getFrequencyDuration(SubscriptionFrequency frequency) {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return const Duration(days: 7);
      case SubscriptionFrequency.biweekly:
        return const Duration(days: 14);
      case SubscriptionFrequency.monthly:
        return const Duration(days: 30);
    }
  }

  // Preset gift types (maintaining backward compatibility)
  Map<String, double> getPresetGiftTypes() {
    return {
      'Small Gift (50 Credits)': 4.99,
      'Medium Gift (100 Credits)': 9.99,
      'Large Gift (250 Credits)': 24.99,
      'Premium Gift (500 Credits)': 49.99,
    };
  }

  // Custom gift amount suggestions
  List<double> getCustomGiftSuggestions() {
    return [1.0, 3.0, 5.0, 10.0, 15.0, 25.0, 50.0, 100.0];
  }

  // ========================================
  // MISSING GIFT SYSTEM METHODS (From to_do.md)
  // ========================================

  /// Purchase a gift for someone (convenience wrapper around sendCustomGift)
  Future<String> purchaseGift({
    required String recipientId,
    required String giftType,
    required double amount,
    required String paymentMethodId,
    String? message,
    String? campaignId,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Validate gift type and amount
      final presetGifts = getPresetGiftTypes();
      if (presetGifts.containsKey(giftType)) {
        // Use preset gift amount
        amount = presetGifts[giftType]!;
      }

      // Process payment using existing sendCustomGift method
      final paymentResult = await sendCustomGift(
        recipientId: recipientId,
        amount: amount,
        paymentMethodId: paymentMethodId,
        message: message,
        campaignId: campaignId,
      );

      // Create detailed gift record
      final gift = GiftModel(
        id: '', // Will be set by Firestore
        senderId: user.uid,
        recipientId: recipientId,
        giftType: giftType,
        amount: amount,
        createdAt: Timestamp.now(),
        type: presetGifts.containsKey(giftType)
            ? GiftType.preset
            : GiftType.custom,
        message: message,
        campaignId: campaignId,
        paymentIntentId: paymentResult['paymentIntentId'] as String?,
        status: paymentResult['status'] == 'succeeded'
            ? 'completed'
            : 'pending',
      );

      final docRef = await _firestore
          .collection('gifts')
          .add(gift.toFirestore());

      // Send notification to recipient
      await _sendGiftNotification(
        senderId: user.uid,
        recipientId: recipientId,
        giftType: giftType,
        amount: amount,
        giftId: docRef.id,
      );

      return docRef.id;
    } catch (e) {
      AppLogger.error('Error purchasing gift: $e');
      rethrow;
    }
  }

  /// Redeem a gift using a gift code or gift ID
  Future<Map<String, dynamic>> redeemGift(String giftCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Look up gift by code or ID
      QuerySnapshot giftQuery;

      // First try to find by gift code (if it's a code-based gift)
      giftQuery = await _firestore
          .collection('gifts')
          .where('giftCode', isEqualTo: giftCode)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      // If not found by code, try by document ID
      if (giftQuery.docs.isEmpty) {
        final giftDoc = await _firestore
            .collection('gifts')
            .doc(giftCode)
            .get();
        if (giftDoc.exists) {
          giftQuery = await _firestore
              .collection('gifts')
              .where(FieldPath.documentId, isEqualTo: giftCode)
              .limit(1)
              .get();
        }
      }

      if (giftQuery.docs.isEmpty) {
        throw Exception('Gift not found or already redeemed');
      }

      final giftDoc = giftQuery.docs.first;
      final gift = GiftModel.fromFirestore(giftDoc);

      // Verify the user is the intended recipient
      if (gift.recipientId != user.uid) {
        throw Exception('This gift is not intended for you');
      }

      // Check if gift is already redeemed
      if (gift.status == 'redeemed') {
        throw Exception('Gift has already been redeemed');
      }

      // Redeem the gift
      await _firestore.collection('gifts').doc(giftDoc.id).update({
        'status': 'redeemed',
        'redeemedAt': FieldValue.serverTimestamp(),
        'redeemedBy': user.uid,
      });

      // Process the gift value (add to user's account, credits, etc.)
      await _processGiftRedemption(gift, user.uid);

      // Create redemption record
      await _firestore.collection('gift_redemptions').add({
        'giftId': giftDoc.id,
        'userId': user.uid,
        'amount': gift.amount,
        'giftType': gift.giftType,
        'redeemedAt': FieldValue.serverTimestamp(),
        'processingStatus': 'completed',
      });

      return {
        'success': true,
        'giftId': giftDoc.id,
        'amount': gift.amount,
        'giftType': gift.giftType,
        'message': gift.message,
        'redeemedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.error('Error redeeming gift: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get comprehensive gift history for a user
  Future<Map<String, dynamic>> getGiftHistory(String userId) async {
    try {
      // Get gifts sent by user
      final sentGiftsQuery = await _firestore
          .collection('gifts')
          .where('senderId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      // Get gifts received by user
      final receivedGiftsQuery = await _firestore
          .collection('gifts')
          .where('recipientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      // Get gift subscriptions sent
      final sentSubscriptionsQuery = await _firestore
          .collection('gift_subscriptions')
          .where('senderId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      // Get gift subscriptions received
      final receivedSubscriptionsQuery = await _firestore
          .collection('gift_subscriptions')
          .where('recipientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      // Get gift redemptions
      final redemptionsQuery = await _firestore
          .collection('gift_redemptions')
          .where('userId', isEqualTo: userId)
          .orderBy('redeemedAt', descending: true)
          .get();

      // Process sent gifts
      final sentGifts = <Map<String, dynamic>>[];
      for (final doc in sentGiftsQuery.docs) {
        final gift = GiftModel.fromFirestore(doc);
        final recipientDoc = await _firestore
            .collection('users')
            .doc(gift.recipientId)
            .get();
        final recipientData = recipientDoc.data();

        sentGifts.add({
          'id': doc.id,
          'type': 'sent',
          'giftType': gift.giftType,
          'amount': gift.amount,
          'status': gift.status,
          'createdAt': gift.createdAt,
          'message': gift.message,
          'recipientName':
              recipientData?['fullName'] ??
              recipientData?['displayName'] ??
              'Unknown',
          'recipientId': gift.recipientId,
          'campaignId': gift.campaignId,
        });
      }

      // Process received gifts
      final receivedGifts = <Map<String, dynamic>>[];
      for (final doc in receivedGiftsQuery.docs) {
        final gift = GiftModel.fromFirestore(doc);
        final senderDoc = await _firestore
            .collection('users')
            .doc(gift.senderId)
            .get();
        final senderData = senderDoc.data();

        receivedGifts.add({
          'id': doc.id,
          'type': 'received',
          'giftType': gift.giftType,
          'amount': gift.amount,
          'status': gift.status,
          'createdAt': gift.createdAt,
          'message': gift.message,
          'senderName':
              senderData?['fullName'] ??
              senderData?['displayName'] ??
              'Anonymous',
          'senderId': gift.senderId,
          'campaignId': gift.campaignId,
        });
      }

      // Process sent subscriptions
      final sentSubscriptions = <Map<String, dynamic>>[];
      for (final doc in sentSubscriptionsQuery.docs) {
        final subscription = GiftSubscriptionModel.fromFirestore(doc);
        final recipientDoc = await _firestore
            .collection('users')
            .doc(subscription.recipientId)
            .get();
        final recipientData = recipientDoc.data();

        sentSubscriptions.add({
          'id': doc.id,
          'type': 'sent_subscription',
          'amount': subscription.amount,
          'frequency': subscription.frequency.name,
          'status': subscription.status.name,
          'createdAt': subscription.createdAt,
          'nextPaymentDate': subscription.nextPaymentDate,
          'message': subscription.message,
          'recipientName':
              recipientData?['fullName'] ??
              recipientData?['displayName'] ??
              'Unknown',
          'recipientId': subscription.recipientId,
        });
      }

      // Process received subscriptions
      final receivedSubscriptions = <Map<String, dynamic>>[];
      for (final doc in receivedSubscriptionsQuery.docs) {
        final subscription = GiftSubscriptionModel.fromFirestore(doc);
        final senderDoc = await _firestore
            .collection('users')
            .doc(subscription.senderId)
            .get();
        final senderData = senderDoc.data();

        receivedSubscriptions.add({
          'id': doc.id,
          'type': 'received_subscription',
          'amount': subscription.amount,
          'frequency': subscription.frequency.name,
          'status': subscription.status.name,
          'createdAt': subscription.createdAt,
          'nextPaymentDate': subscription.nextPaymentDate,
          'message': subscription.message,
          'senderName':
              senderData?['fullName'] ??
              senderData?['displayName'] ??
              'Anonymous',
          'senderId': subscription.senderId,
        });
      }

      // Process redemptions
      final redemptions = <Map<String, dynamic>>[];
      for (final doc in redemptionsQuery.docs) {
        final redemptionData = doc.data();
        redemptions.add({
          'id': doc.id,
          'type': 'redemption',
          'giftId': redemptionData['giftId'],
          'amount': redemptionData['amount'],
          'giftType': redemptionData['giftType'],
          'redeemedAt': redemptionData['redeemedAt'],
          'processingStatus': redemptionData['processingStatus'],
        });
      }

      // Calculate summary statistics
      final totalSent = sentGifts.fold<double>(
        0.0,
        (sum, gift) => sum + (gift['amount'] as double),
      );
      final totalReceived = receivedGifts.fold<double>(
        0.0,
        (sum, gift) => sum + (gift['amount'] as double),
      );
      final totalRedeemed = redemptions.fold<double>(
        0.0,
        (sum, redemption) => sum + (redemption['amount'] as double),
      );

      return {
        'sentGifts': sentGifts,
        'receivedGifts': receivedGifts,
        'sentSubscriptions': sentSubscriptions,
        'receivedSubscriptions': receivedSubscriptions,
        'redemptions': redemptions,
        'summary': {
          'totalSent': totalSent,
          'totalReceived': totalReceived,
          'totalRedeemed': totalRedeemed,
          'giftsSentCount': sentGifts.length,
          'giftsReceivedCount': receivedGifts.length,
          'subscriptionsSentCount': sentSubscriptions.length,
          'subscriptionsReceivedCount': receivedSubscriptions.length,
          'redemptionsCount': redemptions.length,
        },
      };
    } catch (e) {
      AppLogger.error('Error getting gift history: $e');
      return {
        'sentGifts': <Map<String, dynamic>>[],
        'receivedGifts': <Map<String, dynamic>>[],
        'sentSubscriptions': <Map<String, dynamic>>[],
        'receivedSubscriptions': <Map<String, dynamic>>[],
        'redemptions': <Map<String, dynamic>>[],
        'summary': {
          'totalSent': 0.0,
          'totalReceived': 0.0,
          'totalRedeemed': 0.0,
          'giftsSentCount': 0,
          'giftsReceivedCount': 0,
          'subscriptionsSentCount': 0,
          'subscriptionsReceivedCount': 0,
          'redemptionsCount': 0,
        },
        'error': e.toString(),
      };
    }
  }

  // ========================================
  // HELPER METHODS FOR NEW FUNCTIONALITY
  // ========================================

  String _getGiftCategory(String giftType) {
    final presetGifts = getPresetGiftTypes();
    if (presetGifts.containsKey(giftType)) {
      if (giftType.contains('Palette') ||
          giftType.contains('Brush') ||
          giftType.contains('Canvas') ||
          giftType.contains('Supplies')) {
        return 'art_supplies';
      } else if (giftType.contains('Studio') || giftType.contains('Time')) {
        return 'studio_access';
      } else if (giftType.contains('Support') || giftType.contains('Premium')) {
        return 'support';
      }
    }
    return 'custom';
  }

  Future<void> _sendGiftNotification({
    required String senderId,
    required String recipientId,
    required String giftType,
    required double amount,
    required String giftId,
  }) async {
    try {
      // Get sender info
      final senderDoc = await _firestore
          .collection('users')
          .doc(senderId)
          .get();
      final senderData = senderDoc.data();
      final senderName =
          senderData?['fullName'] ?? senderData?['displayName'] ?? 'Someone';

      // Create notification
      await _firestore.collection('notifications').add({
        'type': 'gift_received',
        'recipientId': recipientId,
        'senderId': senderId,
        'giftId': giftId,
        'title': 'You received a gift!',
        'message':
            '$senderName sent you a $giftType worth \$${amount.toStringAsFixed(2)}',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'metadata': {
          'giftType': giftType,
          'amount': amount,
          'senderName': senderName,
        },
      });
    } catch (e) {
      AppLogger.error('Error sending gift notification: $e');
      // Don't throw - notifications are not critical
    }
  }

  Future<void> _processGiftRedemption(GiftModel gift, String userId) async {
    try {
      // Add gift value to user's account balance or credits
      await _firestore.collection('users').doc(userId).update({
        'accountBalance': FieldValue.increment(gift.amount),
        'totalGiftsRedeemed': FieldValue.increment(gift.amount),
        'lastGiftRedeemedAt': FieldValue.serverTimestamp(),
      });

      // If it's an art supplies gift, add to user's supplies inventory
      if (_getGiftCategory(gift.giftType) == 'art_supplies') {
        await _firestore.collection('user_inventory').doc(userId).set({
          'supplies': FieldValue.arrayUnion([
            {
              'type': gift.giftType,
              'value': gift.amount,
              'receivedAt': FieldValue.serverTimestamp(),
              'fromGiftId': gift.id,
            },
          ]),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      AppLogger.error('Error processing gift redemption: $e');
      // Don't throw - we want the redemption to succeed even if balance update fails
    }
  }
}

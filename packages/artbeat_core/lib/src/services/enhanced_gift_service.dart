import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/gift_model.dart';
import '../models/gift_campaign_model.dart';
import '../models/gift_subscription_model.dart';
import 'payment_service.dart';

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
      'Mini Palette': 5.00,
      'Brush Pack': 10.00,
      'Canvas Set': 15.00,
      'Art Supplies': 25.00,
      'Studio Time': 50.00,
      'Premium Support': 100.00,
    };
  }

  // Custom gift amount suggestions
  List<double> getCustomGiftSuggestions() {
    return [1.0, 3.0, 5.0, 10.0, 15.0, 25.0, 50.0, 100.0];
  }
}

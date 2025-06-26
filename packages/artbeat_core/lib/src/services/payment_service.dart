import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../models/subscription_tier.dart';
import '../models/payment_method_model.dart';
import '../models/gift_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling payments and subscriptions with Stripe integration
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();

  factory PaymentService() {
    return _instance;
  }

  PaymentService._internal() {
    initializeDependencies();
  }

  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  late final http.Client _httpClient;

  static const String _baseUrl =
      'https://us-central1-wordnerd-artbeat.cloudfunctions.net';

  void initializeDependencies({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    http.Client? httpClient,
  }) {
    _auth = auth ?? FirebaseAuth.instance;
    _firestore = firestore ?? FirebaseFirestore.instance;
    _httpClient = httpClient ?? http.Client();
  }

  /// Create a new customer in Stripe
  Future<String> createCustomer({
    required String email,
    required String name,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/create-customer'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'name': name, 'userId': userId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create customer');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['customerId'] as String;
    } catch (e) {
      debugPrint('Error creating customer: $e');
      rethrow;
    }
  }

  /// Create a setup intent for adding payment methods
  Future<String> createSetupIntent(String customerId) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/create-setup-intent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'customerId': customerId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create setup intent');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['clientSecret'] as String;
    } catch (e) {
      debugPrint('Error creating setup intent: $e');
      rethrow;
    }
  }

  /// Set up Stripe payment sheet for adding a payment method
  Future<void> setupPaymentSheet({
    required String customerId,
    required String setupIntentClientSecret,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          customerId: customerId,
          style: ThemeMode.system,
          merchantDisplayName: 'ARTbeat',
          setupIntentClientSecret: setupIntentClientSecret,
        ),
      );
    } catch (e) {
      debugPrint('Error setting up payment sheet: $e');
      rethrow;
    }
  }

  /// Get customer's saved payment methods
  Future<List<PaymentMethodModel>> getPaymentMethods(String customerId) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/payment-methods/$customerId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get payment methods');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final paymentMethodsData = data['paymentMethods'] as List<dynamic>?;
      if (paymentMethodsData == null) {
        return [];
      }
      return paymentMethodsData
          .map((pm) => PaymentMethodModel.fromJson(pm as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting payment methods: $e');
      return [];
    }
  }

  /// Set a payment method as default for a customer
  Future<Map<String, dynamic>> setDefaultPaymentMethod({
    required String customerId,
    required String paymentMethodId,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/update-customer'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerId': customerId,
          'defaultPaymentMethod': paymentMethodId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to set default payment method');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error setting default payment method: $e');
      rethrow;
    }
  }

  /// Detach a payment method from a customer
  Future<Map<String, dynamic>> detachPaymentMethod(
    String paymentMethodId,
  ) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/detach-payment-method'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'paymentMethodId': paymentMethodId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to detach payment method');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error detaching payment method: $e');
      rethrow;
    }
  }

  /// Process a payment
  Future<bool> processPayment({
    required String paymentMethodId,
    required double amount,
    String? description,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/process-payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'paymentMethodId': paymentMethodId,
          'amount': amount,
          'userId': userId,
          if (description != null) 'description': description,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to process payment');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } catch (e) {
      debugPrint('Error processing payment: $e');
      rethrow;
    }
  }

  /// Request a refund
  Future<Map<String, dynamic>> requestRefund({
    required String paymentId,
    required String subscriptionId,
    required String reason,
    String? additionalDetails,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/request-refund'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'paymentId': paymentId,
          'subscriptionId': subscriptionId,
          'userId': userId,
          'reason': reason,
          if (additionalDetails != null) 'additionalDetails': additionalDetails,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to request refund');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Update subscription status in Firestore
      await _updateSubscriptionInFirestore(subscriptionId, {
        'refundRequested': true,
        'refundReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return data;
    } catch (e) {
      debugPrint('Error requesting refund: $e');
      rethrow;
    }
  }

  /// Change subscription tier
  Future<Map<String, dynamic>> changeSubscriptionTier({
    required String customerId,
    required String subscriptionId,
    required SubscriptionTier newTier,
    bool prorated = true,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final priceId = _getPriceIdForTier(newTier);
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/change-subscription-tier'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerId': customerId,
          'subscriptionId': subscriptionId,
          'newPriceId': priceId,
          'prorated': prorated,
          'userId': userId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to change subscription tier');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Update subscription in Firestore
      await _updateSubscriptionInFirestore(subscriptionId, {
        'tier': newTier.apiName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return data;
    } catch (e) {
      debugPrint('Error changing subscription tier: $e');
      rethrow;
    }
  }

  /// Cancel subscription
  Future<Map<String, dynamic>> cancelSubscription(String subscriptionId) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/cancel-subscription'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'subscriptionId': subscriptionId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel subscription');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Update subscription in Firestore
      await _updateSubscriptionInFirestore(subscriptionId, {
        'isActive': false,
        'autoRenew': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return data;
    } catch (e) {
      debugPrint('Error cancelling subscription: $e');
      rethrow;
    }
  }

  /// Process a gift payment and create gift record
  Future<Map<String, dynamic>> processGiftPayment(GiftModel gift) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get or create customer ID for sender
      final customerId = await _getOrCreateCustomerId();

      // Process payment through Firebase Function
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/process-gift-payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'senderId': gift.senderId,
          'recipientId': gift.recipientId,
          'amount': gift.amount,
          'customerId': customerId,
          'giftType': gift.giftType,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to process gift payment');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Create gift record in Firestore
      await _firestore.collection('gifts').add({
        'senderId': gift.senderId,
        'recipientId': gift.recipientId,
        'amount': gift.amount,
        'giftType': gift.giftType,
        'paymentIntentId': data['paymentIntentId'],
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return data;
    } catch (e) {
      debugPrint('Error processing gift payment: $e');
      rethrow;
    }
  }

  /// Get list of gifts sent by the current user
  Future<List<GiftModel>> getSentGifts() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final QuerySnapshot giftsSnapshot = await _firestore
          .collection('gifts')
          .where('senderId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return giftsSnapshot.docs
          .map((doc) => GiftModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting sent gifts: $e');
      rethrow;
    }
  }

  /// Get list of gifts received by the current user
  Future<List<GiftModel>> getReceivedGifts() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final QuerySnapshot giftsSnapshot = await _firestore
          .collection('gifts')
          .where('recipientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return giftsSnapshot.docs
          .map((doc) => GiftModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting received gifts: $e');
      rethrow;
    }
  }

  /// Process a sponsorship payment (placeholder for Stripe integration)
  Future<void> processSponsorshipPayment(
    Map<String, dynamic> sponsorship,
  ) async {
    try {
      // This is a placeholder for actual Stripe recurring payment logic
      // You would call a cloud function to create a recurring subscription for the artist
      await _firestore.collection('sponsorships').add({
        ...sponsorship,
        'status': 'pending',
      });
      // TODO: Integrate with Stripe for real recurring billing
    } catch (e) {
      debugPrint('Error processing sponsorship payment: $e');
      rethrow;
    }
  }

  /// Get price ID for subscription tier
  String _getPriceIdForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.artistPro:
        return 'price_artist_pro_monthly';
      case SubscriptionTier.gallery:
        return 'price_gallery_monthly';
      case SubscriptionTier.free:
      case SubscriptionTier.artistBasic:
        throw Exception('Free tiers do not have price IDs');
    }
  }

  /// Update subscription document in Firestore
  Future<void> _updateSubscriptionInFirestore(
    String subscriptionId,
    Map<String, dynamic> data,
  ) async {
    final subscriptionsRef = _firestore.collection('subscriptions');
    final snapshot = await subscriptionsRef
        .where('stripeSubscriptionId', isEqualTo: subscriptionId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update(data);
    }
  }

  /// Get or create customer ID for the current user
  Future<String> _getOrCreateCustomerId() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Check if customer ID already exists in Firestore
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data();
    if (userDoc.exists && data != null && data.containsKey('customerId')) {
      final customerId = data['customerId'] as String?;
      if (customerId != null) {
        return customerId;
      }
    }

    // If not, create a new customer in Stripe
    final email = _auth.currentUser?.email ?? '';
    final name = _auth.currentUser?.displayName ?? '';
    return createCustomer(email: email, name: name);
  }
}

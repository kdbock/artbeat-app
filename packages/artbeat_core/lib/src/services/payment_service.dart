import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../models/subscription_tier.dart';
import '../models/payment_method_model.dart';
import '../models/gift_model.dart';
import '../utils/env_loader.dart';
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
    _initializeStripe();
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

  /// Initialize Stripe with publishable key
  void _initializeStripe() {
    try {
      final publishableKey = EnvLoader().get('STRIPE_PUBLISHABLE_KEY');
      if (publishableKey.isNotEmpty) {
        Stripe.publishableKey = publishableKey;
        debugPrint('✅ Stripe initialized with publishable key');
      } else {
        debugPrint('⚠️ Stripe publishable key not found in environment');
      }
    } catch (e) {
      debugPrint('❌ Error initializing Stripe: $e');
    }
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
        Uri.parse('$_baseUrl/createCustomer'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'userId': userId}),
      );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        debugPrint(
          'Create customer error - Status: ${response.statusCode}, Body: $errorBody',
        );

        // Check if this is a configuration issue
        if (response.statusCode == 500 && errorBody.contains('stripe')) {
          throw Exception(
            'Payment service is not configured. Please contact support or try again later.',
          );
        }

        throw Exception(
          'Failed to create customer: ${response.statusCode} - $errorBody',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final customerId = data['customerId'] as String;

      // Store customer ID in Firestore for immediate availability
      await _firestore.collection('users').doc(userId).update({
        'stripeCustomerId': customerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return customerId;
    } catch (e) {
      debugPrint('Error creating customer: $e');
      rethrow;
    }
  }

  /// Create a setup intent for adding payment methods
  Future<String> createSetupIntent(String customerId) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/createSetupIntent'),
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
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/getPaymentMethods'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'customerId': customerId}),
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
        Uri.parse('$_baseUrl/updateCustomer'),
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
        Uri.parse('$_baseUrl/detachPaymentMethod'),
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
        Uri.parse('$_baseUrl/requestRefund'),
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
        Uri.parse('$_baseUrl/changeSubscriptionTier'),
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
        Uri.parse('$_baseUrl/cancelSubscription'),
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
  Future<Map<String, dynamic>> processGiftPayment(
    GiftModel gift, {
    required String paymentMethodId,
    String? message,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Process payment through Firebase Function
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/process-gift-payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'senderId': gift.senderId,
          'recipientId': gift.recipientId,
          'amount': gift.amount,
          'paymentMethodId': paymentMethodId,
          'giftType': gift.giftType,
          if (message != null) 'message': message,
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
      // Create recurring billing schedule with Stripe
      final subscriptionResponse = await _httpClient.post(
        Uri.parse('$_baseUrl/createRecurringPayment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _auth.currentUser?.getIdToken()}',
        },
        body: json.encode({
          'amount': sponsorship['amount'],
          'currency': sponsorship['currency'] ?? 'usd',
          'interval': sponsorship['billingInterval'] ?? 'month',
          'customerId': _auth.currentUser?.uid,
          'metadata': {
            'sponsorshipId': sponsorship['id'],
            'eventId': sponsorship['eventId'],
            'sponsorshipType': sponsorship['type'],
          },
        }),
      );

      if (subscriptionResponse.statusCode == 200) {
        final subscriptionData = json.decode(subscriptionResponse.body);

        // Save sponsorship with Stripe subscription ID
        await _firestore.collection('sponsorships').add({
          ...sponsorship,
          'status': 'active',
          'stripeSubscriptionId': subscriptionData['subscriptionId'],
          'stripeCustomerId': subscriptionData['customerId'],
          'nextBillingDate': DateTime.now()
              .add(
                Duration(
                  days: sponsorship['billingInterval'] == 'year' ? 365 : 30,
                ),
              )
              .millisecondsSinceEpoch,
        });
      } else {
        throw Exception(
          'Failed to create recurring payment: ${subscriptionResponse.body}',
        );
      }
    } catch (e) {
      debugPrint('Error processing sponsorship payment: $e');
      rethrow;
    }
  }

  /// Request a refund for a ticket purchase
  static Future<void> refundPayment({
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    try {
      final auth = FirebaseAuth.instance;
      final httpClient = http.Client();

      // Call cloud function to process refund through Stripe
      final response = await httpClient.post(
        Uri.parse('$_baseUrl/processRefund'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await auth.currentUser?.getIdToken()}',
        },
        body: json.encode({
          'paymentId': paymentId,
          'amount': amount,
          'reason': reason ?? 'Requested by user',
          'userId': auth.currentUser?.uid,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Update payment record in Firestore
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(paymentId)
            .update({
              'status': 'refunded',
              'refundId': responseData['refundId'],
              'refundAmount': amount,
              'refundedAt': FieldValue.serverTimestamp(),
              'refundReason': reason,
            });

        debugPrint(
          'Refund processed successfully: ${responseData['refundId']}',
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Refund failed: ${errorData['error']}');
      }
    } catch (e) {
      debugPrint('Error processing refund: $e');
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

    debugPrint('Getting or creating customer ID for user: $userId');

    // Check if customer ID already exists in Firestore
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data();
    debugPrint('User document exists: ${userDoc.exists}, data: $data');

    if (userDoc.exists &&
        data != null &&
        data.containsKey('stripeCustomerId')) {
      final customerId = data['stripeCustomerId'] as String?;
      if (customerId != null) {
        debugPrint('Found existing customer ID: $customerId');
        return customerId;
      }
    }

    // If not, create a new customer in Stripe
    final email = _auth.currentUser?.email ?? '';
    final name = _auth.currentUser?.displayName ?? '';
    debugPrint('Creating new customer with email: $email, name: $name');
    return createCustomer(email: email, name: name);
  }

  /// Get the user's default payment method ID
  Future<String?> getDefaultPaymentMethodId() async {
    try {
      final customerId = await _getOrCreateCustomerId();
      final paymentMethods = await getPaymentMethods(customerId);

      // Return the first payment method if available
      // In a real app, you'd want to track which one is the default
      return paymentMethods.isNotEmpty ? paymentMethods.first.id : null;
    } catch (e) {
      debugPrint('Error getting default payment method: $e');
      return null;
    }
  }
}

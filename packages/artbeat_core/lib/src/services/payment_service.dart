import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../models/subscription_tier.dart';
import '../models/payment_method_model.dart';
import '../models/gift_model.dart';
import '../models/gift_subscription_model.dart';
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

      // Create earnings transaction for the recipient
      await _createEarningsTransaction(
        artistId: gift.recipientId,
        type: 'gift',
        amount: gift.amount,
        fromUserId: gift.senderId,
        description: 'Gift received: ${gift.giftType}',
        metadata: {
          'giftType': gift.giftType,
          'paymentIntentId': data['paymentIntentId'],
          if (message != null) 'message': message,
        },
      );

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

  /// Get price ID for subscription tier (2025 updated pricing)
  String _getPriceIdForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return 'price_starter_monthly_499'; // $4.99/month
      case SubscriptionTier.creator:
        return 'price_creator_monthly_1299'; // $12.99/month
      case SubscriptionTier.business:
        return 'price_business_monthly_2999'; // $29.99/month
      case SubscriptionTier.enterprise:
        return 'price_enterprise_monthly_7999'; // $79.99/month
      case SubscriptionTier.free:
        throw Exception('Free tier does not have a price ID');
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
  Future<String> getOrCreateCustomerId() async {
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
      final customerId = await getOrCreateCustomerId();
      final paymentMethods = await getPaymentMethods(customerId);

      // Return the first payment method if available
      // In a real app, you'd want to track which one is the default
      return paymentMethods.isNotEmpty ? paymentMethods.first.id : null;
    } catch (e) {
      debugPrint('Error getting default payment method: $e');
      return null;
    }
  }

  /// Process an ad payment
  Future<Map<String, dynamic>> processAdPayment({
    required String adId,
    required String paymentMethodId,
    required double amount,
    required String adType,
    int? duration,
    String? location,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/processAdPayment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'adId': adId,
          'amount': amount,
          'paymentMethodId': paymentMethodId,
          'adType': adType,
          if (duration != null) 'duration': duration,
          if (location != null) 'location': location,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to process ad payment');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Update ad status in Firestore to indicate payment completed
      await _firestore.collection('ads').doc(adId).update({
        'paymentStatus': 'paid',
        'paymentIntentId': data['paymentIntentId'],
        'paidAmount': amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return data;
    } catch (e) {
      debugPrint('Error processing ad payment: $e');
      rethrow;
    }
  }

  /// Get ad pricing from the server
  Future<Map<String, dynamic>> getAdPricing({
    required String adType,
    required int duration,
    required String location,
  }) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/getAdPricing').replace(
          queryParameters: {
            'adType': adType,
            'duration': duration.toString(),
            'location': location,
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get ad pricing');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting ad pricing: $e');
      rethrow;
    }
  }

  /// Process enhanced gift payment with gift types
  Future<Map<String, dynamic>> processEnhancedGiftPayment({
    required String recipientId,
    required String paymentMethodId,
    required String giftType,
    required double amount,
    String? message,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/processGiftPayment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'senderId': userId,
          'recipientId': recipientId,
          'amount': amount,
          'paymentMethodId': paymentMethodId,
          'giftType': giftType,
          if (message != null) 'message': message,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to process gift payment');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Create gift record in Firestore
      await _firestore.collection('gifts').add({
        'senderId': userId,
        'recipientId': recipientId,
        'amount': amount,
        'giftType': giftType,
        'paymentIntentId': data['paymentIntentId'],
        'status': 'completed',
        'message': message ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return data;
    } catch (e) {
      debugPrint('Error processing enhanced gift payment: $e');
      rethrow;
    }
  }

  /// Get available gift types and their prices
  Map<String, double> getGiftTypes() {
    return {
      'Mini Palette': 5.00,
      'Brush Pack': 10.00,
      'Canvas Set': 15.00,
      'Art Supplies': 25.00,
      'Studio Time': 50.00,
      'Premium Support': 100.00,
    };
  }

  /// Create a new subscription for a customer
  Future<Map<String, dynamic>> createSubscription({
    required String customerId,
    required SubscriptionTier tier,
    String? paymentMethodId,
    String? couponCode,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final priceId = _getPriceIdForTier(tier);
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/createSubscription'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerId': customerId,
          'priceId': priceId,
          'userId': userId,
          if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
          if (couponCode != null) 'couponCode': couponCode,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create subscription');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Store subscription in Firestore with coupon information
      await _firestore.collection('subscriptions').add({
        'userId': userId,
        'customerId': customerId,
        'subscriptionId': data['subscriptionId'],
        'tier': tier.apiName,
        'status': data['status'],
        'isActive': true,
        'autoRenew': true,
        'couponCode': couponCode,
        'couponId': data['couponId'],
        'originalPrice': tier.monthlyPrice,
        'discountedPrice': data['discountedPrice'] ?? tier.monthlyPrice,
        'revenue': data['revenue'] ?? tier.monthlyPrice, // Track actual revenue
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return data;
    } catch (e) {
      debugPrint('Error creating subscription: $e');
      rethrow;
    }
  }

  /// Create a custom subscription with specific price
  Future<Map<String, dynamic>> createCustomSubscription({
    required String customerId,
    required String paymentMethodId,
    required double priceAmount,
    required String currency,
    Map<String, String>? metadata,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/createCustomSubscription'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerId': customerId,
          'paymentMethodId': paymentMethodId,
          'priceAmount': (priceAmount * 100).round(), // Convert to cents
          'currency': currency,
          'userId': userId,
          'metadata': metadata ?? {},
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create custom subscription');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      debugPrint('Error creating custom subscription: $e');
      rethrow;
    }
  }

  /// Pause a subscription
  Future<void> pauseSubscription(String subscriptionId) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/pauseSubscription'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'subscriptionId': subscriptionId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to pause subscription');
      }

      // Update subscription in Firestore
      final subscriptionQuery = await _firestore
          .collection('subscriptions')
          .where('subscriptionId', isEqualTo: subscriptionId)
          .get();

      for (final doc in subscriptionQuery.docs) {
        await doc.reference.update({
          'status': 'paused',
          'pausedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error pausing subscription: $e');
      rethrow;
    }
  }

  /// Resume a paused subscription
  Future<void> resumeSubscription(String subscriptionId) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/resumeSubscription'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'subscriptionId': subscriptionId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to resume subscription');
      }

      // Update subscription in Firestore
      final subscriptionQuery = await _firestore
          .collection('subscriptions')
          .where('subscriptionId', isEqualTo: subscriptionId)
          .get();

      for (final doc in subscriptionQuery.docs) {
        await doc.reference.update({
          'status': 'active',
          'resumedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error resuming subscription: $e');
      rethrow;
    }
  }

  /// Update subscription price
  Future<void> updateSubscriptionPrice({
    required String subscriptionId,
    required double newPriceAmount,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/updateSubscriptionPrice'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'subscriptionId': subscriptionId,
          'newPriceAmount': (newPriceAmount * 100).round(), // Convert to cents
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update subscription price');
      }
    } catch (e) {
      debugPrint('Error updating subscription price: $e');
      rethrow;
    }
  }

  /// Create an earnings transaction for an artist
  Future<void> _createEarningsTransaction({
    required String artistId,
    required String type,
    required double amount,
    required String fromUserId,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get sender's name
      final senderDoc = await _firestore
          .collection('users')
          .doc(fromUserId)
          .get();
      final senderName =
          senderDoc.data()?['displayName'] as String? ?? 'Anonymous';

      // Create earnings transaction
      final transactionRef = _firestore
          .collection('earnings_transactions')
          .doc();
      await transactionRef.set({
        'id': transactionRef.id,
        'artistId': artistId,
        'type': type,
        'amount': amount,
        'fromUserId': fromUserId,
        'fromUserName': senderName,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
        'description': description,
        'metadata': metadata ?? {},
      });

      // Update artist earnings totals
      await _updateArtistEarnings(artistId, type, amount);
    } catch (e) {
      debugPrint('Error creating earnings transaction: $e');
      rethrow;
    }
  }

  /// Update artist earnings totals
  Future<void> _updateArtistEarnings(
    String artistId,
    String type,
    double amount,
  ) async {
    try {
      final earningsRef = _firestore
          .collection('artist_earnings')
          .doc(artistId);

      await _firestore.runTransaction((transaction) async {
        final earningsDoc = await transaction.get(earningsRef);

        if (!earningsDoc.exists) {
          // Create initial earnings record
          final currentMonth = DateTime.now().month.toString();
          transaction.set(earningsRef, {
            'artistId': artistId,
            'totalEarnings': amount,
            'availableBalance': amount,
            'pendingBalance': 0.0,
            'giftEarnings': type == 'gift' ? amount : 0.0,
            'sponsorshipEarnings': type == 'sponsorship' ? amount : 0.0,
            'commissionEarnings': type == 'commission' ? amount : 0.0,
            'subscriptionEarnings': type == 'subscription' ? amount : 0.0,
            'lastUpdated': FieldValue.serverTimestamp(),
            'monthlyBreakdown': {currentMonth: amount},
            'recentTransactions': <Map<String, dynamic>>[],
          });
        } else {
          // Update existing earnings
          final currentMonth = DateTime.now().month.toString();
          final currentData = earningsDoc.data()!;
          final monthlyBreakdown = Map<String, double>.from(
            currentData['monthlyBreakdown'] as Map<String, dynamic>? ?? {},
          );

          monthlyBreakdown[currentMonth] =
              (monthlyBreakdown[currentMonth] ?? 0.0) + amount;

          final updates = {
            'totalEarnings': FieldValue.increment(amount),
            'availableBalance': FieldValue.increment(amount),
            'lastUpdated': FieldValue.serverTimestamp(),
            'monthlyBreakdown': monthlyBreakdown,
          };

          // Update specific earning type
          switch (type) {
            case 'gift':
              updates['giftEarnings'] = FieldValue.increment(amount);
              break;
            case 'sponsorship':
              updates['sponsorshipEarnings'] = FieldValue.increment(amount);
              break;
            case 'commission':
              updates['commissionEarnings'] = FieldValue.increment(amount);
              break;
            case 'subscription':
              updates['subscriptionEarnings'] = FieldValue.increment(amount);
              break;
          }

          transaction.update(earningsRef, updates);
        }
      });
    } catch (e) {
      debugPrint('Error updating artist earnings: $e');
      rethrow;
    }
  }

  /// Get sponsorship analytics for an artist
  Future<Map<String, dynamic>> getSponsorshipAnalytics({
    required String artistId,
    String timeframe = 'month',
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/getSponsorshipAnalytics'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'artistId': artistId, 'timeframe': timeframe}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get sponsorship analytics');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting sponsorship analytics: $e');
      rethrow;
    }
  }

  /// Process custom gift payment with flexible amounts
  Future<Map<String, dynamic>> processCustomGiftPayment({
    required String recipientId,
    required double amount,
    required String paymentMethodId,
    String? message,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/processCustomGiftPayment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'senderId': userId,
          'recipientId': recipientId,
          'amount': amount,
          'paymentMethodId': paymentMethodId,
          if (message != null) 'message': message,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to process custom gift payment');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error processing custom gift payment: $e');
      rethrow;
    }
  }

  /// Create a gift subscription for recurring payments
  Future<Map<String, dynamic>> createGiftSubscription({
    required String recipientId,
    required double amount,
    required SubscriptionFrequency frequency,
    required String paymentMethodId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Map frequency to Stripe interval
      String interval;
      int intervalCount = 1;
      switch (frequency) {
        case SubscriptionFrequency.weekly:
          interval = 'week';
          break;
        case SubscriptionFrequency.biweekly:
          interval = 'week';
          intervalCount = 2;
          break;
        case SubscriptionFrequency.monthly:
          interval = 'month';
          break;
      }

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/createGiftSubscription'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'senderId': userId,
          'recipientId': recipientId,
          'amount': amount,
          'interval': interval,
          'intervalCount': intervalCount,
          'paymentMethodId': paymentMethodId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create gift subscription');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error creating gift subscription: $e');
      rethrow;
    }
  }

  /// Pause a gift subscription
  Future<void> pauseGiftSubscription(String stripeSubscriptionId) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/pauseGiftSubscription'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'subscriptionId': stripeSubscriptionId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to pause gift subscription');
      }
    } catch (e) {
      debugPrint('Error pausing gift subscription: $e');
      rethrow;
    }
  }

  /// Resume a gift subscription
  Future<void> resumeGiftSubscription(String stripeSubscriptionId) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/resumeGiftSubscription'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'subscriptionId': stripeSubscriptionId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to resume gift subscription');
      }
    } catch (e) {
      debugPrint('Error resuming gift subscription: $e');
      rethrow;
    }
  }

  /// Cancel a gift subscription
  Future<void> cancelGiftSubscription(String stripeSubscriptionId) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/cancelGiftSubscription'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'subscriptionId': stripeSubscriptionId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel gift subscription');
      }
    } catch (e) {
      debugPrint('Error cancelling gift subscription: $e');
      rethrow;
    }
  }

  /// Create a free subscription using a coupon (no payment required)
  Future<Map<String, dynamic>> createFreeSubscription({
    required String customerId,
    required SubscriptionTier tier,
    required String couponId,
    required String couponCode,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create a mock subscription record for free access
      final subscriptionData = {
        'subscriptionId':
            'free_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'active',
        'couponId': couponId,
        'discountedPrice': 0.0,
        'revenue': 0.0, // No revenue for free subscriptions
      };

      // Store subscription in Firestore
      await _firestore.collection('subscriptions').add({
        'userId': userId,
        'customerId': customerId,
        'subscriptionId': subscriptionData['subscriptionId'],
        'tier': tier.apiName,
        'status': subscriptionData['status'],
        'isActive': true,
        'autoRenew': false, // Free subscriptions don't auto-renew
        'couponCode': couponCode,
        'couponId': couponId,
        'originalPrice': tier.monthlyPrice,
        'discountedPrice': 0.0,
        'revenue': 0.0, // Track as zero revenue for analytics
        'isFree': true, // Flag to identify free subscriptions
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return subscriptionData;
    } catch (e) {
      debugPrint('Error creating free subscription: $e');
      rethrow;
    }
  }

  /// Process commission deposit payment
  Future<Map<String, dynamic>> processCommissionDepositPayment({
    required String commissionId,
    required double amount,
    required String paymentMethodId,
    String? message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      final customerId = await getOrCreateCustomerId();

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/processCommissionDepositPayment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customerId': customerId,
          'commissionId': commissionId,
          'amount': amount,
          'paymentMethodId': paymentMethodId,
          'message': message,
          'userId': user.uid,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to process commission deposit payment');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      // Store payment record in Firestore
      await _firestore.collection('commission_payments').add({
        'commissionId': commissionId,
        'userId': user.uid,
        'type': 'deposit',
        'amount': amount,
        'paymentIntentId': result['paymentIntentId'],
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {'message': message},
      });

      // Update commission status
      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .update({
            'status': 'in_progress',
            'metadata.depositPaidAt': FieldValue.serverTimestamp(),
            'metadata.depositPaymentId': result['paymentIntentId'],
          });

      return result;
    } catch (e) {
      debugPrint('Error processing commission deposit payment: $e');
      rethrow;
    }
  }

  /// Process commission milestone payment
  Future<Map<String, dynamic>> processCommissionMilestonePayment({
    required String commissionId,
    required String milestoneId,
    required double amount,
    required String paymentMethodId,
    String? message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      final customerId = await getOrCreateCustomerId();

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/processCommissionMilestonePayment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customerId': customerId,
          'commissionId': commissionId,
          'milestoneId': milestoneId,
          'amount': amount,
          'paymentMethodId': paymentMethodId,
          'message': message,
          'userId': user.uid,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to process commission milestone payment');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      // Store payment record in Firestore
      await _firestore.collection('commission_payments').add({
        'commissionId': commissionId,
        'milestoneId': milestoneId,
        'userId': user.uid,
        'type': 'milestone',
        'amount': amount,
        'paymentIntentId': result['paymentIntentId'],
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {'message': message},
      });

      // Update milestone status
      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .update({
            'milestones': FieldValue.arrayUnion([
              {
                'id': milestoneId,
                'paid': true,
                'paidAt': FieldValue.serverTimestamp(),
                'paymentId': result['paymentIntentId'],
              },
            ]),
          });

      return result;
    } catch (e) {
      debugPrint('Error processing commission milestone payment: $e');
      rethrow;
    }
  }

  /// Process final commission payment (remaining balance)
  Future<Map<String, dynamic>> processCommissionFinalPayment({
    required String commissionId,
    required double amount,
    required String paymentMethodId,
    String? message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      final customerId = await getOrCreateCustomerId();

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/processCommissionFinalPayment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customerId': customerId,
          'commissionId': commissionId,
          'amount': amount,
          'paymentMethodId': paymentMethodId,
          'message': message,
          'userId': user.uid,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to process commission final payment');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      // Store payment record in Firestore
      await _firestore.collection('commission_payments').add({
        'commissionId': commissionId,
        'userId': user.uid,
        'type': 'final',
        'amount': amount,
        'paymentIntentId': result['paymentIntentId'],
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {'message': message},
      });

      // Update commission status
      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .update({
            'status': 'completed',
            'metadata.finalPaidAt': FieldValue.serverTimestamp(),
            'metadata.finalPaymentId': result['paymentIntentId'],
          });

      return result;
    } catch (e) {
      debugPrint('Error processing commission final payment: $e');
      rethrow;
    }
  }

  /// Get commission payment history
  Future<List<Map<String, dynamic>>> getCommissionPayments(
    String commissionId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      final querySnapshot = await _firestore
          .collection('commission_payments')
          .where('commissionId', isEqualTo: commissionId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting commission payments: $e');
      return [];
    }
  }
}

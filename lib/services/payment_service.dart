import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat/models/subscription_model.dart';
import 'package:artbeat/models/payment_method_model.dart';

/// Service for handling payment operations and Stripe integration
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Replace with your own Cloud Functions URL or API endpoint
  final String _paymentApiUrl =
      'https://us-central1-wordnerd-4ef38.cloudfunctions.net/createPaymentIntent';
  final String _subscriptionApiUrl =
      'https://us-central1-wordnerd-4ef38.cloudfunctions.net/createSubscription';
  final String _setupIntentApiUrl =
      'https://us-central1-wordnerd-4ef38.cloudfunctions.net/createSetupIntent';
  final String _customerApiUrl =
      'https://us-central1-wordnerd-4ef38.cloudfunctions.net/createCustomer';
  final String _paymentMethodsApiUrl =
      'https://us-central1-wordnerd-4ef38.cloudfunctions.net/getPaymentMethods';
  final String _detachPaymentMethodApiUrl =
      'https://us-central1-wordnerd-4ef38.cloudfunctions.net/detachPaymentMethod';
  final String _updateCustomerApiUrl =
      'https://us-central1-wordnerd-4ef38.cloudfunctions.net/updateCustomer';

  /// Initialize Stripe with your publishable key
  static Future<void> initialize() async {
    Stripe.publishableKey =
        'pk_test_51NyuijHl9TaH01UKjjwGvGy1iOIs3LUlv0OBDT5YPbT5KrESr0uKCo9fzu8TXMEoCWRXkZdgOaebPxMbl4hLEPdV00yaNfkZsb'; // Test key - replace with your actual key in production
    await Stripe.instance.applySettings();
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Create a payment intent for subscription
  Future<Map<String, dynamic>> createPaymentIntent({
    required SubscriptionTier tier,
    required String email,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    double amount = 0;
    String currency = 'usd';
    String planId = '';

    // Set price based on subscription tier
    switch (tier) {
      case SubscriptionTier.standard:
        amount = 999; // $9.99 in cents
        planId = 'price_artist_pro_monthly';
        break;
      case SubscriptionTier.premium:
        amount = 4999; // $49.99 in cents
        planId = 'price_gallery_monthly';
        break;
      default:
        throw Exception('Free tier does not require payment');
    }

    try {
      // Make API call to create payment intent
      final response = await http.post(
        Uri.parse(_paymentApiUrl),
        body: jsonEncode({
          'email': email,
          'amount': amount,
          'currency': currency,
          'userId': userId,
          'planId': planId,
          'metadata': {
            'userId': userId,
            'subscriptionTier': tier.toString(),
          },
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(
            responseData['error'] ?? 'Payment intent creation failed');
      }

      return responseData;
    } catch (e) {
      throw Exception('Error creating payment: $e');
    }
  }

  /// Process payment with Stripe
  Future<bool> processPayment({
    required SubscriptionTier tier,
    required String email,
  }) async {
    try {
      // 1. Create payment intent on the server
      final paymentIntentData = await createPaymentIntent(
        tier: tier,
        email: email,
      );

      // 2. Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['clientSecret'],
          merchantDisplayName: 'WordNerd Artist Subscription',
          customerId: paymentIntentData['customer'],
          customerEphemeralKeySecret: paymentIntentData['ephemeralKey'],
          style: ThemeMode.system,
        ),
      );

      // 3. Present payment sheet and await result
      await Stripe.instance.presentPaymentSheet();

      // 4. Create subscription in Stripe and save to Firestore
      await _createSubscription(
        tier: tier,
        customerId: paymentIntentData['customer'],
        priceId: tier == SubscriptionTier.standard
            ? 'price_artist_pro_monthly'
            : 'price_gallery_monthly',
      );

      return true;
    } catch (e) {
      print('Payment error: $e');
      if (e is StripeException) {
        if (e.error.code == 'Canceled') {
          return false; // User canceled, not an error to show
        }
      }
      rethrow; // Rethrow for handling in UI
    }
  }

  /// Create subscription in Stripe and save to Firestore
  Future<void> _createSubscription({
    required SubscriptionTier tier,
    required String customerId,
    required String priceId,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // 1. Call API to create subscription in Stripe
      final response = await http.post(
        Uri.parse(_subscriptionApiUrl),
        body: jsonEncode({
          'customerId': customerId,
          'priceId': priceId,
          'userId': userId,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(
            responseData['error'] ?? 'Subscription creation failed');
      }

      // 2. Save subscription to Firestore
      final startDate = DateTime.now();
      final endDate = DateTime.now().add(const Duration(days: 30));

      await _firestore.collection('subscriptions').add({
        'userId': userId,
        'tier': _tierToString(tier),
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'isActive': true,
        'autoRenew': true,
        'paymentMethod': 'card',
        'stripeCustomerId': customerId,
        'stripePriceId': priceId,
        'stripeSubscriptionId': responseData['subscriptionId'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update user profile with subscription tier
      await _updateUserSubscriptionTier(tier);
    } catch (e) {
      throw Exception('Error creating subscription: $e');
    }
  }

  /// Update user's artist profile with subscription tier
  Future<void> _updateUserSubscriptionTier(SubscriptionTier tier) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Update artist profile
      final artistProfileSnapshot = await _firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: userId)
          .get();

      if (artistProfileSnapshot.docs.isNotEmpty) {
        await _firestore
            .collection('artistProfiles')
            .doc(artistProfileSnapshot.docs.first.id)
            .update({
          'subscriptionTier': _tierToString(tier),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating user subscription tier: $e');
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // 1. Get active subscription
      final subscriptionSnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      if (subscriptionSnapshot.docs.isEmpty) {
        throw Exception('No active subscription found');
      }

      final subscriptionDoc = subscriptionSnapshot.docs.first;
      final subscriptionData = subscriptionDoc.data();
      final stripeSubscriptionId = subscriptionData['stripeSubscriptionId'];

      if (stripeSubscriptionId == null) {
        throw Exception('Subscription ID not found');
      }

      // 2. Call API to cancel subscription in Stripe
      final response = await http.post(
        Uri.parse(
            'https://us-central1-wordnerd-4ef38.cloudfunctions.net/cancelSubscription'),
        body: jsonEncode({
          'subscriptionId': stripeSubscriptionId,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(
            responseData['error'] ?? 'Subscription cancellation failed');
      }

      // 3. Update subscription in Firestore
      await subscriptionDoc.reference.update({
        'isActive': false,
        'autoRenew': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Update user profile with free tier
      await _updateUserSubscriptionTier(SubscriptionTier.free);
    } catch (e) {
      throw Exception('Error canceling subscription: $e');
    }
  }

  /// Helper method to convert SubscriptionTier to string
  String _tierToString(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'free';
      case SubscriptionTier.standard:
        return 'standard';
      case SubscriptionTier.premium:
        return 'premium';
    }
  }

  /// Create a new customer in Stripe
  Future<String> createCustomer(
      {required String email, required String userId}) async {
    try {
      final response = await http.post(
        Uri.parse(_customerApiUrl),
        body: jsonEncode({
          'email': email,
          'userId': userId,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(responseData['error'] ?? 'Failed to create customer');
      }

      return responseData['customerId'];
    } catch (e) {
      throw Exception('Error creating customer: $e');
    }
  }

  /// Create a setup intent for adding a payment method
  Future<String> createSetupIntent(String customerId) async {
    try {
      final response = await http.post(
        Uri.parse(_setupIntentApiUrl),
        body: jsonEncode({
          'customerId': customerId,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(
            responseData['error'] ?? 'Failed to create setup intent');
      }

      return responseData['clientSecret'];
    } catch (e) {
      throw Exception('Error creating setup intent: $e');
    }
  }

  /// Setup payment sheet for adding a payment method
  Future<void> setupPaymentSheet({
    required String customerId,
    required String setupIntentClientSecret,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: setupIntentClientSecret,
          merchantDisplayName: 'WordNerd',
          customerId: customerId,
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Colors.blue,
            ),
          ),
        ),
      );
    } catch (e) {
      throw Exception('Error setting up payment sheet: $e');
    }
  }

  /// Get customer's payment methods
  Future<List<PaymentMethodModel>> getPaymentMethods(String customerId) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://us-central1-wordnerd-4ef38.cloudfunctions.net/getPaymentMethods'),
        body: jsonEncode({
          'customerId': customerId,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(
            responseData['error'] ?? 'Failed to retrieve payment methods');
      }

      final List<dynamic> paymentMethodsData = responseData['paymentMethods'];
      return paymentMethodsData
          .map((data) => PaymentMethodModel.fromJson(data))
          .toList();
    } catch (e) {
      throw Exception('Error retrieving payment methods: $e');
    }
  }

  /// Set default payment method
  Future<void> setDefaultPaymentMethod({
    required String customerId,
    required String paymentMethodId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_updateCustomerApiUrl),
        body: jsonEncode({
          'customerId': customerId,
          'defaultPaymentMethod': paymentMethodId,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(
            responseData['error'] ?? 'Failed to set default payment method');
      }
    } catch (e) {
      throw Exception('Error setting default payment method: $e');
    }
  }

  /// Detach payment method from customer
  Future<void> detachPaymentMethod(String paymentMethodId) async {
    try {
      final response = await http.post(
        Uri.parse(_detachPaymentMethodApiUrl),
        body: jsonEncode({
          'paymentMethodId': paymentMethodId,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(
            responseData['error'] ?? 'Failed to remove payment method');
      }
    } catch (e) {
      throw Exception('Error removing payment method: $e');
    }
  }

  /// Request a refund for a subscription payment
  Future<void> requestRefund({
    required String paymentId,
    required String subscriptionId,
    required String reason,
    String? additionalDetails,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // 1. Call the API to request a refund in Stripe
      final response = await http.post(
        Uri.parse(
            'https://us-central1-wordnerd-4ef38.cloudfunctions.net/requestRefund'),
        body: jsonEncode({
          'paymentId': paymentId,
          'subscriptionId': subscriptionId,
          'userId': userId,
          'reason': reason,
          'additionalDetails': additionalDetails,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(responseData['error'] ?? 'Refund request failed');
      }

      // 2. Save refund request to Firestore for tracking
      await _firestore.collection('refundRequests').add({
        'userId': userId,
        'paymentId': paymentId,
        'subscriptionId': subscriptionId,
        'reason': reason,
        'additionalDetails': additionalDetails,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error requesting refund: $e');
    }
  }

  /// Change subscription tier
  Future<void> changeSubscriptionTier({
    required SubscriptionTier newTier,
    required String subscriptionId,
    required bool prorated,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // 1. Get subscription details
      final subscriptionSnapshot = await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();

      if (!subscriptionSnapshot.exists) {
        throw Exception('Subscription not found');
      }

      final subscriptionData =
          subscriptionSnapshot.data() as Map<String, dynamic>;
      final stripeSubscriptionId = subscriptionData['stripeSubscriptionId'];
      final currentTier = _tierFromString(subscriptionData['tier']);

      if (currentTier == newTier) {
        throw Exception('Already subscribed to this tier');
      }

      // 2. If downgrading to free plan, just cancel subscription
      if (newTier == SubscriptionTier.free) {
        await cancelSubscription();
        return;
      }

      // 3. Call API to update subscription in Stripe
      final response = await http.post(
        Uri.parse(
            'https://us-central1-wordnerd-4ef38.cloudfunctions.net/changeSubscriptionTier'),
        body: jsonEncode({
          'subscriptionId': stripeSubscriptionId,
          'newPriceId': _getStripePriceId(newTier),
          'prorated': prorated,
          'userId': userId,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(responseData['error'] ?? 'Subscription update failed');
      }

      // 4. Update subscription in Firestore (Stripe webhook will also handle this,
      // but we update immediately for responsiveness)
      await subscriptionSnapshot.reference.update({
        'tier': _tierToString(newTier),
        'stripePriceId': _getStripePriceId(newTier),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 5. Update user profile with subscription tier
      await _updateUserSubscriptionTier(newTier);
    } catch (e) {
      throw Exception('Error changing subscription tier: $e');
    }
  }

  /// Helper method to convert string tier to enum
  SubscriptionTier _tierFromString(String tier) {
    switch (tier.toLowerCase()) {
      case 'free':
        return SubscriptionTier.free;
      case 'standard':
        return SubscriptionTier.standard;
      case 'premium':
        return SubscriptionTier.premium;
      default:
        return SubscriptionTier.free;
    }
  }

  /// Helper to get Stripe price ID based on tier
  String _getStripePriceId(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.standard:
        return 'price_artist_pro_monthly';
      case SubscriptionTier.premium:
        return 'price_gallery_monthly';
      default:
        return '';
    }
  }
}

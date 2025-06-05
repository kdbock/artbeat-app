import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/subscription_tier.dart' show SubscriptionTier;
import '../models/payment_method_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gift_model.dart';

/// Service for handling payments and subscriptions
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();

  factory PaymentService() {
    return _instance;
  }

  PaymentService._internal() {
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
  }

  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;

  static const String _baseUrl = 'https://your-payment-api.com';

  /// Change subscription tier
  Future<void> changeSubscriptionTier({
    required String customerId,
    required String subscriptionId,
    required SubscriptionTier newTier,
    bool prorated = true,
  }) async {
    try {
      await _post('/change-subscription-tier', {
        'customerId': customerId,
        'subscriptionId': subscriptionId,
        'newTier': newTier.apiName,
        'prorated': prorated,
      });
    } catch (e) {
      debugPrint('Error changing subscription tier: $e');
      rethrow;
    }
  }

  /// Create a new Stripe customer
  Future<String> createCustomer({
    required String email,
    required String name,
  }) async {
    try {
      final data = await _post('/create-customer', {
        'email': email,
        'name': name,
      });
      return data['customerId'];
    } catch (e) {
      print('Error creating customer: $e');
      rethrow;
    }
  }

  /// Set up the payment sheet
  Future<void> setupPaymentSheet({
    required String customerId,
    required String setupIntentClientSecret,
  }) async {
    try {
      await _post('/setup-payment-sheet', {
        'customerId': customerId,
        'setupIntentClientSecret': setupIntentClientSecret,
      });
    } catch (e) {
      debugPrint('Error setting up payment sheet: $e');
      rethrow;
    }
  }

  /// Create a setup intent
  Future<String> createSetupIntent(String customerId) async {
    try {
      final data = await _post('/create-setup-intent', {
        'customerId': customerId,
      });
      return data['clientSecret'];
    } catch (e) {
      debugPrint('Error creating setup intent: $e');
      rethrow;
    }
  }

  /// Get customer's payment methods
  Future<List<PaymentMethodModel>> getPaymentMethods(String customerId) async {
    try {
      final data = await _get('/payment-methods/$customerId');
      return (data['paymentMethods'] as List)
          .map((pm) => PaymentMethodModel.fromJson(pm))
          .toList();
    } catch (e) {
      debugPrint('Error getting payment methods: $e');
      return [];
    }
  }

  /// Set default payment method
  Future<void> setDefaultPaymentMethod({
    required String customerId,
    required String paymentMethodId,
  }) async {
    try {
      await _post('/set-default-payment-method', {
        'customerId': customerId,
        'paymentMethodId': paymentMethodId,
      });
    } catch (e) {
      debugPrint('Error setting default payment method: $e');
      rethrow;
    }
  }

  /// Detach a payment method
  Future<void> detachPaymentMethod(String paymentMethodId) async {
    try {
      await _post('/detach-payment-method', {
        'paymentMethodId': paymentMethodId,
      });
    } catch (e) {
      debugPrint('Error detaching payment method: $e');
      rethrow;
    }
  }

  /// Process a payment
  Future<bool> processPayment({
    required String customerId,
    required String paymentMethodId,
    required int amount,
    required String currency,
    required String description,
  }) async {
    try {
      await _post('/process-payment', {
        'customerId': customerId,
        'paymentMethodId': paymentMethodId,
        'amount': amount,
        'currency': currency,
        'description': description,
      });
      return true;
    } catch (e) {
      debugPrint('Error processing payment: $e');
      return false;
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      await _post('/cancel-subscription', {
        'subscriptionId': subscriptionId,
      });
    } catch (e) {
      debugPrint('Error cancelling subscription: $e');
      rethrow;
    }
  }

  /// Request a refund
  Future<bool> requestRefund({
    required String paymentId,
    required String reason,
    double? amount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/requestRefund'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'userId': user.uid,
          'paymentId': paymentId,
          'reason': reason,
          if (amount != null)
            'amount': (amount * 100).round(), // Stripe uses cents
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error requesting refund: $e');
      return false;
    }
  }

  /// Process a gift payment
  Future<void> processGiftPayment(GiftModel gift) async {
    try {
      await _firestore.collection('gifts').add(gift.toFirestore());

      // Using transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        // Update recipient's gifts received
        transaction.set(
          _firestore.collection('users').doc(gift.recipientId),
          {'giftsReceived': FieldValue.increment(1)},
          SetOptions(merge: true),
        );

        // Update sender's gifts sent
        transaction.set(
          _firestore.collection('users').doc(gift.senderId),
          {'giftsSent': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      debugPrint('Error processing gift payment: $e');
      rethrow;
    }
  }

  /// Get gifts sent by a user
  Future<List<GiftModel>> getSentGifts(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('gifts')
          .where('senderId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GiftModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching sent gifts: $e');
      return [];
    }
  }

  /// Get gifts received by a user
  Future<List<GiftModel>> getReceivedGifts(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('gifts')
          .where('recipientId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GiftModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching received gifts: $e');
      return [];
    }
  }

  /// Get auth headers with ID token
  Future<Map<String, String>> _getAuthHeaders() async {
    final user = _auth.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  Future<dynamic> _post(String path, [dynamic body]) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: await _getAuthHeaders(),
      body: jsonEncode(body),
    );
    _handleResponse(response);
    return jsonDecode(response.body);
  }

  Future<dynamic> _get(String path) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: await _getAuthHeaders(),
    );
    _handleResponse(response);
    return jsonDecode(response.body);
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP error: ${response.statusCode} - ${response.body}');
    }
  }
}

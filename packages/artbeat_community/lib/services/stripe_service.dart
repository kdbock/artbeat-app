import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Stripe service for handling commission payments
class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();
  final http.Client _httpClient = http.Client();

  static const String _baseUrl =
      'https://us-central1-wordnerd-artbeat.cloudfunctions.net';

  /// Initialize Stripe
  void initialize() {
    // Stripe is already initialized in PaymentService
    debugPrint('✅ Stripe service initialized for commissions');
  }

  /// Process commission deposit payment
  Future<Map<String, dynamic>> processCommissionDeposit({
    required String commissionId,
    required double amount,
    String? paymentMethodId,
    String? message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      // Get or create payment method
      final paymentMethod =
          paymentMethodId ?? await _paymentService.getDefaultPaymentMethodId();

      if (paymentMethod == null) {
        throw Exception(
          'No payment method available. Please set up a payment method in your profile first.',
        );
      }

      // Process payment using PaymentService
      final result = await _paymentService.processCommissionDepositPayment(
        commissionId: commissionId,
        amount: amount,
        paymentMethodId: paymentMethod,
        message: message,
      );

      // Update commission status locally
      await _updateCommissionStatus(commissionId, 'in_progress');

      return result;
    } catch (e) {
      debugPrint('Error processing commission deposit: $e');
      rethrow;
    }
  }

  /// Process commission milestone payment
  Future<Map<String, dynamic>> processCommissionMilestone({
    required String commissionId,
    required String milestoneId,
    required double amount,
    String? paymentMethodId,
    String? message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      // Get or create payment method
      final paymentMethod =
          paymentMethodId ?? await _paymentService.getDefaultPaymentMethodId();

      if (paymentMethod == null) {
        throw Exception(
          'No payment method available. Please set up a payment method in your profile first.',
        );
      }

      // Process payment using PaymentService
      final result = await _paymentService.processCommissionMilestonePayment(
        commissionId: commissionId,
        milestoneId: milestoneId,
        amount: amount,
        paymentMethodId: paymentMethod,
        message: message,
      );

      return result;
    } catch (e) {
      debugPrint('Error processing commission milestone: $e');
      rethrow;
    }
  }

  /// Process final commission payment
  Future<Map<String, dynamic>> processCommissionFinal({
    required String commissionId,
    required double amount,
    String? paymentMethodId,
    String? message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      // Get or create payment method
      final paymentMethod =
          paymentMethodId ?? await _paymentService.getDefaultPaymentMethodId();

      if (paymentMethod == null) {
        throw Exception(
          'No payment method available. Please set up a payment method in your profile first.',
        );
      }

      // Process payment using PaymentService
      final result = await _paymentService.processCommissionFinalPayment(
        commissionId: commissionId,
        amount: amount,
        paymentMethodId: paymentMethod,
        message: message,
      );

      // Update commission status locally
      await _updateCommissionStatus(commissionId, 'completed');

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
    return _paymentService.getCommissionPayments(commissionId);
  }

  /// Create payment intent for commission
  Future<String> createCommissionPaymentIntent({
    required String commissionId,
    required double amount,
    required String type, // 'deposit', 'milestone', 'final'
    String? milestoneId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      final customerId = await _paymentService.getOrCreateCustomerId();

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/createCommissionPaymentIntent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customerId': customerId,
          'commissionId': commissionId,
          'amount': amount,
          'type': type,
          'milestoneId': milestoneId,
          'userId': user.uid,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create payment intent');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      return result['clientSecret'] as String;
    } catch (e) {
      debugPrint('Error creating commission payment intent: $e');
      rethrow;
    }
  }

  /// Confirm payment with Stripe
  Future<void> confirmCommissionPayment(
    String clientSecret,
    String paymentMethodId,
  ) async {
    try {
      // Payment confirmation is handled by the PaymentService
      // This method is kept for future use if direct Stripe confirmation is needed
      debugPrint('Commission payment confirmation handled by PaymentService');
    } catch (e) {
      debugPrint('Error confirming commission payment: $e');
      rethrow;
    }
  }

  /// Helper method to update commission status
  Future<void> _updateCommissionStatus(
    String commissionId,
    String status,
  ) async {
    try {
      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error updating commission status: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }

  /// Process commission payment (generic method)
  Future<Map<String, dynamic>> processCommissionPayment({
    required String commissionId,
    required double amount,
    required String paymentType, // 'deposit', 'milestone', 'final'
    String? milestoneId,
    String? paymentMethodId,
    String? message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      // Get or create payment method
      final paymentMethod =
          paymentMethodId ?? await _paymentService.getDefaultPaymentMethodId();

      if (paymentMethod == null) {
        throw Exception(
          'No payment method available. Please set up a payment method in your profile first.',
        );
      }

      // Route to appropriate payment method based on type
      switch (paymentType) {
        case 'deposit':
          return await _paymentService.processCommissionDepositPayment(
            commissionId: commissionId,
            amount: amount,
            paymentMethodId: paymentMethod,
            message: message,
          );
        case 'milestone':
          if (milestoneId == null) {
            throw Exception('Milestone ID required for milestone payment');
          }
          return await _paymentService.processCommissionMilestonePayment(
            commissionId: commissionId,
            milestoneId: milestoneId,
            amount: amount,
            paymentMethodId: paymentMethod,
            message: message,
          );
        case 'final':
          return await _paymentService.processCommissionFinalPayment(
            commissionId: commissionId,
            amount: amount,
            paymentMethodId: paymentMethod,
            message: message,
          );
        default:
          throw Exception('Invalid payment type: $paymentType');
      }
    } catch (e) {
      debugPrint('Error processing commission payment: $e');
      rethrow;
    }
  }

  /// Process refund for commission payment
  Future<Map<String, dynamic>> refundPayment({
    required String paymentIntentId,
    required double amount,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/refundPayment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'paymentIntentId': paymentIntentId,
          'amount': amount,
          'reason': reason ?? 'requested_by_customer',
          'metadata': metadata ?? {},
          'userId': user.uid,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to process refund: ${response.body}');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      // Log refund in commission history
      if (metadata != null && metadata.containsKey('commissionId')) {
        final commissionId = metadata['commissionId'] as String;
        await _firestore
            .collection('direct_commissions')
            .doc(commissionId)
            .update({
              'metadata.refunds': FieldValue.arrayUnion([
                {
                  'paymentIntentId': paymentIntentId,
                  'amount': amount,
                  'reason': reason,
                  'timestamp': FieldValue.serverTimestamp(),
                  'processedBy': user.uid,
                },
              ]),
            });
      }

      return result;
    } catch (e) {
      debugPrint('Error processing refund: $e');
      rethrow;
    }
  }

  /// Get payment history for user
  Future<List<Map<String, dynamic>>> getPaymentHistory({
    String? commissionId,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      // Query commission payments collection
      Query query = _firestore
          .collection('commission_payments')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // Filter by commission if specified
      if (commissionId != null) {
        query = query.where('commissionId', isEqualTo: commissionId);
      }

      // Add date filters if specified
      if (startDate != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final querySnapshot = await query.get();
      final payments = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return payments;
    } catch (e) {
      debugPrint('Error getting payment history: $e');
      rethrow;
    }
  }
}

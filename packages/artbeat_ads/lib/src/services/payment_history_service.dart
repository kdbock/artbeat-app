import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/payment_history_model.dart';

/// Service for managing payment history and transaction records
///
/// Provides functionality for:
/// - Recording payment transactions
/// - Retrieving user payment history
/// - Generating financial reports
/// - Managing receipts and refunds
class PaymentHistoryService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'payment_history';

  /// Record a new payment transaction
  Future<void> recordPayment({
    required String userId,
    required String adId,
    required String adTitle,
    required double amount,
    String currency = 'USD',
    required PaymentMethod paymentMethod,
    PaymentStatus status = PaymentStatus.pending,
    String? stripePaymentIntentId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final payment = PaymentHistoryModel(
        id: '', // Will be set by Firestore
        userId: userId,
        adId: adId,
        adTitle: adTitle,
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
        status: status,
        transactionDate: DateTime.now(),
        stripePaymentIntentId: stripePaymentIntentId,
        metadata: metadata ?? {},
      );

      await _firestore.collection(_collectionName).add(payment.toFirestore());

      notifyListeners();
    } catch (e) {
      debugPrint('Error recording payment: $e');
      rethrow;
    }
  }

  /// Update payment status (e.g., from pending to completed)
  Future<void> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? failureReason,
    String? receiptUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.value,
        'updatedAt': Timestamp.now(),
      };

      if (failureReason != null) {
        updateData['failureReason'] = failureReason;
      }

      if (receiptUrl != null) {
        updateData['receiptUrl'] = receiptUrl;
      }

      await _firestore
          .collection(_collectionName)
          .doc(paymentId)
          .update(updateData);

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      rethrow;
    }
  }

  /// Record a refund transaction
  Future<void> recordRefund({
    required String paymentId,
    required double refundAmount,
    required String refundReason,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(paymentId).update({
        'status': PaymentStatus.refunded.value,
        'refundedAt': Timestamp.now(),
        'refundAmount': refundAmount,
        'refundReason': refundReason,
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error recording refund: $e');
      rethrow;
    }
  }

  /// Get payment history for a specific user
  Stream<List<PaymentHistoryModel>> getUserPaymentHistory({
    required String userId,
    int limit = 50,
    PaymentStatus? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('transactionDate', descending: true);

      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.value);
      }

      if (startDate != null) {
        query = query.where(
          'transactionDate',
          isGreaterThanOrEqualTo: startDate,
        );
      }

      if (endDate != null) {
        query = query.where('transactionDate', isLessThanOrEqualTo: endDate);
      }

      query = query.limit(limit);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => PaymentHistoryModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      debugPrint('Error getting user payment history: $e');
      return Stream.value([]);
    }
  }

  /// Get payment details by ID
  Future<PaymentHistoryModel?> getPaymentById(String paymentId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(paymentId)
          .get();

      if (doc.exists) {
        return PaymentHistoryModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting payment by ID: $e');
      return null;
    }
  }

  /// Get total revenue for a user within date range
  Future<double> getUserTotalRevenue({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String currency = 'USD',
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: PaymentStatus.completed.value)
          .where('currency', isEqualTo: currency);

      if (startDate != null) {
        query = query.where(
          'transactionDate',
          isGreaterThanOrEqualTo: startDate,
        );
      }

      if (endDate != null) {
        query = query.where('transactionDate', isLessThanOrEqualTo: endDate);
      }

      final querySnapshot = await query.get();
      double totalRevenue = 0.0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = ((data['amount'] as num?) ?? 0).toDouble();
        final refundAmount = ((data['refundAmount'] as num?) ?? 0).toDouble();
        totalRevenue += (amount - refundAmount);
      }

      return totalRevenue;
    } catch (e) {
      debugPrint('Error calculating total revenue: $e');
      return 0.0;
    }
  }

  /// Get payment statistics for a user
  Future<Map<String, dynamic>> getUserPaymentStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId);

      if (startDate != null) {
        query = query.where(
          'transactionDate',
          isGreaterThanOrEqualTo: startDate,
        );
      }

      if (endDate != null) {
        query = query.where('transactionDate', isLessThanOrEqualTo: endDate);
      }

      final querySnapshot = await query.get();

      int totalPayments = 0;
      int successfulPayments = 0;
      int failedPayments = 0;
      int refundedPayments = 0;
      double totalAmount = 0.0;
      double refundedAmount = 0.0;

      for (var doc in querySnapshot.docs) {
        final payment = PaymentHistoryModel.fromFirestore(doc);
        totalPayments++;
        totalAmount += payment.amount;

        switch (payment.status) {
          case PaymentStatus.completed:
            successfulPayments++;
            break;
          case PaymentStatus.failed:
            failedPayments++;
            break;
          case PaymentStatus.refunded:
          case PaymentStatus.partiallyRefunded:
            refundedPayments++;
            refundedAmount += (payment.refundAmount ?? 0);
            break;
          default:
            break;
        }
      }

      return {
        'totalPayments': totalPayments,
        'successfulPayments': successfulPayments,
        'failedPayments': failedPayments,
        'refundedPayments': refundedPayments,
        'totalAmount': totalAmount,
        'refundedAmount': refundedAmount,
        'netRevenue': totalAmount - refundedAmount,
        'successRate': totalPayments > 0
            ? (successfulPayments / totalPayments) * 100
            : 0.0,
      };
    } catch (e) {
      debugPrint('Error getting payment statistics: $e');
      return {};
    }
  }

  /// Get monthly payment summary for charts/graphs
  Future<List<Map<String, dynamic>>> getMonthlyPaymentSummary({
    required String userId,
    required int monthsBack,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = DateTime(endDate.year, endDate.month - monthsBack, 1);

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('transactionDate', isGreaterThanOrEqualTo: startDate)
          .where('transactionDate', isLessThanOrEqualTo: endDate)
          .orderBy('transactionDate')
          .get();

      final monthlyData = <String, Map<String, dynamic>>{};

      // Initialize months
      for (int i = 0; i < monthsBack; i++) {
        final monthDate = DateTime(endDate.year, endDate.month - i, 1);
        final monthKey =
            '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}';
        monthlyData[monthKey] = {
          'month': monthKey,
          'totalAmount': 0.0,
          'totalPayments': 0,
          'successfulPayments': 0,
          'refundedAmount': 0.0,
        };
      }

      for (var doc in querySnapshot.docs) {
        final payment = PaymentHistoryModel.fromFirestore(doc);
        final monthKey =
            '${payment.transactionDate.year}-${payment.transactionDate.month.toString().padLeft(2, '0')}';

        if (monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey]!['totalAmount'] =
              (monthlyData[monthKey]!['totalAmount'] as double) +
              payment.amount;
          monthlyData[monthKey]!['totalPayments'] =
              (monthlyData[monthKey]!['totalPayments'] as int) + 1;

          if (payment.status == PaymentStatus.completed) {
            monthlyData[monthKey]!['successfulPayments'] =
                (monthlyData[monthKey]!['successfulPayments'] as int) + 1;
          }

          if (payment.isRefunded && payment.refundAmount != null) {
            monthlyData[monthKey]!['refundedAmount'] =
                (monthlyData[monthKey]!['refundedAmount'] as double) +
                payment.refundAmount!;
          }
        }
      }

      return monthlyData.values.toList()..sort(
        (a, b) => (a['month'] as String).compareTo(b['month'] as String),
      );
    } catch (e) {
      debugPrint('Error getting monthly payment summary: $e');
      return [];
    }
  }

  /// Search payments by ad title or transaction ID
  Future<List<PaymentHistoryModel>> searchPayments({
    required String userId,
    required String searchTerm,
    int limit = 20,
  }) async {
    try {
      // Search by ad title
      final titleQuery = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('adTitle', isGreaterThanOrEqualTo: searchTerm)
          .where('adTitle', isLessThan: '${searchTerm}z')
          .limit(limit)
          .get();

      // Search by payment intent ID
      final intentQuery = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('stripePaymentIntentId', isEqualTo: searchTerm)
          .limit(limit)
          .get();

      final results = <PaymentHistoryModel>[];
      final seenIds = <String>{};

      // Add results from title search
      for (var doc in titleQuery.docs) {
        if (!seenIds.contains(doc.id)) {
          results.add(PaymentHistoryModel.fromFirestore(doc));
          seenIds.add(doc.id);
        }
      }

      // Add results from intent ID search
      for (var doc in intentQuery.docs) {
        if (!seenIds.contains(doc.id)) {
          results.add(PaymentHistoryModel.fromFirestore(doc));
          seenIds.add(doc.id);
        }
      }

      // Sort by transaction date (newest first)
      results.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      return results.take(limit).toList();
    } catch (e) {
      debugPrint('Error searching payments: $e');
      return [];
    }
  }

  /// Generate receipt URL (placeholder - integrate with actual receipt generation)
  Future<String?> generateReceipt(String paymentId) async {
    try {
      // TODO: Integrate with actual receipt generation service
      // For now, return a placeholder URL
      return 'https://receipts.artbeat.com/receipt/$paymentId.pdf';
    } catch (e) {
      debugPrint('Error generating receipt: $e');
      return null;
    }
  }
}

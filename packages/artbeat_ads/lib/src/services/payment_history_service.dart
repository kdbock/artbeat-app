import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' as intl;
import '../models/payment_history_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Service for managing payment history and transaction records
///
/// Provides functionality for:
/// - Recording payment transactions
/// - Retrieving user payment history
/// - Generating financial reports
/// - Managing receipts and refunds
class PaymentHistoryService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'payment_history';

  PaymentHistoryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

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
      AppLogger.error('Error recording payment: $e');
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
      AppLogger.error('Error updating payment status: $e');
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
      AppLogger.error('Error recording refund: $e');
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
      AppLogger.error('Error getting user payment history: $e');
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
      AppLogger.error('Error getting payment by ID: $e');
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
      AppLogger.error('Error calculating total revenue: $e');
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
      AppLogger.error('Error getting payment statistics: $e');
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
      AppLogger.error('Error getting monthly payment summary: $e');
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
      AppLogger.error('Error searching payments: $e');
      return [];
    }
  }

  /// Generate receipt URL (creates HTML receipt with payment details)
  Future<String?> generateReceipt(String paymentId) async {
    try {
      // Get payment details from Firestore
      final paymentDoc = await _firestore
          .collection('payment_history')
          .doc(paymentId)
          .get();

      if (!paymentDoc.exists) {
        AppLogger.error('Payment not found: $paymentId');
        return null;
      }

      final payment = PaymentHistoryModel.fromFirestore(paymentDoc);

      // Get user details
      final userDoc = await _firestore
          .collection('users')
          .doc(payment.userId)
          .get();

      final userName = userDoc.exists
          ? (userDoc.data()?['displayName'] as String?) ?? 'Unknown User'
          : 'Unknown User';

      // Generate HTML receipt
      final htmlReceipt = _generateHtmlReceipt(payment, userName);

      // For now, return a data URL with the HTML content
      // In production, this could be uploaded to cloud storage or converted to PDF
      final encodedHtml = Uri.encodeComponent(htmlReceipt);
      final dataUrl = 'data:text/html;charset=utf-8,$encodedHtml';

      return dataUrl;
    } catch (e) {
      AppLogger.error('Error generating receipt: $e');
      return null;
    }
  }

  /// Generate HTML receipt content
  String _generateHtmlReceipt(PaymentHistoryModel payment, String userName) {
    final formattedDate = intl.DateFormat(
      'MMMM dd, yyyy',
    ).format(payment.transactionDate);
    final formattedTime = intl.DateFormat(
      'HH:mm:ss',
    ).format(payment.transactionDate);

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>ARTbeat Receipt - ${payment.id}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .receipt-container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            border-bottom: 2px solid #333;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        .logo {
            font-size: 24px;
            font-weight: bold;
            color: #333;
            margin-bottom: 10px;
        }
        .receipt-title {
            font-size: 18px;
            color: #666;
        }
        .details {
            margin: 20px 0;
        }
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid #eee;
        }
        .detail-label {
            font-weight: bold;
            color: #333;
        }
        .detail-value {
            color: #666;
        }
        .amount {
            font-size: 20px;
            font-weight: bold;
            color: #28a745;
            text-align: center;
            margin: 20px 0;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 5px;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            text-align: center;
            font-size: 12px;
            color: #666;
        }
        .status {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 15px;
            font-size: 12px;
            font-weight: bold;
            text-transform: uppercase;
        }
        .status-completed {
            background-color: #d4edda;
            color: #155724;
        }
        .status-refunded {
            background-color: #f8d7da;
            color: #721c24;
        }
    </style>
</head>
<body>
    <div class="receipt-container">
        <div class="header">
            <div class="logo">ARTbeat</div>
            <div class="receipt-title">Payment Receipt</div>
        </div>

        <div class="details">
            <div class="detail-row">
                <span class="detail-label">Receipt Number:</span>
                <span class="detail-value">${payment.id}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Customer:</span>
                <span class="detail-value">$userName</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Date:</span>
                <span class="detail-value">$formattedDate</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Time:</span>
                <span class="detail-value">$formattedTime</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Payment Method:</span>
                <span class="detail-value">${payment.paymentMethod.displayName}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Status:</span>
                <span class="detail-value">
                    <span class="status status-${payment.status.value.toLowerCase()}">
                        ${payment.status.displayName}
                    </span>
                </span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Description:</span>
                <span class="detail-value">${payment.adTitle}</span>
            </div>
        </div>

        <div class="amount">
            Total: \$${payment.amount.toStringAsFixed(2)} ${payment.currency}
        </div>

        ${payment.refundedAt != null ? '''
        <div class="details">
            <div class="detail-row">
                <span class="detail-label" style="color: #dc3545;">Refund Date:</span>
                <span class="detail-value">${intl.DateFormat('MMMM dd, yyyy').format(payment.refundedAt!)}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label" style="color: #dc3545;">Refund Amount:</span>
                <span class="detail-value">\$${payment.refundAmount?.toStringAsFixed(2) ?? '0.00'}</span>
            </div>
            ${payment.refundReason != null ? '''
            <div class="detail-row">
                <span class="detail-label" style="color: #dc3545;">Refund Reason:</span>
                <span class="detail-value">${payment.refundReason}</span>
            </div>
            ''' : ''}
        </div>
        ''' : ''}

        <div class="footer">
            <p>Thank you for using ARTbeat!</p>
            <p>This receipt was generated on ${intl.DateFormat('MMMM dd, yyyy \'at\' HH:mm').format(DateTime.now())}</p>
            <p>For support, please contact support@artbeat.com</p>
        </div>
    </div>
</body>
</html>
''';
  }
}

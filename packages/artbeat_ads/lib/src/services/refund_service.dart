import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/refund_request_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Service for managing refund requests and processing workflows
///
/// Provides functionality for:
/// - Creating and managing refund requests
/// - Admin approval and rejection workflows
/// - Automated refund processing
/// - Integration with payment systems
/// - Dispute resolution tracking
class RefundService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'refund_requests';
  static const String _paymentHistoryCollection = 'payment_history';

  /// Submit a new refund request
  Future<String> submitRefundRequest({
    required String paymentId,
    required String userId,
    required String adId,
    required String adTitle,
    required double originalAmount,
    required double requestedAmount,
    required RefundReason reason,
    required String description,
    List<String>? attachmentUrls,
    RefundPriority priority = RefundPriority.normal,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate refund request
      if (requestedAmount <= 0 || requestedAmount > originalAmount) {
        throw ArgumentError('Invalid refund amount');
      }

      // Check if there's already a pending refund for this payment
      final existingRefunds = await _firestore
          .collection(_collectionName)
          .where('paymentId', isEqualTo: paymentId)
          .where(
            'status',
            whereIn: [
              RefundStatus.pending.value,
              RefundStatus.underReview.value,
              RefundStatus.approved.value,
              RefundStatus.processing.value,
            ],
          )
          .get();

      if (existingRefunds.docs.isNotEmpty) {
        throw Exception('A refund request already exists for this payment');
      }

      final refundRequest = RefundRequestModel(
        id: '', // Will be set by Firestore
        paymentId: paymentId,
        userId: userId,
        adId: adId,
        adTitle: adTitle,
        originalAmount: originalAmount,
        requestedAmount: requestedAmount,
        reason: reason,
        description: description,
        requestedAt: DateTime.now(),
        attachmentUrls: attachmentUrls ?? [],
        priority: priority,
        metadata: metadata ?? {},
      );

      final docRef = await _firestore
          .collection(_collectionName)
          .add(refundRequest.toFirestore());

      // Auto-approve certain types of refunds
      if (_shouldAutoApprove(refundRequest)) {
        await _autoApproveRefund(docRef.id, refundRequest);
      }

      notifyListeners();
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error submitting refund request: $e');
      rethrow;
    }
  }

  /// Get refund requests for a user
  Stream<List<RefundRequestModel>> getUserRefundRequests({
    required String userId,
    RefundStatus? statusFilter,
    int limit = 50,
  }) {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('requestedAt', descending: true);

      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.value);
      }

      query = query.limit(limit);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => RefundRequestModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      AppLogger.error('Error getting user refund requests: $e');
      return Stream.value([]);
    }
  }

  /// Get all refund requests (admin view)
  Stream<List<RefundRequestModel>> getAllRefundRequests({
    RefundStatus? statusFilter,
    RefundPriority? priorityFilter,
    int limit = 100,
  }) {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .orderBy('requestedAt', descending: true);

      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.value);
      }

      if (priorityFilter != null) {
        query = query.where('priority', isEqualTo: priorityFilter.value);
      }

      query = query.limit(limit);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => RefundRequestModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      AppLogger.error('Error getting all refund requests: $e');
      return Stream.value([]);
    }
  }

  /// Get refund request by ID
  Future<RefundRequestModel?> getRefundRequestById(String refundId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(refundId)
          .get();

      if (doc.exists) {
        return RefundRequestModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting refund request by ID: $e');
      return null;
    }
  }

  /// Approve refund request (admin action)
  Future<void> approveRefundRequest({
    required String refundId,
    required String adminId,
    required double approvedAmount,
    String? adminNotes,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(refundId).update({
        'status': RefundStatus.approved.value,
        'adminId': adminId,
        'approvedAmount': approvedAmount,
        'adminNotes': adminNotes,
        'processedAt': Timestamp.now(),
      });

      // Start processing the refund
      await _processApprovedRefund(refundId);

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error approving refund request: $e');
      rethrow;
    }
  }

  /// Reject refund request (admin action)
  Future<void> rejectRefundRequest({
    required String refundId,
    required String adminId,
    required String adminNotes,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(refundId).update({
        'status': RefundStatus.rejected.value,
        'adminId': adminId,
        'adminNotes': adminNotes,
        'processedAt': Timestamp.now(),
      });

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error rejecting refund request: $e');
      rethrow;
    }
  }

  /// Update refund status
  Future<void> updateRefundStatus({
    required String refundId,
    required RefundStatus status,
    String? stripeRefundId,
    String? adminNotes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.value,
        'updatedAt': Timestamp.now(),
      };

      if (stripeRefundId != null) {
        updateData['stripeRefundId'] = stripeRefundId;
      }

      if (adminNotes != null) {
        updateData['adminNotes'] = adminNotes;
      }

      await _firestore
          .collection(_collectionName)
          .doc(refundId)
          .update(updateData);

      // If refund is completed, update the payment history
      if (status == RefundStatus.completed) {
        await _updatePaymentHistoryWithRefund(refundId);
      }

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error updating refund status: $e');
      rethrow;
    }
  }

  /// Get refund statistics
  Future<Map<String, dynamic>> getRefundStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(_collectionName);

      if (startDate != null) {
        query = query.where('requestedAt', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('requestedAt', isLessThanOrEqualTo: endDate);
      }

      final querySnapshot = await query.get();

      int totalRequests = 0;
      int pendingRequests = 0;
      int approvedRequests = 0;
      int rejectedRequests = 0;
      int completedRequests = 0;
      double totalRequestedAmount = 0.0;
      double totalApprovedAmount = 0.0;
      double totalCompletedAmount = 0.0;
      int highPriorityRequests = 0;
      int overdueRequests = 0;

      for (var doc in querySnapshot.docs) {
        final refund = RefundRequestModel.fromFirestore(doc);
        totalRequests++;
        totalRequestedAmount += refund.requestedAmount;

        if (refund.isHighPriority) {
          highPriorityRequests++;
        }

        if (refund.isOverdue && refund.isPending) {
          overdueRequests++;
        }

        switch (refund.status) {
          case RefundStatus.pending:
          case RefundStatus.underReview:
            pendingRequests++;
            break;
          case RefundStatus.approved:
          case RefundStatus.processing:
            approvedRequests++;
            if (refund.approvedAmount != null) {
              totalApprovedAmount += refund.approvedAmount!;
            }
            break;
          case RefundStatus.rejected:
          case RefundStatus.failed:
            rejectedRequests++;
            break;
          case RefundStatus.completed:
            completedRequests++;
            if (refund.approvedAmount != null) {
              totalCompletedAmount += refund.approvedAmount!;
            }
            break;
        }
      }

      return {
        'totalRequests': totalRequests,
        'pendingRequests': pendingRequests,
        'approvedRequests': approvedRequests,
        'rejectedRequests': rejectedRequests,
        'completedRequests': completedRequests,
        'totalRequestedAmount': totalRequestedAmount,
        'totalApprovedAmount': totalApprovedAmount,
        'totalCompletedAmount': totalCompletedAmount,
        'highPriorityRequests': highPriorityRequests,
        'overdueRequests': overdueRequests,
        'approvalRate': totalRequests > 0
            ? (approvedRequests / totalRequests) * 100
            : 0.0,
        'completionRate': approvedRequests > 0
            ? (completedRequests / approvedRequests) * 100
            : 0.0,
        'averageRefundAmount': completedRequests > 0
            ? totalCompletedAmount / completedRequests
            : 0.0,
      };
    } catch (e) {
      AppLogger.error('Error getting refund statistics: $e');
      return {};
    }
  }

  /// Get monthly refund summary
  Future<List<Map<String, dynamic>>> getMonthlyRefundSummary({
    required int monthsBack,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = DateTime(endDate.year, endDate.month - monthsBack, 1);

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('requestedAt', isGreaterThanOrEqualTo: startDate)
          .where('requestedAt', isLessThanOrEqualTo: endDate)
          .orderBy('requestedAt')
          .get();

      final monthlyData = <String, Map<String, dynamic>>{};

      // Initialize months
      for (int i = 0; i < monthsBack; i++) {
        final monthDate = DateTime(endDate.year, endDate.month - i, 1);
        final monthKey =
            '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}';
        monthlyData[monthKey] = {
          'month': monthKey,
          'totalRequests': 0,
          'approvedRequests': 0,
          'rejectedRequests': 0,
          'totalRefundedAmount': 0.0,
          'averageProcessingTime': 0.0,
        };
      }

      for (var doc in querySnapshot.docs) {
        final refund = RefundRequestModel.fromFirestore(doc);
        final monthKey =
            '${refund.requestedAt.year}-${refund.requestedAt.month.toString().padLeft(2, '0')}';

        if (monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey]!['totalRequests'] =
              (monthlyData[monthKey]!['totalRequests'] as int) + 1;

          if (refund.isApproved || refund.isCompleted) {
            monthlyData[monthKey]!['approvedRequests'] =
                (monthlyData[monthKey]!['approvedRequests'] as int) + 1;

            if (refund.approvedAmount != null) {
              monthlyData[monthKey]!['totalRefundedAmount'] =
                  (monthlyData[monthKey]!['totalRefundedAmount'] as double) +
                  refund.approvedAmount!;
            }
          }

          if (refund.isRejected) {
            monthlyData[monthKey]!['rejectedRequests'] =
                (monthlyData[monthKey]!['rejectedRequests'] as int) + 1;
          }
        }
      }

      return monthlyData.values.toList()..sort(
        (a, b) => (a['month'] as String).compareTo(b['month'] as String),
      );
    } catch (e) {
      AppLogger.error('Error getting monthly refund summary: $e');
      return [];
    }
  }

  /// Search refund requests
  Future<List<RefundRequestModel>> searchRefundRequests({
    required String searchTerm,
    String? userId,
    int limit = 20,
  }) async {
    try {
      Query baseQuery = _firestore.collection(_collectionName);

      if (userId != null) {
        baseQuery = baseQuery.where('userId', isEqualTo: userId);
      }

      // Search by ad title
      final titleQuery = await baseQuery
          .where('adTitle', isGreaterThanOrEqualTo: searchTerm)
          .where('adTitle', isLessThan: '${searchTerm}z')
          .limit(limit)
          .get();

      // Search by payment ID
      final paymentQuery = await baseQuery
          .where('paymentId', isEqualTo: searchTerm)
          .limit(limit)
          .get();

      final results = <RefundRequestModel>[];
      final seenIds = <String>{};

      // Add results from title search
      for (var doc in titleQuery.docs) {
        if (!seenIds.contains(doc.id)) {
          results.add(RefundRequestModel.fromFirestore(doc));
          seenIds.add(doc.id);
        }
      }

      // Add results from payment ID search
      for (var doc in paymentQuery.docs) {
        if (!seenIds.contains(doc.id)) {
          results.add(RefundRequestModel.fromFirestore(doc));
          seenIds.add(doc.id);
        }
      }

      // Sort by requested date (newest first)
      results.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

      return results.take(limit).toList();
    } catch (e) {
      AppLogger.error('Error searching refund requests: $e');
      return [];
    }
  }

  /// Process Stripe refund using PaymentService
  Future<String?> processStripeRefund({
    required String paymentIntentId,
    required double amount,
    String? reason,
  }) async {
    try {
      // Use PaymentService to process actual Stripe refund
      await PaymentService.refundPayment(
        paymentId: paymentIntentId,
        amount: amount,
        reason: reason ?? 'Refund requested by user',
      );

      // Return the payment intent ID as confirmation
      // The actual refund ID is handled by Stripe and stored in Firestore
      AppLogger.info(
        'Stripe refund processed successfully for $paymentIntentId',
      );
      return paymentIntentId;
    } catch (e) {
      AppLogger.error('Error processing Stripe refund: $e');
      return null;
    }
  }

  // Private helper methods

  bool _shouldAutoApprove(RefundRequestModel refund) {
    // Auto-approve small amounts, technical issues, or service not provided
    return refund.requestedAmount <= 5.0 ||
        refund.reason == RefundReason.technicalIssue ||
        refund.reason == RefundReason.serviceNotProvided;
  }

  Future<void> _autoApproveRefund(
    String refundId,
    RefundRequestModel refund,
  ) async {
    await approveRefundRequest(
      refundId: refundId,
      adminId: 'system_auto',
      approvedAmount: refund.requestedAmount,
      adminNotes: 'Auto-approved based on system criteria',
    );
  }

  Future<void> _processApprovedRefund(String refundId) async {
    try {
      final refund = await getRefundRequestById(refundId);
      if (refund == null) return;

      // Update status to processing
      await updateRefundStatus(
        refundId: refundId,
        status: RefundStatus.processing,
      );

      // Get original payment to find Stripe payment intent
      final paymentDoc = await _firestore
          .collection(_paymentHistoryCollection)
          .doc(refund.paymentId)
          .get();

      if (paymentDoc.exists) {
        final paymentData = paymentDoc.data() as Map<String, dynamic>;
        final stripePaymentIntentId =
            paymentData['stripePaymentIntentId'] as String?;

        if (stripePaymentIntentId != null) {
          // Process Stripe refund
          final stripeRefundId = await processStripeRefund(
            paymentIntentId: stripePaymentIntentId,
            amount: refund.approvedAmount ?? refund.requestedAmount,
            reason: refund.reason.displayName,
          );

          if (stripeRefundId != null) {
            // Mark as completed
            await updateRefundStatus(
              refundId: refundId,
              status: RefundStatus.completed,
              stripeRefundId: stripeRefundId,
            );
          } else {
            // Mark as failed
            await updateRefundStatus(
              refundId: refundId,
              status: RefundStatus.failed,
              adminNotes: 'Failed to process refund with payment processor',
            );
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error processing approved refund: $e');
      await updateRefundStatus(
        refundId: refundId,
        status: RefundStatus.failed,
        adminNotes: 'Error during refund processing: $e',
      );
    }
  }

  Future<void> _updatePaymentHistoryWithRefund(String refundId) async {
    try {
      final refund = await getRefundRequestById(refundId);
      if (refund == null || refund.approvedAmount == null) return;

      await _firestore
          .collection(_paymentHistoryCollection)
          .doc(refund.paymentId)
          .update({
            'status': refund.isFullRefund ? 'refunded' : 'partially_refunded',
            'refundedAt': Timestamp.now(),
            'refundAmount': refund.approvedAmount,
            'refundReason': refund.reason.displayName,
          });
    } catch (e) {
      AppLogger.error('Error updating payment history with refund: $e');
    }
  }
}

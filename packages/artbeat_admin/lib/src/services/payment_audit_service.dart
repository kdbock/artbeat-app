import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Audit service for tracking all admin payment actions
/// Critical for compliance, security, and accountability
class PaymentAuditService extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  PaymentAuditService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Log admin payment actions
  Future<void> logPaymentAction({
    required String adminId,
    required String adminEmail,
    required String action,
    required String transactionId,
    required Map<String, dynamic> details,
    String? userId,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final auditEntry = {
        'adminId': adminId,
        'adminEmail': adminEmail,
        'action': action,
        'transactionId': transactionId,
        'userId': userId,
        'details': details,
        'ipAddress': ipAddress,
        'userAgent': userAgent,
        'timestamp': FieldValue.serverTimestamp(),
        'sessionId': _generateSessionId(),
      };

      await _firestore.collection('payment_audit_log').add(auditEntry);

      // Also log to general admin audit log
      await _firestore.collection('admin_audit_log').add({
        ...auditEntry,
        'module': 'payments',
        'severity': _getActionSeverity(action),
      });

      debugPrint(
          'Payment audit logged: $action for transaction $transactionId');
    } catch (e) {
      debugPrint('Failed to log payment audit: $e');
      // Don't throw - audit logging failures shouldn't break the app
    }
  }

  /// Log refund actions specifically
  Future<void> logRefundAction({
    required String adminId,
    required String adminEmail,
    required String transactionId,
    required double refundAmount,
    required String reason,
    String? userId,
    String? notes,
  }) async {
    await logPaymentAction(
      adminId: adminId,
      adminEmail: adminEmail,
      action: 'REFUND_PROCESSED',
      transactionId: transactionId,
      userId: userId,
      details: {
        'refundAmount': refundAmount,
        'reason': reason,
        'notes': notes,
        'refundType': 'full_refund', // Could be partial in future
      },
    );
  }

  /// Log data export actions
  Future<void> logDataExport({
    required String adminId,
    required String adminEmail,
    required String exportType,
    required int recordCount,
    required Map<String, dynamic> filters,
    String? fileName,
  }) async {
    await logPaymentAction(
      adminId: adminId,
      adminEmail: adminEmail,
      action: 'DATA_EXPORT',
      transactionId: 'EXPORT_${DateTime.now().millisecondsSinceEpoch}',
      details: {
        'exportType': exportType,
        'recordCount': recordCount,
        'filters': filters,
        'fileName': fileName,
        'exportFormat': 'csv', // Could support more formats
      },
    );
  }

  /// Log sensitive data access
  Future<void> logSensitiveDataAccess({
    required String adminId,
    required String adminEmail,
    required String dataType,
    required String recordId,
    required String accessReason,
  }) async {
    await logPaymentAction(
      adminId: adminId,
      adminEmail: adminEmail,
      action: 'SENSITIVE_DATA_ACCESS',
      transactionId: recordId,
      details: {
        'dataType': dataType,
        'accessReason': accessReason,
        'accessType': 'view', // Could be 'edit', 'delete'
      },
    );
  }

  /// Get audit trail for a specific transaction
  Future<List<Map<String, dynamic>>> getTransactionAuditTrail(
      String transactionId) async {
    try {
      final query = await _firestore
          .collection('payment_audit_log')
          .where('transactionId', isEqualTo: transactionId)
          .orderBy('timestamp', descending: true)
          .get();

      return query.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      debugPrint('Failed to get transaction audit trail: $e');
      return [];
    }
  }

  /// Get admin activity summary
  Future<Map<String, dynamic>> getAdminActivitySummary(String adminId,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      var query = _firestore
          .collection('payment_audit_log')
          .where('adminId', isEqualTo: adminId);

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();

      final actions = <String, int>{};
      for (final doc in snapshot.docs) {
        final action = doc.data()['action'] as String? ?? 'UNKNOWN';
        actions[action] = (actions[action] ?? 0) + 1;
      }

      return {
        'totalActions': snapshot.docs.length,
        'actionsByType': actions,
        'lastActivity': snapshot.docs.isNotEmpty
            ? (snapshot.docs.first.data()['timestamp'] as Timestamp?)?.toDate()
            : null,
      };
    } catch (e) {
      debugPrint('Failed to get admin activity summary: $e');
      return <String, dynamic>{
        'totalActions': 0,
        'actionsByType': <String, int>{},
        'lastActivity': null
      };
    }
  }

  /// Get recent audit entries for monitoring
  Future<List<Map<String, dynamic>>> getRecentAuditEntries(
      {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('payment_audit_log')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      debugPrint('Failed to get recent audit entries: $e');
      return [];
    }
  }

  /// Check for suspicious activity patterns
  Future<List<Map<String, dynamic>>> detectSuspiciousActivity(
      {Duration? timeWindow}) async {
    try {
      final window = timeWindow ?? const Duration(hours: 24);
      final cutoff = DateTime.now().subtract(window);

      final query = await _firestore
          .collection('payment_audit_log')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
          .where('action', whereIn: [
        'REFUND_PROCESSED',
        'DATA_EXPORT',
        'SENSITIVE_DATA_ACCESS'
      ]).get();

      // Group by admin and count suspicious actions
      final suspiciousActivity = <String, Map<String, dynamic>>{};

      for (final doc in query.docs) {
        final data = doc.data();
        final adminId = data['adminId'] as String? ?? 'unknown';

        if (!suspiciousActivity.containsKey(adminId)) {
          suspiciousActivity[adminId] = {
            'adminId': adminId,
            'adminEmail': data['adminEmail'] ?? 'unknown',
            'actions': <String, int>{},
            'lastAction': data['timestamp'],
            'actionCount': 0,
          };
        }

        final adminData = suspiciousActivity[adminId]!;
        final action = data['action'] as String? ?? 'UNKNOWN';
        adminData['actions'][action] = (adminData['actions'][action] ?? 0) + 1;
        adminData['actionCount'] = (adminData['actionCount'] as int) + 1;

        // Flag as suspicious if too many actions in time window
        if ((adminData['actionCount'] as int) > 10) {
          adminData['suspicious'] = true;
        }
      }

      return suspiciousActivity.values
          .where((activity) => activity['suspicious'] == true)
          .toList();
    } catch (e) {
      debugPrint('Failed to detect suspicious activity: $e');
      return [];
    }
  }

  String _generateSessionId() {
    return 'SESSION_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  String _getActionSeverity(String action) {
    switch (action) {
      case 'REFUND_PROCESSED':
        return 'medium';
      case 'DATA_EXPORT':
        return 'high';
      case 'SENSITIVE_DATA_ACCESS':
        return 'high';
      case 'BULK_OPERATION':
        return 'medium';
      default:
        return 'low';
    }
  }

  /// Clean up old audit entries (compliance requirement)
  Future<void> cleanupOldEntries({Duration? retentionPeriod}) async {
    try {
      final period = retentionPeriod ??
          const Duration(days: 2555); // 7 years for financial records
      final cutoff = DateTime.now().subtract(period);

      final query = await _firestore
          .collection('payment_audit_log')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoff))
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Cleaned up ${query.docs.length} old audit entries');
    } catch (e) {
      debugPrint('Failed to cleanup old audit entries: $e');
    }
  }
}

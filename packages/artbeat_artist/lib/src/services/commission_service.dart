import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/commission_model.dart';

class CommissionService {
  final FirebaseFirestore _firestore;

  CommissionService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get commissions for a specific user (either as artist or gallery)
  Future<List<CommissionModel>> getCommissionsByUser(String userId) async {
    try {
      final artistCommissions = await _firestore
          .collection('commissions')
          .where('artistUserId', isEqualTo: userId)
          .get();

      final galleryCommissions = await _firestore
          .collection('commissions')
          .where('galleryUserId', isEqualTo: userId)
          .get();

      final commissions = [
        ...artistCommissions.docs
            .map((doc) => CommissionModel.fromFirestore(doc)),
        ...galleryCommissions.docs
            .map((doc) => CommissionModel.fromFirestore(doc)),
      ];

      // Sort by creation date descending
      commissions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return commissions;
    } catch (e) {
      debugPrint('Error getting commissions: $e');
      rethrow;
    }
  }

  /// Create a new commission agreement
  Future<void> createCommission(CommissionModel commission) async {
    try {
      await _firestore
          .collection('commissions')
          .doc(commission.id)
          .set(commission.toFirestore());
    } catch (e) {
      debugPrint('Error creating commission: $e');
      rethrow;
    }
  }

  /// Update commission status and details
  Future<void> updateCommission(
    String commissionId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore
          .collection('commissions')
          .doc(commissionId)
          .update(updates);
    } catch (e) {
      debugPrint('Error updating commission: $e');
      rethrow;
    }
  }

  /// Add a transaction to a commission
  Future<void> addTransaction(
    String commissionId,
    CommissionTransaction transaction,
  ) async {
    try {
      await _firestore.collection('commissions').doc(commissionId).update({
        'transactions': FieldValue.arrayUnion([transaction.toMap()]),
      });
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      rethrow;
    }
  }

  /// Update commission status
  Future<void> updateStatus(
    String commissionId,
    CommissionStatus newStatus,
  ) async {
    try {
      final updates = {
        'status': _statusToString(newStatus),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == CommissionStatus.completed) {
        updates['completedAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == CommissionStatus.paid) {
        updates['paidAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('commissions')
          .doc(commissionId)
          .update(updates);
    } catch (e) {
      debugPrint('Error updating commission status: $e');
      rethrow;
    }
  }

  String _statusToString(CommissionStatus status) {
    return switch (status) {
      CommissionStatus.pending => 'pending',
      CommissionStatus.active => 'active',
      CommissionStatus.completed => 'completed',
      CommissionStatus.paid => 'paid',
      CommissionStatus.cancelled => 'cancelled',
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/commission_dispute_model.dart';

class CommissionDisputeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new dispute
  Future<String> createDispute({
    required String commissionId,
    required String otherPartyId,
    required String otherPartyName,
    required DisputeReason reason,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User must be authenticated');

      final disputeId = _firestore.collection('commission_disputes').doc().id;

      final dispute = CommissionDispute(
        id: disputeId,
        commissionId: commissionId,
        initiatedById: user.uid,
        initiatedByName: user.displayName ?? 'Unknown',
        otherPartyId: otherPartyId,
        otherPartyName: otherPartyName,
        reason: reason,
        description: description,
        status: DisputeStatus.open,
        createdAt: DateTime.now(),
        messages: [],
        evidence: [],
        priority: 3,
        dueDate: DateTime.now().add(const Duration(days: 7)),
        metadata: metadata ?? {},
      );

      await _firestore
          .collection('commission_disputes')
          .doc(disputeId)
          .set(dispute.toFirestore());

      // Add initial message
      await addMessage(disputeId, 'Dispute initiated: $description');

      return disputeId;
    } catch (e) {
      throw Exception('Failed to create dispute: $e');
    }
  }

  /// Get disputes for a user
  Future<List<CommissionDispute>> getDisputesForUser(
    String userId, {
    DisputeStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection('commission_disputes')
          .where('initiatedById', isEqualTo: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final result = await query.orderBy('createdAt', descending: true).get();

      return result.docs
          .map((doc) => CommissionDispute.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get disputes: $e');
    }
  }

  /// Add message to dispute
  Future<void> addMessage(String disputeId, String message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User must be authenticated');

      final messageId = _firestore
          .collection('commission_disputes')
          .doc(disputeId)
          .collection('messages')
          .doc()
          .id;

      final disputeMessage = DisputeMessage(
        id: messageId,
        senderId: user.uid,
        senderName: user.displayName ?? 'Unknown',
        message: message,
        timestamp: DateTime.now(),
        attachments: [],
      );

      // Add to messages array
      await _firestore.collection('commission_disputes').doc(disputeId).update({
        'messages': FieldValue.arrayUnion([disputeMessage.toMap()]),
      });
    } catch (e) {
      throw Exception('Failed to add message: $e');
    }
  }

  /// Upload evidence
  Future<void> uploadEvidence({
    required String disputeId,
    required String title,
    required String description,
    required String fileUrl,
    required String fileType,
    required int fileSizeBytes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User must be authenticated');

      final evidence = DisputeEvidence(
        id: _firestore.collection('commission_disputes').doc().id,
        uploadedById: user.uid,
        uploadedByName: user.displayName ?? 'Unknown',
        title: title,
        description: description,
        fileUrl: fileUrl,
        fileType: fileType,
        fileSizeBytes: fileSizeBytes,
        uploadedAt: DateTime.now(),
      );

      await _firestore.collection('commission_disputes').doc(disputeId).update({
        'evidence': FieldValue.arrayUnion([evidence.toMap()]),
      });
    } catch (e) {
      throw Exception('Failed to upload evidence: $e');
    }
  }

  /// Update dispute status
  Future<void> updateDisputeStatus(
    String disputeId,
    DisputeStatus status,
  ) async {
    try {
      await _firestore.collection('commission_disputes').doc(disputeId).update({
        'status': status.name,
      });
    } catch (e) {
      throw Exception('Failed to update dispute status: $e');
    }
  }

  /// Resolve dispute
  Future<void> resolveDispute({
    required String disputeId,
    required String resolution,
    double? suggestedRefund,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User must be authenticated');

      await _firestore.collection('commission_disputes').doc(disputeId).update({
        'status': DisputeStatus.resolved.name,
        'resolvedAt': Timestamp.now(),
        'resolutionNotes': resolution,
        'resolvedById': user.uid,
        'suggestedRefund': suggestedRefund,
      });
    } catch (e) {
      throw Exception('Failed to resolve dispute: $e');
    }
  }

  /// Get open disputes (for admin)
  Future<List<CommissionDispute>> getOpenDisputes() async {
    try {
      final query = await _firestore
          .collection('commission_disputes')
          .where('status', isEqualTo: DisputeStatus.open.name)
          .orderBy('priority', descending: true)
          .orderBy('createdAt')
          .get();

      return query.docs
          .map((doc) => CommissionDispute.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get open disputes: $e');
    }
  }

  /// Assign mediator
  Future<void> assignMediator(String disputeId, String mediatorId) async {
    try {
      await _firestore.collection('commission_disputes').doc(disputeId).update({
        'mediatorId': mediatorId,
        'status': DisputeStatus.inMediation.name,
      });
    } catch (e) {
      throw Exception('Failed to assign mediator: $e');
    }
  }
}

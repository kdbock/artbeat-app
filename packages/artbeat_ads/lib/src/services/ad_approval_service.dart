import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ad_approval_model.dart';
import '../models/ad_status.dart';

/// Service for handling ad approval workflow
class AdApprovalService {
  final _approvalsRef = FirebaseFirestore.instance.collection('ad_approvals');

  Future<String> requestApproval(AdApprovalModel approval) async {
    final doc = await _approvalsRef.add(approval.toMap());
    return doc.id;
  }

  Future<void> updateApprovalStatus(
    String approvalId,
    AdStatus status, {
    String? reason,
  }) async {
    await _approvalsRef.doc(approvalId).update({
      'status': status.index,
      'reason': reason,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AdApprovalModel?> getApproval(String approvalId) async {
    final doc = await _approvalsRef.doc(approvalId).get();
    if (!doc.exists) return null;
    return AdApprovalModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<AdApprovalModel>> getApprovalsByStatus(AdStatus status) {
    return _approvalsRef
        .where('status', isEqualTo: status.index)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdApprovalModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }
}

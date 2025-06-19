import 'package:cloud_firestore/cloud_firestore.dart';
import 'ad_status.dart';

/// Model for ad approval workflow
class AdApprovalModel {
  final String id;
  final String adId;
  final String reviewerId;
  final AdStatus status;
  final String? reason;
  final DateTime requestedAt;
  final DateTime? reviewedAt;

  AdApprovalModel({
    required this.id,
    required this.adId,
    required this.reviewerId,
    required this.status,
    this.reason,
    required this.requestedAt,
    this.reviewedAt,
  });

  factory AdApprovalModel.fromMap(Map<String, dynamic> map, String id) {
    final rawStatus = map['status'];
    final intStatus = rawStatus is int
        ? rawStatus
        : int.tryParse(rawStatus.toString()) ?? 0;
    return AdApprovalModel(
      id: id,
      adId: map['adId']?.toString() ?? '',
      reviewerId: map['reviewerId']?.toString() ?? '',
      status: AdStatus.values[intStatus],
      reason: map['reason']?.toString(),
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'adId': adId,
    'reviewerId': reviewerId,
    'status': status.index,
    'reason': reason,
    'requestedAt': Timestamp.fromDate(requestedAt),
    'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
  };
}

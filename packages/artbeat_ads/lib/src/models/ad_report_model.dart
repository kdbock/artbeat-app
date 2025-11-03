import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for reporting advertisements with reasons and tracking
class AdReportModel {
  final String id;
  final String adId;
  final String reportedBy;
  final String reason;
  final String? additionalDetails;
  final DateTime createdAt;
  final AdReportStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? adminNotes;

  AdReportModel({
    required this.id,
    required this.adId,
    required this.reportedBy,
    required this.reason,
    this.additionalDetails,
    required this.createdAt,
    this.status = AdReportStatus.pending,
    this.reviewedBy,
    this.reviewedAt,
    this.adminNotes,
  });

  factory AdReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdReportModel(
      id: doc.id,
      adId: (data['adId'] ?? '') as String,
      reportedBy: (data['reportedBy'] ?? '') as String,
      reason: (data['reason'] ?? '') as String,
      additionalDetails: data['additionalDetails'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: AdReportStatus.fromString(
        (data['status'] ?? 'pending') as String,
      ),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      adminNotes: data['adminNotes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adId': adId,
      'reportedBy': reportedBy,
      'reason': reason,
      if (additionalDetails != null) 'additionalDetails': additionalDetails,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.value,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (adminNotes != null) 'adminNotes': adminNotes,
    };
  }

  AdReportModel copyWith({
    String? id,
    String? adId,
    String? reportedBy,
    String? reason,
    String? additionalDetails,
    DateTime? createdAt,
    AdReportStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? adminNotes,
  }) {
    return AdReportModel(
      id: id ?? this.id,
      adId: adId ?? this.adId,
      reportedBy: reportedBy ?? this.reportedBy,
      reason: reason ?? this.reason,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }
}

/// Status of ad reports
enum AdReportStatus {
  pending,
  reviewed,
  dismissed,
  actionTaken;

  String get value => name;

  String get displayName {
    switch (this) {
      case AdReportStatus.pending:
        return 'Pending Review';
      case AdReportStatus.reviewed:
        return 'Reviewed';
      case AdReportStatus.dismissed:
        return 'Dismissed';
      case AdReportStatus.actionTaken:
        return 'Action Taken';
    }
  }

  static AdReportStatus fromString(String value) {
    return AdReportStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AdReportStatus.pending,
    );
  }
}

/// Predefined report reasons for ads
class AdReportReasons {
  static const List<Map<String, String>> reasons = [
    {
      'value': 'inappropriate_content',
      'label': 'Inappropriate Content',
      'description': 'Contains inappropriate, offensive, or harmful content',
    },
    {
      'value': 'misleading',
      'label': 'Misleading or False',
      'description': 'Contains false information or misleading claims',
    },
    {
      'value': 'spam',
      'label': 'Spam',
      'description': 'Repetitive, irrelevant, or unsolicited advertising',
    },
    {
      'value': 'copyright',
      'label': 'Copyright Violation',
      'description': 'Uses copyrighted material without permission',
    },
    {
      'value': 'harassment',
      'label': 'Harassment',
      'description': 'Promotes harassment or bullying behavior',
    },
    {
      'value': 'hate_speech',
      'label': 'Hate Speech',
      'description': 'Contains discriminatory or hateful content',
    },
    {
      'value': 'scam',
      'label': 'Scam or Fraud',
      'description': 'Appears to be fraudulent or scamming users',
    },
    {
      'value': 'other',
      'label': 'Other',
      'description': 'Something else not covered by the options above',
    },
  ];

  static Map<String, String>? getReasonByValue(String value) {
    for (final reason in reasons) {
      if (reason['value'] == value) return reason;
    }
    return null;
  }
}

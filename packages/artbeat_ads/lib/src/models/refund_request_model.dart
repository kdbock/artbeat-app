import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a refund request for ad payments
///
/// Tracks refund requests, processing status, and administrative decisions
/// for complete dispute management and automated refund workflows.
class RefundRequestModel {
  final String id;
  final String paymentId;
  final String userId;
  final String adId;
  final String adTitle;
  final double originalAmount;
  final double requestedAmount;
  final RefundReason reason;
  final String description;
  final RefundStatus status;
  final DateTime requestedAt;
  final String? adminId;
  final String? adminNotes;
  final DateTime? processedAt;
  final double? approvedAmount;
  final String? stripeRefundId;
  final List<String> attachmentUrls;
  final RefundPriority priority;
  final Map<String, dynamic> metadata;

  RefundRequestModel({
    required this.id,
    required this.paymentId,
    required this.userId,
    required this.adId,
    required this.adTitle,
    required this.originalAmount,
    required this.requestedAmount,
    required this.reason,
    required this.description,
    this.status = RefundStatus.pending,
    required this.requestedAt,
    this.adminId,
    this.adminNotes,
    this.processedAt,
    this.approvedAmount,
    this.stripeRefundId,
    this.attachmentUrls = const [],
    this.priority = RefundPriority.normal,
    this.metadata = const {},
  });

  /// Create from Firestore document
  factory RefundRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RefundRequestModel(
      id: doc.id,
      paymentId: (data['paymentId'] as String?) ?? '',
      userId: (data['userId'] as String?) ?? '',
      adId: (data['adId'] as String?) ?? '',
      adTitle: (data['adTitle'] as String?) ?? '',
      originalAmount: ((data['originalAmount'] as num?) ?? 0).toDouble(),
      requestedAmount: ((data['requestedAmount'] as num?) ?? 0).toDouble(),
      reason: RefundReason.fromString((data['reason'] as String?) ?? 'other'),
      description: (data['description'] as String?) ?? '',
      status: RefundStatus.fromString((data['status'] as String?) ?? 'pending'),
      requestedAt:
          (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminId: data['adminId'] as String?,
      adminNotes: data['adminNotes'] as String?,
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      approvedAmount: (data['approvedAmount'] as num?)?.toDouble(),
      stripeRefundId: data['stripeRefundId'] as String?,
      attachmentUrls: List<String>.from(
        (data['attachmentUrls'] as List?) ?? [],
      ),
      priority: RefundPriority.fromString(
        (data['priority'] as String?) ?? 'normal',
      ),
      metadata: Map<String, dynamic>.from((data['metadata'] as Map?) ?? {}),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'paymentId': paymentId,
      'userId': userId,
      'adId': adId,
      'adTitle': adTitle,
      'originalAmount': originalAmount,
      'requestedAmount': requestedAmount,
      'reason': reason.value,
      'description': description,
      'status': status.value,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'adminId': adminId,
      'adminNotes': adminNotes,
      'processedAt': processedAt != null
          ? Timestamp.fromDate(processedAt!)
          : null,
      'approvedAmount': approvedAmount,
      'stripeRefundId': stripeRefundId,
      'attachmentUrls': attachmentUrls,
      'priority': priority.value,
      'metadata': metadata,
    };
  }

  /// Create copy with updated fields
  RefundRequestModel copyWith({
    String? id,
    String? paymentId,
    String? userId,
    String? adId,
    String? adTitle,
    double? originalAmount,
    double? requestedAmount,
    RefundReason? reason,
    String? description,
    RefundStatus? status,
    DateTime? requestedAt,
    String? adminId,
    String? adminNotes,
    DateTime? processedAt,
    double? approvedAmount,
    String? stripeRefundId,
    List<String>? attachmentUrls,
    RefundPriority? priority,
    Map<String, dynamic>? metadata,
  }) {
    return RefundRequestModel(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      userId: userId ?? this.userId,
      adId: adId ?? this.adId,
      adTitle: adTitle ?? this.adTitle,
      originalAmount: originalAmount ?? this.originalAmount,
      requestedAmount: requestedAmount ?? this.requestedAmount,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      adminId: adminId ?? this.adminId,
      adminNotes: adminNotes ?? this.adminNotes,
      processedAt: processedAt ?? this.processedAt,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      stripeRefundId: stripeRefundId ?? this.stripeRefundId,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      priority: priority ?? this.priority,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if refund is pending admin review
  bool get isPending => status == RefundStatus.pending;

  /// Check if refund was approved
  bool get isApproved => status == RefundStatus.approved;

  /// Check if refund was rejected
  bool get isRejected => status == RefundStatus.rejected;

  /// Check if refund is being processed
  bool get isProcessing => status == RefundStatus.processing;

  /// Check if refund is complete
  bool get isCompleted => status == RefundStatus.completed;

  /// Check if request is high priority
  bool get isHighPriority => priority == RefundPriority.high;

  /// Get formatted original amount
  String get formattedOriginalAmount =>
      '\$${originalAmount.toStringAsFixed(2)}';

  /// Get formatted requested amount
  String get formattedRequestedAmount =>
      '\$${requestedAmount.toStringAsFixed(2)}';

  /// Get formatted approved amount
  String? get formattedApprovedAmount {
    if (approvedAmount == null) return null;
    return '\$${approvedAmount!.toStringAsFixed(2)}';
  }

  /// Calculate refund percentage
  double get refundPercentage {
    if (originalAmount == 0) return 0;
    return (requestedAmount / originalAmount) * 100;
  }

  /// Check if this is a partial refund
  bool get isPartialRefund => requestedAmount < originalAmount;

  /// Check if this is a full refund
  bool get isFullRefund => requestedAmount >= originalAmount;

  /// Get days since request
  int get daysSinceRequest => DateTime.now().difference(requestedAt).inDays;

  /// Check if request is overdue (>7 days)
  bool get isOverdue => daysSinceRequest > 7;

  @override
  String toString() {
    return 'RefundRequestModel(id: $id, paymentId: $paymentId, amount: $requestedAmount, status: ${status.value})';
  }
}

/// Refund reason enum
enum RefundReason {
  adNotDisplayed,
  technicalIssue,
  unauthorizedCharge,
  serviceNotProvided,
  qualityIssue,
  changeOfMind,
  duplicate,
  fraudulent,
  other;

  String get value => name;

  static RefundReason fromString(String value) {
    return RefundReason.values.firstWhere(
      (reason) => reason.value == value,
      orElse: () => RefundReason.other,
    );
  }

  String get displayName {
    switch (this) {
      case RefundReason.adNotDisplayed:
        return 'Ad Not Displayed';
      case RefundReason.technicalIssue:
        return 'Technical Issue';
      case RefundReason.unauthorizedCharge:
        return 'Unauthorized Charge';
      case RefundReason.serviceNotProvided:
        return 'Service Not Provided';
      case RefundReason.qualityIssue:
        return 'Quality Issue';
      case RefundReason.changeOfMind:
        return 'Change of Mind';
      case RefundReason.duplicate:
        return 'Duplicate Charge';
      case RefundReason.fraudulent:
        return 'Fraudulent Transaction';
      case RefundReason.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case RefundReason.adNotDisplayed:
        return 'Ad was not displayed as expected';
      case RefundReason.technicalIssue:
        return 'Technical problems with the service';
      case RefundReason.unauthorizedCharge:
        return 'Charge was made without authorization';
      case RefundReason.serviceNotProvided:
        return 'Advertising service was not provided';
      case RefundReason.qualityIssue:
        return 'Quality of service did not meet expectations';
      case RefundReason.changeOfMind:
        return 'Customer changed their mind';
      case RefundReason.duplicate:
        return 'Duplicate charge for the same service';
      case RefundReason.fraudulent:
        return 'Fraudulent or suspicious transaction';
      case RefundReason.other:
        return 'Other reason not listed above';
    }
  }
}

/// Refund status enum
enum RefundStatus {
  pending,
  underReview,
  approved,
  rejected,
  processing,
  completed,
  failed;

  String get value => name;

  static RefundStatus fromString(String value) {
    return RefundStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RefundStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case RefundStatus.pending:
        return 'Pending Review';
      case RefundStatus.underReview:
        return 'Under Review';
      case RefundStatus.approved:
        return 'Approved';
      case RefundStatus.rejected:
        return 'Rejected';
      case RefundStatus.processing:
        return 'Processing';
      case RefundStatus.completed:
        return 'Completed';
      case RefundStatus.failed:
        return 'Failed';
    }
  }

  /// Get color for status display
  String get colorHex {
    switch (this) {
      case RefundStatus.pending:
      case RefundStatus.underReview:
        return '#FF9800'; // Orange
      case RefundStatus.approved:
      case RefundStatus.completed:
        return '#4CAF50'; // Green
      case RefundStatus.rejected:
      case RefundStatus.failed:
        return '#F44336'; // Red
      case RefundStatus.processing:
        return '#2196F3'; // Blue
    }
  }
}

/// Refund priority enum
enum RefundPriority {
  low,
  normal,
  high,
  urgent;

  String get value => name;

  static RefundPriority fromString(String value) {
    return RefundPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => RefundPriority.normal,
    );
  }

  String get displayName {
    switch (this) {
      case RefundPriority.low:
        return 'Low';
      case RefundPriority.normal:
        return 'Normal';
      case RefundPriority.high:
        return 'High';
      case RefundPriority.urgent:
        return 'Urgent';
    }
  }

  /// Get color for priority display
  String get colorHex {
    switch (this) {
      case RefundPriority.low:
        return '#4CAF50'; // Green
      case RefundPriority.normal:
        return '#2196F3'; // Blue
      case RefundPriority.high:
        return '#FF9800'; // Orange
      case RefundPriority.urgent:
        return '#F44336'; // Red
    }
  }
}

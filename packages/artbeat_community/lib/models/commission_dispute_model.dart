import 'package:cloud_firestore/cloud_firestore.dart';

/// Commission dispute resolution model
class CommissionDispute {
  final String id;
  final String commissionId;
  final String initiatedById;
  final String initiatedByName;
  final String otherPartyId;
  final String otherPartyName;
  final DisputeReason reason;
  final String description;
  final DisputeStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final String? resolvedById; // Admin who resolved
  final double? suggestedRefund; // Suggested refund amount
  final List<DisputeMessage> messages;
  final List<DisputeEvidence> evidence;
  final String? mediatorId;
  final int priority; // 1-5, 5 being highest
  final DateTime? dueDate; // When must be resolved by
  final Map<String, dynamic> metadata;

  CommissionDispute({
    required this.id,
    required this.commissionId,
    required this.initiatedById,
    required this.initiatedByName,
    required this.otherPartyId,
    required this.otherPartyName,
    required this.reason,
    required this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolutionNotes,
    this.resolvedById,
    this.suggestedRefund,
    required this.messages,
    required this.evidence,
    this.mediatorId,
    this.priority = 3,
    this.dueDate,
    required this.metadata,
  });

  // Get days since dispute created
  int get daysSinceCreated => DateTime.now().difference(createdAt).inDays;

  factory CommissionDispute.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CommissionDispute(
      id: doc.id,
      commissionId: data['commissionId'] as String? ?? '',
      initiatedById: data['initiatedById'] as String? ?? '',
      initiatedByName: data['initiatedByName'] as String? ?? '',
      otherPartyId: data['otherPartyId'] as String? ?? '',
      otherPartyName: data['otherPartyName'] as String? ?? '',
      reason: DisputeReason.values.firstWhere(
        (r) => r.name == (data['reason'] as String? ?? 'qualityIssue'),
        orElse: () => DisputeReason.qualityIssue,
      ),
      description: data['description'] as String? ?? '',
      status: DisputeStatus.values.firstWhere(
        (s) => s.name == (data['status'] as String? ?? 'open'),
        orElse: () => DisputeStatus.open,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolutionNotes: data['resolutionNotes'] as String?,
      resolvedById: data['resolvedById'] as String?,
      suggestedRefund: (data['suggestedRefund'] as num?)?.toDouble(),
      messages:
          (data['messages'] as List<dynamic>?)
              ?.map((m) => DisputeMessage.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      evidence:
          (data['evidence'] as List<dynamic>?)
              ?.map((e) => DisputeEvidence.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      mediatorId: data['mediatorId'] as String?,
      priority: data['priority'] as int? ?? 3,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'commissionId': commissionId,
      'initiatedById': initiatedById,
      'initiatedByName': initiatedByName,
      'otherPartyId': otherPartyId,
      'otherPartyName': otherPartyName,
      'reason': reason.name,
      'description': description,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolutionNotes': resolutionNotes,
      'resolvedById': resolvedById,
      'suggestedRefund': suggestedRefund,
      'messages': messages.map((m) => m.toMap()).toList(),
      'evidence': evidence.map((e) => e.toMap()).toList(),
      'mediatorId': mediatorId,
      'priority': priority,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'metadata': metadata,
    };
  }

  CommissionDispute copyWith({
    String? id,
    String? commissionId,
    String? initiatedById,
    String? initiatedByName,
    String? otherPartyId,
    String? otherPartyName,
    DisputeReason? reason,
    String? description,
    DisputeStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolutionNotes,
    String? resolvedById,
    double? suggestedRefund,
    List<DisputeMessage>? messages,
    List<DisputeEvidence>? evidence,
    String? mediatorId,
    int? priority,
    DateTime? dueDate,
    Map<String, dynamic>? metadata,
  }) {
    return CommissionDispute(
      id: id ?? this.id,
      commissionId: commissionId ?? this.commissionId,
      initiatedById: initiatedById ?? this.initiatedById,
      initiatedByName: initiatedByName ?? this.initiatedByName,
      otherPartyId: otherPartyId ?? this.otherPartyId,
      otherPartyName: otherPartyName ?? this.otherPartyName,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      resolvedById: resolvedById ?? this.resolvedById,
      suggestedRefund: suggestedRefund ?? this.suggestedRefund,
      messages: messages ?? this.messages,
      evidence: evidence ?? this.evidence,
      mediatorId: mediatorId ?? this.mediatorId,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum DisputeReason {
  qualityIssue('Quality Not as Expected'),
  nonDelivery('Work Not Delivered'),
  communicationFailure('Poor Communication'),
  latenessIssue('Delivery Too Late'),
  priceDispute('Disagreement on Price'),
  scopeChange('Scope Changed Unexpectedly'),
  other('Other');

  const DisputeReason(this.displayName);
  final String displayName;
}

enum DisputeStatus {
  open('Open'),
  inMediation('In Mediation'),
  escalated('Escalated'),
  resolved('Resolved'),
  closed('Closed');

  const DisputeStatus(this.displayName);
  final String displayName;
}

/// Message in dispute thread
class DisputeMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final List<String> attachments;

  DisputeMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.attachments,
  });

  factory DisputeMessage.fromMap(Map<String, dynamic> data) {
    return DisputeMessage(
      id: data['id'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      message: data['message'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attachments: List<String>.from(
        data['attachments'] as List<dynamic>? ?? [],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'attachments': attachments,
    };
  }
}

/// Evidence for dispute (images, files, etc.)
class DisputeEvidence {
  final String id;
  final String uploadedById;
  final String uploadedByName;
  final String title;
  final String description;
  final String fileUrl;
  final String fileType; // image, document, video
  final int fileSizeBytes;
  final DateTime uploadedAt;

  DisputeEvidence({
    required this.id,
    required this.uploadedById,
    required this.uploadedByName,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileType,
    required this.fileSizeBytes,
    required this.uploadedAt,
  });

  factory DisputeEvidence.fromMap(Map<String, dynamic> data) {
    return DisputeEvidence(
      id: data['id'] as String? ?? '',
      uploadedById: data['uploadedById'] as String? ?? '',
      uploadedByName: data['uploadedByName'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      fileUrl: data['fileUrl'] as String? ?? '',
      fileType: data['fileType'] as String? ?? 'document',
      fileSizeBytes: data['fileSizeBytes'] as int? ?? 0,
      uploadedAt:
          (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uploadedById': uploadedById,
      'uploadedByName': uploadedByName,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum CampaignStatus { active, paused, completed, cancelled }

class GiftCampaignModel {
  final String id;
  final String artistId;
  final String title;
  final String description;
  final double goalAmount;
  final double currentAmount;
  final Timestamp createdAt;
  final Timestamp? endDate;
  final CampaignStatus status;
  final String? imageUrl;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final int supporterCount;
  final Timestamp? lastUpdated;

  GiftCampaignModel({
    required this.id,
    required this.artistId,
    required this.title,
    required this.description,
    required this.goalAmount,
    this.currentAmount = 0.0,
    required this.createdAt,
    this.endDate,
    this.status = CampaignStatus.active,
    this.imageUrl,
    this.tags = const [],
    this.metadata = const {},
    this.supporterCount = 0,
    this.lastUpdated,
  });

  factory GiftCampaignModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GiftCampaignModel(
      id: doc.id,
      artistId: data['artistId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      goalAmount: (data['goalAmount'] as num? ?? 0).toDouble(),
      currentAmount: (data['currentAmount'] as num? ?? 0).toDouble(),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      endDate: data['endDate'] as Timestamp?,
      status: _parseCampaignStatus(data['status'] as String?),
      imageUrl: data['imageUrl'] as String?,
      tags: List<String>.from(data['tags'] as List? ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      supporterCount: data['supporterCount'] as int? ?? 0,
      lastUpdated: data['lastUpdated'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'artistId': artistId,
      'title': title,
      'description': description,
      'goalAmount': goalAmount,
      'currentAmount': currentAmount,
      'createdAt': createdAt,
      if (endDate != null) 'endDate': endDate,
      'status': status.name,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'tags': tags,
      'metadata': metadata,
      'supporterCount': supporterCount,
      'lastUpdated': lastUpdated ?? FieldValue.serverTimestamp(),
    };
  }

  static CampaignStatus _parseCampaignStatus(String? statusString) {
    switch (statusString) {
      case 'paused':
        return CampaignStatus.paused;
      case 'completed':
        return CampaignStatus.completed;
      case 'cancelled':
        return CampaignStatus.cancelled;
      default:
        return CampaignStatus.active;
    }
  }

  // Helper methods
  double get progressPercentage {
    if (goalAmount <= 0) return 0.0;
    return (currentAmount / goalAmount * 100).clamp(0.0, 100.0);
  }

  bool get isActive => status == CampaignStatus.active;
  bool get isCompleted =>
      status == CampaignStatus.completed || currentAmount >= goalAmount;
  bool get isPaused => status == CampaignStatus.paused;
  bool get isCancelled => status == CampaignStatus.cancelled;
  bool get hasEndDate => endDate != null;
  bool get isExpired =>
      hasEndDate && endDate!.toDate().isBefore(DateTime.now());

  double get remainingAmount =>
      (goalAmount - currentAmount).clamp(0.0, goalAmount);

  Duration? get timeRemaining {
    if (!hasEndDate) return null;
    final now = DateTime.now();
    final end = endDate!.toDate();
    if (end.isBefore(now)) return null;
    return end.difference(now);
  }

  GiftCampaignModel copyWith({
    String? id,
    String? artistId,
    String? title,
    String? description,
    double? goalAmount,
    double? currentAmount,
    Timestamp? createdAt,
    Timestamp? endDate,
    CampaignStatus? status,
    String? imageUrl,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    int? supporterCount,
    Timestamp? lastUpdated,
  }) {
    return GiftCampaignModel(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      title: title ?? this.title,
      description: description ?? this.description,
      goalAmount: goalAmount ?? this.goalAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      createdAt: createdAt ?? this.createdAt,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      supporterCount: supporterCount ?? this.supporterCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

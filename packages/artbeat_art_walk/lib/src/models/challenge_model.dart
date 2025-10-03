import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing different types of challenges
enum ChallengeType { daily, weekly, monthly, special }

/// Model class for user challenges
class ChallengeModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final ChallengeType type;
  final int targetCount;
  final int currentCount;
  final int rewardXP;
  final String rewardDescription;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? completedAt;

  const ChallengeModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.targetCount,
    required this.currentCount,
    required this.rewardXP,
    required this.rewardDescription,
    required this.isCompleted,
    required this.createdAt,
    required this.expiresAt,
    this.completedAt,
  });

  /// Create ChallengeModel from Firestore document
  factory ChallengeModel.fromMap(Map<String, dynamic> map) {
    return ChallengeModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: ChallengeType.values.firstWhere(
        (e) => e.toString() == 'ChallengeType.${map['type']}',
        orElse: () => ChallengeType.daily,
      ),
      targetCount: map['targetCount'] as int? ?? 0,
      currentCount: map['currentCount'] as int? ?? 0,
      rewardXP: map['rewardXP'] as int? ?? 0,
      rewardDescription: map['rewardDescription'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt:
          (map['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 1)),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'rewardXP': rewardXP,
      'rewardDescription': rewardDescription,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (targetCount == 0) return 0.0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }

  /// Check if challenge is expired
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Create a copy with updated fields
  ChallengeModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    ChallengeType? type,
    int? targetCount,
    int? currentCount,
    int? rewardXP,
    String? rewardDescription,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? completedAt,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      rewardXP: rewardXP ?? this.rewardXP,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

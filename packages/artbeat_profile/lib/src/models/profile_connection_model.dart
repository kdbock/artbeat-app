import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for profile connections (mutual friends, suggestions, etc.)
class ProfileConnectionModel {
  final String id;
  final String userId;
  final String connectedUserId;
  final String connectedUserName;
  final String? connectedUserAvatar;
  final String
  connectionType; // 'mutual_follower', 'suggestion', 'recent_interaction'
  final int mutualFollowersCount;
  final List<String> mutualFollowerIds;
  final double
  connectionScore; // Algorithm-based score for recommendation strength
  final Map<String, dynamic>?
  connectionReason; // Why this connection is suggested
  final DateTime createdAt;
  final DateTime? lastInteraction;
  final bool isBlocked;
  final bool isDismissed;

  ProfileConnectionModel({
    required this.id,
    required this.userId,
    required this.connectedUserId,
    required this.connectedUserName,
    this.connectedUserAvatar,
    required this.connectionType,
    this.mutualFollowersCount = 0,
    this.mutualFollowerIds = const [],
    this.connectionScore = 0.0,
    this.connectionReason,
    required this.createdAt,
    this.lastInteraction,
    this.isBlocked = false,
    this.isDismissed = false,
  });

  factory ProfileConnectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileConnectionModel(
      id: doc.id,
      userId: data['userId'] as String,
      connectedUserId: data['connectedUserId'] as String,
      connectedUserName: data['connectedUserName'] as String,
      connectedUserAvatar: data['connectedUserAvatar'] as String?,
      connectionType: data['connectionType'] as String,
      mutualFollowersCount:
          (data['mutualFollowersCount'] as num?)?.toInt() ?? 0,
      mutualFollowerIds: List<String>.from(
        (data['mutualFollowerIds'] as List<dynamic>?) ?? [],
      ),
      connectionScore: (data['connectionScore'] as num?)?.toDouble() ?? 0.0,
      connectionReason: data['connectionReason'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastInteraction: data['lastInteraction'] != null
          ? (data['lastInteraction'] as Timestamp).toDate()
          : null,
      isBlocked: (data['isBlocked'] as bool?) ?? false,
      isDismissed: (data['isDismissed'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'connectedUserId': connectedUserId,
      'connectedUserName': connectedUserName,
      'connectedUserAvatar': connectedUserAvatar,
      'connectionType': connectionType,
      'mutualFollowersCount': mutualFollowersCount,
      'mutualFollowerIds': mutualFollowerIds,
      'connectionScore': connectionScore,
      'connectionReason': connectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastInteraction': lastInteraction != null
          ? Timestamp.fromDate(lastInteraction!)
          : null,
      'isBlocked': isBlocked,
      'isDismissed': isDismissed,
    };
  }

  ProfileConnectionModel copyWith({
    String? connectedUserName,
    String? connectedUserAvatar,
    int? mutualFollowersCount,
    List<String>? mutualFollowerIds,
    double? connectionScore,
    Map<String, dynamic>? connectionReason,
    DateTime? lastInteraction,
    bool? isBlocked,
    bool? isDismissed,
  }) {
    return ProfileConnectionModel(
      id: id,
      userId: userId,
      connectedUserId: connectedUserId,
      connectedUserName: connectedUserName ?? this.connectedUserName,
      connectedUserAvatar: connectedUserAvatar ?? this.connectedUserAvatar,
      connectionType: connectionType,
      mutualFollowersCount: mutualFollowersCount ?? this.mutualFollowersCount,
      mutualFollowerIds: mutualFollowerIds ?? this.mutualFollowerIds,
      connectionScore: connectionScore ?? this.connectionScore,
      connectionReason: connectionReason ?? this.connectionReason,
      createdAt: createdAt,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      isBlocked: isBlocked ?? this.isBlocked,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  String get connectionReasonText {
    if (connectionReason == null) return '';

    switch (connectionType) {
      case 'mutual_follower':
        return mutualFollowersCount > 0
            ? '$mutualFollowersCount mutual ${mutualFollowersCount == 1 ? 'follower' : 'followers'}'
            : 'Mutual connection';
      case 'suggestion':
        return (connectionReason?['reason'] as String?) ?? 'Suggested for you';
      case 'recent_interaction':
        return 'Recently interacted with your content';
      default:
        return '';
    }
  }

  bool get isHighPriority => connectionScore > 0.7 || mutualFollowersCount > 5;
}

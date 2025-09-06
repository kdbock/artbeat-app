import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing message reactions (emojis, thumbs up/down, etc.)
class MessageReactionModel {
  final String id;
  final String messageId;
  final String chatId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String reactionType;
  final String emoji;
  final DateTime createdAt;
  final DateTime updatedAt;

  MessageReactionModel({
    required this.id,
    required this.messageId,
    required this.chatId,
    required this.userId,
    required this.userName,
    this.userAvatar = '',
    required this.reactionType,
    required this.emoji,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory MessageReactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageReactionModel(
      id: doc.id,
      messageId: (data['messageId'] as String?) ?? '',
      chatId: (data['chatId'] as String?) ?? '',
      userId: (data['userId'] as String?) ?? '',
      userName: (data['userName'] as String?) ?? '',
      userAvatar: (data['userAvatar'] as String?) ?? '',
      reactionType: (data['reactionType'] as String?) ?? '',
      emoji: (data['emoji'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create from Map
  factory MessageReactionModel.fromMap(Map<String, dynamic> map) {
    return MessageReactionModel(
      id: (map['id'] as String?) ?? '',
      messageId: (map['messageId'] as String?) ?? '',
      chatId: (map['chatId'] as String?) ?? '',
      userId: (map['userId'] as String?) ?? '',
      userName: (map['userName'] as String?) ?? '',
      userAvatar: (map['userAvatar'] as String?) ?? '',
      reactionType: (map['reactionType'] as String?) ?? '',
      emoji: (map['emoji'] as String?) ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              (map['createdAt'] as String?) ?? DateTime.now().toIso8601String(),
            ),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(
              (map['updatedAt'] as String?) ?? DateTime.now().toIso8601String(),
            ),
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'messageId': messageId,
      'chatId': chatId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'reactionType': reactionType,
      'emoji': emoji,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a new reaction
  factory MessageReactionModel.create({
    required String messageId,
    required String chatId,
    required String userId,
    required String userName,
    String userAvatar = '',
    required String reactionType,
    required String emoji,
  }) {
    final now = DateTime.now();
    return MessageReactionModel(
      id: '${messageId}_${userId}_${reactionType}',
      messageId: messageId,
      chatId: chatId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      reactionType: reactionType,
      emoji: emoji,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Check if this is a positive reaction
  bool get isPositive => ReactionTypes.positive.contains(reactionType);

  /// Check if this is a negative reaction
  bool get isNegative => ReactionTypes.negative.contains(reactionType);

  /// Check if this is an emoji reaction
  bool get isEmoji => reactionType == ReactionTypes.emoji;

  /// Create a copy with updated fields
  MessageReactionModel copyWith({
    String? id,
    String? messageId,
    String? chatId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? reactionType,
    String? emoji,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageReactionModel(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      reactionType: reactionType ?? this.reactionType,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'MessageReactionModel(id: $id, messageId: $messageId, userId: $userId, emoji: $emoji)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageReactionModel &&
        other.id == id &&
        other.messageId == messageId &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ messageId.hashCode ^ userId.hashCode;
  }
}

/// Helper class containing reaction type constants
class ReactionTypes {
  static const String like = 'like';
  static const String love = 'love';
  static const String laugh = 'laugh';
  static const String surprise = 'surprise';
  static const String sad = 'sad';
  static const String angry = 'angry';
  static const String thumbsUp = 'thumbs_up';
  static const String thumbsDown = 'thumbs_down';
  static const String heart = 'heart';
  static const String fire = 'fire';
  static const String clap = 'clap';
  static const String emoji = 'emoji'; // For custom emojis

  static const List<String> allTypes = [
    like,
    love,
    laugh,
    surprise,
    sad,
    angry,
    thumbsUp,
    thumbsDown,
    heart,
    fire,
    clap,
    emoji,
  ];

  /// Quick reactions for the long-press picker
  static const List<String> quickReactions = [
    like,
    love,
    laugh,
    thumbsUp,
    heart,
  ];

  /// Positive reactions
  static const List<String> positive = [
    like,
    love,
    laugh,
    thumbsUp,
    heart,
    fire,
    clap,
  ];

  /// Negative reactions
  static const List<String> negative = [
    sad,
    angry,
    thumbsDown,
    surprise, // Can be negative in some contexts
  ];

  static String getEmoji(String reactionType) {
    switch (reactionType) {
      case like:
        return '👍';
      case love:
        return '❤️';
      case laugh:
        return '😂';
      case surprise:
        return '😮';
      case sad:
        return '😢';
      case angry:
        return '😠';
      case thumbsUp:
        return '👍';
      case thumbsDown:
        return '👎';
      case heart:
        return '�';
      case fire:
        return '�';
      case clap:
        return '�';
      default:
        return '�';
    }
  }

  static String getDisplayName(String reactionType) {
    switch (reactionType) {
      case like:
        return 'Like';
      case love:
        return 'Love';
      case laugh:
        return 'Laugh';
      case surprise:
        return 'Surprise';
      case sad:
        return 'Sad';
      case angry:
        return 'Angry';
      case thumbsUp:
        return 'Thumbs Up';
      case thumbsDown:
        return 'Thumbs Down';
      case heart:
        return 'Heart';
      case fire:
        return 'Fire';
      case clap:
        return 'Clap';
      default:
        return 'Reaction';
    }
  }
}

/// Model for aggregated reaction counts on a message
class MessageReactionsSummary {
  final String messageId;
  final Map<String, int> reactionCounts;
  final Map<String, List<MessageReactionModel>> reactionsByType;
  final int totalReactions;

  MessageReactionsSummary({
    required this.messageId,
    required this.reactionCounts,
    required this.reactionsByType,
  }) : totalReactions = reactionCounts.values.fold(
         0,
         (sum, count) => sum + count,
       );

  /// Create from list of reactions
  factory MessageReactionsSummary.fromReactions(
    String messageId,
    List<MessageReactionModel> reactions,
  ) {
    final counts = <String, int>{};
    final byType = <String, List<MessageReactionModel>>{};

    for (final reaction in reactions) {
      counts[reaction.reactionType] = (counts[reaction.reactionType] ?? 0) + 1;
      byType.putIfAbsent(reaction.reactionType, () => []).add(reaction);
    }

    return MessageReactionsSummary(
      messageId: messageId,
      reactionCounts: counts,
      reactionsByType: byType,
    );
  }

  /// Get count for a specific reaction type
  int getCount(String reactionType) => reactionCounts[reactionType] ?? 0;

  /// Get reactions for a specific type
  List<MessageReactionModel> getReactions(String reactionType) =>
      reactionsByType[reactionType] ?? [];

  /// Check if a user has reacted with a specific type
  bool hasUserReacted(String userId, String reactionType) {
    return getReactions(
      reactionType,
    ).any((reaction) => reaction.userId == userId);
  }

  /// Get the user's reaction for a specific type
  MessageReactionModel? getUserReaction(String userId, String reactionType) {
    try {
      return getReactions(
        reactionType,
      ).firstWhere((reaction) => reaction.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Get the most popular reaction type
  String? get mostPopularReaction {
    if (reactionCounts.isEmpty) return null;
    return reactionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Check if message has any reactions
  bool get hasReactions => totalReactions > 0;
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Universal engagement model for all ARTbeat content
/// Replaces the complex mix of likes, applause, follows, etc.
class EngagementModel {
  final String id;
  final String contentId;
  final String contentType; // 'post', 'artwork', 'art_walk', 'event', 'profile'
  final String userId;
  final EngagementType type;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  EngagementModel({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.userId,
    required this.type,
    required this.createdAt,
    this.metadata,
  });

  factory EngagementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EngagementModel(
      id: doc.id,
      contentId: data['contentId'] as String,
      contentType: data['contentType'] as String,
      userId: data['userId'] as String,
      type: EngagementType.fromString(data['type'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'contentId': contentId,
      'contentType': contentType,
      'userId': userId,
      'type': type.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }
}

/// The five universal engagement types for ARTbeat
enum EngagementType {
  appreciate('appreciate'), // Replaces like, applause, fan, rate
  connect('connect'), // Replaces follow, fan of, subscribe
  discuss('discuss'), // Replaces comment, review
  amplify('amplify'), // Replaces share, repost
  gift('gift'); // Send monetary appreciation

  const EngagementType(this.value);
  final String value;

  static EngagementType fromString(String value) {
    return EngagementType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => EngagementType.appreciate,
    );
  }

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case EngagementType.appreciate:
        return 'Appreciate';
      case EngagementType.connect:
        return 'Connect';
      case EngagementType.discuss:
        return 'Discuss';
      case EngagementType.amplify:
        return 'Amplify';
      case EngagementType.gift:
        return 'Gift';
    }
  }

  /// Get icon name for UI
  String get iconName {
    switch (this) {
      case EngagementType.appreciate:
        return 'palette'; // or 'heart'
      case EngagementType.connect:
        return 'link';
      case EngagementType.discuss:
        return 'chat_bubble';
      case EngagementType.amplify:
        return 'campaign'; // megaphone icon
      case EngagementType.gift:
        return 'card_giftcard'; // gift icon
    }
  }

  /// Get past tense for notifications
  String get pastTense {
    switch (this) {
      case EngagementType.appreciate:
        return 'appreciated';
      case EngagementType.connect:
        return 'connected with';
      case EngagementType.discuss:
        return 'discussed';
      case EngagementType.amplify:
        return 'amplified';
      case EngagementType.gift:
        return 'sent a gift to';
    }
  }
}

/// Engagement statistics for any content
class EngagementStats {
  final int appreciateCount;
  final int connectCount;
  final int discussCount;
  final int amplifyCount;
  final int giftCount;
  final double totalGiftValue; // Total monetary value of gifts received
  final DateTime lastUpdated;

  EngagementStats({
    this.appreciateCount = 0,
    this.connectCount = 0,
    this.discussCount = 0,
    this.amplifyCount = 0,
    this.giftCount = 0,
    this.totalGiftValue = 0.0,
    required this.lastUpdated,
  });

  factory EngagementStats.fromFirestore(Map<String, dynamic> data) {
    return EngagementStats(
      // New universal fields with backward compatibility fallbacks
      appreciateCount:
          data['appreciateCount'] as int? ??
          data['applauseCount'] as int? ??
          data['likeCount'] as int? ??
          0,
      connectCount: data['connectCount'] as int? ?? 0,
      discussCount:
          data['discussCount'] as int? ?? data['commentCount'] as int? ?? 0,
      amplifyCount:
          data['amplifyCount'] as int? ?? data['shareCount'] as int? ?? 0,
      giftCount: data['giftCount'] as int? ?? 0,
      totalGiftValue: (data['totalGiftValue'] as num?)?.toDouble() ?? 0.0,
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory EngagementStats.fromMap(Map<String, dynamic> data) {
    return EngagementStats(
      appreciateCount: data['appreciateCount'] as int? ?? 0,
      connectCount: data['connectCount'] as int? ?? 0,
      discussCount: data['discussCount'] as int? ?? 0,
      amplifyCount: data['amplifyCount'] as int? ?? 0,
      giftCount: data['giftCount'] as int? ?? 0,
      totalGiftValue: (data['totalGiftValue'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: data['lastUpdated'] is Timestamp
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.tryParse(data['lastUpdated'] as String? ?? '') ??
                DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'appreciateCount': appreciateCount,
      'connectCount': connectCount,
      'discussCount': discussCount,
      'amplifyCount': amplifyCount,
      'giftCount': giftCount,
      'totalGiftValue': totalGiftValue,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'appreciateCount': appreciateCount,
      'connectCount': connectCount,
      'discussCount': discussCount,
      'amplifyCount': amplifyCount,
      'giftCount': giftCount,
      'totalGiftValue': totalGiftValue,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  EngagementStats copyWith({
    int? appreciateCount,
    int? connectCount,
    int? discussCount,
    int? amplifyCount,
    int? giftCount,
    double? totalGiftValue,
    DateTime? lastUpdated,
  }) {
    return EngagementStats(
      appreciateCount: appreciateCount ?? this.appreciateCount,
      connectCount: connectCount ?? this.connectCount,
      discussCount: discussCount ?? this.discussCount,
      amplifyCount: amplifyCount ?? this.amplifyCount,
      giftCount: giftCount ?? this.giftCount,
      totalGiftValue: totalGiftValue ?? this.totalGiftValue,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get total engagement count
  int get totalEngagement =>
      appreciateCount + connectCount + discussCount + amplifyCount + giftCount;

  /// Get count for specific engagement type
  int getCount(EngagementType type) {
    switch (type) {
      case EngagementType.appreciate:
        return appreciateCount;
      case EngagementType.connect:
        return connectCount;
      case EngagementType.discuss:
        return discussCount;
      case EngagementType.amplify:
        return amplifyCount;
      case EngagementType.gift:
        return giftCount;
    }
  }
}

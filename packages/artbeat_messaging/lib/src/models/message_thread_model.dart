import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing message threading and reply functionality
class MessageThreadModel {
  final String id;
  final String chatId;
  final String parentMessageId;
  final List<String> replyMessageIds;
  final String threadStarterId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int replyCount;
  final String? lastReplyId;
  final DateTime? lastReplyAt;
  final bool isActive;

  MessageThreadModel({
    required this.id,
    required this.chatId,
    required this.parentMessageId,
    required this.replyMessageIds,
    required this.threadStarterId,
    required this.createdAt,
    required this.updatedAt,
    this.replyCount = 0,
    this.lastReplyId,
    this.lastReplyAt,
    this.isActive = true,
  });

  /// Create from Firestore document
  factory MessageThreadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageThreadModel(
      id: doc.id,
      chatId: (data['chatId'] as String?) ?? '',
      parentMessageId: (data['parentMessageId'] as String?) ?? '',
      replyMessageIds: List<String>.from(
        data['replyMessageIds'] as List? ?? [],
      ),
      threadStarterId: (data['threadStarterId'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      replyCount: (data['replyCount'] as int?) ?? 0,
      lastReplyId: data['lastReplyId'] as String?,
      lastReplyAt: (data['lastReplyAt'] as Timestamp?)?.toDate(),
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }

  /// Create from Map
  factory MessageThreadModel.fromMap(Map<String, dynamic> map) {
    return MessageThreadModel(
      id: (map['id'] as String?) ?? '',
      chatId: (map['chatId'] as String?) ?? '',
      parentMessageId: (map['parentMessageId'] as String?) ?? '',
      replyMessageIds: List<String>.from(map['replyMessageIds'] as List? ?? []),
      threadStarterId: (map['threadStarterId'] as String?) ?? '',
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
      replyCount: (map['replyCount'] as int?) ?? 0,
      lastReplyId: map['lastReplyId'] as String?,
      lastReplyAt: map['lastReplyAt'] is Timestamp
          ? (map['lastReplyAt'] as Timestamp).toDate()
          : map['lastReplyAt'] != null
          ? DateTime.parse(map['lastReplyAt'] as String)
          : null,
      isActive: (map['isActive'] as bool?) ?? true,
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'parentMessageId': parentMessageId,
      'replyMessageIds': replyMessageIds,
      'threadStarterId': threadStarterId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'replyCount': replyCount,
      'lastReplyId': lastReplyId,
      'lastReplyAt': lastReplyAt != null
          ? Timestamp.fromDate(lastReplyAt!)
          : null,
      'isActive': isActive,
    };
  }

  /// Add a reply to the thread
  MessageThreadModel addReply(String replyMessageId) {
    final updatedReplies = List<String>.from(replyMessageIds)
      ..add(replyMessageId);
    return MessageThreadModel(
      id: id,
      chatId: chatId,
      parentMessageId: parentMessageId,
      replyMessageIds: updatedReplies,
      threadStarterId: threadStarterId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      replyCount: replyCount + 1,
      lastReplyId: replyMessageId,
      lastReplyAt: DateTime.now(),
      isActive: isActive,
    );
  }

  /// Remove a reply from the thread
  MessageThreadModel removeReply(String replyMessageId) {
    final updatedReplies = List<String>.from(replyMessageIds)
      ..remove(replyMessageId);
    return MessageThreadModel(
      id: id,
      chatId: chatId,
      parentMessageId: parentMessageId,
      replyMessageIds: updatedReplies,
      threadStarterId: threadStarterId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      replyCount: replyCount > 0 ? replyCount - 1 : 0,
      lastReplyId: updatedReplies.isNotEmpty ? updatedReplies.last : null,
      lastReplyAt: updatedReplies.isNotEmpty ? DateTime.now() : null,
      isActive: updatedReplies.isNotEmpty,
    );
  }

  /// Check if a message is part of this thread
  bool containsMessage(String messageId) {
    return parentMessageId == messageId || replyMessageIds.contains(messageId);
  }

  /// Create a copy with updated fields
  MessageThreadModel copyWith({
    String? id,
    String? chatId,
    String? parentMessageId,
    List<String>? replyMessageIds,
    String? threadStarterId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? replyCount,
    String? lastReplyId,
    DateTime? lastReplyAt,
    bool? isActive,
  }) {
    return MessageThreadModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      parentMessageId: parentMessageId ?? this.parentMessageId,
      replyMessageIds: replyMessageIds ?? this.replyMessageIds,
      threadStarterId: threadStarterId ?? this.threadStarterId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replyCount: replyCount ?? this.replyCount,
      lastReplyId: lastReplyId ?? this.lastReplyId,
      lastReplyAt: lastReplyAt ?? this.lastReplyAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'MessageThreadModel(id: $id, chatId: $chatId, parentMessageId: $parentMessageId, replyCount: $replyCount, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageThreadModel &&
        other.id == id &&
        other.chatId == chatId &&
        other.parentMessageId == parentMessageId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ chatId.hashCode ^ parentMessageId.hashCode;
  }
}

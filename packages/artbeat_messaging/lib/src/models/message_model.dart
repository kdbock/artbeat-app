import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, video, file }

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final bool isRead;
  final String? replyToId;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.isRead = false,
    this.replyToId,
    this.metadata,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: (map['id'] as String?) ?? '',
      senderId: (map['senderId'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == (map['type'] as String?),
        orElse: () => MessageType.text,
      ),
      isRead: (map['isRead'] as bool?) ?? false,
      replyToId: map['replyToId'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: (data['senderId'] as String?) ?? '',
      content: (data['text'] as String?) ?? (data['content'] as String?) ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      type: data['imageUrl'] != null
          ? MessageType.image
          : data['fileUrl'] != null
          ? MessageType.file
          : MessageType.text,
      isRead:
          (data['read'] as Map<String, dynamic>?)?.values.contains(true) ??
          false,
      replyToId: data['replyToMessageId'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString(),
      'isRead': isRead,
      'replyToId': replyToId,
      'metadata': metadata,
    };
  }
}

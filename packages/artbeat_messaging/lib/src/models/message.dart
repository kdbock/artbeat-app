import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;
  final String? replyToId;
  final Map<String, dynamic>? metadata;
  final String? senderName;
  final String? senderPhotoUrl;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.text,
    this.imageUrl,
    required this.timestamp,
    this.isRead = false,
    this.replyToId,
    this.metadata,
    this.senderName,
    this.senderPhotoUrl,
  }) : assert(
         text != null || imageUrl != null,
         'Message must have either text or image',
       );

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      chatId: data['chatId'] as String,
      senderId: data['senderId'] as String,
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] as bool? ?? false,
      replyToId: data['replyToId'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      senderName: data['senderName'] as String?,
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      if (text != null) 'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      if (replyToId != null) 'replyToId': replyToId,
      if (metadata != null) 'metadata': metadata,
      if (senderName != null) 'senderName': senderName,
      if (senderPhotoUrl != null) 'senderPhotoUrl': senderPhotoUrl,
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    String? imageUrl,
    DateTime? timestamp,
    bool? isRead,
    String? replyToId,
    Map<String, dynamic>? metadata,
    String? senderName,
    String? senderPhotoUrl,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      replyToId: replyToId ?? this.replyToId,
      metadata: metadata ?? this.metadata,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Message &&
        other.id == id &&
        other.chatId == chatId &&
        other.senderId == senderId &&
        other.text == text &&
        other.imageUrl == imageUrl &&
        other.timestamp == timestamp &&
        other.isRead == isRead &&
        other.replyToId == replyToId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        chatId.hashCode ^
        senderId.hashCode ^
        text.hashCode ^
        imageUrl.hashCode ^
        timestamp.hashCode ^
        isRead.hashCode ^
        replyToId.hashCode;
  }
}

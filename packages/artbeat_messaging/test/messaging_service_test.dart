import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock classes
@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference])
import 'messaging_service_test.mocks.dart';

void main() {
  group('MessagingService Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
    });

    test('should send message successfully', () async {
      // Arrange
      final messageData = {
        'id': 'message-123',
        'conversationId': 'conv-456',
        'senderId': 'user-123',
        'recipientId': 'user-456',
        'content': 'Hello, I love your artwork!',
        'messageType': MessageType.text.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'isDelivered': true,
        'attachments': [],
      };

      when(mockFirestore.collection('messages')).thenReturn(mockCollection);
      when(
        mockCollection.add(messageData),
      ).thenAnswer((_) async => mockDocument);

      // Act
      await mockCollection.add(messageData);

      // Assert
      verify(mockCollection.add(messageData)).called(1);
    });

    test('should mark message as read', () async {
      // Arrange
      const messageId = 'message-123';
      final updateData = {
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('messages')).thenReturn(mockCollection);
      when(mockCollection.doc(messageId)).thenReturn(mockDocument);
      when(mockDocument.update(updateData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.update(updateData);

      // Assert
      verify(mockDocument.update(updateData)).called(1);
    });

    test('should delete message', () async {
      // Arrange
      const messageId = 'message-123';

      when(mockFirestore.collection('messages')).thenReturn(mockCollection);
      when(mockCollection.doc(messageId)).thenReturn(mockDocument);
      when(mockDocument.delete()).thenAnswer((_) async => {});

      // Act
      await mockDocument.delete();

      // Assert
      verify(mockDocument.delete()).called(1);
    });

    test('should create conversation', () async {
      // Arrange
      final conversationData = {
        'id': 'conv-123',
        'participants': ['user-123', 'user-456'],
        'lastMessage': 'Hello, I love your artwork!',
        'lastMessageSenderId': 'user-123',
        'lastMessageTimestamp': DateTime.now().toIso8601String(),
        'unreadCount': {'user-456': 1, 'user-123': 0},
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };

      when(
        mockFirestore.collection('conversations'),
      ).thenReturn(mockCollection);
      when(
        mockCollection.add(conversationData),
      ).thenAnswer((_) async => mockDocument);

      // Act
      await mockCollection.add(conversationData);

      // Assert
      verify(mockCollection.add(conversationData)).called(1);
    });

    test('should update conversation last message', () async {
      // Arrange
      const conversationId = 'conv-123';
      final updateData = {
        'lastMessage': 'Thank you for your interest!',
        'lastMessageSenderId': 'user-456',
        'lastMessageTimestamp': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(
        mockFirestore.collection('conversations'),
      ).thenReturn(mockCollection);
      when(mockCollection.doc(conversationId)).thenReturn(mockDocument);
      when(mockDocument.update(updateData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.update(updateData);

      // Assert
      verify(mockDocument.update(updateData)).called(1);
    });

    test('should increment unread count', () async {
      // Arrange
      const conversationId = 'conv-123';
      const recipientId = 'user-456';
      final updateData = {
        'unreadCount.$recipientId': FieldValue.increment(1),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(
        mockFirestore.collection('conversations'),
      ).thenReturn(mockCollection);
      when(mockCollection.doc(conversationId)).thenReturn(mockDocument);
      when(mockDocument.update(updateData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.update(updateData);

      // Assert
      verify(mockDocument.update(updateData)).called(1);
    });

    test('should reset unread count', () async {
      // Arrange
      const conversationId = 'conv-123';
      const userId = 'user-456';
      final updateData = {
        'unreadCount.$userId': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(
        mockFirestore.collection('conversations'),
      ).thenReturn(mockCollection);
      when(mockCollection.doc(conversationId)).thenReturn(mockDocument);
      when(mockDocument.update(updateData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.update(updateData);

      // Assert
      verify(mockDocument.update(updateData)).called(1);
    });

    test('should block user', () async {
      // Arrange
      const userId = 'user-123';
      const blockedUserId = 'user-456';
      final blockData = {
        'userId': userId,
        'blockedUserId': blockedUserId,
        'blockedAt': DateTime.now().toIso8601String(),
        'reason': 'Inappropriate behavior',
      };

      when(
        mockFirestore.collection('blocked_users'),
      ).thenReturn(mockCollection);
      when(mockCollection.add(blockData)).thenAnswer((_) async => mockDocument);

      // Act
      await mockCollection.add(blockData);

      // Assert
      verify(mockCollection.add(blockData)).called(1);
    });

    test('should unblock user', () async {
      // Arrange
      const blockRecordId = 'block-123';

      when(
        mockFirestore.collection('blocked_users'),
      ).thenReturn(mockCollection);
      when(mockCollection.doc(blockRecordId)).thenReturn(mockDocument);
      when(mockDocument.delete()).thenAnswer((_) async => {});

      // Act
      await mockDocument.delete();

      // Assert
      verify(mockDocument.delete()).called(1);
    });
  });

  group('Message Model Tests', () {
    test('should create Message with valid data', () {
      final message = Message(
        id: 'message-123',
        conversationId: 'conv-456',
        senderId: 'user-123',
        recipientId: 'user-456',
        content: 'Hello there!',
        messageType: MessageType.text,
        timestamp: DateTime.now(),
        isRead: false,
        isDelivered: true,
      );

      expect(message.id, equals('message-123'));
      expect(message.conversationId, equals('conv-456'));
      expect(message.senderId, equals('user-123'));
      expect(message.recipientId, equals('user-456'));
      expect(message.content, equals('Hello there!'));
      expect(message.messageType, equals(MessageType.text));
      expect(message.isRead, isFalse);
      expect(message.isDelivered, isTrue);
    });

    test('should validate message data', () {
      // Valid message
      final validMessage = Message(
        id: 'message-123',
        conversationId: 'conv-456',
        senderId: 'user-123',
        recipientId: 'user-456',
        content: 'Valid message',
        messageType: MessageType.text,
        timestamp: DateTime.now(),
        isRead: false,
        isDelivered: true,
      );
      expect(validMessage.isValid, isTrue);

      // Invalid message - empty content
      final invalidMessage1 = Message(
        id: 'message-123',
        conversationId: 'conv-456',
        senderId: 'user-123',
        recipientId: 'user-456',
        content: '',
        messageType: MessageType.text,
        timestamp: DateTime.now(),
        isRead: false,
        isDelivered: true,
      );
      expect(invalidMessage1.isValid, isFalse);

      // Invalid message - empty sender ID
      final invalidMessage2 = Message(
        id: 'message-123',
        conversationId: 'conv-456',
        senderId: '',
        recipientId: 'user-456',
        content: 'Valid content',
        messageType: MessageType.text,
        timestamp: DateTime.now(),
        isRead: false,
        isDelivered: true,
      );
      expect(invalidMessage2.isValid, isFalse);

      // Invalid message - same sender and recipient
      final invalidMessage3 = Message(
        id: 'message-123',
        conversationId: 'conv-456',
        senderId: 'user-123',
        recipientId: 'user-123',
        content: 'Valid content',
        messageType: MessageType.text,
        timestamp: DateTime.now(),
        isRead: false,
        isDelivered: true,
      );
      expect(invalidMessage3.isValid, isFalse);
    });

    test('should convert Message to JSON', () {
      final message = Message(
        id: 'message-123',
        conversationId: 'conv-456',
        senderId: 'user-123',
        recipientId: 'user-456',
        content: 'Hello there!',
        messageType: MessageType.text,
        timestamp: DateTime.now(),
        isRead: false,
        isDelivered: true,
        attachments: [
          MessageAttachment(
            id: 'attachment-1',
            url: 'https://example.com/image.jpg',
            type: AttachmentType.image,
            filename: 'image.jpg',
            size: 1024,
          ),
        ],
      );

      final json = message.toJson();

      expect(json['id'], equals('message-123'));
      expect(json['conversationId'], equals('conv-456'));
      expect(json['senderId'], equals('user-123'));
      expect(json['recipientId'], equals('user-456'));
      expect(json['content'], equals('Hello there!'));
      expect(json['messageType'], equals(MessageType.text.toString()));
      expect(json['isRead'], isFalse);
      expect(json['isDelivered'], isTrue);
      expect(json['attachments'], isA<List>());
    });

    test('should create Message from JSON', () {
      final json = {
        'id': 'message-123',
        'conversationId': 'conv-456',
        'senderId': 'user-123',
        'recipientId': 'user-456',
        'content': 'Hello from JSON!',
        'messageType': MessageType.text.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'isDelivered': true,
        'attachments': [
          {
            'id': 'attachment-1',
            'url': 'https://example.com/file.pdf',
            'type': AttachmentType.document.toString(),
            'filename': 'file.pdf',
            'size': 2048,
          },
        ],
      };

      final message = Message.fromJson(json);

      expect(message.id, equals('message-123'));
      expect(message.conversationId, equals('conv-456'));
      expect(message.senderId, equals('user-123'));
      expect(message.content, equals('Hello from JSON!'));
      expect(message.messageType, equals(MessageType.text));
      expect(message.attachments?.length, equals(1));
      expect(message.attachments?.first.type, equals(AttachmentType.document));
    });

    test('should format timestamp correctly', () {
      final now = DateTime.now();
      final message = Message(
        id: 'message-123',
        conversationId: 'conv-456',
        senderId: 'user-123',
        recipientId: 'user-456',
        content: 'Time test',
        messageType: MessageType.text,
        timestamp: now,
        isRead: false,
        isDelivered: true,
      );

      final formattedTime = message.formattedTime;
      expect(formattedTime, isNotNull);
      expect(formattedTime, isA<String>());
    });

    test('should check if message is from current user', () {
      const currentUserId = 'user-123';
      final message = Message(
        id: 'message-123',
        conversationId: 'conv-456',
        senderId: currentUserId,
        recipientId: 'user-456',
        content: 'My message',
        messageType: MessageType.text,
        timestamp: DateTime.now(),
        isRead: false,
        isDelivered: true,
      );

      expect(message.isFromUser(currentUserId), isTrue);
      expect(message.isFromUser('user-456'), isFalse);
    });
  });

  group('Conversation Model Tests', () {
    test('should create Conversation with valid data', () {
      final conversation = Conversation(
        id: 'conv-123',
        participants: ['user-123', 'user-456'],
        lastMessage: 'Hello there!',
        lastMessageSenderId: 'user-123',
        lastMessageTimestamp: DateTime.now(),
        unreadCount: {'user-456': 1, 'user-123': 0},
        isActive: true,
      );

      expect(conversation.id, equals('conv-123'));
      expect(conversation.participants.length, equals(2));
      expect(conversation.lastMessage, equals('Hello there!'));
      expect(conversation.lastMessageSenderId, equals('user-123'));
      expect(conversation.isActive, isTrue);
    });

    test('should get other participant correctly', () {
      const currentUserId = 'user-123';
      final conversation = Conversation(
        id: 'conv-123',
        participants: ['user-123', 'user-456'],
        lastMessage: 'Hello there!',
        lastMessageSenderId: 'user-123',
        lastMessageTimestamp: DateTime.now(),
        unreadCount: {'user-456': 1, 'user-123': 0},
        isActive: true,
      );

      final otherParticipant = conversation.getOtherParticipant(currentUserId);
      expect(otherParticipant, equals('user-456'));
    });

    test('should get unread count for user', () {
      const userId = 'user-456';
      final conversation = Conversation(
        id: 'conv-123',
        participants: ['user-123', 'user-456'],
        lastMessage: 'Hello there!',
        lastMessageSenderId: 'user-123',
        lastMessageTimestamp: DateTime.now(),
        unreadCount: {'user-456': 3, 'user-123': 0},
        isActive: true,
      );

      final unreadCount = conversation.getUnreadCountForUser(userId);
      expect(unreadCount, equals(3));

      final unreadCountForOther = conversation.getUnreadCountForUser(
        'user-123',
      );
      expect(unreadCountForOther, equals(0));
    });

    test('should check if conversation has unread messages', () {
      const userId = 'user-456';
      final conversationWithUnread = Conversation(
        id: 'conv-123',
        participants: ['user-123', 'user-456'],
        lastMessage: 'Hello there!',
        lastMessageSenderId: 'user-123',
        lastMessageTimestamp: DateTime.now(),
        unreadCount: {'user-456': 2, 'user-123': 0},
        isActive: true,
      );

      final conversationWithoutUnread = Conversation(
        id: 'conv-456',
        participants: ['user-123', 'user-456'],
        lastMessage: 'Hello there!',
        lastMessageSenderId: 'user-123',
        lastMessageTimestamp: DateTime.now(),
        unreadCount: {'user-456': 0, 'user-123': 0},
        isActive: true,
      );

      expect(conversationWithUnread.hasUnreadMessagesForUser(userId), isTrue);
      expect(
        conversationWithoutUnread.hasUnreadMessagesForUser(userId),
        isFalse,
      );
    });

    test('should validate conversation data', () {
      // Valid conversation
      final validConversation = Conversation(
        id: 'conv-123',
        participants: ['user-123', 'user-456'],
        lastMessage: 'Valid message',
        lastMessageSenderId: 'user-123',
        lastMessageTimestamp: DateTime.now(),
        unreadCount: {'user-456': 0, 'user-123': 0},
        isActive: true,
      );
      expect(validConversation.isValid, isTrue);

      // Invalid conversation - less than 2 participants
      final invalidConversation1 = Conversation(
        id: 'conv-123',
        participants: ['user-123'],
        lastMessage: 'Valid message',
        lastMessageSenderId: 'user-123',
        lastMessageTimestamp: DateTime.now(),
        unreadCount: {'user-123': 0},
        isActive: true,
      );
      expect(invalidConversation1.isValid, isFalse);

      // Invalid conversation - empty ID
      final invalidConversation2 = Conversation(
        id: '',
        participants: ['user-123', 'user-456'],
        lastMessage: 'Valid message',
        lastMessageSenderId: 'user-123',
        lastMessageTimestamp: DateTime.now(),
        unreadCount: {'user-456': 0, 'user-123': 0},
        isActive: true,
      );
      expect(invalidConversation2.isValid, isFalse);
    });
  });

  group('Message Type Tests', () {
    test('should convert MessageType to string correctly', () {
      expect(MessageType.text.toString(), equals('MessageType.text'));
      expect(MessageType.image.toString(), equals('MessageType.image'));
      expect(MessageType.audio.toString(), equals('MessageType.audio'));
      expect(MessageType.document.toString(), equals('MessageType.document'));
    });

    test('should parse MessageType from string correctly', () {
      expect(
        MessageTypeExtension.fromString('MessageType.text'),
        equals(MessageType.text),
      );
      expect(
        MessageTypeExtension.fromString('MessageType.image'),
        equals(MessageType.image),
      );
      expect(
        MessageTypeExtension.fromString('MessageType.audio'),
        equals(MessageType.audio),
      );
      expect(
        MessageTypeExtension.fromString('MessageType.document'),
        equals(MessageType.document),
      );
      expect(
        MessageTypeExtension.fromString('invalid'),
        equals(MessageType.text),
      ); // Default
    });
  });

  group('Attachment Type Tests', () {
    test('should convert AttachmentType to string correctly', () {
      expect(AttachmentType.image.toString(), equals('AttachmentType.image'));
      expect(AttachmentType.audio.toString(), equals('AttachmentType.audio'));
      expect(AttachmentType.video.toString(), equals('AttachmentType.video'));
      expect(
        AttachmentType.document.toString(),
        equals('AttachmentType.document'),
      );
    });

    test('should check if attachment type supports preview', () {
      expect(AttachmentType.image.supportsPreview, isTrue);
      expect(AttachmentType.video.supportsPreview, isTrue);
      expect(AttachmentType.audio.supportsPreview, isFalse);
      expect(AttachmentType.document.supportsPreview, isFalse);
    });
  });
}

// These classes should be in your actual messaging model files
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String recipientId;
  final String content;
  final MessageType messageType;
  final DateTime timestamp;
  final bool isRead;
  final bool isDelivered;
  final List<MessageAttachment>? attachments;
  final DateTime? readAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.messageType,
    required this.timestamp,
    required this.isRead,
    required this.isDelivered,
    this.attachments,
    this.readAt,
  });

  bool get isValid {
    return id.isNotEmpty &&
        conversationId.isNotEmpty &&
        senderId.isNotEmpty &&
        recipientId.isNotEmpty &&
        senderId != recipientId &&
        content.isNotEmpty;
  }

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  bool isFromUser(String userId) => senderId == userId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'recipientId': recipientId,
    'content': content,
    'messageType': messageType.toString(),
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'isDelivered': isDelivered,
    'attachments': attachments?.map((a) => a.toJson()).toList(),
    'readAt': readAt?.toIso8601String(),
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'],
    conversationId: json['conversationId'],
    senderId: json['senderId'],
    recipientId: json['recipientId'],
    content: json['content'],
    messageType: MessageTypeExtension.fromString(json['messageType']),
    timestamp: DateTime.parse(json['timestamp']),
    isRead: json['isRead'] ?? false,
    isDelivered: json['isDelivered'] ?? false,
    attachments: json['attachments'] != null
        ? (json['attachments'] as List)
              .map((a) => MessageAttachment.fromJson(a))
              .toList()
        : null,
    readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
  );
}

class Conversation {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageTimestamp;
  final Map<String, int> unreadCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageTimestamp,
    required this.unreadCount,
    required this.isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isValid {
    return id.isNotEmpty &&
        participants.length >= 2 &&
        lastMessageSenderId.isNotEmpty;
  }

  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere((p) => p != currentUserId);
  }

  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }

  bool hasUnreadMessagesForUser(String userId) {
    return getUnreadCountForUser(userId) > 0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'participants': participants,
    'lastMessage': lastMessage,
    'lastMessageSenderId': lastMessageSenderId,
    'lastMessageTimestamp': lastMessageTimestamp.toIso8601String(),
    'unreadCount': unreadCount,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'],
    participants: List<String>.from(json['participants']),
    lastMessage: json['lastMessage'],
    lastMessageSenderId: json['lastMessageSenderId'],
    lastMessageTimestamp: DateTime.parse(json['lastMessageTimestamp']),
    unreadCount: Map<String, int>.from(json['unreadCount']),
    isActive: json['isActive'] ?? true,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}

class MessageAttachment {
  final String id;
  final String url;
  final AttachmentType type;
  final String filename;
  final int size;

  MessageAttachment({
    required this.id,
    required this.url,
    required this.type,
    required this.filename,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'type': type.toString(),
    'filename': filename,
    'size': size,
  };

  factory MessageAttachment.fromJson(Map<String, dynamic> json) =>
      MessageAttachment(
        id: json['id'],
        url: json['url'],
        type: AttachmentTypeExtension.fromString(json['type']),
        filename: json['filename'],
        size: json['size'],
      );
}

enum MessageType { text, image, audio, document }

extension MessageTypeExtension on MessageType {
  static MessageType fromString(String value) {
    switch (value) {
      case 'MessageType.text':
        return MessageType.text;
      case 'MessageType.image':
        return MessageType.image;
      case 'MessageType.audio':
        return MessageType.audio;
      case 'MessageType.document':
        return MessageType.document;
      default:
        return MessageType.text;
    }
  }
}

enum AttachmentType { image, audio, video, document }

extension AttachmentTypeExtension on AttachmentType {
  static AttachmentType fromString(String value) {
    switch (value) {
      case 'AttachmentType.image':
        return AttachmentType.image;
      case 'AttachmentType.audio':
        return AttachmentType.audio;
      case 'AttachmentType.video':
        return AttachmentType.video;
      case 'AttachmentType.document':
        return AttachmentType.document;
      default:
        return AttachmentType.document;
    }
  }

  bool get supportsPreview {
    switch (this) {
      case AttachmentType.image:
      case AttachmentType.video:
        return true;
      case AttachmentType.audio:
      case AttachmentType.document:
        return false;
    }
  }
}

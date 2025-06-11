import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_messaging/artbeat_messaging.dart';

void main() {
  group('MessageModel', () {
    test('creates message with required fields', () {
      final now = DateTime.now();
      final message = MessageModel(
        id: 'msg1',
        senderId: 'user1',
        content: 'Test message',
        timestamp: now,
      );

      expect(message.id, 'msg1');
      expect(message.senderId, 'user1');
      expect(message.content, 'Test message');
      expect(message.timestamp, now);
      expect(message.type, MessageType.text); // default type
      expect(message.isRead, false); // default value
    });

    test('handles reply messages', () {
      final now = DateTime.now();
      final message = MessageModel(
        id: 'msg2',
        senderId: 'user1',
        content: 'Reply message',
        timestamp: now,
        replyToId: 'msg1',
      );

      expect(message.replyToId, 'msg1');
    });
  });

  group('ChatModel', () {
    test('creates chat from Firestore document', () async {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      final doc = FakeDocumentSnapshot(
        documentID: 'chat1',
        documentData: {
          'participants': [
            {
              'id': 'user1',
              'displayName': 'Test User 1',
              'lastSeen': timestamp,
              'isOnline': true,
              'deviceTokens': ['token1'],
            },
            {
              'id': 'user2',
              'displayName': 'Test User 2',
              'lastSeen': timestamp,
              'isOnline': false,
              'deviceTokens': [],
            },
          ],
          'lastMessage': {
            'id': 'msg1',
            'senderId': 'user1',
            'content': 'Hello',
            'timestamp': timestamp,
            'type': 'MessageType.text',
            'isRead': false,
          },
          'createdAt': timestamp,
          'updatedAt': timestamp,
          'isGroup': false,
          'participantIds': ['user1', 'user2'],
        },
      );

      final chat = ChatModel.fromFirestore(doc);

      expect(chat.id, 'chat1');
      expect(chat.participants.length, 2);
      expect(chat.participants[0].displayName, 'Test User 1');
      expect(chat.participants[0].deviceTokens, ['token1']);
      expect(chat.participants[1].displayName, 'Test User 2');
      expect(chat.participants[1].deviceTokens, isEmpty);
      expect(chat.lastMessage?.content, 'Hello');
      expect(chat.lastMessage?.senderId, 'user1');
      expect(chat.isGroup, false);
      expect(chat.createdAt, now);
      expect(chat.updatedAt, now);
    });
  });
}

class FakeDocumentSnapshot implements DocumentSnapshot {
  final String documentID;
  final Map<String, dynamic> documentData;

  FakeDocumentSnapshot({required this.documentID, required this.documentData});

  @override
  String get id => documentID;

  @override
  Map<String, dynamic> data() => documentData;

  @override
  bool get exists => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

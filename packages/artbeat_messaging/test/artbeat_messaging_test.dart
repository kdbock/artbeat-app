import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mockito/mockito.dart';
import 'package:artbeat_messaging/artbeat_messaging.dart';
import 'package:mockito/annotations.dart';
import 'artbeat_messaging_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseAuth>(),
  MockSpec<User>(as: #TestMockUser),
  MockSpec<FirebaseMessaging>(),
  MockSpec<NotificationSettings>(),
])
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
      final fakeFirestore = FakeFirebaseFirestore();
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      final docRef = fakeFirestore.collection('chats').doc('chat1');
      await docRef.set({
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
      });

      final doc = await docRef.get();
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

  group('ChatService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ChatService chatService;
    late MockFirebaseAuth mockAuth;
    late TestMockUser testUser;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      testUser = TestMockUser();
      when(mockAuth.currentUser).thenReturn(testUser);
      when(testUser.uid).thenReturn('test-user-id');
      chatService = ChatService(firestore: fakeFirestore, auth: mockAuth);
    });

    test('get chats returns list of chats', () async {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);
      final userId = testUser.uid;

      await fakeFirestore.collection('chats').doc('chat1').set({
        'participants': [
          {
            'id': userId,
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
          'content': 'Hello',
          'senderId': userId,
          'timestamp': timestamp,
          'type': 'MessageType.text',
          'isRead': false,
        },
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'isGroup': false,
        'participantIds': [userId, 'user2'],
      });

      final chats = await chatService.getChats();
      expect(chats.length, 1);
      expect(chats.first.id, 'chat1');
      expect(chats.first.participants.length, 2);
    });

    test('send message updates chat and creates message', () async {
      final now = DateTime.now();
      final chatId = 'chat1';
      final userId = testUser.uid;
      final timestamp = Timestamp.fromDate(now);

      // Create chat first
      await fakeFirestore.collection('chats').doc(chatId).set({
        'participants': [
          {
            'id': userId,
            'displayName': 'Test User 1',
            'lastSeen': timestamp,
            'isOnline': true,
            'deviceTokens': ['token1'],
          },
        ],
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'isGroup': false,
        'participantIds': [userId],
      });

      const testMessage = 'Test message';
      await chatService.sendMessage(chatId, testMessage);

      final messageDoc =
          await fakeFirestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .get();

      expect(messageDoc.docs.isNotEmpty, true);
      expect(messageDoc.docs.first.data()['content'], testMessage);
      expect(messageDoc.docs.first.data()['senderId'], userId);
      expect(messageDoc.docs.first.data()['type'], MessageType.text.toString());
    });

    test('send image creates message with image URL', () async {
      final now = DateTime.now();
      final chatId = 'chat1';
      final userId = testUser.uid;
      final timestamp = Timestamp.fromDate(now);

      // Create chat first
      await fakeFirestore.collection('chats').doc(chatId).set({
        'participants': [
          {
            'id': userId,
            'displayName': 'Test User 1',
            'lastSeen': timestamp,
            'isOnline': true,
            'deviceTokens': ['token1'],
          },
        ],
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'isGroup': false,
        'participantIds': [userId],
      });

      const imagePath = 'test/assets/test_image.jpg';
      await chatService.sendImage(chatId, imagePath);

      final messageDoc =
          await fakeFirestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .get();

      expect(messageDoc.docs.isNotEmpty, true);
      expect(
        messageDoc.docs.first.data()['type'],
        MessageType.image.toString(),
      );
      expect(messageDoc.docs.first.data()['senderId'], userId);
      expect(messageDoc.docs.first.data()['content'], contains('https://'));
    });

    test('getTypingStatus returns current typing users', () async {
      final chatId = 'chat1';
      final userId = testUser.uid;
      final timestamp = Timestamp.fromDate(DateTime.now());

      // Create chat first
      await fakeFirestore.collection('chats').doc(chatId).set({
        'participants': [
          {'id': userId},
        ],
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'participantIds': [userId],
      });

      await fakeFirestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc('status')
          .set({'user1': true, 'user2': false});

      final status = await chatService.getTypingStatus(chatId).first;
      expect(status['user1'], true);
      expect(status['user2'], false);
    });

    test('updateTypingStatus sets user as typing', () async {
      final chatId = 'chat1';
      final userId = testUser.uid;
      final timestamp = Timestamp.fromDate(DateTime.now());

      // Create chat first
      await fakeFirestore.collection('chats').doc(chatId).set({
        'participants': [
          {'id': userId},
        ],
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'participantIds': [userId],
      });

      await chatService.updateTypingStatus(chatId, userId, true);

      // Wait for any pending operations in fake_cloud_firestore
      await Future<void>.delayed(Duration.zero);

      // Get the typing status through the stream to ensure we're getting the latest data
      final status = await chatService.getTypingStatus(chatId).first;
      expect(status[userId], true);
    });

    test('clearTypingStatus removes user typing status', () async {
      final chatId = 'chat1';
      final userId = testUser.uid;
      final timestamp = Timestamp.fromDate(DateTime.now());

      // Create chat first
      await fakeFirestore.collection('chats').doc(chatId).set({
        'participants': [
          {'id': userId},
        ],
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'participantIds': [userId],
      });

      // First set typing status
      await fakeFirestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc('status')
          .set({userId: true});

      // Then clear it
      await chatService.clearTypingStatus(chatId, userId);

      final statusDoc =
          await fakeFirestore
              .collection('chats')
              .doc(chatId)
              .collection('typing')
              .doc('status')
              .get();

      expect(statusDoc.exists, true);
      final data = statusDoc.data() as Map<String, dynamic>;
      expect(data.containsKey(userId), false);
    });
  });
}

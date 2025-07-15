import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:artbeat_messaging/src/services/chat_service.dart';
import 'package:artbeat_messaging/src/models/message_model.dart';
import 'package:artbeat_messaging/src/models/chat_model.dart';

// Mock classes
@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  FirebaseStorage,
  CollectionReference,
  DocumentReference,
  Query,
  QuerySnapshot,
  DocumentSnapshot,
  QueryDocumentSnapshot,
  User,
])
import 'chat_service_test.mocks.dart';

void main() {
  group('ChatService Tests', () {
    late ChatService chatService;
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockFirebaseStorage mockStorage;
    late MockUser mockUser;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockStorage = MockFirebaseStorage();
      mockUser = MockUser();

      chatService = ChatService(
        firestore: mockFirestore,
        auth: mockAuth,
        storage: mockStorage,
      );
    });

    group('Authentication', () {
      test('should return current user ID when authenticated', () {
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('test-user-123');

        expect(chatService.currentUserId, equals('test-user-123'));
      });

      test('should throw exception when user not authenticated', () {
        when(mockAuth.currentUser).thenReturn(null);

        expect(() => chatService.currentUserId, throwsException);
      });
    });

    group('MessageModel', () {
      test('should create MessageModel with required fields', () {
        final timestamp = DateTime.now();
        final message = MessageModel(
          id: 'msg-123',
          senderId: 'user-123',
          content: 'Hello world!',
          timestamp: timestamp,
          type: MessageType.text,
        );

        expect(message.id, equals('msg-123'));
        expect(message.senderId, equals('user-123'));
        expect(message.content, equals('Hello world!'));
        expect(message.timestamp, equals(timestamp));
        expect(message.type, equals(MessageType.text));
        expect(message.isRead, isFalse); // default value
      });

      test('should convert MessageModel to Map', () {
        final timestamp = DateTime.now();
        final message = MessageModel(
          id: 'msg-123',
          senderId: 'user-123',
          content: 'Hello world!',
          timestamp: timestamp,
          type: MessageType.text,
          isRead: true,
        );

        final map = message.toMap();

        expect(map['id'], equals('msg-123'));
        expect(map['senderId'], equals('user-123'));
        expect(map['content'], equals('Hello world!'));
        expect(map['type'], equals('MessageType.text'));
        expect(map['isRead'], isTrue);
      });

      test('should create MessageModel from Map', () {
        final timestamp = DateTime.now();
        final map = {
          'id': 'msg-123',
          'senderId': 'user-123',
          'content': 'Hello world!',
          'timestamp': Timestamp.fromDate(timestamp),
          'type': 'MessageType.text',
          'isRead': true,
        };

        final message = MessageModel.fromMap(map);

        expect(message.id, equals('msg-123'));
        expect(message.senderId, equals('user-123'));
        expect(message.content, equals('Hello world!'));
        expect(message.type, equals(MessageType.text));
        expect(message.isRead, isTrue);
      });
    });

    group('ChatModel', () {
      test('should create ChatModel with required fields', () {
        final createdAt = DateTime.now();
        final updatedAt = DateTime.now();

        final chat = ChatModel(
          id: 'chat-123',
          participantIds: ['user-1', 'user-2'],
          createdAt: createdAt,
          updatedAt: updatedAt,
          unreadCounts: {'user-1': 0, 'user-2': 2},
        );

        expect(chat.id, equals('chat-123'));
        expect(chat.participantIds, equals(['user-1', 'user-2']));
        expect(chat.createdAt, equals(createdAt));
        expect(chat.updatedAt, equals(updatedAt));
        expect(chat.isGroup, isFalse); // default value
        expect(chat.unreadCounts, equals({'user-1': 0, 'user-2': 2}));
      });

      test('should get participant display name from participants data', () {
        final createdAt = DateTime.now();
        final updatedAt = DateTime.now();

        final chat = ChatModel(
          id: 'chat-123',
          participantIds: ['user-1', 'user-2'],
          createdAt: createdAt,
          updatedAt: updatedAt,
          unreadCounts: {'user-1': 0, 'user-2': 2},
          participants: [
            {
              'id': 'user-1',
              'fullName': 'Kristy Kelly',
              'profileImageUrl': 'https://example.com/profile1.jpg',
            },
            {
              'id': 'user-2',
              'fullName': 'izzy piel',
              'profileImageUrl': 'https://example.com/profile2.jpg',
            },
          ],
        );

        expect(
          chat.getParticipantDisplayName('user-1'),
          equals('Kristy Kelly'),
        );
        expect(chat.getParticipantDisplayName('user-2'), equals('izzy piel'));
        expect(
          chat.getParticipantDisplayName('unknown-user'),
          equals('Unknown User'),
        );
        expect(
          chat.getParticipantPhotoUrl('user-1'),
          equals('https://example.com/profile1.jpg'),
        );
        expect(
          chat.getParticipantPhotoUrl('user-2'),
          equals('https://example.com/profile2.jpg'),
        );
        expect(chat.getParticipantPhotoUrl('unknown-user'), isNull);
      });
    });

    group('Service Methods', () {
      test('refresh should complete without error', () async {
        await expectLater(chatService.refresh(), completes);
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:artbeat_messaging/artbeat_messaging.dart';
import 'package:mockito/mockito.dart';
import 'artbeat_messaging_test.mocks.dart';

void main() {
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

    test('typing indicators', () async {
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

      // Test getTypingStatus
      await fakeFirestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc('status')
          .set({'user1': true, 'user2': false});

      final typingStatus = await chatService.getTypingStatus(chatId).first;
      expect(typingStatus['user1'], true);
      expect(typingStatus['user2'], false);

      // Test updateTypingStatus
      await chatService.updateTypingStatus(chatId, userId, true);

      // Wait for the typing status to be set
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Get the typing status and verify it was set
      final status = await chatService.getTypingStatus(chatId).first;
      expect(status[userId], true);

      // Test clearTypingStatus
      await chatService.clearTypingStatus(chatId, userId);
      await Future<void>.delayed(Duration.zero);
      final clearedStatus = await chatService.getTypingStatus(chatId).first;
      expect(clearedStatus[userId], null);
    });
  });
}

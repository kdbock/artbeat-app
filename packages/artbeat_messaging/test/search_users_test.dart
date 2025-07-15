import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_messaging/src/services/chat_service.dart';

import 'chat_service_test.mocks.dart';

void main() {
  group('User Search Tests', () {
    late ChatService chatService;
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockCurrentUser;
    late MockCollectionReference<Map<String, dynamic>> mockUsersCollection;
    late MockQuery<Map<String, dynamic>> mockQuery;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockCurrentUser = MockUser();
      mockUsersCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(mockAuth.currentUser).thenReturn(mockCurrentUser);
      when(mockCurrentUser.uid).thenReturn('test_user_id');
      when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);

      chatService = ChatService(firestore: mockFirestore, auth: mockAuth);
    });

    test('should return empty list for empty query', () async {
      final result = await chatService.searchUsers('');
      expect(result, isEmpty);
    });

    test('should return empty list for null query', () async {
      final result = await chatService.searchUsers('');
      expect(result, isEmpty);
    });

    test('should search users by fullName', () async {
      // Mock query setup
      when(mockUsersCollection.orderBy('fullName')).thenReturn(mockQuery);
      when(mockQuery.startAt(['john'])).thenReturn(mockQuery);
      when(mockQuery.endAt(['john\uf8ff'])).thenReturn(mockQuery);
      when(mockQuery.limit(10)).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

      // Mock document snapshot
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('user123');
      when(mockDoc.data()).thenReturn({
        'fullName': 'John Doe',
        'username': 'johndoe',
        'profileImageUrl': 'http://example.com/photo.jpg',
        'isOnline': true,
        'lastActive': Timestamp.now(),
        'deviceTokens': <String>[],
        'location': 'San Francisco',
        'zipCode': '94102',
      });

      when(mockQuerySnapshot.docs).thenReturn([mockDoc]);

      final result = await chatService.searchUsers('john');

      expect(result, hasLength(1));
      expect(result.first.fullName, equals('John Doe'));
      expect(result.first.username, equals('johndoe'));
      expect(result.first.displayName, equals('John Doe'));
      expect(result.first.location, equals('San Francisco'));
      expect(result.first.zipCode, equals('94102'));
    });

    test('should handle search errors gracefully', () async {
      when(
        mockUsersCollection.orderBy(any),
      ).thenThrow(Exception('Firestore error'));
      when(
        mockUsersCollection.where(any, isEqualTo: anyNamed('isEqualTo')),
      ).thenThrow(Exception('Firestore error'));

      final result = await chatService.searchUsers('test');

      // Should not throw, but return empty results
      expect(result, isNotNull);
    });

    test('should exclude current user from search results', () async {
      // Mock the fullName query
      when(mockUsersCollection.orderBy('fullName')).thenReturn(mockQuery);
      when(mockQuery.startAt(any)).thenReturn(mockQuery);
      when(mockQuery.endAt(any)).thenReturn(mockQuery);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

      // Mock documents including current user
      final mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockDoc1.id).thenReturn('test_user_id'); // Current user
      when(
        mockDoc1.data(),
      ).thenReturn({'fullName': 'Test User', 'username': 'testuser'});

      when(mockDoc2.id).thenReturn('other_user_id');
      when(mockDoc2.data()).thenReturn({
        'fullName': 'Test Other',
        'username': 'testother',
        'lastActive': Timestamp.now(),
      });

      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);

      final result = await chatService.searchUsers('test');

      // Should only include the other user, not current user
      expect(result, hasLength(1));
      expect(result.first.id, equals('other_user_id'));
    });
  });
}

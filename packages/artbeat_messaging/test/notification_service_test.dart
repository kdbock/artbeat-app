import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:artbeat_messaging/artbeat_messaging.dart';
import 'package:mockito/mockito.dart';
import 'artbeat_messaging_test.mocks.dart';

class MockMessaging extends Mock implements FirebaseMessaging {
  @override
  Future<String?> getToken({String? vapidKey}) async => 'test-fcm-token';

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
  }) async {
    return MockSettings();
  }

  @override
  Stream<String> get onTokenRefresh => Stream.value('test-fcm-token');
}

class MockSettings extends Mock implements NotificationSettings {
  @override
  AuthorizationStatus get authorizationStatus => AuthorizationStatus.authorized;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late TestMockUser testUser;
    late NotificationService notificationService;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      testUser = TestMockUser();

      when(mockAuth.currentUser).thenReturn(testUser);
      when(testUser.uid).thenReturn('test-user-id');

      notificationService = NotificationService(
        firestore: fakeFirestore,
        auth: mockAuth,
        messaging: MockMessaging(),
      );
    });

    test('markNotificationAsRead updates notification document', () async {
      final notificationId = 'test-notification';

      // Create test notification
      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('notifications')
          .doc(notificationId)
          .set({
            'isRead': false,
            'title': 'Test',
            'body': 'Test notification',
            'timestamp': FieldValue.serverTimestamp(),
          });

      await notificationService.markNotificationAsRead(notificationId);

      final notificationDoc =
          await fakeFirestore
              .collection('users')
              .doc('test-user-id')
              .collection('notifications')
              .doc(notificationId)
              .get();

      expect(notificationDoc.data()?['isRead'], true);
    });

    test('getUnreadNotificationsCount returns correct count', () async {
      // Add some test notifications
      final notificationsRef = fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .collection('notifications');

      await notificationsRef.add({
        'isRead': false,
        'title': 'Test 1',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await notificationsRef.add({
        'isRead': false,
        'title': 'Test 2',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await notificationsRef.add({
        'isRead': true,
        'title': 'Test 3',
        'timestamp': FieldValue.serverTimestamp(),
      });

      final count =
          await notificationService.getUnreadNotificationsCount().first;

      expect(count, 2);
    });
  });
}

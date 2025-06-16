import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:artbeat_art_walk/src/services/testable_achievement_service.dart';

void main() {
  group('AchievementService Tests', () {
    late TestableAchievementService achievementService;
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = FakeFirebaseFirestore();
      achievementService = TestableAchievementService(
        auth: mockAuth,
        firestore: mockFirestore,
      );
    });

    test('Initial setup', () {
      expect(achievementService, isNotNull);
    });
  });
}

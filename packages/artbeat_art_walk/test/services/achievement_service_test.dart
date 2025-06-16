import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

void main() {
  group('AchievementService Tests', () {
    late AchievementService achievementService;
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = FakeFirebaseFirestore();
      achievementService = AchievementService();
    });

    test('retrieves user achievements correctly', () async {
      final mockUser = MockUser(
        uid: 'test-user-id',
        email: 'test@example.com',
      );
      await mockAuth.signInWithCustomToken('test-token');

      // Add test achievement
      await mockFirestore
          .collection('users')
          .doc(mockUser.uid)
          .collection('achievements')
          .doc('first_walk_achievement')
          .set({
        'id': 'first_walk_achievement',
        'userId': mockUser.uid,
        'type': AchievementType.firstWalk.name,
        'earnedAt': DateTime.now().toIso8601String(),
        'isNew': true,
        'metadata': {
          'walkId': 'test-walk-id',
          'walkName': 'Test Walk',
        },
      });

      final achievements = await achievementService.getUserAchievements(
        userId: mockUser.uid,
      );

      expect(achievements, isNotEmpty);
      expect(achievements.first.type, equals(AchievementType.firstWalk));
    });

    test('retrieves unviewed achievements correctly', () async {
      final mockUser = MockUser(uid: 'test-user-id');
      await mockAuth.signInWithCustomToken('test-token');

      final achievements = await achievementService.getUnviewedAchievements(
        userId: mockUser.uid,
      );

      expect(achievements, isEmpty);
    });

    test('throws error when user is not authenticated', () {
      expect(
        () => achievementService.getUserAchievements(),
        throwsA(isA<Exception>()),
      );
    });

    test('marks achievement as viewed successfully', () async {
      final mockUser = MockUser(uid: 'test-user-id');
      await mockAuth.signInWithCustomToken('test-token');

      const achievementId = 'test_achievement';
      await mockFirestore
          .collection('users')
          .doc(mockUser.uid)
          .collection('achievements')
          .doc(achievementId)
          .set({
        'id': achievementId,
        'userId': mockUser.uid,
        'type': AchievementType.firstWalk.name,
        'earnedAt': DateTime.now().toIso8601String(),
        'isNew': true,
        'metadata': {
          'walkId': 'test-walk-id',
          'walkName': 'Test Walk',
        },
      });

      final success = await achievementService.markAchievementAsViewed(
        achievementId,
        userId: mockUser.uid,
      );

      expect(success, isTrue);
    });
  });
}

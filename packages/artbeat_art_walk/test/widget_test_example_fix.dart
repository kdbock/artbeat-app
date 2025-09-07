// Example of how to fix the failing widget tests
// Replace your current widget test setup with this pattern:

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'test_utils.dart';

void main() {
  group('Fixed Widget Tests Example', () {
    setUpAll(() async {
      // Initialize Firebase for all tests
      await TestUtils.initializeFirebaseForTesting();
    });

    testWidgets('Should display loading screen initially', (tester) async {
      final artWalk = ArtWalkModel(
        id: 'test-walk-id',
        title: 'Test Art Walk',
        description: 'A test art walk',
        userId: 'test-user',
        createdAt: DateTime.now(),
        artworkIds: ['art1', 'art2'],
        isPublic: true,
        tags: [],
        zipCode: 'test-region',
        difficulty: 'easy',
        estimatedDuration: 60.0,
        estimatedDistance: 1000.0,
        viewCount: 0,
      );

      // Use the test wrapper instead of MaterialApp directly
      await tester.pumpWidget(
        TestUtils.createTestWidgetWrapper(
          child: EnhancedArtWalkExperienceScreen(
            artWalkId: 'test-walk-id',
            artWalk: artWalk,
          ),
        ),
      );

      // Now the test should work without provider errors
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test Art Walk'), findsOneWidget);
    });
  });
}

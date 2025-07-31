import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

void main() {
  group('Enhanced Art Walk Experience Simple Tests', () {
    testWidgets('Should display loading screen initially', (tester) async {
      final artWalk = ArtWalkModel(
        id: 'test-walk-id',
        title: 'Test Art Walk',
        description: 'A test art walk',
        userId: 'test-user-id',
        createdAt: DateTime.now(),
        artworkIds: ['art1', 'art2'],
        isPublic: true,
        tags: [],
        zipCode: 'test-region',
        estimatedDuration: 60.0, // Duration in minutes
        estimatedDistance: 1000.0, // Distance in miles
        viewCount: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedArtWalkExperienceScreen(
            artWalkId: 'test-walk-id',
            artWalk: artWalk,
          ),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test Art Walk'), findsOneWidget);
    });

    testWidgets('Should have proper app bar title', (tester) async {
      final artWalk = ArtWalkModel(
        id: 'test-walk-id',
        title: 'My Amazing Art Walk',
        description: 'A test art walk',
        userId: 'test-user-id',
        createdAt: DateTime.now(),
        artworkIds: ['art1', 'art2'],
        isPublic: true,
        tags: [],
        zipCode: 'test-region',
        estimatedDuration: 60.0, // Duration in minutes
        estimatedDistance: 1000.0, // Distance in miles
        viewCount: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedArtWalkExperienceScreen(
            artWalkId: 'test-walk-id',
            artWalk: artWalk,
          ),
        ),
      );

      // Should show the art walk title in the app bar
      expect(find.text('My Amazing Art Walk'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Should have info button in app bar', (tester) async {
      final artWalk = ArtWalkModel(
        id: 'test-walk-id',
        title: 'Test Art Walk',
        description: 'A test art walk',
        userId: 'test-user-id',
        createdAt: DateTime.now(),
        artworkIds: ['art1', 'art2'],
        isPublic: true,
        tags: [],
        zipCode: 'test-region',
        estimatedDuration: 60.0, // Duration in minutes
        estimatedDistance: 1000.0, // Distance in miles
        viewCount: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedArtWalkExperienceScreen(
            artWalkId: 'test-walk-id',
            artWalk: artWalk,
          ),
        ),
      );

      // Should have info button in app bar
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}

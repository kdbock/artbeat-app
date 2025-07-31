import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:artbeat_art_walk/artbeat_art_walk.dart';

import 'enhanced_art_walk_experience_test.mocks.dart';

@GenerateMocks([ArtWalkService, ArtWalkNavigationService])
void main() {
  group('Enhanced Art Walk Experience Tests', () {
    late MockArtWalkService mockArtWalkService;

    setUp(() {
      mockArtWalkService = MockArtWalkService();
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
        estimatedDuration: 60.0, // Duration in minutes
        estimatedDistance: 1000.0,
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

    testWidgets('Should show navigation button when not in navigation mode', (
      tester,
    ) async {
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
        estimatedDuration: 60.0, // Duration in minutes
        estimatedDistance: 1000.0,
        viewCount: 0,
      );

      // Mock the services to return empty data to avoid loading state
      when(mockArtWalkService.getArtInWalk(any)).thenAnswer((_) async => []);
      when(
        mockArtWalkService.getUserVisitedArt(any),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedArtWalkExperienceScreen(
            artWalkId: 'test-walk-id',
            artWalk: artWalk,
          ),
        ),
      );

      // Wait for the widget to finish loading
      await tester.pumpAndSettle();

      // Should show start navigation button when not in navigation mode
      expect(find.text('Start Navigation'), findsOneWidget);
    });

    testWidgets('Should show info dialog when info button is tapped', (
      tester,
    ) async {
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
        estimatedDuration: 60.0, // Duration in minutes
        estimatedDistance: 1000.0,
        viewCount: 0,
      );

      // Mock the services
      when(mockArtWalkService.getArtInWalk(any)).thenAnswer((_) async => []);
      when(
        mockArtWalkService.getUserVisitedArt(any),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedArtWalkExperienceScreen(
            artWalkId: 'test-walk-id',
            artWalk: artWalk,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the info button
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      // Should show the info dialog
      expect(find.text('How to Use'), findsOneWidget);
      expect(find.text('• Follow the blue route line'), findsOneWidget);
      expect(find.text('• Green markers = visited'), findsOneWidget);
    });
  });
}

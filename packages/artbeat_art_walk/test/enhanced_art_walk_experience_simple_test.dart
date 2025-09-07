import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart' show EnhancedUniversalHeader;
import 'enhanced_art_walk_experience_test.mocks.dart';

void main() {
  group('Enhanced Art Walk Experience Simple Tests', () {
    late MockArtWalkService mockArtWalkService;

    setUp(() {
      mockArtWalkService = MockArtWalkService();

      // Setup default mock responses
      when(mockArtWalkService.getArtInWalk(any)).thenAnswer((_) async => []);
      when(
        mockArtWalkService.getUserVisitedArt(any),
      ).thenAnswer((_) async => []);
    });
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
            artWalkService: mockArtWalkService,
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
            artWalkService: mockArtWalkService,
          ),
        ),
      );

      // Wait for the widget to load
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show the art walk title in the header
      expect(find.text('My Amazing Art Walk'), findsOneWidget);
      // The screen uses EnhancedUniversalHeader instead of AppBar
      expect(find.byType(EnhancedUniversalHeader), findsOneWidget);
    });

    testWidgets('Should render without crashing', (tester) async {
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
            artWalkService: mockArtWalkService,
          ),
        ),
      );

      // Wait for the widget to load
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should render the basic structure without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(EnhancedArtWalkExperienceScreen), findsOneWidget);
    });
  });
}

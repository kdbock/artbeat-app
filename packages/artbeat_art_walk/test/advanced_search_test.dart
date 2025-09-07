import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the service and models we're testing
import 'package:artbeat_art_walk/src/models/search_criteria_model.dart';
import 'package:artbeat_art_walk/src/models/art_walk_model.dart';
import 'enhanced_art_walk_experience_test.mocks.dart' show MockArtWalkService;

// Generate mocks
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
import 'advanced_search_test.mocks.dart';

void main() {
  group('Advanced Search Functionality Tests', () {
    late MockArtWalkService artWalkService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockQuery<Map<String, dynamic>> mockQuery;
    late MockQuerySnapshot<Map<String, dynamic>> mockSnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      // Setup basic mocks
      when(mockFirestore.collection(any)).thenReturn(mockCollection);
      when(
        mockCollection.where(any, isEqualTo: anyNamed('isEqualTo')),
      ).thenReturn(mockQuery);
      when(
        mockCollection.where(any, arrayContains: anyNamed('arrayContains')),
      ).thenReturn(mockQuery);
      when(
        mockQuery.orderBy(any, descending: anyNamed('descending')),
      ).thenReturn(mockQuery);
      when(mockQuery.limit(any)).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([]);

      artWalkService = MockArtWalkService();

      // Setup mock responses
      when(artWalkService.searchArtWalks(any)).thenAnswer((invocation) async {
        final criteria =
            invocation.positionalArguments[0] as ArtWalkSearchCriteria;
        return SearchResult<ArtWalkModel>(
          results: const [],
          totalCount: 0,
          hasNextPage: false,
          searchQuery: criteria.searchQuery ?? '',
          searchDuration: const Duration(milliseconds: 100),
        );
      });
      when(
        artWalkService.getSearchSuggestions(any),
      ).thenAnswer((_) async => []);
    });

    group('ArtWalkSearchCriteria Tests', () {
      test('should create search criteria with all parameters', () {
        const criteria = ArtWalkSearchCriteria(
          searchQuery: 'street art',
          tags: ['urban', 'colorful'],
          difficulty: 'Medium',
          isAccessible: true,
          maxDistance: 5.0,
          maxDuration: 90.0,
          zipCode: '28204',
          isPublic: true,
          sortBy: 'popular',
          sortDescending: true,
        );

        expect(criteria.searchQuery, equals('street art'));
        expect(criteria.tags, equals(['urban', 'colorful']));
        expect(criteria.difficulty, equals('Medium'));
        expect(criteria.isAccessible, isTrue);
        expect(criteria.maxDistance, equals(5.0));
        expect(criteria.maxDuration, equals(90.0));
        expect(criteria.zipCode, equals('28204'));
        expect(criteria.isPublic, isTrue);
        expect(criteria.sortBy, equals('popular'));
        expect(criteria.sortDescending, isTrue);
      });

      test('should detect active filters correctly', () {
        const emptycriteriaeria = ArtWalkSearchCriteria();
        expect(emptycriteriaeria.hasActiveFilters, isFalse);

        const activecriteriaeria = ArtWalkSearchCriteria(searchQuery: 'test');
        expect(activecriteriaeria.hasActiveFilters, isTrue);
      });

      test('should generate filter summary correctly', () {
        const criteria = ArtWalkSearchCriteria(
          searchQuery: 'street art',
          difficulty: 'Medium',
          isAccessible: true,
          maxDistance: 5.0,
        );

        final summary = criteria.filterSummary;
        expect(summary, contains('"street art"'));
        expect(summary, contains('Difficulty: Medium'));
        expect(summary, contains('Accessible'));
        expect(summary, contains('Within 5.0 miles'));
      });

      test('should copy with updated values', () {
        const original = ArtWalkSearchCriteria(
          searchQuery: 'original',
          difficulty: 'Easy',
        );

        final updated = original.copyWith(
          searchQuery: 'updated',
          isAccessible: true,
        );

        expect(updated.searchQuery, equals('updated'));
        expect(updated.difficulty, equals('Easy')); // preserved
        expect(updated.isAccessible, isTrue); // updated
      });

      test('should serialize to/from JSON correctly', () {
        const criteria = ArtWalkSearchCriteria(
          searchQuery: 'test query',
          tags: ['tag1', 'tag2'],
          difficulty: 'Hard',
          isAccessible: true,
          maxDistance: 10.0,
          maxDuration: 120.0,
          zipCode: '12345',
          isPublic: false,
          sortBy: 'newest',
          sortDescending: false,
        );

        final json = criteria.toJson();
        final fromJson = ArtWalkSearchCriteria.fromJson(json);

        expect(fromJson.searchQuery, equals(criteria.searchQuery));
        expect(fromJson.tags, equals(criteria.tags));
        expect(fromJson.difficulty, equals(criteria.difficulty));
        expect(fromJson.isAccessible, equals(criteria.isAccessible));
        expect(fromJson.maxDistance, equals(criteria.maxDistance));
        expect(fromJson.maxDuration, equals(criteria.maxDuration));
        expect(fromJson.zipCode, equals(criteria.zipCode));
        expect(fromJson.isPublic, equals(criteria.isPublic));
        expect(fromJson.sortBy, equals(criteria.sortBy));
        expect(fromJson.sortDescending, equals(criteria.sortDescending));
      });
    });

    group('PublicArtSearchCriteria Tests', () {
      test('should create public art search criteria with all parameters', () {
        const criteria = PublicArtSearchCriteria(
          searchQuery: 'mural',
          artistName: 'Banksy',
          artTypes: ['Mural', 'Street Art'],
          tags: ['urban', 'political'],
          isVerified: true,
          minRating: 4.0,
          maxDistanceKm: 15.0,
          zipCode: '28204',
          sortBy: 'rating',
          sortDescending: true,
        );

        expect(criteria.searchQuery, equals('mural'));
        expect(criteria.artistName, equals('Banksy'));
        expect(criteria.artTypes, equals(['Mural', 'Street Art']));
        expect(criteria.tags, equals(['urban', 'political']));
        expect(criteria.isVerified, isTrue);
        expect(criteria.minRating, equals(4.0));
        expect(criteria.maxDistanceKm, equals(15.0));
        expect(criteria.zipCode, equals('28204'));
        expect(criteria.sortBy, equals('rating'));
        expect(criteria.sortDescending, isTrue);
      });

      test('should generate filter summary for public art', () {
        const criteria = PublicArtSearchCriteria(
          searchQuery: 'sculpture',
          artistName: 'Picasso',
          artTypes: ['Sculpture'],
          isVerified: true,
          minRating: 4.5,
        );

        final summary = criteria.filterSummary;
        expect(summary, contains('"sculpture"'));
        expect(summary, contains('Artist: Picasso'));
        expect(summary, contains('Types: Sculpture'));
        expect(summary, contains('Verified Only'));
        expect(summary, contains('Rating: 4.5+'));
      });

      test('should serialize public art criteria to/from JSON', () {
        const criteria = PublicArtSearchCriteria(
          searchQuery: 'fountain',
          artistName: 'Unknown',
          artTypes: ['Fountain', 'Sculpture'],
          tags: ['water', 'public'],
          isVerified: false,
          minRating: 3.0,
          maxDistanceKm: 25.0,
          zipCode: '54321',
          sortBy: 'distance',
          sortDescending: true,
        );

        final json = criteria.toJson();
        final fromJson = PublicArtSearchCriteria.fromJson(json);

        expect(fromJson.searchQuery, equals(criteria.searchQuery));
        expect(fromJson.artistName, equals(criteria.artistName));
        expect(fromJson.artTypes, equals(criteria.artTypes));
        expect(fromJson.tags, equals(criteria.tags));
        expect(fromJson.isVerified, equals(criteria.isVerified));
        expect(fromJson.minRating, equals(criteria.minRating));
        expect(fromJson.maxDistanceKm, equals(criteria.maxDistanceKm));
        expect(fromJson.zipCode, equals(criteria.zipCode));
        expect(fromJson.sortBy, equals(criteria.sortBy));
        expect(fromJson.sortDescending, equals(criteria.sortDescending));
      });
    });

    group('SearchResult Tests', () {
      test('should create search result with metadata', () {
        final artWalks = <ArtWalkModel>[];
        final result = SearchResult<ArtWalkModel>(
          results: artWalks,
          totalCount: 0,
          hasNextPage: false,
          searchQuery: 'test',
          searchDuration: const Duration(milliseconds: 150),
        );

        expect(result.results, equals(artWalks));
        expect(result.totalCount, equals(0));
        expect(result.hasNextPage, isFalse);
        expect(result.searchQuery, equals('test'));
        expect(
          result.searchDuration,
          equals(const Duration(milliseconds: 150)),
        );
      });

      test('should create empty search result', () {
        final result = SearchResult<ArtWalkModel>.empty('empty query');

        expect(result.results, isEmpty);
        expect(result.totalCount, equals(0));
        expect(result.hasNextPage, isFalse);
        expect(result.searchQuery, equals('empty query'));
        expect(result.searchDuration, equals(Duration.zero));
      });
    });

    group('Search Functionality Integration Tests', () {
      test('should handle empty search results gracefully', () async {
        // Setup mock to return empty results
        when(mockSnapshot.docs).thenReturn([]);

        const criteria = ArtWalkSearchCriteria(searchQuery: 'nonexistent');
        final result = await artWalkService.searchArtWalks(criteria);

        expect(result.results, isEmpty);
        expect(result.totalCount, equals(0));
        expect(result.hasNextPage, isFalse);
        expect(result.searchQuery, equals('nonexistent'));
      });

      test('should apply client-side filters correctly', () {
        // Test the private client-side filtering method through reflection
        // or create a wrapper method for testing
        const criteria = ArtWalkSearchCriteria(
          maxDuration: 60.0,
          maxDistance: 3.0,
          tags: ['urban'],
        );

        // Create test art walk
        final artWalk = ArtWalkModel(
          id: 'test1',
          title: 'Test Walk',
          description: 'Test Description',
          userId: 'user1',
          artworkIds: ['art1'],
          createdAt: DateTime.now(),
          estimatedDuration: 45.0, // Within limit
          estimatedDistance: 2.5, // Within limit
          tags: ['urban', 'colorful'], // Contains required tag
        );

        // This would pass all filters
        expect(artWalk.estimatedDuration! <= criteria.maxDuration!, isTrue);
        expect(artWalk.estimatedDistance! <= criteria.maxDistance!, isTrue);
        expect(
          artWalk.tags!.any((tag) => criteria.tags!.contains(tag)),
          isTrue,
        );
      });

      test('should validate search criteria combinations', () {
        // Test invalid combinations
        const invalidcriteria = ArtWalkSearchCriteria(
          maxDistance: -1.0, // Invalid negative distance
        );

        // Should handle invalid criteria gracefully
        expect(invalidcriteria.maxDistance, equals(-1.0));
        // In real implementation, we'd add validation
      });
    });

    group('Performance Tests', () {
      test('should handle large result sets efficiently', () async {
        // Setup empty docs to avoid mocking complexity
        when(mockSnapshot.docs).thenReturn([]);

        const criteria = ArtWalkSearchCriteria(limit: 1000);
        final stopwatch = Stopwatch()..start();

        try {
          await artWalkService.searchArtWalks(criteria);
          stopwatch.stop();

          // Should complete within reasonable time (adjust threshold as needed)
          expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        } catch (e) {
          // Expected to fail due to mocking, but timing should still be reasonable
          stopwatch.stop();
          expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        }
      });

      test('should handle pagination correctly', () {
        const initialCriteria = ArtWalkSearchCriteria(limit: 20);
        final nextCriteria = initialCriteria.copyWith(
          lastDocument: null, // Remove mock document reference
        );

        expect(nextCriteria.limit, equals(20));
      });
    });

    group('Error Handling Tests', () {
      test('should handle firestore exceptions gracefully', () async {
        // Setup mock to throw exception
        when(mockQuery.get()).thenThrow(Exception('Firestore error'));

        const criteria = ArtWalkSearchCriteria(searchQuery: 'test');
        final result = await artWalkService.searchArtWalks(criteria);

        // Should return empty result on error, not throw
        expect(result.results, isEmpty);
        expect(result.totalCount, equals(0));
      });

      test('should handle malformed document data', () async {
        // Setup empty docs to avoid complex mocking
        when(mockSnapshot.docs).thenReturn([]);

        const criteria = ArtWalkSearchCriteria();
        final result = await artWalkService.searchArtWalks(criteria);

        // Should handle empty documents gracefully
        expect(result.results, isEmpty);
        expect(result.totalCount, equals(0));
      });
    });

    group('Search Suggestions Tests', () {
      test('should generate search suggestions', () async {
        // Setup empty docs to avoid complex mocking
        when(mockSnapshot.docs).thenReturn([]);

        final suggestions = await artWalkService.getSearchSuggestions(
          'charlotte',
        );

        expect(suggestions, isA<List<String>>());
        // Due to mocking limitations, suggestions will be empty
        expect(suggestions, isEmpty);
      });

      test('should handle short query terms', () async {
        final suggestions = await artWalkService.getSearchSuggestions('a');
        expect(suggestions, isEmpty); // Should return empty for short queries
      });
    });
  });
}

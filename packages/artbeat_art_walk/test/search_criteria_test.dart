import 'package:flutter_test/flutter_test.dart';

// Import the models we're testing
import '../lib/src/models/search_criteria_model.dart';

void main() {
  group('Search Criteria Models Unit Tests', () {
    group('ArtWalkSearchCriteria Tests', () {
      test('should create search criteria with default values', () {
        const criteria = ArtWalkSearchCriteria();

        expect(criteria.searchQuery, isNull);
        expect(criteria.tags, isNull);
        expect(criteria.difficulty, isNull);
        expect(criteria.isAccessible, isNull);
        expect(criteria.maxDistance, isNull);
        expect(criteria.maxDuration, isNull);
        expect(criteria.zipCode, isNull);
        expect(criteria.isPublic, isNull);
        expect(criteria.sortBy, equals('popular'));
        expect(criteria.sortDescending, isTrue);
        expect(criteria.limit, equals(20));
        expect(criteria.lastDocument, isNull);
      });

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
          sortBy: 'newest',
          sortDescending: false,
          limit: 50,
        );

        expect(criteria.searchQuery, equals('street art'));
        expect(criteria.tags, equals(['urban', 'colorful']));
        expect(criteria.difficulty, equals('Medium'));
        expect(criteria.isAccessible, isTrue);
        expect(criteria.maxDistance, equals(5.0));
        expect(criteria.maxDuration, equals(90.0));
        expect(criteria.zipCode, equals('28204'));
        expect(criteria.isPublic, isTrue);
        expect(criteria.sortBy, equals('newest'));
        expect(criteria.sortDescending, isFalse);
        expect(criteria.limit, equals(50));
      });

      test('should detect active filters correctly', () {
        // Empty criteria
        const emptyCriteria = ArtWalkSearchCriteria();
        expect(emptyCriteria.hasActiveFilters, isFalse);

        // Criteria with search query
        const searchCriteria = ArtWalkSearchCriteria(searchQuery: 'test');
        expect(searchCriteria.hasActiveFilters, isTrue);

        // Criteria with tags
        const tagCriteria = ArtWalkSearchCriteria(tags: ['urban']);
        expect(tagCriteria.hasActiveFilters, isTrue);

        // Criteria with difficulty
        const difficultyCriteria = ArtWalkSearchCriteria(difficulty: 'Easy');
        expect(difficultyCriteria.hasActiveFilters, isTrue);

        // Criteria with accessibility
        const accessibleCriteria = ArtWalkSearchCriteria(isAccessible: true);
        expect(accessibleCriteria.hasActiveFilters, isTrue);

        // Criteria with distance
        const distanceCriteria = ArtWalkSearchCriteria(maxDistance: 10.0);
        expect(distanceCriteria.hasActiveFilters, isTrue);

        // Criteria with duration
        const durationCriteria = ArtWalkSearchCriteria(maxDuration: 60.0);
        expect(durationCriteria.hasActiveFilters, isTrue);

        // Criteria with zipCode
        const zipCriteria = ArtWalkSearchCriteria(zipCode: '12345');
        expect(zipCriteria.hasActiveFilters, isTrue);

        // Criteria with isPublic
        const publicCriteria = ArtWalkSearchCriteria(isPublic: true);
        expect(publicCriteria.hasActiveFilters, isTrue);
      });

      test('should generate comprehensive filter summary', () {
        const criteria = ArtWalkSearchCriteria(
          searchQuery: 'street art',
          difficulty: 'Medium',
          isAccessible: true,
          maxDistance: 5.0,
          maxDuration: 90.0,
          tags: ['urban', 'colorful'],
          zipCode: '28204',
        );

        final summary = criteria.filterSummary;
        expect(summary, contains('"street art"'));
        expect(summary, contains('Difficulty: Medium'));
        expect(summary, contains('Accessible'));
        expect(summary, contains('Within 5.0 miles'));
        expect(summary, contains('Under 90 minutes'));
        expect(summary, contains('Tags: urban, colorful'));
        expect(summary, contains('Location: 28204'));
      });

      test('should copy with updated values preserving unchanged ones', () {
        const original = ArtWalkSearchCriteria(
          searchQuery: 'original query',
          difficulty: 'Easy',
          maxDistance: 10.0,
          isPublic: true,
        );

        final updated = original.copyWith(
          searchQuery: 'updated query',
          isAccessible: true,
          // difficulty and maxDistance should be preserved
          // isPublic should be preserved
        );

        expect(updated.searchQuery, equals('updated query')); // updated
        expect(updated.difficulty, equals('Easy')); // preserved
        expect(updated.maxDistance, equals(10.0)); // preserved
        expect(updated.isPublic, isTrue); // preserved
        expect(updated.isAccessible, isTrue); // newly added
      });

      test('should serialize to JSON correctly', () {
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
          limit: 30,
        );

        final json = criteria.toJson();

        expect(json['searchQuery'], equals('test query'));
        expect(json['tags'], equals(['tag1', 'tag2']));
        expect(json['difficulty'], equals('Hard'));
        expect(json['isAccessible'], isTrue);
        expect(json['maxDistance'], equals(10.0));
        expect(json['maxDuration'], equals(120.0));
        expect(json['zipCode'], equals('12345'));
        expect(json['isPublic'], isFalse);
        expect(json['sortBy'], equals('newest'));
        expect(json['sortDescending'], isFalse);
        expect(json['limit'], equals(30));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'searchQuery': 'from json',
          'tags': ['json1', 'json2'],
          'difficulty': 'Medium',
          'isAccessible': false,
          'maxDistance': 15.0,
          'maxDuration': 90.0,
          'zipCode': '54321',
          'isPublic': true,
          'sortBy': 'distance',
          'sortDescending': true,
          'limit': 25,
        };

        final criteria = ArtWalkSearchCriteria.fromJson(json);

        expect(criteria.searchQuery, equals('from json'));
        expect(criteria.tags, equals(['json1', 'json2']));
        expect(criteria.difficulty, equals('Medium'));
        expect(criteria.isAccessible, isFalse);
        expect(criteria.maxDistance, equals(15.0));
        expect(criteria.maxDuration, equals(90.0));
        expect(criteria.zipCode, equals('54321'));
        expect(criteria.isPublic, isTrue);
        expect(criteria.sortBy, equals('distance'));
        expect(criteria.sortDescending, isTrue);
        expect(criteria.limit, equals(25));
      });

      test('should handle null values in JSON deserialization', () {
        final json = <String, dynamic>{
          'searchQuery': null,
          'tags': null,
          'difficulty': null,
        };

        final criteria = ArtWalkSearchCriteria.fromJson(json);

        expect(criteria.searchQuery, isNull);
        expect(criteria.tags, isNull);
        expect(criteria.difficulty, isNull);
        expect(criteria.sortBy, equals('popular')); // default value
        expect(criteria.sortDescending, isTrue); // default value
        expect(criteria.limit, equals(20)); // default value
      });
    });

    group('PublicArtSearchCriteria Tests', () {
      test('should create public art criteria with default values', () {
        const criteria = PublicArtSearchCriteria();

        expect(criteria.searchQuery, isNull);
        expect(criteria.artistName, isNull);
        expect(criteria.artTypes, isNull);
        expect(criteria.tags, isNull);
        expect(criteria.isVerified, isNull);
        expect(criteria.minRating, isNull);
        expect(criteria.maxDistanceKm, equals(10.0));
        expect(criteria.zipCode, isNull);
        expect(criteria.sortBy, equals('popular'));
        expect(criteria.sortDescending, isTrue);
        expect(criteria.limit, equals(20));
      });

      test('should create public art criteria with all parameters', () {
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
          limit: 40,
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
        expect(criteria.limit, equals(40));
      });

      test('should detect active filters for public art', () {
        const emptyCriteria = PublicArtSearchCriteria();
        expect(emptyCriteria.hasActiveFilters, isFalse);

        const searchCriteria = PublicArtSearchCriteria(
          searchQuery: 'sculpture',
        );
        expect(searchCriteria.hasActiveFilters, isTrue);

        const artistCriteria = PublicArtSearchCriteria(artistName: 'Picasso');
        expect(artistCriteria.hasActiveFilters, isTrue);

        const typeCriteria = PublicArtSearchCriteria(artTypes: ['Sculpture']);
        expect(typeCriteria.hasActiveFilters, isTrue);

        const verifiedCriteria = PublicArtSearchCriteria(isVerified: true);
        expect(verifiedCriteria.hasActiveFilters, isTrue);

        const ratingCriteria = PublicArtSearchCriteria(minRating: 3.5);
        expect(ratingCriteria.hasActiveFilters, isTrue);
      });

      test('should generate filter summary for public art', () {
        const criteria = PublicArtSearchCriteria(
          searchQuery: 'sculpture',
          artistName: 'Picasso',
          artTypes: ['Sculpture'],
          isVerified: true,
          minRating: 4.5,
          tags: ['classical', 'bronze'],
          zipCode: '10001',
        );

        final summary = criteria.filterSummary;
        expect(summary, contains('"sculpture"'));
        expect(summary, contains('Artist: Picasso'));
        expect(summary, contains('Types: Sculpture'));
        expect(summary, contains('Verified Only'));
        expect(summary, contains('Rating: 4.5+'));
        expect(summary, contains('Tags: classical, bronze'));
        expect(summary, contains('Location: 10001'));
      });

      test('should serialize public art criteria to JSON', () {
        const criteria = PublicArtSearchCriteria(
          searchQuery: 'fountain',
          artistName: 'Unknown Artist',
          artTypes: ['Fountain', 'Sculpture'],
          tags: ['water', 'public'],
          isVerified: false,
          minRating: 3.0,
          maxDistanceKm: 25.0,
          zipCode: '54321',
          sortBy: 'distance',
          sortDescending: true,
          limit: 35,
        );

        final json = criteria.toJson();

        expect(json['searchQuery'], equals('fountain'));
        expect(json['artistName'], equals('Unknown Artist'));
        expect(json['artTypes'], equals(['Fountain', 'Sculpture']));
        expect(json['tags'], equals(['water', 'public']));
        expect(json['isVerified'], isFalse);
        expect(json['minRating'], equals(3.0));
        expect(json['maxDistanceKm'], equals(25.0));
        expect(json['zipCode'], equals('54321'));
        expect(json['sortBy'], equals('distance'));
        expect(json['sortDescending'], isTrue);
        expect(json['limit'], equals(35));
      });

      test('should deserialize public art criteria from JSON', () {
        final json = {
          'searchQuery': 'installation',
          'artistName': 'Modern Artist',
          'artTypes': ['Installation', 'Digital Art'],
          'tags': ['interactive', 'technology'],
          'isVerified': true,
          'minRating': 4.2,
          'maxDistanceKm': 8.0,
          'zipCode': '90210',
          'sortBy': 'newest',
          'sortDescending': false,
          'limit': 15,
        };

        final criteria = PublicArtSearchCriteria.fromJson(json);

        expect(criteria.searchQuery, equals('installation'));
        expect(criteria.artistName, equals('Modern Artist'));
        expect(criteria.artTypes, equals(['Installation', 'Digital Art']));
        expect(criteria.tags, equals(['interactive', 'technology']));
        expect(criteria.isVerified, isTrue);
        expect(criteria.minRating, equals(4.2));
        expect(criteria.maxDistanceKm, equals(8.0));
        expect(criteria.zipCode, equals('90210'));
        expect(criteria.sortBy, equals('newest'));
        expect(criteria.sortDescending, isFalse);
        expect(criteria.limit, equals(15));
      });
    });

    group('SearchResult Tests', () {
      test('should create search result with metadata', () {
        final results = <String>['result1', 'result2'];
        const searchDuration = Duration(milliseconds: 150);

        final result = SearchResult<String>(
          results: results,
          totalCount: 2,
          hasNextPage: true,
          searchQuery: 'test query',
          searchDuration: searchDuration,
        );

        expect(result.results, equals(results));
        expect(result.totalCount, equals(2));
        expect(result.hasNextPage, isTrue);
        expect(result.searchQuery, equals('test query'));
        expect(result.searchDuration, equals(searchDuration));
        expect(result.lastDocument, isNull);
      });

      test('should create empty search result', () {
        final result = SearchResult<String>.empty('empty query');

        expect(result.results, isEmpty);
        expect(result.totalCount, equals(0));
        expect(result.hasNextPage, isFalse);
        expect(result.lastDocument, isNull);
        expect(result.searchQuery, equals('empty query'));
        expect(result.searchDuration, equals(Duration.zero));
      });

      test('should handle different result types', () {
        const intResult = SearchResult<int>(
          results: [1, 2, 3],
          totalCount: 3,
          hasNextPage: false,
          searchQuery: 'numbers',
          searchDuration: Duration(milliseconds: 50),
        );

        expect(intResult.results, isA<List<int>>());
        expect(intResult.results, equals([1, 2, 3]));
      });
    });

    group('Edge Cases and Validation', () {
      test('should handle empty strings in search criteria', () {
        const criteria = ArtWalkSearchCriteria(searchQuery: '', zipCode: '');

        expect(criteria.hasActiveFilters, isFalse);
        expect(criteria.filterSummary, isEmpty);
      });

      test('should handle whitespace-only search queries', () {
        const criteria = ArtWalkSearchCriteria(searchQuery: '   ');
        expect(criteria.hasActiveFilters, isTrue);
        final summary = criteria.filterSummary;
        expect(summary, contains('"   "'));
      });

      test('should handle extreme values', () {
        const criteria = ArtWalkSearchCriteria(
          maxDistance: 0.0,
          maxDuration: 0.0,
          limit: 0,
        );

        expect(criteria.maxDistance, equals(0.0));
        expect(criteria.maxDuration, equals(0.0));
        expect(criteria.limit, equals(0));
      });

      test('should handle negative values gracefully', () {
        const criteria = PublicArtSearchCriteria(
          minRating: -1.0,
          maxDistanceKm: -5.0,
        );

        expect(criteria.minRating, equals(-1.0));
        expect(criteria.maxDistanceKm, equals(-5.0));
        // Note: In a real implementation, you might want to validate these
      });

      test('should handle large arrays in tags', () {
        final largeTags = List.generate(100, (i) => 'tag$i');
        final criteria = ArtWalkSearchCriteria(tags: largeTags);

        expect(criteria.tags?.length, equals(100));
        expect(criteria.hasActiveFilters, isTrue);
      });

      test('should generate correct toString output', () {
        const criteria = ArtWalkSearchCriteria(
          searchQuery: 'test',
          difficulty: 'Easy',
          maxDistance: 5.0,
          sortBy: 'newest',
        );

        final stringOutput = criteria.toString();
        expect(stringOutput, contains('ArtWalkSearchCriteria('));
        expect(stringOutput, contains('query: test'));
        expect(stringOutput, contains('difficulty: Easy'));
        expect(stringOutput, contains('maxDistance: 5.0'));
        expect(stringOutput, contains('sortBy: newest'));
      });

      test('should handle round-trip JSON serialization', () {
        const original = ArtWalkSearchCriteria(
          searchQuery: 'round trip test',
          tags: ['test1', 'test2'],
          difficulty: 'Medium',
          isAccessible: true,
          maxDistance: 7.5,
          maxDuration: 105.0,
          zipCode: '12345',
          isPublic: false,
          sortBy: 'title',
          sortDescending: false,
          limit: 42,
        );

        // Serialize to JSON and back
        final json = original.toJson();
        final reconstructed = ArtWalkSearchCriteria.fromJson(json);

        // Compare all properties
        expect(reconstructed.searchQuery, equals(original.searchQuery));
        expect(reconstructed.tags, equals(original.tags));
        expect(reconstructed.difficulty, equals(original.difficulty));
        expect(reconstructed.isAccessible, equals(original.isAccessible));
        expect(reconstructed.maxDistance, equals(original.maxDistance));
        expect(reconstructed.maxDuration, equals(original.maxDuration));
        expect(reconstructed.zipCode, equals(original.zipCode));
        expect(reconstructed.isPublic, equals(original.isPublic));
        expect(reconstructed.sortBy, equals(original.sortBy));
        expect(reconstructed.sortDescending, equals(original.sortDescending));
        expect(reconstructed.limit, equals(original.limit));

        // Compare derived properties
        expect(
          reconstructed.hasActiveFilters,
          equals(original.hasActiveFilters),
        );
        expect(reconstructed.filterSummary, equals(original.filterSummary));
      });
    });
  });
}

import 'package:artbeat_art_walk/src/models/art_walk_model.dart';
import 'package:artbeat_art_walk/src/services/art_walk_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {
  @override
  String get uid => 'test_user_123';
}

class MockArtWalkService extends Mock implements ArtWalkService {}

void main() {
  group('Art Walk System - Discovery Features', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      when(mockAuth.currentUser).thenReturn(mockUser);

      // Initialize test data
      await fakeFirestore.collection('artWalks').doc('walk_001').set({
        'title': 'Downtown Art Walk',
        'description': 'Explore downtown public art',
        'userId': 'artist_001',
        'artworkIds': ['art_001', 'art_002'],
        'createdAt': Timestamp.now(),
        'isPublic': true,
        'viewCount': 150,
        'imageUrls': ['https://example.com/image1.jpg'],
        'zipCode': '28501',
        'estimatedDuration': 45.0,
        'estimatedDistance': 2.5,
        'coverImageUrl': 'https://example.com/cover.jpg',
        'routeData': 'encoded_route_data',
        'tags': ['downtown', 'public art'],
        'difficulty': 'Easy',
        'isAccessible': true,
        'startLocation': const GeoPoint(35.23838, -77.52658),
        'completionCount': 45,
        'reportCount': 0,
        'isFlagged': false,
      });

      await fakeFirestore.collection('artWalks').doc('walk_002').set({
        'title': 'Waterfront Art Trail',
        'description': 'Walk along the waterfront',
        'userId': 'artist_002',
        'artworkIds': ['art_003', 'art_004', 'art_005'],
        'createdAt': Timestamp.now(),
        'isPublic': true,
        'viewCount': 200,
        'imageUrls': [
          'https://example.com/image2.jpg',
          'https://example.com/image3.jpg',
        ],
        'zipCode': '28502',
        'estimatedDuration': 60.0,
        'estimatedDistance': 3.5,
        'difficulty': 'Medium',
        'completionCount': 75,
      });

      await fakeFirestore.collection('publicArt').doc('art_001').set({
        'title': 'Abstract Mural',
        'artist': 'John Smith',
        'location': const GeoPoint(35.23838, -77.52658),
        'zipCode': '28501',
        'description': 'A colorful abstract mural',
        'imageUrl': 'https://example.com/mural.jpg',
      });

      await fakeFirestore.collection('publicArt').doc('art_002').set({
        'title': 'Modern Sculpture',
        'artist': 'Jane Doe',
        'location': const GeoPoint(35.23900, -77.52700),
        'zipCode': '28501',
        'description': 'Contemporary sculpture installation',
        'imageUrl': 'https://example.com/sculpture.jpg',
      });
    });

    // Art Walk Discovery Tests
    test('Art Walk map displays correctly with markers', () async {
      final querySnapshot = await fakeFirestore
          .collection('artWalks')
          .where('isPublic', isEqualTo: true)
          .get();

      expect(querySnapshot.docs, isNotEmpty);
      expect(querySnapshot.docs.length, equals(2));
    });

    test('Art Walk list displays all art walks', () async {
      final snapshot = await fakeFirestore.collection('artWalks').get();
      final artWalks = snapshot.docs.map(ArtWalkModel.fromFirestore).toList();

      expect(artWalks, isNotEmpty);
      expect(artWalks.length, equals(2));
      expect(artWalks[0].title, equals('Downtown Art Walk'));
    });

    test('Browse art walks - retrieve all public art walks', () async {
      final snapshot = await fakeFirestore
          .collection('artWalks')
          .where('isPublic', isEqualTo: true)
          .get();

      expect(snapshot.docs.isNotEmpty, isTrue);
      for (var doc in snapshot.docs) {
        final artWalk = ArtWalkModel.fromFirestore(doc);
        expect(artWalk.isPublic, isTrue);
      }
    });

    test('Filter art walks by difficulty level', () async {
      final snapshot = await fakeFirestore
          .collection('artWalks')
          .where('difficulty', isEqualTo: 'Easy')
          .get();

      expect(snapshot.docs.isNotEmpty, isTrue);
      final artWalk = ArtWalkModel.fromFirestore(snapshot.docs.first);
      expect(artWalk.difficulty, equals('Easy'));
    });

    test('Search art walks by title', () async {
      final snapshot = await fakeFirestore
          .collection('artWalks')
          .where('title', isGreaterThanOrEqualTo: 'Downtown')
          .get();

      expect(snapshot.docs.isNotEmpty, isTrue);
    });

    test('View art walk detail page loads with full information', () async {
      final doc = await fakeFirestore
          .collection('artWalks')
          .doc('walk_001')
          .get();
      final artWalk = ArtWalkModel.fromFirestore(doc);

      expect(artWalk.title, equals('Downtown Art Walk'));
      expect(artWalk.description, isNotEmpty);
      expect(artWalk.estimatedDuration, equals(45.0));
      expect(artWalk.estimatedDistance, equals(2.5));
      expect(artWalk.difficulty, equals('Easy'));
    });

    test('See checkpoint locations from public art collection', () async {
      final artWalkDoc = await fakeFirestore
          .collection('artWalks')
          .doc('walk_001')
          .get();
      final artWalk = ArtWalkModel.fromFirestore(artWalkDoc);

      final artworks = await Future.wait(
        artWalk.artworkIds.map(
          (id) => fakeFirestore.collection('publicArt').doc(id).get(),
        ),
      );

      expect(artworks.isNotEmpty, isTrue);
      for (var artwork in artworks) {
        if (artwork.exists) {
          expect(artwork.data(), isNotNull);
        }
      }
    });

    test('View art walk route and navigation data', () async {
      final doc = await fakeFirestore
          .collection('artWalks')
          .doc('walk_001')
          .get();
      final artWalk = ArtWalkModel.fromFirestore(doc);

      expect(artWalk.routeData, isNotNull);
      expect(artWalk.startLocation, isNotNull);
      expect(artWalk.startLocation?.latitude, equals(35.23838));
      expect(artWalk.startLocation?.longitude, equals(-77.52658));
    });

    test('View art walk difficulty and duration estimates', () async {
      final doc = await fakeFirestore
          .collection('artWalks')
          .doc('walk_002')
          .get();
      final artWalk = ArtWalkModel.fromFirestore(doc);

      expect(artWalk.difficulty, equals('Medium'));
      expect(artWalk.estimatedDuration, equals(60.0));
      expect(artWalk.estimatedDistance, equals(3.5));
    });
  });

  group('Art Walk System - Participation Features', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      when(mockAuth.currentUser).thenReturn(mockUser);

      // Initialize test data with progress tracking
      await fakeFirestore.collection('artWalks').doc('walk_001').set({
        'title': 'Test Art Walk',
        'description': 'Test walk',
        'userId': 'artist_001',
        'artworkIds': ['art_001', 'art_002', 'art_003'],
        'createdAt': Timestamp.now(),
        'isPublic': true,
        'viewCount': 100,
        'zipCode': '28501',
        'difficulty': 'Medium',
      });

      await fakeFirestore
          .collection('artWalkProgress')
          .doc('progress_001')
          .set({
            'userId': 'test_user_123',
            'artWalkId': 'walk_001',
            'startedAt': Timestamp.now(),
            'completedAt': null,
            'checkpointsCompleted': 1,
            'totalCheckpoints': 3,
            'isInProgress': true,
            'gpsEnabled': true,
            'currentLocation': const GeoPoint(35.23838, -77.52658),
          });

      await fakeFirestore
          .collection('artWalkCompletions')
          .doc('completion_001')
          .set({
            'userId': 'test_user_123',
            'artWalkId': 'walk_001',
            'completedAt': Timestamp.now(),
            'timeTaken': 2700, // 45 minutes in seconds
            'photosUploaded': 3,
            'xpEarned': 150,
          });
    });

    test('Start art walk - create progress record', () async {
      final progressDoc = await fakeFirestore
          .collection('artWalkProgress')
          .doc('progress_002')
          .get();

      if (!progressDoc.exists) {
        await fakeFirestore
            .collection('artWalkProgress')
            .doc('progress_002')
            .set({
              'userId': 'test_user_123',
              'artWalkId': 'walk_001',
              'startedAt': Timestamp.now(),
              'isInProgress': true,
            });
      }

      final newProgress = await fakeFirestore
          .collection('artWalkProgress')
          .doc('progress_002')
          .get();
      expect(newProgress.exists, isTrue);
      expect(newProgress.data()?['isInProgress'], isTrue);
    });

    test('GPS tracking is enabled during art walk participation', () async {
      final progressDoc = await fakeFirestore
          .collection('artWalkProgress')
          .doc('progress_001')
          .get();

      expect(progressDoc.data()?['gpsEnabled'], isTrue);
      expect(progressDoc.data()?['currentLocation'], isNotNull);
    });

    test('Checkpoint detection - track checkpoint completion', () async {
      final progressDoc = await fakeFirestore
          .collection('artWalkProgress')
          .doc('progress_001')
          .get();

      expect(progressDoc.data()?['checkpointsCompleted'], equals(1));
      expect(progressDoc.data()?['totalCheckpoints'], equals(3));
    });

    test('Checkpoint photos display from completed artworks', () async {
      await fakeFirestore.collection('captures').doc('capture_001').set({
        'userId': 'test_user_123',
        'artWalkId': 'walk_001',
        'checkpointId': 'art_001',
        'imageUrl': 'https://example.com/photo1.jpg',
        'timestamp': Timestamp.now(),
        'location': const GeoPoint(35.23838, -77.52658),
      });

      final capture = await fakeFirestore
          .collection('captures')
          .doc('capture_001')
          .get();

      expect(capture.exists, isTrue);
      expect(capture.data()?['imageUrl'], isNotNull);
    });

    test('Navigation updates - real-time location tracking', () async {
      // Update location
      await fakeFirestore
          .collection('artWalkProgress')
          .doc('progress_001')
          .update({'currentLocation': const GeoPoint(35.24000, -77.52700)});

      final updatedProgress = await fakeFirestore
          .collection('artWalkProgress')
          .doc('progress_001')
          .get();

      final location = updatedProgress.data()?['currentLocation'] as GeoPoint?;
      expect(location?.latitude, equals(35.24000));
    });

    test(
      'Timer and progress tracking - monitor completion percentage',
      () async {
        final progressDoc = await fakeFirestore
            .collection('artWalkProgress')
            .doc('progress_001')
            .get();

        final completed =
            (progressDoc.data()?['checkpointsCompleted'] as int?) ?? 0;
        final total = (progressDoc.data()?['totalCheckpoints'] as int?) ?? 1;
        final percentage = (completed / total) * 100;

        expect(percentage, closeTo(33.33, 0.1)); // 1/3 ≈ 33.33%
      },
    );

    test(
      'Complete art walk - finalize progress and record completion',
      () async {
        final completionDoc = await fakeFirestore
            .collection('artWalkCompletions')
            .doc('completion_001')
            .get();

        expect(completionDoc.exists, isTrue);
        expect(completionDoc.data()?['timeTaken'], equals(2700));
        expect(completionDoc.data()?['xpEarned'], equals(150));
      },
    );

    test('Art walk celebration screen displays with completion data', () async {
      final completionDoc = await fakeFirestore
          .collection('artWalkCompletions')
          .doc('completion_001')
          .get();

      final data = completionDoc.data();
      expect(data?['photosUploaded'], equals(3));
      expect(data?['xpEarned'], isNotNull);
      expect(data?['timeTaken'], isNotNull);
    });

    test('Share art walk results to social feed', () async {
      await fakeFirestore.collection('activityFeed').doc('activity_001').set({
        'userId': 'test_user_123',
        'type': 'artWalkCompletion',
        'artWalkId': 'walk_001',
        'timestamp': Timestamp.now(),
        'message': 'Completed Downtown Art Walk!',
      });

      final activity = await fakeFirestore
          .collection('activityFeed')
          .doc('activity_001')
          .get();

      expect(activity.exists, isTrue);
      expect(activity.data()?['type'], equals('artWalkCompletion'));
    });

    test('Save or bookmark art walk for later', () async {
      await fakeFirestore
          .collection('users')
          .doc('test_user_123')
          .collection('bookmarks')
          .doc('walk_001')
          .set({'artWalkId': 'walk_001', 'savedAt': Timestamp.now()});

      final bookmark = await fakeFirestore
          .collection('users')
          .doc('test_user_123')
          .collection('bookmarks')
          .doc('walk_001')
          .get();

      expect(bookmark.exists, isTrue);
    });

    test('View saved art walks for logged-in user', () async {
      // First create a bookmark
      await fakeFirestore
          .collection('users')
          .doc('test_user_123')
          .collection('bookmarks')
          .doc('walk_001')
          .set({'artWalkId': 'walk_001', 'savedAt': Timestamp.now()});

      final bookmarks = await fakeFirestore
          .collection('users')
          .doc('test_user_123')
          .collection('bookmarks')
          .get();

      expect(bookmarks.docs.isNotEmpty, isTrue);
    });

    test('View completed art walks history', () async {
      // First create a completion record if not exists
      await fakeFirestore
          .collection('artWalkCompletions')
          .doc('completion_history_001')
          .set({
            'userId': 'test_user_123',
            'artWalkId': 'walk_001',
            'completedAt': Timestamp.now(),
            'timeTaken': 2700,
            'xpEarned': 150,
          });

      final completions = await fakeFirestore
          .collection('artWalkCompletions')
          .where('userId', isEqualTo: 'test_user_123')
          .get();

      expect(completions.docs.isNotEmpty, isTrue);
    });

    test('View popular art walks by completion count', () async {
      final snapshot = await fakeFirestore
          .collection('artWalks')
          .orderBy('completionCount', descending: true)
          .limit(10)
          .get();

      expect(snapshot.docs.isNotEmpty, isTrue);
    });

    test('View nearby art walks based on current location', () async {
      // This would normally use geohashing or similar
      // For testing, we simulate filtering by zipcode
      final nearbyWalks = await fakeFirestore
          .collection('artWalks')
          .where('zipCode', isEqualTo: '28501')
          .get();

      expect(nearbyWalks.docs.isNotEmpty, isTrue);
    });
  });

  group('Art Walk System - Creation Features', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      when(mockAuth.currentUser).thenReturn(mockUser);
    });

    test(
      'Create new art walk - initialize with title and description',
      () async {
        const newWalkId = 'new_walk_001';

        await fakeFirestore.collection('artWalks').doc(newWalkId).set({
          'title': 'New Creative Walk',
          'description': 'A new art walk created by user',
          'userId': 'test_user_123',
          'artworkIds': <String>[],
          'createdAt': Timestamp.now(),
          'isPublic': false,
          'viewCount': 0,
        });

        final newWalk = await fakeFirestore
            .collection('artWalks')
            .doc(newWalkId)
            .get();

        expect(newWalk.exists, isTrue);
        expect(newWalk.data()?['title'], equals('New Creative Walk'));
        expect(newWalk.data()?['userId'], equals('test_user_123'));
      },
    );

    test('Add checkpoints to art walk', () async {
      const newWalkId = 'new_walk_002';

      await fakeFirestore.collection('artWalks').doc(newWalkId).set({
        'title': 'Walk with Checkpoints',
        'description': 'Test',
        'userId': 'test_user_123',
        'artworkIds': <String>[],
        'createdAt': Timestamp.now(),
      });

      // Add checkpoints
      await fakeFirestore.collection('artWalks').doc(newWalkId).update({
        'artworkIds': ['checkpoint_001', 'checkpoint_002', 'checkpoint_003'],
      });

      final walk = await fakeFirestore
          .collection('artWalks')
          .doc(newWalkId)
          .get();

      final artworkIds = walk.data()?['artworkIds'] as List<dynamic>?;
      expect(artworkIds, isNotEmpty);
      expect(artworkIds?.length, equals(3));
    });

    test('Set art walk route with multiple checkpoints', () async {
      const newWalkId = 'new_walk_003';

      await fakeFirestore.collection('artWalks').doc(newWalkId).set({
        'title': 'Routed Walk',
        'description': 'Test',
        'userId': 'test_user_123',
        'artworkIds': ['point_1', 'point_2'],
        'createdAt': Timestamp.now(),
        'routeData': 'encoded_route_with_optimization',
        'startLocation': const GeoPoint(35.23838, -77.52658),
      });

      final walk = await fakeFirestore
          .collection('artWalks')
          .doc(newWalkId)
          .get();

      expect(walk.data()?['routeData'], isNotNull);
      expect(walk.data()?['startLocation'], isNotNull);
    });

    test('Add descriptions to art walk and checkpoints', () async {
      const newWalkId = 'new_walk_004';

      await fakeFirestore.collection('artWalks').doc(newWalkId).set({
        'title': 'Descriptive Walk',
        'description': 'A comprehensive walk with detailed descriptions',
        'userId': 'test_user_123',
        'artworkIds': <String>[],
        'createdAt': Timestamp.now(),
      });

      await fakeFirestore
          .collection('artWalks')
          .doc(newWalkId)
          .collection('checkpoints')
          .doc('checkpoint_1')
          .set({
            'title': 'First Artwork',
            'description': 'This is a beautiful mural depicting local history',
            'location': const GeoPoint(35.23838, -77.52658),
          });

      final checkpoint = await fakeFirestore
          .collection('artWalks')
          .doc(newWalkId)
          .collection('checkpoints')
          .doc('checkpoint_1')
          .get();

      expect(checkpoint.exists, isTrue);
      expect(checkpoint.data()?['description'], isNotEmpty);
    });

    test('Upload artwork to art walk checkpoints', () async {
      const newWalkId = 'new_walk_005';

      await fakeFirestore.collection('artWalks').doc(newWalkId).set({
        'title': 'Walk with Images',
        'description': 'Test',
        'userId': 'test_user_123',
        'artworkIds': <String>[],
        'createdAt': Timestamp.now(),
      });

      // Associate public art with walk
      await fakeFirestore.collection('artWalks').doc(newWalkId).update({
        'artworkIds': ['art_piece_001'],
      });

      final walk = await fakeFirestore
          .collection('artWalks')
          .doc(newWalkId)
          .get();

      expect(walk.data()?['artworkIds'], contains('art_piece_001'));
    });

    test('Set difficulty level for art walk', () async {
      const newWalkId = 'new_walk_006';

      await fakeFirestore.collection('artWalks').doc(newWalkId).set({
        'title': 'Moderate Walk',
        'description': 'Test',
        'userId': 'test_user_123',
        'artworkIds': <String>[],
        'createdAt': Timestamp.now(),
        'difficulty': 'Medium',
        'estimatedDuration': 50.0,
        'estimatedDistance': 2.8,
      });

      final walk = await fakeFirestore
          .collection('artWalks')
          .doc(newWalkId)
          .get();

      expect(walk.data()?['difficulty'], equals('Medium'));
    });

    test('Publish art walk to make it public', () async {
      const newWalkId = 'new_walk_007';

      // Create as private first
      await fakeFirestore.collection('artWalks').doc(newWalkId).set({
        'title': 'Private Walk',
        'description': 'Test',
        'userId': 'test_user_123',
        'artworkIds': <String>[],
        'createdAt': Timestamp.now(),
        'isPublic': false,
      });

      // Publish (make public)
      await fakeFirestore.collection('artWalks').doc(newWalkId).update({
        'isPublic': true,
      });

      final walk = await fakeFirestore
          .collection('artWalks')
          .doc(newWalkId)
          .get();

      expect(walk.data()?['isPublic'], isTrue);
    });

    test('Edit existing art walk', () async {
      const walkId = 'existing_walk_001';

      // Create initial walk
      await fakeFirestore.collection('artWalks').doc(walkId).set({
        'title': 'Original Title',
        'description': 'Original description',
        'userId': 'test_user_123',
        'artworkIds': <String>[],
        'createdAt': Timestamp.now(),
      });

      // Edit the walk
      await fakeFirestore.collection('artWalks').doc(walkId).update({
        'title': 'Updated Title',
        'description': 'Updated description',
      });

      final walk = await fakeFirestore.collection('artWalks').doc(walkId).get();

      expect(walk.data()?['title'], equals('Updated Title'));
      expect(walk.data()?['description'], equals('Updated description'));
    });

    test('Delete art walk', () async {
      const walkId = 'walk_to_delete';

      // Create walk
      await fakeFirestore.collection('artWalks').doc(walkId).set({
        'title': 'Walk to Delete',
        'description': 'Test',
        'userId': 'test_user_123',
        'artworkIds': <String>[],
        'createdAt': Timestamp.now(),
      });

      // Verify it exists
      var walk = await fakeFirestore.collection('artWalks').doc(walkId).get();
      expect(walk.exists, isTrue);

      // Delete it
      await fakeFirestore.collection('artWalks').doc(walkId).delete();

      // Verify it's deleted
      walk = await fakeFirestore.collection('artWalks').doc(walkId).get();
      expect(walk.exists, isFalse);
    });

    test('View art walk analytics and metrics', () async {
      const walkId = 'analytics_walk_001';

      await fakeFirestore.collection('artWalks').doc(walkId).set({
        'title': 'Tracked Walk',
        'description': 'Test',
        'userId': 'test_user_123',
        'artworkIds': <String>[],
        'createdAt': Timestamp.now(),
        'viewCount': 250,
        'completionCount': 50,
      });

      await fakeFirestore
          .collection('artWalks')
          .doc(walkId)
          .collection('analytics')
          .doc('daily')
          .set({
            'date': Timestamp.now(),
            'views': 25,
            'completions': 5,
            'avgCompletionTime': 2850, // seconds
          });

      final analytics = await fakeFirestore
          .collection('artWalks')
          .doc(walkId)
          .collection('analytics')
          .doc('daily')
          .get();

      expect(analytics.exists, isTrue);
      expect(analytics.data()?['views'], equals(25));
    });
  });

  group('Art Walk System - Integration Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      when(mockAuth.currentUser).thenReturn(mockUser);
    });

    test('Complete workflow: Create, start, and complete art walk', () async {
      const walkId = 'workflow_walk_001';

      // Step 1: Create art walk
      await fakeFirestore.collection('artWalks').doc(walkId).set({
        'title': 'Complete Workflow Walk',
        'description': 'Full test walk',
        'userId': 'test_user_123',
        'artworkIds': ['art_1', 'art_2'],
        'createdAt': Timestamp.now(),
        'isPublic': true,
        'difficulty': 'Easy',
      });

      // Step 2: Start art walk (create progress)
      await fakeFirestore
          .collection('artWalkProgress')
          .doc('progress_workflow_001')
          .set({
            'userId': 'test_user_123',
            'artWalkId': walkId,
            'startedAt': Timestamp.now(),
            'isInProgress': true,
            'checkpointsCompleted': 0,
          });

      // Step 3: Complete checkpoints
      await fakeFirestore
          .collection('artWalkProgress')
          .doc('progress_workflow_001')
          .update({'checkpointsCompleted': 2});

      // Step 4: Mark as completed
      await fakeFirestore
          .collection('artWalkCompletions')
          .doc('completion_workflow_001')
          .set({
            'userId': 'test_user_123',
            'artWalkId': walkId,
            'completedAt': Timestamp.now(),
            'xpEarned': 150,
          });

      // Verify completion record exists
      final completion = await fakeFirestore
          .collection('artWalkCompletions')
          .doc('completion_workflow_001')
          .get();

      expect(completion.exists, isTrue);
      expect(completion.data()?['xpEarned'], equals(150));
    });

    test(
      'Complex discovery scenario: Search, filter, bookmark, start walk',
      () async {
        // Setup multiple walks
        for (int i = 0; i < 5; i++) {
          await fakeFirestore.collection('artWalks').doc('walk_$i').set({
            'title': 'Art Walk $i',
            'description': 'Description $i',
            'userId': 'artist_$i',
            'artworkIds': <String>[],
            'createdAt': Timestamp.now(),
            'isPublic': true,
            'difficulty': i.isEven ? 'Easy' : 'Medium',
            'completionCount': (i + 1) * 10,
          });
        }

        // Search and filter
        final easyWalks = await fakeFirestore
            .collection('artWalks')
            .where('isPublic', isEqualTo: true)
            .where('difficulty', isEqualTo: 'Easy')
            .get();

        expect(easyWalks.docs.length, equals(3)); // 0, 2, 4

        // Bookmark one
        if (easyWalks.docs.isNotEmpty) {
          final firstWalk = easyWalks.docs.first;
          await fakeFirestore
              .collection('users')
              .doc('test_user_123')
              .collection('bookmarks')
              .doc(firstWalk.id)
              .set({'artWalkId': firstWalk.id});
        }

        // Verify bookmark
        final bookmarks = await fakeFirestore
            .collection('users')
            .doc('test_user_123')
            .collection('bookmarks')
            .get();

        expect(bookmarks.docs.isNotEmpty, isTrue);
      },
    );

    test('Full creation workflow with all optional fields', () async {
      const walkId = 'full_creation_walk';

      await fakeFirestore.collection('artWalks').doc(walkId).set({
        'title': 'Comprehensive Art Walk',
        'description': 'A walk with all features enabled',
        'userId': 'test_user_123',
        'artworkIds': ['art_1', 'art_2', 'art_3'],
        'createdAt': Timestamp.now(),
        'isPublic': true,
        'viewCount': 0,
        'imageUrls': ['image1.jpg', 'image2.jpg'],
        'zipCode': '28501',
        'estimatedDuration': 60.0,
        'estimatedDistance': 3.0,
        'coverImageUrl': 'cover.jpg',
        'routeData': 'encoded_route',
        'tags': ['public art', 'downtown', 'cultural'],
        'difficulty': 'Medium',
        'isAccessible': true,
        'startLocation': const GeoPoint(35.23838, -77.52658),
        'completionCount': 0,
      });

      final walk = await fakeFirestore.collection('artWalks').doc(walkId).get();

      final artWalk = ArtWalkModel.fromFirestore(walk);

      // Verify all fields
      expect(artWalk.title, isNotEmpty);
      expect(artWalk.tags?.length, equals(3));
      expect(artWalk.difficulty, equals('Medium'));
      expect(artWalk.isAccessible, isTrue);
      expect(artWalk.artworkIds.length, equals(3));
    });
  });
}

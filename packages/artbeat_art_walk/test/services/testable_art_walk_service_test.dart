import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:artbeat_art_walk/src/models/public_art_model.dart';
import 'package:artbeat_art_walk/src/models/art_walk_model.dart';
import 'package:artbeat_art_walk/src/services/testable_art_walk_service.dart';
import 'testable_art_walk_service_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User, FirebaseFirestore])
class MockArtWalkCacheService implements IArtWalkCacheService {
  final List<PublicArtModel> _cachedPublicArt;
  final List<ArtWalkModel> _cachedArtWalks;

  MockArtWalkCacheService({
    List<PublicArtModel>? cachedPublicArt,
    List<ArtWalkModel>? cachedArtWalks,
  })  : _cachedPublicArt = cachedPublicArt ?? [],
        _cachedArtWalks = cachedArtWalks ?? [];

  @override
  Future<void> cachePublicArt(List<PublicArtModel> artworks) async {
    // Implementation not needed for tests
  }

  @override
  Future<List<PublicArtModel>> getCachedPublicArt() async {
    return _cachedPublicArt;
  }

  @override
  Future<void> cacheArtWalks(List<ArtWalkModel> artWalks) async {
    // Implementation not needed for tests
  }

  @override
  Future<List<ArtWalkModel>> getCachedArtWalks() async {
    return _cachedArtWalks;
  }
}

void main() {
  const testUserId = 'test-user-id';
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late TestableArtWalkService artWalkService;
  late MockArtWalkCacheService mockCacheService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockCacheService = MockArtWalkCacheService();

    // Set up auth mocks
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(testUserId);

    // Create the service with mocked dependencies
    artWalkService = TestableArtWalkService(
      firestore: fakeFirestore,
      auth: mockAuth,
      cacheService: mockCacheService,
    );
  });

  group('Cache Fallback Tests', () {
    test('getAllPublicArt falls back to cache when Firestore fails', () async {
      // Arrange
      final mockFirestore = MockFirebaseFirestore();

      // Setup Firestore to throw when accessed
      when(mockFirestore.collection(any)).thenThrow(
        FirebaseException(plugin: 'firestore', code: 'unavailable'),
      );

      final cachedArt = [
        PublicArtModel(
          id: 'cached-art-1',
          userId: testUserId,
          title: 'Cached Art 1',
          description: 'Cached Description',
          imageUrl: 'cached-image.jpg',
          location: const GeoPoint(40.7128, -74.0060),
          tags: ['cached', 'art'],
          usersFavorited: [],
          createdAt: Timestamp.now(),
        ),
      ];

      mockCacheService = MockArtWalkCacheService(cachedPublicArt: cachedArt);

      artWalkService = TestableArtWalkService(
        firestore: mockFirestore,
        auth: mockAuth,
        cacheService: mockCacheService,
      );

      // Act
      final result = await artWalkService.getAllPublicArt();

      // Assert
      expect(result.length, 1);
      expect(result.first.id, 'cached-art-1');
      expect(result.first.title, 'Cached Art 1');
    });

    test('getAllArtWalks falls back to cache when Firestore fails', () async {
      // Arrange
      final mockFirestore = MockFirebaseFirestore();

      // Setup Firestore to throw when accessed
      when(mockFirestore.collection(any)).thenThrow(
        FirebaseException(plugin: 'firestore', code: 'unavailable'),
      );

      final cachedWalks = [
        ArtWalkModel(
          id: 'cached-walk-1',
          userId: testUserId,
          title: 'Cached Walk 1',
          description: 'Cached Description',
          publicArtIds: ['art-1', 'art-2'],
          createdAt: DateTime.now(),
          isPublic: true,
          viewCount: 10,
          imageUrls: ['cached-image.jpg'],
        ),
      ];

      mockCacheService = MockArtWalkCacheService(cachedArtWalks: cachedWalks);

      artWalkService = TestableArtWalkService(
        firestore: mockFirestore,
        auth: mockAuth,
        cacheService: mockCacheService,
      );

      // Act
      final result = await artWalkService.getAllArtWalks();

      // Assert
      expect(result.length, 1);
      expect(result.first.id, 'cached-walk-1');
      expect(result.first.title, 'Cached Walk 1');
    });
  });

  group('Basic ArtWalkService Tests', () {
    test('getCurrentUserId returns the current user ID', () {
      // Act
      final userId = artWalkService.getCurrentUserId();

      // Assert
      expect(userId, testUserId);
      verify(mockAuth.currentUser).called(1);
      verify(mockUser.uid).called(1);
    });

    test('getAllPublicArt returns empty list when no public art exists',
        () async {
      // Act
      final result = await artWalkService.getAllPublicArt();

      // Assert
      expect(result, isEmpty);
    });

    test('getAllArtWalks returns empty list when no art walks exist', () async {
      // Act
      final result = await artWalkService.getAllArtWalks();

      // Assert
      expect(result, isEmpty);
    });
  });

  group('ArtWalkService CRUD Operations', () {
    test('getPublicArtById returns null for non-existent ID', () async {
      // Act
      final result = await artWalkService.getPublicArtById('non-existent-id');

      // Assert
      expect(result, isNull);
    });

    test('getPublicArtById returns public art for valid ID', () async {
      // Arrange
      final publicArtDoc =
          fakeFirestore.collection('publicArt').doc('test-art-id');
      await publicArtDoc.set({
        'userId': testUserId,
        'title': 'Test Art',
        'description': 'Test Description',
        'imageUrl': 'test-image.jpg',
        'location': const GeoPoint(40.7128, -74.0060),
        'tags': const ['test', 'art'],
        'usersFavorited': const [],
        'createdAt': Timestamp.now(),
      });

      // Act
      final result = await artWalkService.getPublicArtById('test-art-id');

      // Assert
      expect(result, isNotNull);
      expect(result?.title, 'Test Art');
      expect(result?.userId, testUserId);
    });

    test('getArtWalkById returns null for non-existent ID', () async {
      // Act
      final result = await artWalkService.getArtWalkById('non-existent-id');

      // Assert
      expect(result, isNull);
    });

    test('getArtWalkById returns art walk for valid ID', () async {
      // Arrange
      final artWalkDoc =
          fakeFirestore.collection('artWalks').doc('test-walk-id');
      await artWalkDoc.set({
        'userId': testUserId,
        'title': 'Test Walk',
        'description': 'Test Description',
        'publicArtIds': ['art-1', 'art-2'],
        'createdAt': Timestamp.now(),
        'isPublic': true,
        'viewCount': 0,
        'imageUrls': ['image1.jpg'],
      });

      // Act
      final result = await artWalkService.getArtWalkById('test-walk-id');

      // Assert
      expect(result, isNotNull);
      expect(result?.title, 'Test Walk');
      expect(result?.userId, testUserId);
      expect(result?.publicArtIds, ['art-1', 'art-2']);
      expect(result?.isPublic, true);
    });

    test('getPublicArtByUserId returns public art for user', () async {
      // Arrange
      await fakeFirestore.collection('publicArt').doc('art-1').set({
        'userId': testUserId,
        'title': 'User Art 1',
        'description': 'Test Description',
        'imageUrl': 'test-image.jpg',
        'location': const GeoPoint(40.7128, -74.0060),
        'tags': const ['test', 'art'],
        'usersFavorited': const [],
        'createdAt': Timestamp.now(),
      });

      await fakeFirestore.collection('publicArt').doc('art-2').set({
        'userId': 'other-user-id',
        'title': 'Other User Art',
        'description': 'Test Description',
        'imageUrl': 'test-image.jpg',
        'location': const GeoPoint(40.7128, -74.0060),
        'tags': const ['test', 'art'],
        'usersFavorited': const [],
        'createdAt': Timestamp.now(),
      });

      // Act
      final result = await artWalkService.getPublicArtByUserId(testUserId);

      // Assert
      expect(result.length, 1);
      expect(result.first.title, 'User Art 1');
      expect(result.first.userId, testUserId);
    });

    test('getArtWalksByUserId returns art walks for user', () async {
      // Arrange
      await fakeFirestore.collection('artWalks').doc('walk-1').set({
        'userId': testUserId,
        'title': 'User Walk 1',
        'description': 'Test Description',
        'publicArtIds': ['art-1', 'art-2'],
        'createdAt': Timestamp.now(),
        'isPublic': true,
        'viewCount': 0,
        'imageUrls': ['image1.jpg'],
      });

      await fakeFirestore.collection('artWalks').doc('walk-2').set({
        'userId': 'other-user-id',
        'title': 'Other User Walk',
        'description': 'Test Description',
        'publicArtIds': ['art-3'],
        'createdAt': Timestamp.now(),
        'isPublic': true,
        'viewCount': 0,
        'imageUrls': ['image2.jpg'],
      });

      // Act
      final result = await artWalkService.getArtWalksByUserId(testUserId);

      // Assert
      expect(result.length, 1);
      expect(result.first.title, 'User Walk 1');
      expect(result.first.userId, testUserId);
    });

    test('incrementArtWalkViewCount increases the view count', () async {
      // Arrange
      await fakeFirestore.collection('artWalks').doc('walk-1').set({
        'userId': testUserId,
        'title': 'User Walk 1',
        'description': 'Test Description',
        'publicArtIds': ['art-1', 'art-2'],
        'createdAt': Timestamp.now(),
        'isPublic': true,
        'viewCount': 5,
        'imageUrls': ['image1.jpg'],
      });

      // Act
      await artWalkService.incrementArtWalkViewCount('walk-1');

      // Verify
      final doc =
          await fakeFirestore.collection('artWalks').doc('walk-1').get();

      // Assert
      expect(doc.data()?['viewCount'], 6);
    });
  });

  // End of tests
}

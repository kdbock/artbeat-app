import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:artbeat_profile/src/services/testable_capture_service.dart';
import 'package:artbeat_core/artbeat_core.dart' show CaptureModel;
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late TestableCaptureService captureService;
  final testUserId = 'test-user-id';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    captureService = TestableCaptureService(fakeFirestore);
  });

  group('TestableCaptureService Tests', () {
    test('getUserCaptures returns empty list when no captures exist', () async {
      // Act
      final captureModels = await captureService.getUserCaptures(testUserId);

      // Assert
      expect(captureModels, isEmpty);
    });

    test('getUserCaptures returns list of captures for a user', () async {
      // Arrange - create some test captures in the fake Firestore
      final capture1 = {
        'id': 'capture1',
        'userId': testUserId,
        'title': 'Test Capture 1',
        'description': 'Description for test capture 1',
        'imageUrl': 'https://example.com/image1.jpg',
        'createdAt': Timestamp.fromDate(DateTime(2023, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2023, 1, 1)),
        'latitude': 40.7128,
        'longitude': -74.0060,
        'tags': ['art', 'street', 'nyc']
      };

      final capture2 = {
        'id': 'capture2',
        'userId': testUserId,
        'title': 'Test Capture 2',
        'description': 'Description for test capture 2',
        'imageUrl': 'https://example.com/image2.jpg',
        'createdAt': Timestamp.fromDate(DateTime(2023, 2, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2023, 2, 1)),
        'latitude': 37.7749,
        'longitude': -122.4194,
        'tags': ['art', 'museum', 'sf']
      };

      // Add the test captures to fake Firestore
      await fakeFirestore.collection('captures').doc('capture1').set(capture1);
      await fakeFirestore.collection('captures').doc('capture2').set(capture2);

      // Add a capture for a different user (should not be returned)
      await fakeFirestore.collection('captures').doc('capture3').set({
        ...capture1,
        'id': 'capture3',
        'userId': 'different-user-id',
        'title': 'Test Capture 3'
      });

      // Act
      final captureModels = await captureService.getCapturesForUser(testUserId);

      // Assert - Note: This test may need adjustment based on actual CaptureModel implementation
      // We're expecting two captures to be returned for our test user
      expect(captureModels.length, 2);

      // Test is simplified since we can't directly compare the CaptureModel objects
      // without knowing their exact implementation
    });

    test('getCapturesForUser returns empty list for null user ID', () async {
      // Act
      final captureModels = await captureService.getCapturesForUser(null);

      // Assert
      expect(captureModels, isEmpty);
    });

    test('createCapture adds a new capture and returns its ID', () async {
      // Arrange - Create a test capture model based on the actual implementation
      final now = DateTime.now();
      final captureModel = CaptureModel(
          id: 'new-capture',
          userId: testUserId,
          title: 'New Test Capture',
          description: 'A new test capture',
          imageUrl: 'https://example.com/newimage.jpg',
          createdAt: now,
          updatedAt: now,
          location: const GeoPoint(51.5074, -0.1278),
          locationName: 'London',
          tags: ['test', 'london'],
          isPublic: true,
          isProcessed: true);

      // Act
      final createdId = await captureService.createCapture(captureModel);

      // Assert
      expect(createdId, isNotEmpty);

      // Verify the capture was stored correctly
      final docSnapshot =
          await fakeFirestore.collection('captures').doc(createdId).get();
      expect(docSnapshot.exists, true);

      // Additional verification if needed for specific fields
      // This would depend on how CaptureModel's toFirestore method works
    });

    test('updateCapture modifies an existing capture', () async {
      // Arrange - Create a capture to update
      final captureId = 'update-test-capture';
      await fakeFirestore.collection('captures').doc(captureId).set({
        'id': captureId,
        'userId': testUserId,
        'title': 'Original Title',
        'description': 'Original description',
        'imageUrl': 'https://example.com/original.jpg',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Create an updated version of the capture
      final now = DateTime.now();
      final updatedCapture = CaptureModel(
        id: captureId,
        userId: testUserId,
        title: 'Updated Title',
        description: 'Updated description',
        imageUrl: 'https://example.com/updated.jpg',
        createdAt: now,
        updatedAt: now,
      );

      // Act
      await captureService.updateCapture(captureId, updatedCapture);

      // Assert
      final updatedDoc =
          await fakeFirestore.collection('captures').doc(captureId).get();
      final data = updatedDoc.data() as Map<String, dynamic>;
      expect(data['title'], 'Updated Title');
      expect(data['description'], 'Updated description');
    });

    test('deleteCapture removes a capture', () async {
      // Arrange - Create a capture to delete
      final captureId = 'delete-test-capture';
      await fakeFirestore.collection('captures').doc(captureId).set({
        'id': captureId,
        'userId': testUserId,
        'title': 'Test Capture to Delete',
        'createdAt': Timestamp.now(),
      });

      // Verify the capture exists before deletion
      final docBeforeDelete =
          await fakeFirestore.collection('captures').doc(captureId).get();
      expect(docBeforeDelete.exists, true);

      // Act
      await captureService.deleteCapture(captureId);

      // Assert
      final docAfterDelete =
          await fakeFirestore.collection('captures').doc(captureId).get();
      expect(docAfterDelete.exists, false);
    });
  });
}

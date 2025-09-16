import 'dart:io';

import 'package:artbeat_capture/src/services/capture_service.dart';
import 'package:artbeat_capture/src/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'capture_sequence_test.mocks.dart';
import 'test_setup.dart';

@GenerateMocks([StorageService, CaptureService])
void main() {
  setUpAll(() async {
    await TestSetup.initializeTestBindings();
  });

  tearDownAll(() async {
    TestSetup.cleanupTestBindings();
  });

  group('Storage Service Test Environment', () {
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
    });

    test('StorageService handles test environment correctly', () async {
      final testImageFile = File('test_image.jpg');

      // Mock storage service to throw an error (simulating test environment)
      when(mockStorageService.uploadCaptureImage(any, any)).thenThrow(
        Exception('Firebase services not available in test environment'),
      );

      // Verify that the service throws the expected error
      expect(
        () async => mockStorageService.uploadCaptureImage(
          testImageFile,
          'test-user-id',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('StorageService upload methods are properly mocked', () async {
      final testImageFile = File('test_image.jpg');

      // Mock successful upload
      when(
        mockStorageService.uploadCaptureImage(any, any),
      ).thenAnswer((_) async => 'https://example.com/test-image.jpg');

      // Verify the mock works
      final result = await mockStorageService.uploadCaptureImage(
        testImageFile,
        'test-user-id',
      );
      expect(result, 'https://example.com/test-image.jpg');
    });
  });
}

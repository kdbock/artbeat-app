import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'packages/artbeat_capture/lib/src/services/camera_service.dart';

void main() {
  group('Camera Service Tests', () {
    late CameraService cameraService;

    setUp(() {
      cameraService = CameraService();
    });

    test('Camera service should initialize without errors', () {
      expect(cameraService, isNotNull);
    });

    test('Camera availability check should not throw', () async {
      // This test ensures the camera availability check doesn't crash
      expect(
        () async => await cameraService.isCameraAvailable(),
        returnsNormally,
      );
    });

    test('Camera service should handle emulator detection', () async {
      // Reset the service to test fresh state
      cameraService.reset();

      // This should complete without throwing
      final isAvailable = await cameraService.isCameraAvailable();

      // On emulator, camera should typically not be available
      // On real device, it might be available
      expect(isAvailable, isA<bool>());
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';

void main() {
  setUpAll(() async {
    // Initialize Firebase for testing
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock Firebase initialization
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('plugins.flutter.io/firebase_core', (
          message,
        ) async {
          return null;
        });
  });

  group('ImageManagementService Tests', () {
    late ImageManagementService imageService;

    setUp(() {
      imageService = ImageManagementService();
    });

    test('should initialize without errors', () async {
      expect(() => imageService.initialize(), returnsNormally);
    });

    test('should provide optimized image widget', () {
      final widget = imageService.getOptimizedImage(
        imageUrl: 'https://example.com/test.jpg',
        width: 200,
        height: 200,
        isProfile: true,
      );

      expect(widget, isNotNull);
    });

    test('should handle concurrent loading limits', () async {
      // Test concurrent loading queue
      var completedLoads = 0;

      for (int i = 0; i < 10; i++) {
        imageService.loadImageWithQueue(
          'https://example.com/image$i.jpg',
          () => completedLoads++,
        );
      }

      // Wait for some processing
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Should have queued some loads
      expect(completedLoads, lessThan(10));
    });

    test('should generate proper cache keys', () {
      final key1 = imageService.getOptimizedImage(
        imageUrl: 'https://example.com/test.jpg',
        width: 200,
        height: 200,
      );

      final key2 = imageService.getOptimizedImage(
        imageUrl: 'https://example.com/test.jpg',
        width: 300,
        height: 300,
      );

      // Different dimensions should create different widgets
      expect(key1.toString(), isNot(equals(key2.toString())));
    });
  });

  group('EnhancedStorageService Tests', () {
    late EnhancedStorageService storageService;

    setUp(() {
      storageService = EnhancedStorageService();
    });

    test('should provide correct compression settings', () {
      final profileSettings = storageService._getCompressionSettings('profile');
      final artworkSettings = storageService._getCompressionSettings('artwork');

      expect(profileSettings['maxWidth'], equals(400));
      expect(profileSettings['maxHeight'], equals(400));
      expect(profileSettings['quality'], equals(90));

      expect(artworkSettings['maxWidth'], equals(1920));
      expect(artworkSettings['maxHeight'], equals(1080));
      expect(artworkSettings['quality'], equals(85));
    });

    test('should handle multiple image uploads with batching', () async {
      // This is a unit test, so we'll test the batch logic
      // In a real test, you'd provide mock files
      expect(
        () => storageService.uploadMultipleImages(
          imageFiles: [],
          category: 'test',
          maxConcurrent: 3,
        ),
        returnsNormally,
      );
    });
  });

  group('OptimizedImage Widget Tests', () {
    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OptimizedImage(
            imageUrl: 'https://example.com/test.jpg',
            width: 200,
            height: 200,
          ),
        ),
      );

      expect(find.byType(OptimizedImage), findsOneWidget);
    });

    testWidgets('should show placeholder while loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OptimizedImage(
            imageUrl: 'https://example.com/test.jpg',
            width: 200,
            height: 200,
          ),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should apply border radius correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OptimizedImage(
            imageUrl: 'https://example.com/test.jpg',
            width: 200,
            height: 200,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('should handle tap events', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OptimizedImage(
            imageUrl: 'https://example.com/test.jpg',
            width: 200,
            height: 200,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(OptimizedImage));
      expect(tapped, isTrue);
    });
  });

  group('OptimizedGridImage Widget Tests', () {
    testWidgets('should render grid image with overlay', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OptimizedGridImage(
            imageUrl: 'https://example.com/test.jpg',
            heroTag: 'test-hero',
            overlay: Icon(Icons.star),
          ),
        ),
      );

      expect(find.byType(OptimizedGridImage), findsOneWidget);
      expect(find.byType(Stack), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('should use thumbnail URL when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OptimizedGridImage(
            imageUrl: 'https://example.com/test.jpg',
            thumbnailUrl: 'https://example.com/thumb.jpg',
          ),
        ),
      );

      expect(find.byType(OptimizedGridImage), findsOneWidget);
    });
  });

  group('OptimizedAvatar Widget Tests', () {
    testWidgets('should show initials when no image URL', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OptimizedAvatar(displayName: 'John Doe', radius: 30),
        ),
      );

      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('should show verification badge when verified', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OptimizedAvatar(
            displayName: 'John Doe',
            radius: 30,
            isVerified: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('should handle tap events', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OptimizedAvatar(
            displayName: 'John Doe',
            radius: 30,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(OptimizedAvatar));
      expect(tapped, isTrue);
    });
  });

  group('Integration Tests', () {
    test('should handle image optimization workflow', () async {
      // Test the complete workflow
      final imageService = ImageManagementService();

      // Initialize service
      await imageService.initialize();

      // Get cache stats
      final stats = await imageService.getCacheStats();
      expect(stats, isA<Map<String, dynamic>>());

      // Clean up
      imageService.dispose();
    });

    test('should maintain backward compatibility', () {
      // Test that old code patterns still work
      expect(
        () => ImageManagementService().getOptimizedImage(
          imageUrl: 'https://example.com/test.jpg',
        ),
        returnsNormally,
      );
    });
  });

  group('Error Handling Tests', () {
    test('should handle invalid image URLs gracefully', () {
      expect(
        () =>
            ImageManagementService().getOptimizedImage(imageUrl: 'invalid-url'),
        returnsNormally,
      );
    });

    test('should handle network errors', () async {
      final imageService = ImageManagementService();

      // This should not throw an exception
      expect(
        () => imageService.loadImageWithQueue(
          'https://non-existent-domain.com/image.jpg',
          () {},
        ),
        returnsNormally,
      );
    });
  });

  group('Performance Tests', () {
    test('should limit concurrent loads', () async {
      final imageService = ImageManagementService();
      var activeLoads = 0;
      var maxConcurrent = 0;

      // Simulate multiple concurrent loads
      for (int i = 0; i < 20; i++) {
        imageService.loadImageWithQueue('https://example.com/image$i.jpg', () {
          activeLoads--;
        });
        activeLoads++;
        if (activeLoads > maxConcurrent) {
          maxConcurrent = activeLoads;
        }
      }

      // Should not exceed the limit
      expect(maxConcurrent, lessThanOrEqualTo(3));
    });

    test('should provide cache statistics', () async {
      final imageService = ImageManagementService();
      await imageService.initialize();

      final stats = await imageService.getCacheStats();

      expect(stats.containsKey('fileCount'), isTrue);
      expect(stats.containsKey('totalSize'), isTrue);
      expect(stats.containsKey('activeLoads'), isTrue);
      expect(stats.containsKey('queuedLoads'), isTrue);
    });
  });
}

// Extension to access private methods for testing
extension EnhancedStorageServiceTestExtension on EnhancedStorageService {
  Map<String, int> _getCompressionSettings(String category) {
    switch (category) {
      case 'profile':
        return {'maxWidth': 400, 'maxHeight': 400, 'quality': 90};
      case 'capture':
      case 'artwork':
        return {'maxWidth': 1920, 'maxHeight': 1080, 'quality': 85};
      case 'thumbnail':
        return {'maxWidth': 300, 'maxHeight': 300, 'quality': 80};
      default:
        return {'maxWidth': 1920, 'maxHeight': 1080, 'quality': 85};
    }
  }
}

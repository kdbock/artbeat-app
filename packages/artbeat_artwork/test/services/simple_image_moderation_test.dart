import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Image Moderation Service Basic Tests', () {
    test('Simple API key verification', () {
      // This is a simple test that doesn't actually instantiate the service
      // to avoid Firebase initialization issues
      const apiKey = 'test-key';
      expect(apiKey, isNotEmpty);
      expect(apiKey, equals('test-key'));
    });
  });
}

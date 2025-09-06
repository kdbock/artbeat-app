import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_art_walk/src/services/art_walk_security_service.dart';

void main() {
  group('ArtWalkSecurityService Tests', () {
    late ArtWalkSecurityService securityService;

    setUp(() {
      securityService = ArtWalkSecurityService.instance;
    });

    group('Input Validation Tests', () {
      test('should validate valid art walk input', () async {
        final result = await securityService.validateArtWalkInput(
          title: 'Valid Art Walk Title',
          description: 'This is a valid description for an art walk.',
          userId: 'test-user-123',
          tags: ['art', 'walk', 'outdoor'],
          zipCode: '12345',
        );

        expect(result.isValid, isTrue);
        expect(result.sanitizedData, isNotNull);
        expect(result.sanitizedData!['title'], equals('Valid Art Walk Title'));
      });

      test('should reject art walk with short title', () async {
        final result = await securityService.validateArtWalkInput(
          title: 'Hi', // Too short
          description: 'Valid description',
          userId: 'test-user-123',
        );

        expect(result.isValid, isFalse);
        expect(result.errorCode, equals('INVALID_TITLE_LENGTH'));
      });

      test('should reject art walk with long title', () async {
        final longTitle = 'A' * 101; // Too long
        final result = await securityService.validateArtWalkInput(
          title: longTitle,
          description: 'Valid description',
          userId: 'test-user-123',
        );

        expect(result.isValid, isFalse);
        expect(result.errorCode, equals('INVALID_TITLE_LENGTH'));
      });

      test('should reject art walk with long description', () async {
        final longDescription = 'A' * 2001; // Too long
        final result = await securityService.validateArtWalkInput(
          title: 'Valid Title',
          description: longDescription,
          userId: 'test-user-123',
        );

        expect(result.isValid, isFalse);
        expect(result.errorCode, equals('INVALID_DESCRIPTION_LENGTH'));
      });

      test('should reject art walk with prohibited content', () async {
        final result = await securityService.validateArtWalkInput(
          title: 'Art Walk with <script>alert("xss")</script>',
          description: 'Valid description',
          userId: 'test-user-123',
        );

        expect(result.isValid, isFalse);
        expect(result.errorCode, equals('PROHIBITED_CONTENT'));
      });

      test('should reject invalid ZIP code', () async {
        final result = await securityService.validateArtWalkInput(
          title: 'Valid Title',
          description: 'Valid description',
          userId: 'test-user-123',
          zipCode: '123', // Invalid ZIP
        );

        expect(result.isValid, isFalse);
        expect(result.errorCode, equals('INVALID_ZIP_CODE'));
      });

      test('should accept valid ZIP code formats', () async {
        // Test 5-digit ZIP
        var result = await securityService.validateArtWalkInput(
          title: 'Valid Title',
          description: 'Valid description',
          userId: 'test-user-123',
          zipCode: '12345',
        );
        expect(result.isValid, isTrue);

        // Test ZIP+4 format
        result = await securityService.validateArtWalkInput(
          title: 'Valid Title',
          description: 'Valid description',
          userId: 'test-user-123',
          zipCode: '12345-6789',
        );
        expect(result.isValid, isTrue);
      });

      test('should reject excessive tags', () async {
        final tooManyTags = List.generate(11, (i) => 'tag$i');
        final result = await securityService.validateArtWalkInput(
          title: 'Valid Title',
          description: 'Valid description',
          userId: 'test-user-123',
          tags: tooManyTags,
        );

        expect(result.isValid, isFalse);
        expect(result.errorCode, equals('INVALID_TAGS'));
      });
    });

    group('Comment Validation Tests', () {
      test('should validate valid comment input', () async {
        final result = await securityService.validateCommentInput(
          content: 'This is a great art walk!',
          userId: 'test-user-123',
          artWalkId: 'walk-123',
        );

        expect(result.isValid, isTrue);
        expect(
          result.sanitizedData!['content'],
          equals('This is a great art walk!'),
        );
      });

      test('should reject empty comment', () async {
        final result = await securityService.validateCommentInput(
          content: '   ', // Empty/whitespace only
          userId: 'test-user-123',
          artWalkId: 'walk-123',
        );

        expect(result.isValid, isFalse);
        expect(result.errorCode, equals('INVALID_COMMENT_LENGTH'));
      });

      test('should reject comment that is too long', () async {
        final longComment = 'A' * 501; // Too long
        final result = await securityService.validateCommentInput(
          content: longComment,
          userId: 'test-user-123',
          artWalkId: 'walk-123',
        );

        expect(result.isValid, isFalse);
        expect(result.errorCode, equals('INVALID_COMMENT_LENGTH'));
      });

      test('should reject comment with prohibited content', () async {
        final result = await securityService.validateCommentInput(
          content: 'Check this out: javascript:alert("xss")',
          userId: 'test-user-123',
          artWalkId: 'walk-123',
        );

        expect(result.isValid, isFalse);
        expect(result.errorCode, equals('PROHIBITED_CONTENT'));
      });

      test('should detect spam content', () async {
        final result = await securityService.validateCommentInput(
          content:
              'Buy now! Click here for free money! Limited time offer, act now!',
          userId: 'test-user-123',
          artWalkId: 'walk-123',
        );

        expect(result.isValid, isFalse);
        expect(result.errorCode, equals('SPAM_DETECTED'));
      });

      test('should detect repetitive spam patterns', () async {
        final result = await securityService.validateCommentInput(
          content:
              'AAAAA check this out check this out check this out check this out',
          userId: 'test-user-123',
          artWalkId: 'walk-123',
        );

        expect(result.isValid, isFalse);
        expect(result.errorCode, equals('SPAM_DETECTED'));
      });
    });

    group('Input Sanitization Tests', () {
      test('should sanitize HTML tags', () async {
        final result = await securityService.validateArtWalkInput(
          title: 'Art Walk <b>Bold</b> Title',
          description:
              'Description with <em>emphasis</em> and <span>spans</span>',
          userId: 'test-user-123',
        );

        expect(result.isValid, isTrue);
        expect(result.sanitizedData!['title'], equals('Art Walk Bold Title'));
        expect(
          result.sanitizedData!['description'],
          equals('Description with emphasis and spans'),
        );
      });

      test('should sanitize dangerous characters', () async {
        final result = await securityService.validateArtWalkInput(
          title: 'Art Walk & "Quotes" Title',
          description:
              "Description with 'single' and \"double\" quotes & ampersands",
          userId: 'test-user-123',
        );

        expect(result.isValid, isTrue);
        expect(
          result.sanitizedData!['title'],
          equals('Art Walk  Quotes Title'),
        );
      });

      test('should trim whitespace', () async {
        final result = await securityService.validateArtWalkInput(
          title: '   Padded Title   ',
          description: '   Padded Description   ',
          userId: 'test-user-123',
        );

        expect(result.isValid, isTrue);
        expect(result.sanitizedData!['title'], equals('Padded Title'));
        expect(
          result.sanitizedData!['description'],
          equals('Padded Description'),
        );
      });
    });

    group('Security Token Tests', () {
      test('should generate secure tokens', () {
        final token1 = securityService.generateSecureToken();
        final token2 = securityService.generateSecureToken();

        expect(token1, isNotEmpty);
        expect(token2, isNotEmpty);
        expect(token1, isNot(equals(token2))); // Should be unique
        expect(token1.length, greaterThan(20)); // Should be sufficiently long
      });

      test('should hash sensitive data consistently', () {
        const testData = 'sensitive-data-123';
        final hash1 = securityService.hashSensitiveData(testData);
        final hash2 = securityService.hashSensitiveData(testData);

        expect(hash1, equals(hash2)); // Should be consistent
        expect(
          hash1,
          isNot(equals(testData)),
        ); // Should be different from input
        expect(hash1.length, equals(64)); // SHA-256 produces 64-char hex string
      });

      test('should produce different hashes for different data', () {
        final hash1 = securityService.hashSensitiveData('data1');
        final hash2 = securityService.hashSensitiveData('data2');

        expect(hash1, isNot(equals(hash2)));
      });
    });
  });
}

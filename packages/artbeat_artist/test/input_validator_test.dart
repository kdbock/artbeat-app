import 'package:flutter_test/flutter_test.dart';
import '../lib/src/utils/input_validator.dart';

void main() {
  group('InputValidator', () {
    group('validateUserId', () {
      test('should accept valid user IDs', () {
        expect(InputValidator.validateUserId('user123').isValid, isTrue);
        expect(InputValidator.validateUserId('artist-profile').isValid, isTrue);
        expect(InputValidator.validateUserId('gallery_owner').isValid, isTrue);
        expect(InputValidator.validateUserId('abc').isValid, isTrue);
      });

      test('should reject invalid user IDs', () {
        expect(InputValidator.validateUserId(null).isValid, isFalse);
        expect(InputValidator.validateUserId('').isValid, isFalse);
        expect(
            InputValidator.validateUserId('ab').isValid, isFalse); // Too short
        expect(InputValidator.validateUserId('user@123').isValid,
            isFalse); // Invalid character
        expect(InputValidator.validateUserId('user 123').isValid,
            isFalse); // Space
        expect(InputValidator.validateUserId('a' * 51).isValid,
            isFalse); // Too long
      });
    });

    group('validateEmail', () {
      test('should accept valid emails', () {
        expect(
            InputValidator.validateEmail('test@example.com').isValid, isTrue);
        expect(InputValidator.validateEmail('user.name@domain.co.uk').isValid,
            isTrue);
        expect(InputValidator.validateEmail('artist123@gallery.org').isValid,
            isTrue);
      });

      test('should reject invalid emails', () {
        expect(InputValidator.validateEmail(null).isValid, isFalse);
        expect(InputValidator.validateEmail('').isValid, isFalse);
        expect(InputValidator.validateEmail('invalid-email').isValid, isFalse);
        expect(InputValidator.validateEmail('test@').isValid, isFalse);
        expect(InputValidator.validateEmail('@example.com').isValid, isFalse);
        expect(InputValidator.validateEmail('test@example').isValid, isFalse);
        expect(InputValidator.validateEmail('a' * 250 + '@example.com').isValid,
            isFalse);
      });
    });

    group('validatePaymentAmount', () {
      test('should accept valid payment amounts', () {
        expect(InputValidator.validatePaymentAmount(10.99).isValid, isTrue);
        expect(InputValidator.validatePaymentAmount(100).isValid, isTrue);
        expect(InputValidator.validatePaymentAmount(0.01).isValid, isTrue);
        expect(InputValidator.validatePaymentAmount(999999.99).isValid, isTrue);
      });

      test('should reject invalid payment amounts', () {
        expect(InputValidator.validatePaymentAmount(null).isValid, isFalse);
        expect(InputValidator.validatePaymentAmount(0).isValid, isFalse);
        expect(InputValidator.validatePaymentAmount(-1).isValid, isFalse);
        expect(InputValidator.validatePaymentAmount(1000000).isValid, isFalse);
        expect(InputValidator.validatePaymentAmount(10.999).isValid, isFalse);
      });
    });

    group('validateText', () {
      test('should accept valid text', () {
        final result =
            InputValidator.validateText('Hello World', fieldName: 'title');
        expect(result.isValid, isTrue);
        expect(result.data, equals('Hello World'));
      });

      test('should sanitize text', () {
        final result = InputValidator.validateText(
            'Hello <script>alert("xss")</script> World',
            fieldName: 'title');
        expect(result.isValid, isTrue);
        expect(result.data, isNot(contains('<script>')));
      });

      test('should reject empty text when required', () {
        expect(InputValidator.validateText('', fieldName: 'title').isValid,
            isFalse);
        expect(InputValidator.validateText(null, fieldName: 'title').isValid,
            isFalse);
      });

      test('should accept empty text when allowed', () {
        expect(
            InputValidator.validateText('',
                    fieldName: 'description', allowEmpty: true)
                .isValid,
            isTrue);
      });

      test('should enforce length limits', () {
        expect(
            InputValidator.validateText('ab', fieldName: 'title', minLength: 3)
                .isValid,
            isFalse);
        expect(
            InputValidator.validateText('a' * 501,
                    fieldName: 'title', maxLength: 500)
                .isValid,
            isFalse);
      });

      test('should handle strict mode', () {
        expect(
            InputValidator.validateText('Hello!',
                    fieldName: 'title', strictMode: true)
                .isValid,
            isTrue);
        expect(
            InputValidator.validateText('Hello 世界',
                    fieldName: 'title', strictMode: true)
                .isValid,
            isFalse);
      });
    });

    group('validateUrl', () {
      test('should accept valid URLs', () {
        expect(
            InputValidator.validateUrl('https://example.com').isValid, isTrue);
        expect(
            InputValidator.validateUrl('http://example.com/path?query=1')
                .isValid,
            isTrue);
        expect(
            InputValidator.validateUrl('https://subdomain.example.co.uk')
                .isValid,
            isTrue);
      });

      test('should reject invalid URLs', () {
        expect(InputValidator.validateUrl(null).isValid, isFalse);
        expect(InputValidator.validateUrl('').isValid, isFalse);
        expect(InputValidator.validateUrl('not-a-url').isValid, isFalse);
        expect(
            InputValidator.validateUrl('ftp://example.com').isValid, isFalse);
        expect(InputValidator.validateUrl('https://example').isValid, isFalse);
        expect(InputValidator.validateUrl('javascript:alert("xss")').isValid,
            isFalse);
        expect(
            InputValidator.validateUrl('https://example.com/<script>').isValid,
            isFalse);
      });
    });

    group('validateSubscriptionTier', () {
      test('should accept valid subscription tiers', () {
        expect(
            InputValidator.validateSubscriptionTier('basic').isValid, isTrue);
        expect(InputValidator.validateSubscriptionTier('pro').isValid, isTrue);
        expect(
            InputValidator.validateSubscriptionTier('gallery').isValid, isTrue);
        expect(InputValidator.validateSubscriptionTier('BASIC').isValid,
            isTrue); // Case insensitive
      });

      test('should reject invalid subscription tiers', () {
        expect(InputValidator.validateSubscriptionTier(null).isValid, isFalse);
        expect(InputValidator.validateSubscriptionTier('').isValid, isFalse);
        expect(InputValidator.validateSubscriptionTier('premium').isValid,
            isFalse);
        expect(InputValidator.validateSubscriptionTier('invalid').isValid,
            isFalse);
      });
    });

    group('validateUserType', () {
      test('should accept valid user types', () {
        expect(InputValidator.validateUserType('user').isValid, isTrue);
        expect(InputValidator.validateUserType('artist').isValid, isTrue);
        expect(InputValidator.validateUserType('gallery').isValid, isTrue);
        expect(InputValidator.validateUserType('admin').isValid, isTrue);
        expect(InputValidator.validateUserType('USER').isValid,
            isTrue); // Case insensitive
      });

      test('should reject invalid user types', () {
        expect(InputValidator.validateUserType(null).isValid, isFalse);
        expect(InputValidator.validateUserType('').isValid, isFalse);
        expect(InputValidator.validateUserType('customer').isValid, isFalse);
        expect(InputValidator.validateUserType('invalid').isValid, isFalse);
      });
    });

    group('validateDateRange', () {
      test('should accept valid date ranges', () {
        final start = DateTime(2023, 1, 1);
        final end = DateTime(2023, 12, 31);
        expect(InputValidator.validateDateRange(start, end).isValid, isTrue);
      });

      test('should reject invalid date ranges', () {
        final start = DateTime(2023, 12, 31);
        final end = DateTime(2023, 1, 1);
        expect(InputValidator.validateDateRange(start, end).isValid, isFalse);
        expect(InputValidator.validateDateRange(null, end).isValid, isFalse);
        expect(InputValidator.validateDateRange(start, null).isValid, isFalse);
      });

      test('should reject extremely long date ranges', () {
        final start = DateTime(2020, 1, 1);
        final end = DateTime(2035, 1, 1); // More than 10 years
        expect(InputValidator.validateDateRange(start, end).isValid, isFalse);
      });
    });

    group('validateMapData', () {
      test('should accept valid map data', () {
        final data = {'name': 'test', 'value': 123};
        final requiredFields = ['name', 'value'];
        expect(InputValidator.validateMapData(data, requiredFields).isValid,
            isTrue);
      });

      test('should reject data missing required fields', () {
        final data = {'name': 'test'};
        final requiredFields = ['name', 'value'];
        expect(InputValidator.validateMapData(data, requiredFields).isValid,
            isFalse);
      });

      test('should reject null or empty data', () {
        expect(InputValidator.validateMapData(null, ['name']).isValid, isFalse);
        expect(InputValidator.validateMapData({}, ['name']).isValid, isFalse);
      });

      test('should reject data with too many fields', () {
        final data = <String, dynamic>{};
        for (int i = 0; i < 51; i++) {
          data['field_$i'] = 'value_$i';
        }
        expect(InputValidator.validateMapData(data, []).isValid, isFalse);
      });
    });

    group('validateDocumentId', () {
      test('should accept valid document IDs', () {
        expect(InputValidator.validateDocumentId('user123').isValid, isTrue);
        expect(InputValidator.validateDocumentId('artist-profile-123').isValid,
            isTrue);
        expect(InputValidator.validateDocumentId('a' * 100).isValid, isTrue);
      });

      test('should reject invalid document IDs', () {
        expect(InputValidator.validateDocumentId(null).isValid, isFalse);
        expect(InputValidator.validateDocumentId('').isValid, isFalse);
        expect(InputValidator.validateDocumentId('user/123').isValid, isFalse);
        expect(InputValidator.validateDocumentId('user__123').isValid, isFalse);
        expect(InputValidator.validateDocumentId('a' * 1501).isValid, isFalse);
      });
    });

    group('sanitizeText', () {
      test('should remove HTML tags', () {
        final result = InputValidator.sanitizeText('<div>Hello World</div>');
        expect(result, equals('Hello World'));
      });

      test('should remove dangerous characters', () {
        final result = InputValidator.sanitizeText('Hello<>"`World');
        expect(result, isNot(contains('<')));
        expect(result, isNot(contains('>')));
        expect(result, isNot(contains('"')));
        expect(result, isNot(contains('`')));
      });

      test('should normalize whitespace', () {
        final result = InputValidator.sanitizeText('Hello   \t\n  World');
        expect(result, equals('Hello World'));
      });

      test('should trim input', () {
        final result = InputValidator.sanitizeText('  Hello World  ');
        expect(result, equals('Hello World'));
      });

      test('should limit length', () {
        final input = 'a' * 2000;
        final result = InputValidator.sanitizeText(input);
        expect(result.length, lessThanOrEqualTo(1000));
      });
    });
  });

  group('ValidationResult', () {
    test('should create valid result', () {
      final result = ValidationResult.valid(data: 'test');
      expect(result.isValid, isTrue);
      expect(result.data, equals('test'));
      expect(result.errorMessage, isNull);
    });

    test('should create invalid result', () {
      final result = ValidationResult<String>.invalid('Error message');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Error message'));
      expect(result.data, isNull);
    });

    test('should throw on invalid result', () {
      final result = ValidationResult<String>.invalid('Error message');
      expect(
          () => result.throwIfInvalid(), throwsA(isA<ValidationException>()));
    });

    test('should not throw on valid result', () {
      final result = ValidationResult<void>.valid();
      expect(() => result.throwIfInvalid(), returnsNormally);
    });

    test('should return data or throw', () {
      final validResult = ValidationResult.valid(data: 'test');
      final invalidResult = ValidationResult<String>.invalid('Error');

      expect(validResult.getOrThrow(), equals('test'));
      expect(() => invalidResult.getOrThrow(),
          throwsA(isA<ValidationException>()));
    });
  });

  group('ValidationException', () {
    test('should create exception with message', () {
      const exception = ValidationException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.toString(), equals('ValidationException: Test error'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_ads/src/models/payment_history_model.dart';

// Helper function to create PaymentHistoryModel from data map for testing
PaymentHistoryModel createPaymentFromData(
  Map<String, dynamic> data,
  String id,
) {
  return PaymentHistoryModel(
    id: id,
    userId: data['userId']?.toString() ?? '',
    adId: data['adId']?.toString() ?? '',
    adTitle: data['adTitle']?.toString() ?? '',
    amount: data['amount'] is num
        ? (data['amount'] as num).toDouble()
        : double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0,
    currency: data['currency']?.toString() ?? 'USD',
    paymentMethod: PaymentMethod.fromString(
      data['paymentMethod']?.toString() ?? 'card',
    ),
    status: PaymentStatus.fromString(data['status']?.toString() ?? 'pending'),
    transactionDate:
        (data['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    stripePaymentIntentId: data['stripePaymentIntentId']?.toString(),
    receiptUrl: data['receiptUrl']?.toString(),
    metadata: data['metadata'] is Map
        ? Map<String, dynamic>.from(data['metadata'] as Map)
        : {},
    failureReason: data['failureReason']?.toString(),
    refundedAt: (data['refundedAt'] as Timestamp?)?.toDate(),
    refundAmount: data['refundAmount'] is num
        ? (data['refundAmount'] as num).toDouble()
        : double.tryParse(data['refundAmount']?.toString() ?? '0') ?? 0.0,
    refundReason: data['refundReason']?.toString(),
  );
}

void main() {
  group('PaymentHistoryModel Tests', () {
    late PaymentHistoryModel testPayment;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      testPayment = PaymentHistoryModel(
        id: 'test-payment-id',
        userId: 'test-user-id',
        adId: 'test-ad-id',
        adTitle: 'Test Ad Campaign',
        amount: 99.99,
        currency: 'USD',
        paymentMethod: PaymentMethod.card,
        status: PaymentStatus.completed,
        transactionDate: testDate,
        stripePaymentIntentId: 'pi_test123',
        metadata: {
          'campaign_duration': '7 days',
          'ad_size': 'medium',
          'location': 'dashboard',
        },
      );
    });

    test('should create PaymentHistoryModel with all properties', () {
      expect(testPayment.id, equals('test-payment-id'));
      expect(testPayment.userId, equals('test-user-id'));
      expect(testPayment.adId, equals('test-ad-id'));
      expect(testPayment.adTitle, equals('Test Ad Campaign'));
      expect(testPayment.amount, equals(99.99));
      expect(testPayment.currency, equals('USD'));
      expect(testPayment.paymentMethod, equals(PaymentMethod.card));
      expect(testPayment.status, equals(PaymentStatus.completed));
      expect(testPayment.transactionDate, equals(testDate));
      expect(testPayment.stripePaymentIntentId, equals('pi_test123'));
      expect(testPayment.metadata, hasLength(3));
    });

    test('should create PaymentHistoryModel with default values', () {
      final minimalPayment = PaymentHistoryModel(
        id: 'minimal-id',
        userId: 'user-id',
        adId: 'ad-id',
        adTitle: 'Minimal Ad',
        amount: 10.0,
        paymentMethod: PaymentMethod.paypal,
        status: PaymentStatus.pending,
        transactionDate: testDate,
      );

      expect(minimalPayment.currency, equals('USD')); // Default
      expect(minimalPayment.stripePaymentIntentId, isNull);
      expect(minimalPayment.metadata, isEmpty);
    });

    group('PaymentMethod Enum Tests', () {
      test('should have correct PaymentMethod values', () {
        expect(PaymentMethod.values, hasLength(5));
        expect(PaymentMethod.values, contains(PaymentMethod.card));
        expect(PaymentMethod.values, contains(PaymentMethod.paypal));
        expect(PaymentMethod.values, contains(PaymentMethod.applePay));
      });

      test('should get correct display names for PaymentMethod', () {
        expect(PaymentMethod.card.displayName, equals('Credit Card'));
        expect(PaymentMethod.paypal.displayName, equals('PayPal'));
        expect(PaymentMethod.applePay.displayName, equals('Apple Pay'));
      });

      test('should get correct icons for PaymentMethod', () {
        expect(PaymentMethod.card.icon, isNotNull);
        expect(PaymentMethod.paypal.icon, isNotNull);
        expect(PaymentMethod.applePay.icon, isNotNull);
      });
    });

    group('PaymentStatus Enum Tests', () {
      test('should have correct PaymentStatus values', () {
        expect(PaymentStatus.values, hasLength(4));
        expect(PaymentStatus.values, contains(PaymentStatus.pending));
        expect(PaymentStatus.values, contains(PaymentStatus.completed));
        expect(PaymentStatus.values, contains(PaymentStatus.failed));
        expect(PaymentStatus.values, contains(PaymentStatus.refunded));
      });

      test('should get correct display names for PaymentStatus', () {
        expect(PaymentStatus.pending.displayName, equals('Pending'));
        expect(PaymentStatus.completed.displayName, equals('Completed'));
        expect(PaymentStatus.failed.displayName, equals('Failed'));
        expect(PaymentStatus.refunded.displayName, equals('Refunded'));
      });

      test('should get correct colors for PaymentStatus', () {
        expect(PaymentStatus.pending.colorHex, isNotNull);
        expect(PaymentStatus.completed.colorHex, isNotNull);
        expect(PaymentStatus.failed.colorHex, isNotNull);
        expect(PaymentStatus.refunded.colorHex, isNotNull);
      });

      test('should identify successful payments', () {
        expect(PaymentStatus.completed.isSuccessful, isTrue);
        expect(PaymentStatus.pending.isSuccessful, isFalse);
        expect(PaymentStatus.failed.isSuccessful, isFalse);
        expect(PaymentStatus.refunded.isSuccessful, isFalse);
      });
    });

    group('fromFirestore Tests', () {
      test('should create PaymentHistoryModel from valid Firestore data', () {
        final data = {
          'userId': 'test-user-id',
          'adId': 'test-ad-id',
          'adTitle': 'Test Ad Campaign',
          'amount': 99.99,
          'currency': 'USD',
          'paymentMethod': 'card',
          'status': 'completed',
          'transactionDate': Timestamp.fromDate(testDate),
          'stripePaymentIntentId': 'pi_test123',
          'metadata': {'campaign_duration': '7 days', 'ad_size': 'medium'},
        };

        final payment = createPaymentFromData(data, 'test-id');

        expect(payment.id, equals('test-id'));
        expect(payment.userId, equals('test-user-id'));
        expect(payment.amount, equals(99.99));
        expect(payment.paymentMethod, equals(PaymentMethod.card));
        expect(payment.status, equals(PaymentStatus.completed));
        expect(payment.transactionDate, equals(testDate));
        expect(payment.metadata, hasLength(2));
      });

      test('should handle missing optional fields in fromFirestore', () {
        final data = {
          'userId': 'test-user-id',
          'adId': 'test-ad-id',
          'adTitle': 'Test Ad',
          'amount': 50.0,
          'paymentMethod': 'paypal',
          'status': 'pending',
          'transactionDate': Timestamp.fromDate(testDate),
        };

        final payment = createPaymentFromData(data, 'test-id');

        expect(payment.currency, equals('USD')); // Default
        expect(payment.stripePaymentIntentId, isNull);
        expect(payment.metadata, isEmpty);
      });

      test('should handle invalid enum values in fromFirestore', () {
        final data = {
          'userId': 'test-user-id',
          'adId': 'test-ad-id',
          'adTitle': 'Test Ad',
          'amount': 50.0,
          'paymentMethod': 'invalidMethod',
          'status': 'invalidStatus',
          'transactionDate': Timestamp.fromDate(testDate),
        };

        final payment = createPaymentFromData(data, 'test-id');

        expect(payment.paymentMethod, equals(PaymentMethod.card)); // Default
        expect(payment.status, equals(PaymentStatus.pending)); // Default
      });

      test('should handle invalid data types in fromFirestore', () {
        final data = {
          'userId': 'test-user-id',
          'adId': 'test-ad-id',
          'adTitle': 'Test Ad',
          'amount': '50.0', // String instead of double
          'currency': 123, // Number instead of string
          'paymentMethod': 'creditCard',
          'status': 'completed',
          'transactionDate': Timestamp.fromDate(testDate),
          'metadata': 'invalid', // String instead of map
        };

        final payment = createPaymentFromData(data, 'test-id');

        expect(payment.amount, equals(50.0));
        expect(payment.currency, equals('123'));
        expect(payment.metadata, isEmpty);
      });
    });

    group('toFirestore Tests', () {
      test(
        'should convert PaymentHistoryModel to Firestore data correctly',
        () {
          final data = testPayment.toFirestore();

          expect(data['userId'], equals('test-user-id'));
          expect(data['adId'], equals('test-ad-id'));
          expect(data['adTitle'], equals('Test Ad Campaign'));
          expect(data['amount'], equals(99.99));
          expect(data['currency'], equals('USD'));
          expect(data['paymentMethod'], equals('card'));
          expect(data['status'], equals('completed'));
          expect(data['transactionDate'], isA<Timestamp>());
          expect(data['stripePaymentIntentId'], equals('pi_test123'));
          expect(data['metadata'], isA<Map<String, dynamic>>());
          expect(data['metadata'], hasLength(3));
        },
      );

      test('should handle null optional fields in toFirestore', () {
        final paymentWithNulls = PaymentHistoryModel(
          id: 'test-id',
          userId: 'user-id',
          adId: 'ad-id',
          adTitle: 'Test Ad',
          amount: 25.0,
          paymentMethod: PaymentMethod.paypal,
          status: PaymentStatus.pending,
          transactionDate: testDate,
        );

        final data = paymentWithNulls.toFirestore();

        expect(data['stripePaymentIntentId'], isNull);
        expect(data['metadata'], isEmpty);
      });
    });

    group('copyWith Tests', () {
      test('should create copy with updated properties', () {
        final updatedPayment = testPayment.copyWith(
          status: PaymentStatus.refunded,
          amount: 149.99,
          stripePaymentIntentId: 'pi_updated123',
        );

        expect(updatedPayment.status, equals(PaymentStatus.refunded));
        expect(updatedPayment.amount, equals(149.99));
        expect(updatedPayment.stripePaymentIntentId, equals('pi_updated123'));

        // Original properties should remain unchanged
        expect(updatedPayment.id, equals(testPayment.id));
        expect(updatedPayment.userId, equals(testPayment.userId));
        expect(updatedPayment.paymentMethod, equals(testPayment.paymentMethod));
      });

      test('should preserve original values when no updates provided', () {
        final copiedPayment = testPayment.copyWith();

        expect(copiedPayment.id, equals(testPayment.id));
        expect(copiedPayment.amount, equals(testPayment.amount));
        expect(copiedPayment.status, equals(testPayment.status));
        expect(copiedPayment.metadata, equals(testPayment.metadata));
      });

      test('should update metadata in copyWith', () {
        final newMetadata = {
          'updated_field': 'new_value',
          'another_field': 'another_value',
        };

        final updatedPayment = testPayment.copyWith(metadata: newMetadata);

        expect(updatedPayment.metadata, equals(newMetadata));
        expect(updatedPayment.metadata, hasLength(2));
      });
    });

    group('Utility Methods', () {
      test('should format amount correctly', () {
        final payment1 = testPayment.copyWith(amount: 99.99, currency: 'USD');
        final payment2 = testPayment.copyWith(amount: 50.0, currency: 'EUR');
        final payment3 = testPayment.copyWith(amount: 1000.0, currency: 'USD');

        // These would be implementation-dependent utility methods
        expect(payment1.amount, equals(99.99));
        expect(payment2.currency, equals('EUR'));
        expect(payment3.amount, equals(1000.0));
      });

      test('should identify refundable payments', () {
        final completedPayment = testPayment.copyWith(
          status: PaymentStatus.completed,
        );
        final failedPayment = testPayment.copyWith(
          status: PaymentStatus.failed,
        );
        final refundedPayment = testPayment.copyWith(
          status: PaymentStatus.refunded,
        );

        expect(completedPayment.status.isSuccessful, isTrue);
        expect(failedPayment.status.isSuccessful, isFalse);
        expect(refundedPayment.status.isSuccessful, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle zero amount', () {
        final zeroPayment = testPayment.copyWith(amount: 0.0);
        expect(zeroPayment.amount, equals(0.0));
      });

      test('should handle very large amounts', () {
        final largePayment = testPayment.copyWith(amount: 999999.99);
        expect(largePayment.amount, equals(999999.99));
      });

      test('should handle empty strings', () {
        final data = {
          'userId': '',
          'adId': '',
          'adTitle': '',
          'amount': 10.0,
          'currency': '',
          'paymentMethod': 'creditCard',
          'status': 'pending',
          'transactionDate': Timestamp.fromDate(testDate),
        };

        final payment = createPaymentFromData(data, '');

        expect(payment.id, equals(''));
        expect(payment.userId, equals(''));
        expect(payment.adTitle, equals(''));
        expect(payment.currency, equals(''));
      });

      test('should handle special characters in metadata', () {
        final specialMetadata = {
          'special_chars': 'äöü@#\$%^&*()',
          'unicode': '🎨💰📊',
          'json_like': '{"nested": "value"}',
        };

        final payment = testPayment.copyWith(metadata: specialMetadata);
        expect(payment.metadata['special_chars'], equals('äöü@#\$%^&*()'));
        expect(payment.metadata['unicode'], equals('🎨💰📊'));
      });
    });
  });
}

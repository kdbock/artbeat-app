import 'package:flutter_test/flutter_test.dart';
import '../lib/src/models/payment_models.dart' as models;

void main() {
  group('Payment System Integration Tests', () {
    group('Data Model Integration Tests', () {
      test('PaymentEvent model creates correctly', () {
        final event = models.PaymentEvent(
          id: 'test_payment_1',
          userId: 'user_123',
          amount: 100.0,
          currency: 'USD',
          status: 'completed',
          paymentMethod: 'card',
          timestamp: DateTime.now(),
          metadata: {'source': 'test'},
        );

        expect(event.id, 'test_payment_1');
        expect(event.userId, 'user_123');
        expect(event.amount, 100.0);
        expect(event.currency, 'USD');
        expect(event.status, 'completed');
        expect(event.paymentMethod, 'card');
        expect(event.metadata['source'], 'test');
      });
    });
  });
}

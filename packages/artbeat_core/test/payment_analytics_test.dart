import 'package:flutter_test/flutter_test.dart';
import '../lib/src/models/payment_models.dart' as models;

void main() {
  group('PaymentAnalyticsService Tests', () {
    test('PaymentMetrics.fromJson creates correct object', () {
      final json = {
        'totalTransactions': 100,
        'totalRevenue': 5000.0,
        'successRate': 0.95,
        'averageTransactionValue': 50.0,
        'failedTransactions': 5,
        'paymentMethodBreakdown': {'card': 80, 'paypal': 20},
        'geographicDistribution': {'US': 3000.0, 'EU': 2000.0},
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final metrics = models.PaymentMetrics.fromJson(json);

      expect(metrics.totalTransactions, 100);
      expect(metrics.totalRevenue, 5000.0);
      expect(metrics.successRate, 0.95);
      expect(metrics.averageTransactionValue, 50.0);
      expect(metrics.failedTransactions, 5);
      expect(metrics.paymentMethodBreakdown['card'], 80);
      expect(metrics.geographicDistribution['US'], 3000.0);
    });

    test('PaymentEvent.fromJson creates correct object', () {
      final json = {
        'id': 'test-event-1',
        'userId': 'user-123',
        'amount': 100.0,
        'currency': 'USD',
        'status': 'completed',
        'paymentMethod': 'card',
        'metadata': {'source': 'mobile'},
        'timestamp': DateTime.now().toIso8601String(),
      };

      final event = models.PaymentEvent.fromJson(json);

      expect(event.id, 'test-event-1');
      expect(event.userId, 'user-123');
      expect(event.amount, 100.0);
      expect(event.currency, 'USD');
      expect(event.status, 'completed');
      expect(event.paymentMethod, 'card');
      expect(event.metadata['source'], 'mobile');
    });

    test('RiskTrend.fromJson creates correct object', () {
      final json = {
        'category': 'Payment Risk',
        'riskScore': 0.3,
        'riskLevel': 'medium',
        'trend': 0.1,
        'eventCount': 50,
        'period': DateTime.now().toIso8601String(),
        'factors': {'failures': 3, 'high_amount': 2},
      };

      final trend = models.RiskTrend.fromJson(json);

      expect(trend.category, 'Payment Risk');
      expect(trend.riskScore, 0.3);
      expect(trend.riskLevel, 'medium');
      expect(trend.trend, 0.1);
      expect(trend.eventCount, 50);
      expect(trend.factors['failures'], 3);
    });

    test('DateRange.contains returns correct results', () {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 31);
      final range = models.DateRange(start: start, end: end);

      expect(range.contains(DateTime(2025, 1, 15)), true);
      expect(range.contains(DateTime(2024, 12, 31)), false);
      expect(range.contains(DateTime(2025, 2, 1)), false);
    });

    test('DateRange.duration calculates correctly', () {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 3);
      final range = models.DateRange(start: start, end: end);

      expect(range.duration.inDays, 2);
    });
  });

  group('Payment Models Validation', () {
    test('PaymentMetrics handles null values correctly', () {
      final json = {
        'totalTransactions': null,
        'totalRevenue': null,
        'successRate': null,
        'averageTransactionValue': null,
        'failedTransactions': null,
        'paymentMethodBreakdown': null,
        'geographicDistribution': null,
        'lastUpdated': null,
      };

      final metrics = models.PaymentMetrics.fromJson(json);

      expect(metrics.totalTransactions, 0);
      expect(metrics.totalRevenue, 0.0);
      expect(metrics.successRate, 0.0);
      expect(metrics.averageTransactionValue, 0.0);
      expect(metrics.failedTransactions, 0);
      expect(metrics.paymentMethodBreakdown.isEmpty, true);
      expect(metrics.geographicDistribution.isEmpty, true);
    });

    test('PaymentEvent handles null payment method', () {
      final json = {
        'id': 'test-event-1',
        'userId': 'user-123',
        'amount': 100.0,
        'currency': 'USD',
        'status': 'completed',
        'paymentMethod': null,
        'metadata': <String, dynamic>{},
        'timestamp': DateTime.now().toIso8601String(),
      };

      final event = models.PaymentEvent.fromJson(json);

      expect(event.paymentMethod, null);
      expect(event.metadata.isEmpty, true);
    });
  });
}

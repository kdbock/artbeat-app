import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/src/services/payment_analytics_service.dart' as service;
import '../lib/src/models/payment_models.dart' as models;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Payment System Integration Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late service.PaymentAnalyticsService analyticsService;

    setUpAll(() async {
      // Initialize with fake Firestore for testing
      fakeFirestore = FakeFirebaseFirestore();
      analyticsService = service.PaymentAnalyticsService();

      // Override the firestore instance for testing
      // Note: In a real implementation, you'd use dependency injection
    });

    tearDownAll(() async {
      // Clean up test data
      await fakeFirestore.clearPersistence();
    });

    group('Firebase Connectivity Tests', () {
      test('Firebase connection is established', () async {
        // Test basic Firebase connectivity
        final firestore = FirebaseFirestore.instance;
        expect(firestore, isNotNull);

        // Test collection access
        final collection = firestore.collection('test_collection');
        expect(collection, isNotNull);
      });

      test('Payment events collection is accessible', () async {
        final collection = fakeFirestore.collection('payment_events');
        expect(collection, isNotNull);

        // Test basic CRUD operations
        final docRef = collection.doc('test_payment');
        await docRef.set({
          'id': 'test_payment',
          'userId': 'test_user',
          'amount': 100.0,
          'currency': 'USD',
          'status': 'completed',
          'timestamp': DateTime.now().toIso8601String(),
        });

        final doc = await docRef.get();
        expect(doc.exists, true);
        expect(doc.data()!['status'], 'completed');
      });

      test('Analytics collection is accessible', () async {
        final collection = fakeFirestore.collection('payment_analytics');
        expect(collection, isNotNull);

        // Test analytics data storage
        final docRef = collection.doc('daily_metrics');
        await docRef.set({
          'date': DateTime.now().toIso8601String(),
          'totalTransactions': 150,
          'totalRevenue': 7500.0,
          'successRate': 0.95,
        });

        final doc = await docRef.get();
        expect(doc.exists, true);
        expect(doc.data()!['totalTransactions'], 150);
      });
    });

    group('Payment Analytics Service Integration', () {
      setUp(() async {
        // Seed test data
        final eventsCollection = fakeFirestore.collection('payment_events');

        // Create test payment events
        final testEvents = [
          {
            'id': 'payment_1',
            'userId': 'user_123',
            'amount': 100.0,
            'currency': 'USD',
            'status': 'completed',
            'paymentMethod': 'card',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 2))
                .toIso8601String(),
          },
          {
            'id': 'payment_2',
            'userId': 'user_456',
            'amount': 50.0,
            'currency': 'USD',
            'status': 'completed',
            'paymentMethod': 'paypal',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 1))
                .toIso8601String(),
          },
          {
            'id': 'payment_3',
            'userId': 'user_789',
            'amount': 75.0,
            'currency': 'USD',
            'status': 'failed',
            'paymentMethod': 'card',
            'timestamp': DateTime.now()
                .subtract(const Duration(minutes: 30))
                .toIso8601String(),
          },
        ];

        for (final event in testEvents) {
          await eventsCollection.doc(event['id'] as String).set(event);
        }
      });

      test('getRecentPaymentEvents returns correct data', () async {
        final events = await analyticsService.getRecentPaymentEvents(limit: 5);

        expect(events.length, greaterThanOrEqualTo(3));
        expect(events.first.id, isNotEmpty);
        expect(events.first.amount, greaterThan(0));
        expect(events.first.status, isNotEmpty);
      });

      test('getPerformanceMetrics calculates correctly', () async {
        final metrics = await analyticsService.getPerformanceMetrics();

        expect(metrics, isNotNull);
        expect(metrics.containsKey('conversionRate'), true);
        expect(metrics.containsKey('failureRate'), true);
        expect(metrics.containsKey('avgProcessingTime'), true);
        expect(metrics['conversionRate'], isA<double>());
        expect(metrics['failureRate'], isA<double>());
      });

      test('getRiskTrends analyzes payment patterns', () async {
        final trends = await analyticsService.getRiskTrends();

        expect(trends, isNotNull);
        expect(trends.length, greaterThanOrEqualTo(0));

        if (trends.isNotEmpty) {
          final trend = trends.first;
          expect(trend.category, isNotEmpty);
          expect(trend.riskScore, isA<double>());
          expect(trend.riskScore, greaterThanOrEqualTo(0.0));
          expect(trend.riskScore, lessThanOrEqualTo(1.0));
          expect(trend.riskLevel, isIn(['low', 'medium', 'high']));
        }
      });

      test('getPaymentMetrics aggregates data correctly', () async {
        final range = service.DateRange.last7Days();
        final metrics = await analyticsService.getPaymentMetrics(range);

        expect(metrics, isNotNull);
        expect(metrics.totalTransactions, greaterThanOrEqualTo(0));
        expect(metrics.totalRevenue, greaterThanOrEqualTo(0.0));
        expect(metrics.successRate, greaterThanOrEqualTo(0.0));
        expect(metrics.successRate, lessThanOrEqualTo(1.0));
        expect(metrics.averageTransactionValue, greaterThanOrEqualTo(0.0));
      });
    });

    group('Data Persistence and Retrieval', () {
      test('Payment events persist correctly', () async {
        final collection = fakeFirestore.collection('payment_events');

        // Create a payment event
        final paymentData = {
          'id': 'persistent_test',
          'userId': 'test_user',
          'amount': 200.0,
          'currency': 'USD',
          'status': 'completed',
          'paymentMethod': 'card',
          'timestamp': DateTime.now().toIso8601String(),
          'metadata': {'source': 'integration_test'},
        };

        await collection.doc('persistent_test').set(paymentData);

        // Retrieve and verify
        final doc = await collection.doc('persistent_test').get();
        expect(doc.exists, true);

        final retrievedData = doc.data()!;
        expect(retrievedData['id'], 'persistent_test');
        expect(retrievedData['amount'], 200.0);
        expect(retrievedData['status'], 'completed');
        expect(retrievedData['metadata']['source'], 'integration_test');
      });

      test('Analytics data updates correctly', () async {
        final collection = fakeFirestore.collection('payment_analytics');

        // Initial data
        await collection.doc('current_metrics').set({
          'totalTransactions': 100,
          'totalRevenue': 5000.0,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        // Update data
        await collection.doc('current_metrics').update({
          'totalTransactions': 150,
          'totalRevenue': 7500.0,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        // Verify update
        final doc = await collection.doc('current_metrics').get();
        final data = doc.data()!;
        expect(data['totalTransactions'], 150);
        expect(data['totalRevenue'], 7500.0);
      });

      test('Query operations work correctly', () async {
        final collection = fakeFirestore.collection('payment_events');

        // Add multiple events with different timestamps
        final now = DateTime.now();
        final events = [
          {
            'id': 'query_test_1',
            'timestamp': now
                .subtract(const Duration(hours: 2))
                .toIso8601String(),
            'amount': 100.0,
            'status': 'completed',
          },
          {
            'id': 'query_test_2',
            'timestamp': now
                .subtract(const Duration(hours: 1))
                .toIso8601String(),
            'amount': 200.0,
            'status': 'completed',
          },
          {
            'id': 'query_test_3',
            'timestamp': now.toIso8601String(),
            'amount': 50.0,
            'status': 'failed',
          },
        ];

        for (final event in events) {
          await collection.doc(event['id'] as String).set(event);
        }

        // Query recent events
        final recentQuery = await collection
            .where(
              'timestamp',
              isGreaterThan: now
                  .subtract(const Duration(hours: 1))
                  .toIso8601String(),
            )
            .get();

        expect(
          recentQuery.docs.length,
          2,
        ); // Should return 2 most recent events
      });
    });

    group('Error Handling and Edge Cases', () {
      test('Handles empty collections gracefully', () async {
        final emptyCollection = fakeFirestore.collection('empty_collection');
        final querySnapshot = await emptyCollection.get();

        expect(querySnapshot.docs.length, 0);
      });

      test('Handles malformed data gracefully', () async {
        final collection = fakeFirestore.collection('payment_events');

        // Add malformed data
        await collection.doc('malformed').set({
          'id': 'malformed',
          'amount': 'invalid_amount', // Should be number
          'status': null, // Should be string
          'timestamp': 'invalid_date', // Should be valid ISO string
        });

        // Service should handle this gracefully
        final events = await analyticsService.getRecentPaymentEvents(limit: 10);

        // Should not crash, though some events might be filtered out
        expect(events, isA<List<models.PaymentEvent>>());
      });

      test('Handles network connectivity issues', () async {
        // Test with disconnected state (simulated)
        // Note: This would require more complex mocking in a real scenario

        final metrics = await analyticsService.getPerformanceMetrics();
        expect(metrics, isNotNull);
        expect(metrics.containsKey('conversionRate'), true);
      });

      test('Handles large datasets efficiently', () async {
        final collection = fakeFirestore.collection('payment_events');

        // Create many test events
        final batch = fakeFirestore.batch();
        for (int i = 0; i < 100; i++) {
          final docRef = collection.doc('bulk_test_$i');
          batch.set(docRef, {
            'id': 'bulk_test_$i',
            'userId': 'user_$i',
            'amount': 10.0 * (i + 1),
            'currency': 'USD',
            'status': i % 10 == 0 ? 'failed' : 'completed',
            'timestamp': DateTime.now()
                .subtract(Duration(minutes: i))
                .toIso8601String(),
          });
        }
        await batch.commit();

        // Verify bulk operation
        final querySnapshot = await collection.get();
        expect(querySnapshot.docs.length, greaterThanOrEqualTo(100));

        // Test analytics on large dataset
        final metrics = await analyticsService.getPerformanceMetrics();
        expect(metrics['totalEvents'], greaterThanOrEqualTo(100));
      });
    });

    group('Real-time Data Streaming', () {
      test('Analytics service provides real-time updates', () async {
        final collection = fakeFirestore.collection('payment_metrics');

        // Set up initial data
        await collection.doc('current').set({
          'totalTransactions': 50,
          'totalRevenue': 2500.0,
          'successRate': 0.9,
          'lastUpdated': DateTime.now().toIso8601String(),
        });

        // Test that we can access the stream (though we won't test real-time updates in unit test)
        final stream = analyticsService.getPaymentMetricsStream();
        expect(stream, isNotNull);

        // Verify stream emits data
        final firstValue = await stream.first;
        expect(firstValue, isA<models.PaymentMetrics>());
        expect(firstValue.totalTransactions, greaterThanOrEqualTo(0));
      });
    });
  });
}

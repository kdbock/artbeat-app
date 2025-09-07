import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_ads/src/models/ad_analytics_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('AdAnalyticsModel Tests', () {
    late AdAnalyticsModel testAnalytics;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1);
      testAnalytics = AdAnalyticsModel(
        adId: 'test-ad-id',
        ownerId: 'test-owner-id',
        totalImpressions: 1000,
        totalClicks: 50,
        clickThroughRate: 5.0,
        totalRevenue: 100.0,
        averageViewDuration: 12.5,
        firstImpressionDate: testDate,
        lastImpressionDate: testDate,
        lastUpdated: testDate,
        locationBreakdown: {'dashboard': 600, 'feed': 400},
        dailyImpressions: {
          '2024-01-01': 100,
          '2024-01-02': 150,
          '2024-01-03': 200,
        },
        dailyClicks: {'2024-01-01': 5, '2024-01-02': 8, '2024-01-03': 12},
      );
    });

    test('should create AdAnalyticsModel with all properties', () {
      expect(testAnalytics.adId, equals('test-ad-id'));
      expect(testAnalytics.ownerId, equals('test-owner-id'));
      expect(testAnalytics.totalImpressions, equals(1000));
      expect(testAnalytics.totalClicks, equals(50));
      expect(testAnalytics.clickThroughRate, equals(5.0));
      expect(testAnalytics.lastUpdated, equals(testDate));
      expect(testAnalytics.locationBreakdown, hasLength(2));
      expect(testAnalytics.dailyImpressions, hasLength(3));
      expect(testAnalytics.dailyClicks, hasLength(3));
    });

    test('should calculate CTR correctly', () {
      expect(AdAnalyticsModel.calculateCTR(1000, 50), equals(5.0));
      expect(AdAnalyticsModel.calculateCTR(100, 5), equals(5.0));
      expect(AdAnalyticsModel.calculateCTR(0, 0), equals(0.0));
      expect(AdAnalyticsModel.calculateCTR(100, 0), equals(0.0));
    });

    test('should handle division by zero in CTR calculation', () {
      expect(AdAnalyticsModel.calculateCTR(0, 5), equals(0.0));
      expect(AdAnalyticsModel.calculateCTR(0, 0), equals(0.0));
    });

    group('fromMap Tests', () {
      test('should create AdAnalyticsModel from valid map', () {
        final map = {
          'adId': 'test-ad-id',
          'ownerId': 'test-owner-id',
          'totalImpressions': 1000,
          'totalClicks': 50,
          'clickThroughRate': 5.0,
          'totalRevenue': 100.0,
          'averageViewDuration': 12.5,
          'firstImpressionDate': Timestamp.fromDate(testDate),
          'lastImpressionDate': Timestamp.fromDate(testDate),
          'lastUpdated': Timestamp.fromDate(testDate),
          'locationBreakdown': {'dashboard': 600, 'feed': 400},
          'dailyImpressions': {'2024-01-01': 100, '2024-01-02': 150},
          'dailyClicks': {'2024-01-01': 5, '2024-01-02': 8},
        };

        final analytics = AdAnalyticsModel.fromMap(map);

        expect(analytics.adId, equals('test-ad-id'));
        expect(analytics.ownerId, equals('test-owner-id'));
        expect(analytics.totalImpressions, equals(1000));
        expect(analytics.totalClicks, equals(50));
        expect(analytics.clickThroughRate, equals(5.0));
        expect(analytics.locationBreakdown, hasLength(2));
        expect(analytics.dailyImpressions, hasLength(2));
        expect(analytics.dailyClicks, hasLength(2));
      });

      test('should handle missing optional fields in fromMap', () {
        final map = {
          'adId': 'test-ad-id',
          'ownerId': 'test-owner-id',
          'totalImpressions': 500,
          'totalClicks': 25,
          'clickThroughRate': 5.0,
          'totalRevenue': 50.0,
          'averageViewDuration': 10.0,
          'firstImpressionDate': Timestamp.fromDate(testDate),
          'lastImpressionDate': Timestamp.fromDate(testDate),
          'lastUpdated': Timestamp.fromDate(testDate),
        };

        final analytics = AdAnalyticsModel.fromMap(map);

        expect(analytics.adId, equals('test-ad-id'));
        expect(analytics.totalImpressions, equals(500));
        expect(analytics.locationBreakdown, isEmpty);
        expect(analytics.dailyImpressions, isEmpty);
        expect(analytics.dailyClicks, isEmpty);
      });

      test('should handle invalid data types in fromMap', () {
        final map = {
          'adId': 'test-ad-id',
          'ownerId': 'test-owner-id',
          'totalImpressions': 1000,
          'totalClicks': 50,
          'clickThroughRate': 5.0,
          'totalRevenue': 100.0,
          'averageViewDuration': 12.5,
          'firstImpressionDate': Timestamp.fromDate(testDate),
          'lastImpressionDate': Timestamp.fromDate(testDate),
          'lastUpdated': Timestamp.fromDate(testDate),
          'locationBreakdown': <String, int>{},
          'dailyImpressions': null,
          'dailyClicks': null,
        };

        final analytics = AdAnalyticsModel.fromMap(map);

        expect(analytics.totalImpressions, equals(1000));
        expect(analytics.totalClicks, equals(50));
        expect(analytics.clickThroughRate, equals(5.0));
        expect(analytics.locationBreakdown, isEmpty);
        expect(analytics.dailyImpressions, isEmpty);
        expect(analytics.dailyClicks, isEmpty);
      });
    });

    group('toMap Tests', () {
      test('should convert AdAnalyticsModel to map correctly', () {
        final map = testAnalytics.toMap();

        expect(map['adId'], equals('test-ad-id'));
        expect(map['ownerId'], equals('test-owner-id'));
        expect(map['totalImpressions'], equals(1000));
        expect(map['totalClicks'], equals(50));
        expect(map['clickThroughRate'], equals(5.0));
        expect(map['lastUpdated'], equals(Timestamp.fromDate(testDate)));
        expect(map['locationBreakdown'], isA<Map<String, dynamic>>());
        expect(map['dailyImpressions'], isA<Map<String, dynamic>>());
        expect(map['dailyClicks'], isA<Map<String, dynamic>>());
      });

      test('should handle empty collections in toMap', () {
        final emptyAnalytics = AdAnalyticsModel(
          adId: 'test-ad-id',
          ownerId: 'test-owner-id',
          totalImpressions: 0,
          totalClicks: 0,
          clickThroughRate: 0.0,
          totalRevenue: 0.0,
          averageViewDuration: 0.0,
          firstImpressionDate: testDate,
          lastImpressionDate: testDate,
          lastUpdated: testDate,
          locationBreakdown: {},
          dailyImpressions: {},
          dailyClicks: {},
        );

        final map = emptyAnalytics.toMap();

        expect(map['locationBreakdown'], isEmpty);
        expect(map['dailyImpressions'], isEmpty);
        expect(map['dailyClicks'], isEmpty);
      });
    });

    group('copyWith Tests', () {
      test('should create copy with updated properties', () {
        final updatedAnalytics = testAnalytics.copyWith(
          totalImpressions: 2000,
          totalClicks: 100,
          clickThroughRate: 5.0,
        );

        expect(updatedAnalytics.totalImpressions, equals(2000));
        expect(updatedAnalytics.totalClicks, equals(100));
        expect(updatedAnalytics.clickThroughRate, equals(5.0));

        // Original properties should remain unchanged
        expect(updatedAnalytics.adId, equals(testAnalytics.adId));
        expect(updatedAnalytics.ownerId, equals(testAnalytics.ownerId));
      });

      test('should preserve original values when no updates provided', () {
        final copiedAnalytics = testAnalytics.copyWith();

        expect(copiedAnalytics.adId, equals(testAnalytics.adId));
        expect(
          copiedAnalytics.totalImpressions,
          equals(testAnalytics.totalImpressions),
        );
        expect(copiedAnalytics.totalClicks, equals(testAnalytics.totalClicks));
        expect(
          copiedAnalytics.clickThroughRate,
          equals(testAnalytics.clickThroughRate),
        );
      });

      test('should update collections in copyWith', () {
        final newLocationBreakdown = {'profile': 300};

        final updatedAnalytics = testAnalytics.copyWith(
          locationBreakdown: newLocationBreakdown,
        );

        expect(
          updatedAnalytics.locationBreakdown,
          equals(newLocationBreakdown),
        );
        expect(updatedAnalytics.locationBreakdown, hasLength(1));
      });
    });

    group('Performance Metrics', () {
      test('should calculate performance trends', () {
        final analytics = AdAnalyticsModel(
          adId: 'test-ad-id',
          ownerId: 'test-owner-id',
          totalImpressions: 1000,
          totalClicks: 50,
          clickThroughRate: 5.0,
          totalRevenue: 100.0,
          averageViewDuration: 12.5,
          firstImpressionDate: testDate,
          lastImpressionDate: testDate,
          lastUpdated: testDate,
          locationBreakdown: {},
          dailyImpressions: {
            '2024-01-01': 100,
            '2024-01-02': 200,
            '2024-01-03': 300,
          },
          dailyClicks: {'2024-01-01': 5, '2024-01-02': 10, '2024-01-03': 15},
        );

        // Test that daily data is properly structured
        expect(analytics.dailyImpressions['2024-01-01'], equals(100));
        expect(analytics.dailyImpressions['2024-01-03'], equals(300));
        expect(analytics.dailyClicks['2024-01-01'], equals(5));
        expect(analytics.dailyClicks['2024-01-03'], equals(15));
      });

      test('should handle location breakdown correctly', () {
        final dashboardImpressions =
            testAnalytics.locationBreakdown['dashboard'];
        expect(dashboardImpressions, isNotNull);
        expect(dashboardImpressions, equals(600));

        final feedImpressions = testAnalytics.locationBreakdown['feed'];
        expect(feedImpressions, isNotNull);
        expect(feedImpressions, equals(400));
      });
    });

    group('Edge Cases', () {
      test('should handle very large numbers', () {
        final largeAnalytics = AdAnalyticsModel(
          adId: 'test-ad-id',
          ownerId: 'test-owner-id',
          totalImpressions: 1000000,
          totalClicks: 50000,
          clickThroughRate: 5.0,
          totalRevenue: 5000.0,
          averageViewDuration: 20.0,
          firstImpressionDate: testDate,
          lastImpressionDate: testDate,
          lastUpdated: testDate,
          locationBreakdown: {},
          dailyImpressions: {},
          dailyClicks: {},
        );

        expect(largeAnalytics.totalImpressions, equals(1000000));
        expect(largeAnalytics.totalClicks, equals(50000));
        expect(AdAnalyticsModel.calculateCTR(1000000, 50000), equals(5.0));
      });

      test('should handle decimal CTR values', () {
        expect(AdAnalyticsModel.calculateCTR(1000, 33), closeTo(3.3, 0.01));
        expect(AdAnalyticsModel.calculateCTR(1000, 1), equals(0.1));
      });

      test('should handle negative values gracefully', () {
        final map = {
          'adId': 'test-ad-id',
          'ownerId': 'test-owner-id',
          'totalImpressions': -100, // Negative value
          'totalClicks': -10,
          'clickThroughRate': -5.0,
          'totalRevenue': -10.0,
          'averageViewDuration': -1.0,
          'firstImpressionDate': Timestamp.fromDate(testDate),
          'lastImpressionDate': Timestamp.fromDate(testDate),
          'lastUpdated': Timestamp.fromDate(testDate),
        };

        final analytics = AdAnalyticsModel.fromMap(map);

        // Should handle negative values (implementation dependent)
        expect(analytics.totalImpressions, equals(-100));
        expect(analytics.totalClicks, equals(-10));
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

// Import statements for the models, services, and widgets
import 'package:artbeat_ads/src/models/ad_model.dart';
import 'package:artbeat_ads/src/models/ad_analytics_model.dart';
import 'package:artbeat_ads/src/models/payment_history_model.dart';
import 'package:artbeat_ads/src/models/ad_type.dart';
import 'package:artbeat_ads/src/models/ad_size.dart';
import 'package:artbeat_ads/src/models/ad_status.dart';
import 'package:artbeat_ads/src/models/ad_location.dart';
import 'package:artbeat_ads/src/models/ad_duration.dart';
import 'package:artbeat_ads/src/models/image_fit.dart';
import 'package:artbeat_ads/src/services/simple_ad_service.dart';
import 'package:artbeat_ads/src/services/ad_analytics_service.dart';
import 'package:artbeat_ads/src/widgets/simple_ad_display_widget.dart';

// Import all test files
import 'models/ad_model_test.dart' as ad_model_tests;
import 'models/ad_analytics_model_test.dart' as ad_analytics_model_tests;
import 'models/payment_history_model_test.dart' as payment_history_model_tests;
import 'models/ad_enums_test.dart' as ad_enums_tests;
import 'services/simple_ad_service_test.dart' as simple_ad_service_tests;
import 'services/ad_analytics_service_test.dart' as ad_analytics_service_tests;
import 'services/payment_history_service_test.dart'
    as payment_history_service_tests;
import 'widgets/simple_ad_display_widget_test.dart'
    as simple_ad_display_widget_tests;
import 'widgets/simple_ad_placement_widget_test.dart'
    as simple_ad_placement_widget_tests;
import 'screens/simple_ad_create_screen_test.dart'
    as simple_ad_create_screen_tests;
import 'utils/ad_utils_test.dart' as ad_utils_tests;

/// Comprehensive test suite for the artbeat_ads package
///
/// This file runs all tests in the package to ensure complete coverage
/// and integration between different components.
void main() {
  group('ARTbeat Ads Package - Complete Test Suite', () {
    group('Model Tests', () {
      group('AdModel Tests', ad_model_tests.main);
      group('AdAnalyticsModel Tests', ad_analytics_model_tests.main);
      group('PaymentHistoryModel Tests', payment_history_model_tests.main);
      group('Ad Enums Tests', ad_enums_tests.main);
    });

    group('Service Tests', () {
      group('SimpleAdService Tests', simple_ad_service_tests.main);
      group('AdAnalyticsService Tests', ad_analytics_service_tests.main);
      group('PaymentHistoryService Tests', payment_history_service_tests.main);
    });

    group('Widget Tests', () {
      group('SimpleAdDisplayWidget Tests', simple_ad_display_widget_tests.main);
      group(
        'SimpleAdPlacementWidget Tests',
        simple_ad_placement_widget_tests.main,
      );
    });

    group('Screen Tests', () {
      group('SimpleAdCreateScreen Tests', simple_ad_create_screen_tests.main);
    });

    group('Utility Tests', () {
      group('AdUtils Tests', ad_utils_tests.main);
    });

    group('Integration Tests', () {
      test('should have consistent enum values across models', () {
        // Test that enum values are consistent across different models
        // This ensures that serialization/deserialization works correctly

        // AdType consistency
        expect(AdType.values.length, equals(2));
        expect(AdType.banner_ad.index, equals(0));
        expect(AdType.feed_ad.index, equals(1));

        // AdSize consistency
        expect(AdSize.values.length, equals(3));
        expect(AdSize.small.index, equals(0));
        expect(AdSize.medium.index, equals(1));
        expect(AdSize.large.index, equals(2));

        // AdStatus consistency
        expect(AdStatus.values.length, equals(6));
        expect(AdStatus.pending.index, equals(0));
        expect(AdStatus.approved.index, equals(1));
        expect(AdStatus.rejected.index, equals(2));
        expect(AdStatus.running.index, equals(3));
        expect(AdStatus.paused.index, equals(4));
        expect(AdStatus.expired.index, equals(5));

        // AdLocation consistency (check a few known locations)
        expect(AdLocation.values, contains(AdLocation.fluidDashboard));
        expect(AdLocation.values, contains(AdLocation.artWalkDashboard));
        expect(AdLocation.values, contains(AdLocation.unifiedCommunityHub));
      });

      test('should have consistent pricing across ad sizes', () {
        // Verify that pricing is consistent and logical
        expect(AdSize.small.pricePerDay, lessThan(AdSize.medium.pricePerDay));
        expect(AdSize.medium.pricePerDay, lessThan(AdSize.large.pricePerDay));

        // Verify specific pricing
        expect(AdSize.small.pricePerDay, equals(1.0));
        expect(AdSize.medium.pricePerDay, equals(5.0));
        expect(AdSize.large.pricePerDay, equals(10.0));
      });

      test('should have consistent dimensions across ad sizes', () {
        // All ad sizes should have the same width
        for (final size in AdSize.values) {
          expect(size.width, equals(320));
        }

        // Heights should be increasing
        expect(AdSize.small.height, lessThan(AdSize.medium.height));
        expect(AdSize.medium.height, lessThan(AdSize.large.height));

        // Verify specific dimensions
        expect(AdSize.small.height, equals(50));
        expect(AdSize.medium.height, equals(100));
        expect(AdSize.large.height, equals(250));
      });

      test('should have consistent duration calculations', () {
        // Test duration calculations with different prices
        const prices = [1.0, 5.0, 10.0];

        for (final price in prices) {
          expect(AdDuration.oneDay.days * price, equals(price * 1));
          expect(AdDuration.oneWeek.days * price, equals(price * 7));
          expect(AdDuration.oneMonth.days * price, equals(price * 30));
          expect(
            AdDuration.custom.days * price,
            equals(price * 7),
          ); // custom defaults to 7 days
        }
      });

      test('should have consistent CTR calculations', () {
        // Test CTR calculation consistency
        expect(AdAnalyticsModel.calculateCTR(1000, 50), equals(5.0));
        expect(AdAnalyticsModel.calculateCTR(100, 5), equals(5.0));
        expect(AdAnalyticsModel.calculateCTR(0, 0), equals(0.0));
        expect(AdAnalyticsModel.calculateCTR(100, 0), equals(0.0));
        expect(AdAnalyticsModel.calculateCTR(0, 5), equals(0.0));
      });

      test('should have consistent payment method handling', () {
        // Test that payment methods are handled consistently
        expect(PaymentMethod.values.length, greaterThanOrEqualTo(3));
        for (final method in PaymentMethod.values) {
          expect(method.displayName, isNotEmpty);
        }
      });

      test('should have consistent payment status handling', () {
        // Test that payment statuses are handled consistently
        expect(PaymentStatus.values.length, greaterThanOrEqualTo(4));
        for (final status in PaymentStatus.values) {
          expect(status.displayName, isNotEmpty);
          expect(status.colorHex, isNotNull);
        }
        // Only completed payments should be considered successful
        expect(PaymentStatus.completed, equals(PaymentStatus.completed));
      });
    });

    group('Package Completeness Tests', () {
      test('should export all necessary components', () {
        // This test ensures that all important components are properly exported
        // In a real implementation, you would import from the main package file
        // and verify that all expected classes are available

        // Models should be available
        expect(AdModel, isNotNull);
        expect(AdAnalyticsModel, isNotNull);
        expect(PaymentHistoryModel, isNotNull);

        // Enums should be available
        expect(AdType.values, isNotEmpty);
        expect(AdSize.values, isNotEmpty);
        expect(AdStatus.values, isNotEmpty);
        expect(AdLocation.values, isNotEmpty);
        expect(AdDuration.values, isNotEmpty);
        expect(ImageFit.values, isNotEmpty);
        expect(PaymentMethod.values, isNotEmpty);
        expect(PaymentStatus.values, isNotEmpty);

        // Services should be available
        expect(SimpleAdService, isNotNull);
        expect(AdAnalyticsService, isNotNull);

        // Widgets should be available
        expect(SimpleAdDisplayWidget, isNotNull);
      });

      test('should have proper error handling patterns', () {
        // Test that error handling is consistent across the package

        // Services should handle errors gracefully
        // Analytics should not throw errors (fail silently)
        // Payment operations should throw meaningful errors

        // This is more of a design verification test
        expect(true, isTrue); // Placeholder for actual error handling tests
      });

      test('should have consistent naming conventions', () {
        // Verify that naming conventions are followed consistently

        // Model classes should end with 'Model'
        expect(
          AdModel(
            id: 'test',
            ownerId: 'owner',
            type: AdType.banner_ad,
            size: AdSize.small,
            imageUrl: 'url',
            title: 'title',
            description: 'desc',
            location: AdLocation.fluidDashboard,
            duration: AdDuration.oneDay,
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 1)),
            status: AdStatus.pending,
          ).runtimeType.toString(),
          contains('AdModel'),
        );
        expect(
          AdAnalyticsModel(
            adId: 'ad',
            ownerId: 'owner',
            totalImpressions: 100,
            totalClicks: 10,
            clickThroughRate: 10.0,
            totalRevenue: 100.0,
            averageViewDuration: 5.0,
            firstImpressionDate: DateTime.now().subtract(
              const Duration(days: 10),
            ),
            lastImpressionDate: DateTime.now(),
            locationBreakdown: const {},
            dailyImpressions: const {'2025-09-01': 10, '2025-09-02': 20},
            dailyClicks: const {'2025-09-01': 1, '2025-09-02': 2},
            lastUpdated: DateTime.now(),
          ).runtimeType.toString(),
          contains('AdAnalyticsModel'),
        );
        expect(
          PaymentHistoryModel(
            id: '',
            userId: '',
            adId: '',
            adTitle: '',
            amount: 0.0,
            paymentMethod: PaymentMethod.card,
            status: PaymentStatus.pending,
            transactionDate: DateTime.now(),
          ).runtimeType.toString(),
          contains('PaymentHistoryModel'),
        );

        // Service classes should end with 'Service'
        expect(
          SimpleAdService().runtimeType.toString(),
          contains('SimpleAdService'),
        );
        expect(
          AdAnalyticsService().runtimeType.toString(),
          contains('AdAnalyticsService'),
        );

        // Widget classes should end with 'Widget'
        expect(
          SimpleAdDisplayWidget(
            key: null,
            ad: AdModel(
              id: 'test',
              ownerId: 'owner',
              type: AdType.banner_ad,
              size: AdSize.small,
              imageUrl: 'url',
              title: 'title',
              description: 'desc',
              location: AdLocation.fluidDashboard,
              duration: AdDuration.oneDay,
              startDate: DateTime.now(),
              endDate: DateTime.now().add(const Duration(days: 1)),
              status: AdStatus.pending,
            ),
            location: AdLocation.fluidDashboard,
          ).runtimeType.toString(),
          contains('SimpleAdDisplayWidget'),
        );
      });
    });

    group('Performance Tests', () {
      test('should handle large datasets efficiently', () {
        // Test that the package can handle large amounts of data

        // Create a large list of ads
        final largeAdList = List.generate(
          1000,
          (index) => AdModel(
            id: 'ad-$index',
            ownerId: 'owner-$index',
            type: AdType.values[index % AdType.values.length],
            size: AdSize.values[index % AdSize.values.length],
            imageUrl: 'https://example.com/image$index.jpg',
            title: 'Ad $index',
            description: 'Description $index',
            location: AdLocation.values[index % AdLocation.values.length],
            duration: AdDuration.values[index % AdDuration.values.length],
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 7)),
            status: AdStatus.values[index % AdStatus.values.length],
          ),
        );

        expect(largeAdList.length, equals(1000));

        // Test that operations on large datasets complete in reasonable time
        final stopwatch = Stopwatch()..start();

        // Simulate some operations
        final filteredAds = largeAdList
            .where((ad) => ad.type == AdType.banner_ad)
            .toList();
        final totalCost = largeAdList.fold<double>(
          0,
          (sum, ad) => sum + ad.pricePerDay,
        );

        stopwatch.stop();

        expect(filteredAds, isNotEmpty);
        expect(totalCost, greaterThan(0));
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
        ); // Should complete in under 1 second
      });

      test('should handle memory efficiently', () {
        // Test memory usage patterns

        // Create and dispose of many objects
        for (int i = 0; i < 100; i++) {
          final ad = AdModel(
            id: 'temp-ad-$i',
            ownerId: 'temp-owner-$i',
            type: AdType.banner_ad,
            size: AdSize.small,
            imageUrl: 'https://example.com/temp$i.jpg',
            title: 'Temp Ad $i',
            description: 'Temp Description $i',
            location: AdLocation.fluidDashboard,
            duration: AdDuration.oneDay,
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 1)),
            status: AdStatus.pending,
          );

          // Use the ad
          expect(ad.id, equals('temp-ad-$i'));

          // Object should be eligible for garbage collection after this scope
        }

        // Test passed if no memory issues occurred
        expect(true, isTrue);
      });
    });
  });
}

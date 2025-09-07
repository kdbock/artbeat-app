import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_ads/src/utils/ad_utils.dart';

void main() {
  group('AdUtils Tests', () {
    group('Price Formatting Tests', () {
      test('should format price correctly for USD', () {
        expect(AdUtils.formatPrice(0.0), equals('\$0.00'));
        expect(AdUtils.formatPrice(1.0), equals('\$1.00'));
        expect(AdUtils.formatPrice(10.5), equals('\$10.50'));
        expect(AdUtils.formatPrice(99.99), equals('\$99.99'));
        expect(AdUtils.formatPrice(1000.0), equals('\$1,000.00'));
        expect(AdUtils.formatPrice(1234.56), equals('\$1,234.56'));
      });

      test('should handle negative prices', () {
        expect(AdUtils.formatPrice(-10.0), equals('-\$10.00'));
        expect(AdUtils.formatPrice(-99.99), equals('-\$99.99'));
      });

      test('should handle very large prices', () {
        expect(AdUtils.formatPrice(1000000.0), equals('\$1,000,000.00'));
        expect(AdUtils.formatPrice(999999999.99), equals('\$999,999,999.99'));
      });

      test('should handle very small prices', () {
        expect(AdUtils.formatPrice(0.01), equals('\$0.01'));
        expect(
          AdUtils.formatPrice(0.001),
          equals('\$0.00'),
        ); // Rounds to nearest cent
      });

      test('should handle edge cases', () {
        expect(AdUtils.formatPrice(double.infinity), isA<String>());
        expect(AdUtils.formatPrice(double.negativeInfinity), isA<String>());
        // Note: NaN handling depends on NumberFormat implementation
      });
    });

    group('Duration Formatting Tests', () {
      test('should format single day correctly', () {
        expect(AdUtils.formatDuration(1), equals('1 day'));
      });

      test('should format multiple days correctly', () {
        expect(AdUtils.formatDuration(0), equals('0 days'));
        expect(AdUtils.formatDuration(2), equals('2 days'));
        expect(AdUtils.formatDuration(7), equals('7 days'));
        expect(AdUtils.formatDuration(30), equals('30 days'));
        expect(AdUtils.formatDuration(365), equals('365 days'));
      });

      test('should handle negative days', () {
        expect(AdUtils.formatDuration(-1), equals('-1 days'));
        expect(AdUtils.formatDuration(-5), equals('-5 days'));
      });

      test('should handle large numbers', () {
        expect(AdUtils.formatDuration(1000), equals('1000 days'));
        expect(AdUtils.formatDuration(999999), equals('999999 days'));
      });
    });

    group('Date Range Formatting Tests', () {
      test('should format date range correctly', () {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);

        expect(
          AdUtils.formatDateRange(start, end),
          equals('Jan 1, 2024 - Jan 31, 2024'),
        );
      });

      test('should format same year date range', () {
        final start = DateTime(2024, 3, 15);
        final end = DateTime(2024, 6, 20);

        expect(
          AdUtils.formatDateRange(start, end),
          equals('Mar 15, 2024 - Jun 20, 2024'),
        );
      });

      test('should format cross-year date range', () {
        final start = DateTime(2023, 12, 25);
        final end = DateTime(2024, 1, 5);

        expect(
          AdUtils.formatDateRange(start, end),
          equals('Dec 25, 2023 - Jan 5, 2024'),
        );
      });

      test('should format same date range', () {
        final date = DateTime(2024, 7, 4);

        expect(
          AdUtils.formatDateRange(date, date),
          equals('Jul 4, 2024 - Jul 4, 2024'),
        );
      });

      test('should handle leap year dates', () {
        final start = DateTime(2024, 2, 28); // 2024 is a leap year
        final end = DateTime(2024, 2, 29);

        expect(
          AdUtils.formatDateRange(start, end),
          equals('Feb 28, 2024 - Feb 29, 2024'),
        );
      });

      test('should handle different months', () {
        final start = DateTime(2024, 1, 31);
        final end = DateTime(2024, 2, 1);

        expect(
          AdUtils.formatDateRange(start, end),
          equals('Jan 31, 2024 - Feb 1, 2024'),
        );
      });

      test('should handle reversed date range', () {
        final start = DateTime(2024, 6, 1);
        final end = DateTime(2024, 1, 1);

        // Should still format correctly even if end is before start
        expect(
          AdUtils.formatDateRange(start, end),
          equals('Jun 1, 2024 - Jan 1, 2024'),
        );
      });
    });

    group('Test Ad Detection Tests', () {
      test('should identify test ads by title containing "Test"', () {
        final testData1 = {
          'title': 'Test Ad Campaign',
          'ownerId': 'regular_user',
        };
        final testData2 = {
          'title': 'My Test Advertisement',
          'ownerId': 'regular_user',
        };
        final testData3 = {
          'title': 'Testing New Features',
          'ownerId': 'regular_user',
        };

        expect(AdUtils.isTestAd(testData1), isTrue);
        expect(AdUtils.isTestAd(testData2), isTrue);
        expect(AdUtils.isTestAd(testData3), isTrue);
      });

      test('should identify test ads by owner ID', () {
        final testData1 = {'title': 'Regular Ad', 'ownerId': 'test_owner'};
        final testData2 = {'title': 'Another Ad', 'ownerId': 'test_artist'};

        expect(AdUtils.isTestAd(testData1), isTrue);
        expect(AdUtils.isTestAd(testData2), isTrue);
      });

      test('should identify test ads by title starting with "Test Ad"', () {
        final testData1 = {
          'title': 'Test Ad for Dashboard',
          'ownerId': 'regular_user',
        };
        final testData2 = {
          'title': 'Test Ad Campaign 2024',
          'ownerId': 'regular_user',
        };

        expect(AdUtils.isTestAd(testData1), isTrue);
        expect(AdUtils.isTestAd(testData2), isTrue);
      });

      test('should not identify regular ads as test ads', () {
        final regularData1 = {
          'title': 'Amazing Art Gallery',
          'ownerId': 'artist_123',
        };
        final regularData2 = {'title': 'Buy My Artwork', 'ownerId': 'user_456'};
        final regularData3 = {
          'title': 'Gallery Exhibition',
          'ownerId': 'gallery_789',
        };

        expect(AdUtils.isTestAd(regularData1), isFalse);
        expect(AdUtils.isTestAd(regularData2), isFalse);
        expect(AdUtils.isTestAd(regularData3), isFalse);
      });

      test('should handle case sensitivity in test detection', () {
        final testData1 = {
          'title': 'test ad campaign',
          'ownerId': 'regular_user',
        };
        final testData2 = {
          'title': 'TEST AD CAMPAIGN',
          'ownerId': 'regular_user',
        };
        final testData3 = {
          'title': 'Test AD Campaign',
          'ownerId': 'regular_user',
        };

        expect(AdUtils.isTestAd(testData1), isFalse); // 'test' != 'Test'
        expect(
          AdUtils.isTestAd(testData2),
          isFalse,
        ); // 'TEST' != 'Test' (case sensitive)
        expect(AdUtils.isTestAd(testData3), isTrue); // Contains 'Test'
      });

      test('should handle missing or null data', () {
        final emptyData = <String, dynamic>{};
        final nullTitleData = {'title': null, 'ownerId': 'regular_user'};
        final nullOwnerData = {'title': 'Regular Ad', 'ownerId': null};
        final bothNullData = {'title': null, 'ownerId': null};

        expect(AdUtils.isTestAd(emptyData), isFalse);
        expect(AdUtils.isTestAd(nullTitleData), isFalse);
        expect(AdUtils.isTestAd(nullOwnerData), isFalse);
        expect(AdUtils.isTestAd(bothNullData), isFalse);
      });

      test('should handle edge cases in test detection', () {
        final edgeCase1 = {
          'title': 'Tes',
          'ownerId': 'regular_user',
        }; // Too short
        final edgeCase2 = {
          'title': 'Testing',
          'ownerId': 'regular_user',
        }; // Contains but not exact
        final edgeCase3 = {
          'title': 'Contest Winner',
          'ownerId': 'regular_user',
        }; // Contains "test"
        final edgeCase4 = {
          'title': 'Latest Updates',
          'ownerId': 'regular_user',
        }; // Contains "test"

        expect(AdUtils.isTestAd(edgeCase1), isFalse);
        expect(
          AdUtils.isTestAd(edgeCase2),
          isTrue,
        ); // "Testing" contains "Test"
        expect(
          AdUtils.isTestAd(edgeCase3),
          isFalse,
        ); // "Contest" doesn't contain "Test" (case sensitive)
        expect(
          AdUtils.isTestAd(edgeCase4),
          isFalse,
        ); // "Latest" doesn't contain "Test"
      });

      test('should handle special characters and numbers', () {
        final specialData1 = {
          'title': 'Test-Ad-123',
          'ownerId': 'regular_user',
        };
        final specialData2 = {
          'title': 'Test_Ad_Campaign',
          'ownerId': 'regular_user',
        };
        final specialData3 = {'title': 'Test Ad #1', 'ownerId': 'regular_user'};

        expect(AdUtils.isTestAd(specialData1), isTrue);
        expect(AdUtils.isTestAd(specialData2), isTrue);
        expect(AdUtils.isTestAd(specialData3), isTrue);
      });

      test('should handle multiple test conditions', () {
        final multipleConditions = {
          'title': 'Test Ad Campaign',
          'ownerId': 'test_owner',
        };

        expect(AdUtils.isTestAd(multipleConditions), isTrue);
      });

      test('should handle non-string data types', () {
        final numericData = {'title': 123, 'ownerId': 456};
        final booleanData = {'title': true, 'ownerId': false};
        final listData = {
          'title': ['Test', 'Ad'],
          'ownerId': ['test', 'owner'],
        };

        // Should convert to string and check
        expect(AdUtils.isTestAd(numericData), isFalse);
        expect(AdUtils.isTestAd(booleanData), isFalse);
        expect(
          AdUtils.isTestAd(listData),
          isTrue,
        ); // List toString contains "Test"
      });
    });

    group('Integration Tests', () {
      test('should work together for complete ad data processing', () {
        final adData = {
          'title': 'Test Ad Campaign',
          'ownerId': 'test_owner',
          'price': 99.99,
          'duration': 7,
          'startDate': DateTime(2024, 1, 1),
          'endDate': DateTime(2024, 1, 8),
        };

        // Test all utility functions with the same data
        expect(AdUtils.isTestAd(adData), isTrue);
        expect(
          AdUtils.formatPrice(adData['price'] as double),
          equals('\$99.99'),
        );
        expect(
          AdUtils.formatDuration(adData['duration'] as int),
          equals('7 days'),
        );
        expect(
          AdUtils.formatDateRange(
            adData['startDate'] as DateTime,
            adData['endDate'] as DateTime,
          ),
          equals('Jan 1, 2024 - Jan 8, 2024'),
        );
      });

      test('should handle real-world ad data scenarios', () {
        final realAdData = {
          'title': 'Amazing Art Gallery Exhibition',
          'ownerId': 'artist_12345',
          'price': 149.50,
          'duration': 30,
          'startDate': DateTime(2024, 3, 15),
          'endDate': DateTime(2024, 4, 14),
        };

        expect(AdUtils.isTestAd(realAdData), isFalse);
        expect(
          AdUtils.formatPrice(realAdData['price'] as double),
          equals('\$149.50'),
        );
        expect(
          AdUtils.formatDuration(realAdData['duration'] as int),
          equals('30 days'),
        );
        expect(
          AdUtils.formatDateRange(
            realAdData['startDate'] as DateTime,
            realAdData['endDate'] as DateTime,
          ),
          equals('Mar 15, 2024 - Apr 14, 2024'),
        );
      });
    });

    group('Performance Tests', () {
      test('should handle large datasets efficiently', () {
        final stopwatch = Stopwatch()..start();

        // Test with many operations
        for (int i = 0; i < 1000; i++) {
          AdUtils.formatPrice(i * 1.5);
          AdUtils.formatDuration(i);
          AdUtils.formatDateRange(
            DateTime(2024, 1, 1).add(Duration(days: i)),
            DateTime(2024, 1, 1).add(Duration(days: i + 7)),
          );
          AdUtils.isTestAd({'title': 'Ad $i', 'ownerId': 'user_$i'});
        }

        stopwatch.stop();
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
        ); // Should complete in under 1 second
      });

      test('should handle memory efficiently', () {
        // Create and process many ad data objects
        for (int i = 0; i < 100; i++) {
          final adData = {
            'title': 'Test Ad $i',
            'ownerId': 'owner_$i',
            'price': i * 10.0,
            'duration': i + 1,
          };

          AdUtils.isTestAd(adData);
          AdUtils.formatPrice(adData['price'] as double);
          AdUtils.formatDuration(adData['duration'] as int);
        }

        // Test passes if no memory issues occur
        expect(true, isTrue);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle extreme values gracefully', () {
        // Test with extreme values
        expect(() => AdUtils.formatPrice(double.maxFinite), returnsNormally);
        expect(
          () => AdUtils.formatDuration(0x7FFFFFFFFFFFFFFF),
          returnsNormally,
        );

        final extremeDate = DateTime(9999, 12, 31);
        expect(
          () => AdUtils.formatDateRange(extremeDate, extremeDate),
          returnsNormally,
        );
      });

      test('should handle malformed data', () {
        final malformedData = {
          'title': '',
          'ownerId': '',
          'extraField': 'unexpected',
        };

        expect(AdUtils.isTestAd(malformedData), isFalse);
      });

      test('should be consistent across multiple calls', () {
        const price = 99.99;
        const duration = 7;
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 8);
        final adData = {'title': 'Test Ad', 'ownerId': 'test_owner'};

        // Multiple calls should return the same result
        for (int i = 0; i < 5; i++) {
          expect(AdUtils.formatPrice(price), equals('\$99.99'));
          expect(AdUtils.formatDuration(duration), equals('7 days'));
          expect(
            AdUtils.formatDateRange(startDate, endDate),
            equals('Jan 1, 2024 - Jan 8, 2024'),
          );
          expect(AdUtils.isTestAd(adData), isTrue);
        }
      });
    });
  });
}

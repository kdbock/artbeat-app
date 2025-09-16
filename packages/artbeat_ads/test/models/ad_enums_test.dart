import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:artbeat_ads/src/models/ad_type.dart';
import 'package:artbeat_ads/src/models/ad_size.dart';
import 'package:artbeat_ads/src/models/ad_status.dart';
import 'package:artbeat_ads/src/models/ad_location.dart';
import 'package:artbeat_ads/src/models/ad_duration.dart';
import 'package:artbeat_ads/src/models/image_fit.dart';

void main() {
  group('Ad Enums Tests', () {
    group('AdType Tests', () {
      test('should have correct enum values', () {
        expect(AdType.values, hasLength(2));
        expect(AdType.values, contains(AdType.banner_ad));
        expect(AdType.values, contains(AdType.feed_ad));
      });

      test('should have correct display names', () {
        expect(AdType.banner_ad.displayName, equals('Banner Ad'));
        expect(AdType.feed_ad.displayName, equals('Feed Ad'));
      });

      test('should have correct descriptions', () {
        expect(AdType.banner_ad.description, contains('Banner advertisement'));
        expect(
          AdType.feed_ad.description,
          contains('Advertisement integrated'),
        );
      });

      test('should handle all enum values in switch statements', () {
        for (final adType in AdType.values) {
          expect(adType.displayName, isNotEmpty);
          expect(adType.description, isNotEmpty);
        }
      });
    });

    group('AdSize Tests', () {
      test('should have correct enum values', () {
        expect(AdSize.values, hasLength(3));
        expect(AdSize.values, contains(AdSize.small));
        expect(AdSize.values, contains(AdSize.medium));
        expect(AdSize.values, contains(AdSize.large));
      });

      test('should have correct dimensions', () {
        expect(AdSize.small.width, equals(320));
        expect(AdSize.small.height, equals(50));

        expect(AdSize.medium.width, equals(320));
        expect(AdSize.medium.height, equals(100));

        expect(AdSize.large.width, equals(320));
        expect(AdSize.large.height, equals(250));
      });

      test('should have correct pricing', () {
        expect(AdSize.small.pricePerDay, equals(1.0));
        expect(AdSize.medium.pricePerDay, equals(5.0));
        expect(AdSize.large.pricePerDay, equals(10.0));
      });

      test('should have correct display names', () {
        expect(AdSize.small.displayName, equals('Small (320x50)'));
        expect(AdSize.medium.displayName, equals('Medium (320x100)'));
        expect(AdSize.large.displayName, equals('Large (320x250)'));
      });

      test('should have correct dimensions string', () {
        expect(AdSize.small.dimensions, equals('320x50'));
        expect(AdSize.medium.dimensions, equals('320x100'));
        expect(AdSize.large.dimensions, equals('320x250'));
      });

      test('should maintain consistent width across all sizes', () {
        for (final size in AdSize.values) {
          expect(size.width, equals(320));
        }
      });

      test('should have increasing prices for larger sizes', () {
        expect(AdSize.small.pricePerDay, lessThan(AdSize.medium.pricePerDay));
        expect(AdSize.medium.pricePerDay, lessThan(AdSize.large.pricePerDay));
      });
    });

    group('AdStatus Tests', () {
      test('should have correct enum values', () {
        expect(AdStatus.values, hasLength(8));
        expect(AdStatus.values, contains(AdStatus.draft));
        expect(AdStatus.values, contains(AdStatus.pending));
        expect(AdStatus.values, contains(AdStatus.approved));
        expect(AdStatus.values, contains(AdStatus.rejected));
        expect(AdStatus.values, contains(AdStatus.active));
        expect(AdStatus.values, contains(AdStatus.expired));
        expect(AdStatus.values, contains(AdStatus.running));
        expect(AdStatus.values, contains(AdStatus.paused));
      });

      test('should have correct display names', () {
        expect(AdStatus.draft.displayName, equals('Draft'));
        expect(AdStatus.pending.displayName, equals('Pending Review'));
        expect(AdStatus.approved.displayName, equals('Approved'));
        expect(AdStatus.rejected.displayName, equals('Rejected'));
        expect(AdStatus.active.displayName, equals('Active'));
        expect(AdStatus.expired.displayName, equals('Expired'));
      });

      test('should have correct descriptions', () {
        expect(AdStatus.draft.description, contains('being created'));
        expect(AdStatus.pending.description, contains('review'));
        expect(AdStatus.approved.description, contains('approved'));
        expect(AdStatus.rejected.description, contains('rejected'));
        expect(AdStatus.active.description, contains('currently running'));
        expect(AdStatus.expired.description, contains('expired'));
      });

      test('should have correct colors', () {
        expect(AdStatus.draft.color, isNotNull);
        expect(AdStatus.pending.color, isNotNull);
        expect(AdStatus.approved.color, isNotNull);
        expect(AdStatus.rejected.color, isNotNull);
        expect(AdStatus.active.color, isNotNull);
        expect(AdStatus.expired.color, isNotNull);
      });

      test('should identify editable statuses correctly', () {
        expect(AdStatus.draft.isEditable, isTrue);
        expect(AdStatus.rejected.isEditable, isTrue);
        expect(AdStatus.pending.isEditable, isFalse);
        expect(AdStatus.approved.isEditable, isFalse);
        expect(AdStatus.active.isEditable, isFalse);
        expect(AdStatus.expired.isEditable, isFalse);
      });

      test('should identify final statuses correctly', () {
        expect(AdStatus.expired.isFinal, isTrue);
        expect(AdStatus.rejected.isFinal, isTrue);
        expect(AdStatus.draft.isFinal, isFalse);
        expect(AdStatus.pending.isFinal, isFalse);
        expect(AdStatus.approved.isFinal, isFalse);
        expect(AdStatus.active.isFinal, isFalse);
      });
    });

    group('AdLocation Tests', () {
      test('should have correct enum values', () {
        expect(AdLocation.values, hasLength(9));
        expect(AdLocation.values, contains(AdLocation.fluidDashboard));
        expect(AdLocation.values, contains(AdLocation.artWalkDashboard));
        expect(AdLocation.values, contains(AdLocation.captureDashboard));
        expect(AdLocation.values, contains(AdLocation.unifiedCommunityHub));
        expect(AdLocation.values, contains(AdLocation.eventDashboard));
        expect(
          AdLocation.values,
          contains(AdLocation.artisticMessagingDashboard),
        );
        expect(AdLocation.values, contains(AdLocation.artistPublicProfile));
        expect(AdLocation.values, contains(AdLocation.artistInFeed));
        expect(AdLocation.values, contains(AdLocation.communityInFeed));
      });

      test('should have correct display names', () {
        expect(
          AdLocation.fluidDashboard.displayName,
          equals('Fluid Dashboard'),
        );
        expect(
          AdLocation.artWalkDashboard.displayName,
          equals('Art Walk Dashboard'),
        );
        expect(
          AdLocation.captureDashboard.displayName,
          equals('Capture Dashboard'),
        );
        expect(
          AdLocation.unifiedCommunityHub.displayName,
          equals('Unified Community Hub'),
        );
        expect(
          AdLocation.eventDashboard.displayName,
          equals('Event Dashboard'),
        );
        expect(
          AdLocation.artisticMessagingDashboard.displayName,
          equals('Artistic Messaging Dashboard'),
        );
        expect(
          AdLocation.artistPublicProfile.displayName,
          equals('Artist Public Profile'),
        );
        expect(AdLocation.artistInFeed.displayName, equals('Artist in Feed'));
        expect(
          AdLocation.communityInFeed.displayName,
          equals('Community in Feed'),
        );
      });

      test('should have correct descriptions', () {
        expect(
          AdLocation.fluidDashboard.description,
          contains('fluid dashboard'),
        );
        expect(AdLocation.artWalkDashboard.description, contains('Art walk'));
        expect(AdLocation.captureDashboard.description, contains('capture'));
        expect(
          AdLocation.unifiedCommunityHub.description,
          contains('community hub'),
        );
        expect(AdLocation.eventDashboard.description, contains('Events'));
        expect(
          AdLocation.artisticMessagingDashboard.description,
          contains('messaging'),
        );
        expect(
          AdLocation.artistPublicProfile.description,
          contains('artist profile'),
        );
        expect(AdLocation.artistInFeed.description, contains('Artist content'));
        expect(
          AdLocation.communityInFeed.description,
          contains('Community content'),
        );
      });

      test('should have correct names', () {
        expect(AdLocation.fluidDashboard.name, equals('fluidDashboard'));
        expect(AdLocation.artWalkDashboard.name, equals('artWalkDashboard'));
        expect(AdLocation.captureDashboard.name, equals('captureDashboard'));
        expect(
          AdLocation.unifiedCommunityHub.name,
          equals('unifiedCommunityHub'),
        );
        expect(AdLocation.eventDashboard.name, equals('eventDashboard'));
        expect(
          AdLocation.artisticMessagingDashboard.name,
          equals('artisticMessagingDashboard'),
        );
        expect(
          AdLocation.artistPublicProfile.name,
          equals('artistPublicProfile'),
        );
        expect(AdLocation.artistInFeed.name, equals('artistInFeed'));
        expect(AdLocation.communityInFeed.name, equals('communityInFeed'));
      });
    });

    group('AdDuration Tests', () {
      test('should have correct enum values', () {
        expect(AdDuration.values, hasLength(9));
        expect(AdDuration.values, contains(AdDuration.oneDay));
        expect(AdDuration.values, contains(AdDuration.threeDays));
        expect(AdDuration.values, contains(AdDuration.oneWeek));
        expect(AdDuration.values, contains(AdDuration.twoWeeks));
        expect(AdDuration.values, contains(AdDuration.oneMonth));
        expect(AdDuration.values, contains(AdDuration.daily));
        expect(AdDuration.values, contains(AdDuration.weekly));
        expect(AdDuration.values, contains(AdDuration.monthly));
        expect(AdDuration.values, contains(AdDuration.custom));
      });

      test('should have correct display names', () {
        expect(AdDuration.daily.displayName, equals('1 Day'));
        expect(AdDuration.weekly.displayName, equals('1 Week'));
        expect(AdDuration.monthly.displayName, equals('1 Month'));
        expect(AdDuration.custom.displayName, equals('Custom'));
      });

      test('should have correct day counts', () {
        expect(AdDuration.daily.days, equals(1));
        expect(AdDuration.weekly.days, equals(7));
        expect(AdDuration.monthly.days, equals(30));
        expect(AdDuration.custom.days, equals(0)); // Custom duration
      });

      test('should calculate total cost correctly', () {
        const pricePerDay = 5.0;

        expect(AdDuration.daily.calculateTotalCost(pricePerDay), equals(5.0));
        expect(AdDuration.weekly.calculateTotalCost(pricePerDay), equals(35.0));
        expect(
          AdDuration.monthly.calculateTotalCost(pricePerDay),
          equals(150.0),
        );
        expect(AdDuration.custom.calculateTotalCost(pricePerDay), equals(0.0));
      });

      test('should handle zero price per day', () {
        expect(AdDuration.weekly.calculateTotalCost(0.0), equals(0.0));
      });

      test('should handle negative price per day', () {
        expect(AdDuration.weekly.calculateTotalCost(-5.0), equals(-35.0));
      });

      group('AdDurationExtension Tests', () {
        test('should create AdDuration from map', () {
          final dailyMap = {'type': 'daily', 'days': 1};
          final weeklyMap = {'type': 'weekly', 'days': 7};
          final customMap = {'type': 'custom', 'days': 14};

          expect(
            AdDurationExtension.fromMap(dailyMap),
            equals(AdDuration.daily),
          );
          expect(
            AdDurationExtension.fromMap(weeklyMap),
            equals(AdDuration.weekly),
          );
          expect(
            AdDurationExtension.fromMap(customMap),
            equals(AdDuration.custom),
          );
        });

        test('should handle invalid map data', () {
          final invalidMap = {'type': 'invalid', 'days': 5};
          final emptyMap = <String, dynamic>{};

          expect(
            AdDurationExtension.fromMap(invalidMap),
            equals(AdDuration.daily),
          );
          expect(
            AdDurationExtension.fromMap(emptyMap),
            equals(AdDuration.daily),
          );
        });

        test('should convert AdDuration to map', () {
          final dailyMap = AdDuration.daily.toMap();
          final weeklyMap = AdDuration.weekly.toMap();
          final customMap = AdDuration.custom.toMap();

          expect(dailyMap['type'], equals('daily'));
          expect(dailyMap['days'], equals(1));

          expect(weeklyMap['type'], equals('weekly'));
          expect(weeklyMap['days'], equals(7));

          expect(customMap['type'], equals('custom'));
          expect(customMap['days'], equals(0));
        });
      });
    });

    group('ImageFit Tests', () {
      test('should have correct enum values', () {
        expect(ImageFit.values, hasLength(7));
        expect(ImageFit.values, contains(ImageFit.cover));
        expect(ImageFit.values, contains(ImageFit.contain));
        expect(ImageFit.values, contains(ImageFit.fill));
        expect(ImageFit.values, contains(ImageFit.fitWidth));
        expect(ImageFit.values, contains(ImageFit.fitHeight));
        expect(ImageFit.values, contains(ImageFit.none));
        expect(ImageFit.values, contains(ImageFit.scaleDown));
      });

      test('should have correct display names', () {
        expect(ImageFit.cover.displayName, equals('Cover (Fill & Crop)'));
        expect(
          ImageFit.contain.displayName,
          equals('Contain (Fit & Letterbox)'),
        );
        expect(ImageFit.fill.displayName, equals('Fill (Stretch)'));
        expect(ImageFit.fitWidth.displayName, equals('Fit Width'));
        expect(ImageFit.fitHeight.displayName, equals('Fit Height'));
        expect(ImageFit.none.displayName, equals('None (Original Size)'));
        expect(ImageFit.scaleDown.displayName, equals('Scale Down'));
      });

      test('should have correct descriptions', () {
        expect(ImageFit.cover.description, contains('covers the entire'));
        expect(ImageFit.contain.description, contains('entirely visible'));
        expect(ImageFit.fill.description, contains('fills the entire'));
        expect(ImageFit.fitWidth.description, contains('fit the width'));
        expect(ImageFit.fitHeight.description, contains('fit the height'));
        expect(ImageFit.scaleDown.description, contains('scale down'));
      });

      test('should convert to BoxFit correctly', () {
        expect(ImageFit.cover.boxFit, equals(BoxFit.cover));
        expect(ImageFit.contain.boxFit, equals(BoxFit.contain));
        expect(ImageFit.fill.boxFit, equals(BoxFit.fill));
        expect(ImageFit.fitWidth.boxFit, equals(BoxFit.fitWidth));
        expect(ImageFit.fitHeight.boxFit, equals(BoxFit.fitHeight));
        expect(ImageFit.scaleDown.boxFit, equals(BoxFit.scaleDown));
      });
    });

    group('Enum Integration Tests', () {
      test('should work together in ad model creation', () {
        // Test that all enums can be used together
        final testData = {
          'type': AdType.banner_ad,
          'size': AdSize.large,
          'status': AdStatus.active,
          'location': AdLocation.fluidDashboard,
          'duration': AdDuration.weekly,
          'imageFit': ImageFit.cover,
        };

        expect(testData['type'], isA<AdType>());
        expect(testData['size'], isA<AdSize>());
        expect(testData['status'], isA<AdStatus>());
        expect(testData['location'], isA<AdLocation>());
        expect(testData['duration'], isA<AdDuration>());
        expect(testData['imageFit'], isA<ImageFit>());
      });

      test('should have consistent enum indexing', () {
        // Verify that enum indices are stable for serialization
        expect(AdType.banner_ad.index, equals(0));
        expect(AdType.feed_ad.index, equals(1));

        expect(AdSize.small.index, equals(0));
        expect(AdSize.medium.index, equals(1));
        expect(AdSize.large.index, equals(2));

        expect(AdStatus.pending.index, equals(0));
        expect(AdStatus.approved.index, equals(1));
        expect(AdStatus.rejected.index, equals(2));
        expect(AdStatus.running.index, equals(3));
        expect(AdStatus.paused.index, equals(4));
        expect(AdStatus.expired.index, equals(5));
        expect(AdStatus.draft.index, equals(6));
        expect(AdStatus.active.index, equals(7));
      });

      test('should handle enum comparison correctly', () {
        expect(AdSize.small.pricePerDay < AdSize.medium.pricePerDay, isTrue);
        expect(AdSize.medium.pricePerDay < AdSize.large.pricePerDay, isTrue);

        expect(AdDuration.daily.days < AdDuration.weekly.days, isTrue);
        expect(AdDuration.weekly.days < AdDuration.monthly.days, isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle enum toString methods', () {
        expect(AdType.banner_ad.toString(), contains('banner_ad'));
        expect(AdSize.medium.toString(), contains('medium'));
        expect(AdStatus.pending.toString(), contains('pending'));
        expect(
          AdLocation.fluidDashboard.toString(),
          contains('fluidDashboard'),
        );
      });

      test('should handle enum equality', () {
        expect(AdType.banner_ad == AdType.banner_ad, isTrue);
        expect(AdType.banner_ad == AdType.feed_ad, isFalse);

        expect(AdSize.small == AdSize.small, isTrue);
        expect(AdSize.small == AdSize.large, isFalse);
      });

      test('should handle enum in collections', () {
        final typeSet = {AdType.banner_ad, AdType.feed_ad};
        expect(typeSet, hasLength(2)); // Duplicates removed

        final sizeList = [AdSize.small, AdSize.medium, AdSize.large];
        expect(sizeList, hasLength(3));
        expect(sizeList.contains(AdSize.medium), isTrue);
      });
    });
  });
}

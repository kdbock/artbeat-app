import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_ads/src/models/ad_model.dart';
import 'package:artbeat_ads/src/models/ad_type.dart';
import 'package:artbeat_ads/src/models/ad_size.dart';
import 'package:artbeat_ads/src/models/ad_status.dart';
import 'package:artbeat_ads/src/models/ad_location.dart';
import 'package:artbeat_ads/src/models/ad_duration.dart';
import 'package:artbeat_ads/src/models/image_fit.dart';

void main() {
  group('AdModel Tests', () {
    late AdModel testAd;
    late DateTime testStartDate;
    late DateTime testEndDate;

    setUp(() {
      testStartDate = DateTime(2024, 1, 1);
      testEndDate = DateTime(2024, 1, 31);

      testAd = AdModel(
        id: 'test-ad-id',
        ownerId: 'test-owner-id',
        type: AdType.banner_ad,
        size: AdSize.medium,
        imageUrl: 'https://example.com/image.jpg',
        artworkUrls: [
          'https://example.com/image1.jpg',
          'https://example.com/image2.jpg',
        ],
        title: 'Test Ad Title',
        description: 'Test ad description',
        location: AdLocation.dashboard,
        duration: AdDuration.weekly,
        startDate: testStartDate,
        endDate: testEndDate,
        status: AdStatus.pending,
        approvalId: 'approval-123',
        destinationUrl: 'https://example.com',
        ctaText: 'Shop Now',
        imageFit: ImageFit.cover,
      );
    });

    test('should create AdModel with all properties', () {
      expect(testAd.id, equals('test-ad-id'));
      expect(testAd.ownerId, equals('test-owner-id'));
      expect(testAd.type, equals(AdType.banner_ad));
      expect(testAd.size, equals(AdSize.medium));
      expect(testAd.imageUrl, equals('https://example.com/image.jpg'));
      expect(testAd.artworkUrls, hasLength(2));
      expect(testAd.title, equals('Test Ad Title'));
      expect(testAd.description, equals('Test ad description'));
      expect(testAd.location, equals(AdLocation.dashboard));
      expect(testAd.duration, equals(AdDuration.weekly));
      expect(testAd.startDate, equals(testStartDate));
      expect(testAd.endDate, equals(testEndDate));
      expect(testAd.status, equals(AdStatus.pending));
      expect(testAd.approvalId, equals('approval-123'));
      expect(testAd.destinationUrl, equals('https://example.com'));
      expect(testAd.ctaText, equals('Shop Now'));
      expect(testAd.imageFit, equals(ImageFit.cover));
    });

    test('should calculate price per day from ad size', () {
      final smallAd = testAd.copyWith(size: AdSize.small);
      final mediumAd = testAd.copyWith(size: AdSize.medium);
      final largeAd = testAd.copyWith(size: AdSize.large);

      expect(smallAd.pricePerDay, equals(1.0));
      expect(mediumAd.pricePerDay, equals(5.0));
      expect(largeAd.pricePerDay, equals(10.0));
    });

    test('should create AdModel with default values', () {
      final minimalAd = AdModel(
        id: 'minimal-id',
        ownerId: 'owner-id',
        type: AdType.feed_ad,
        size: AdSize.small,
        imageUrl: 'https://example.com/image.jpg',
        title: 'Minimal Ad',
        description: 'Minimal description',
        location: AdLocation.feed,
        duration: AdDuration.daily,
        startDate: testStartDate,
        endDate: testEndDate,
        status: AdStatus.draft,
      );

      expect(minimalAd.artworkUrls, isEmpty);
      expect(minimalAd.approvalId, isNull);
      expect(minimalAd.destinationUrl, isNull);
      expect(minimalAd.ctaText, isNull);
      expect(minimalAd.imageFit, equals(ImageFit.cover));
    });

    group('fromMap Tests', () {
      test('should create AdModel from valid map', () {
        final map = {
          'ownerId': 'test-owner',
          'type': 0, // AdType.banner_ad
          'size': 1, // AdSize.medium
          'imageUrl': 'https://example.com/image.jpg',
          'artworkUrls':
              'https://example.com/image1.jpg,https://example.com/image2.jpg',
          'title': 'Test Title',
          'description': 'Test Description',
          'location': 0, // AdLocation.dashboard
          'duration': {'type': 'weekly', 'days': 7},
          'startDate': Timestamp.fromDate(testStartDate),
          'endDate': Timestamp.fromDate(testEndDate),
          'status': 0, // AdStatus.pending
          'approvalId': 'approval-123',
          'destinationUrl': 'https://example.com',
          'ctaText': 'Shop Now',
          'imageFit': 0, // ImageFit.cover
        };

        final ad = AdModel.fromMap(map, 'test-id');

        expect(ad.id, equals('test-id'));
        expect(ad.ownerId, equals('test-owner'));
        expect(ad.type, equals(AdType.banner_ad));
        expect(ad.size, equals(AdSize.medium));
        expect(ad.artworkUrls, hasLength(2));
        expect(ad.title, equals('Test Title'));
        expect(ad.status, equals(AdStatus.pending));
      });

      test('should handle invalid enum values with safe defaults', () {
        final map = {
          'ownerId': 'test-owner',
          'type': 999, // Invalid type
          'size': -1, // Invalid size
          'imageUrl': 'https://example.com/image.jpg',
          'title': 'Test Title',
          'description': 'Test Description',
          'location': 100, // Invalid location
          'duration': {'type': 'daily', 'days': 1},
          'startDate': Timestamp.fromDate(testStartDate),
          'endDate': Timestamp.fromDate(testEndDate),
          'status': 50, // Invalid status
        };

        final ad = AdModel.fromMap(map, 'test-id');

        expect(ad.type, equals(AdType.banner_ad)); // Default
        expect(ad.size, equals(AdSize.small)); // Default
        expect(ad.location, equals(AdLocation.dashboard)); // Default
        expect(ad.status, equals(AdStatus.pending)); // Default
      });

      test('should handle artworkUrls as list', () {
        final map = {
          'ownerId': 'test-owner',
          'type': 0,
          'size': 0,
          'imageUrl': 'https://example.com/image.jpg',
          'artworkUrls': [
            'https://example.com/image1.jpg',
            'https://example.com/image2.jpg',
          ],
          'title': 'Test Title',
          'description': 'Test Description',
          'location': 0,
          'duration': {'type': 'daily', 'days': 1},
          'startDate': Timestamp.fromDate(testStartDate),
          'endDate': Timestamp.fromDate(testEndDate),
          'status': 0,
        };

        final ad = AdModel.fromMap(map, 'test-id');
        expect(ad.artworkUrls, hasLength(2));
        expect(ad.artworkUrls.first, equals('https://example.com/image1.jpg'));
      });

      test('should handle empty or null artworkUrls', () {
        final map = {
          'ownerId': 'test-owner',
          'type': 0,
          'size': 0,
          'imageUrl': 'https://example.com/image.jpg',
          'artworkUrls': null,
          'title': 'Test Title',
          'description': 'Test Description',
          'location': 0,
          'duration': {'type': 'daily', 'days': 1},
          'startDate': Timestamp.fromDate(testStartDate),
          'endDate': Timestamp.fromDate(testEndDate),
          'status': 0,
        };

        final ad = AdModel.fromMap(map, 'test-id');
        expect(ad.artworkUrls, isEmpty);
      });
    });

    group('toMap Tests', () {
      test('should convert AdModel to map correctly', () {
        final map = testAd.toMap();

        expect(map['ownerId'], equals('test-owner-id'));
        expect(map['type'], equals(0)); // AdType.banner_ad.index
        expect(map['size'], equals(1)); // AdSize.medium.index
        expect(map['imageUrl'], equals('https://example.com/image.jpg'));
        expect(
          map['artworkUrls'],
          equals(
            'https://example.com/image1.jpg,https://example.com/image2.jpg',
          ),
        );
        expect(map['title'], equals('Test Ad Title'));
        expect(map['description'], equals('Test ad description'));
        expect(map['location'], equals(0)); // AdLocation.dashboard.index
        expect(map['status'], equals(0)); // AdStatus.pending.index
        expect(map['approvalId'], equals('approval-123'));
        expect(map['destinationUrl'], equals('https://example.com'));
        expect(map['ctaText'], equals('Shop Now'));
        expect(map['imageFit'], equals(0)); // ImageFit.cover.index
        expect(map['startDate'], isA<Timestamp>());
        expect(map['endDate'], isA<Timestamp>());
      });

      test('should handle null optional fields in toMap', () {
        final adWithNulls = AdModel(
          id: 'test-id',
          ownerId: 'owner-id',
          type: AdType.feed_ad,
          size: AdSize.small,
          imageUrl: 'https://example.com/image.jpg',
          title: 'Test Title',
          description: 'Test Description',
          location: AdLocation.feed,
          duration: AdDuration.daily,
          startDate: testStartDate,
          endDate: testEndDate,
          status: AdStatus.draft,
        );

        final map = adWithNulls.toMap();

        expect(map['approvalId'], isNull);
        expect(map['destinationUrl'], isNull);
        expect(map['ctaText'], isNull);
      });
    });

    group('copyWith Tests', () {
      test('should create copy with updated properties', () {
        final updatedAd = testAd.copyWith(
          title: 'Updated Title',
          status: AdStatus.approved,
          destinationUrl: 'https://updated.com',
        );

        expect(updatedAd.title, equals('Updated Title'));
        expect(updatedAd.status, equals(AdStatus.approved));
        expect(updatedAd.destinationUrl, equals('https://updated.com'));

        // Original properties should remain unchanged
        expect(updatedAd.id, equals(testAd.id));
        expect(updatedAd.ownerId, equals(testAd.ownerId));
        expect(updatedAd.type, equals(testAd.type));
      });

      test('should handle linkUrl parameter in copyWith', () {
        final updatedAd = testAd.copyWith(linkUrl: 'https://link.com');
        expect(updatedAd.destinationUrl, equals('https://link.com'));
      });

      test('should preserve original values when no updates provided', () {
        final copiedAd = testAd.copyWith();

        expect(copiedAd.id, equals(testAd.id));
        expect(copiedAd.title, equals(testAd.title));
        expect(copiedAd.status, equals(testAd.status));
        expect(copiedAd.destinationUrl, equals(testAd.destinationUrl));
      });
    });

    group('Edge Cases', () {
      test('should handle string enum values in fromMap', () {
        final map = {
          'ownerId': 'test-owner',
          'type': '0', // String instead of int
          'size': '1',
          'imageUrl': 'https://example.com/image.jpg',
          'title': 'Test Title',
          'description': 'Test Description',
          'location': '0',
          'duration': {'type': 'daily', 'days': 1},
          'startDate': Timestamp.fromDate(testStartDate),
          'endDate': Timestamp.fromDate(testEndDate),
          'status': '0',
        };

        final ad = AdModel.fromMap(map, 'test-id');
        expect(ad.type, equals(AdType.banner_ad));
        expect(ad.size, equals(AdSize.medium));
      });

      test('should handle malformed artworkUrls string', () {
        final map = {
          'ownerId': 'test-owner',
          'type': 0,
          'size': 0,
          'imageUrl': 'https://example.com/image.jpg',
          'artworkUrls':
              ',,,https://example.com/image1.jpg,,https://example.com/image2.jpg,,,',
          'title': 'Test Title',
          'description': 'Test Description',
          'location': 0,
          'duration': {'type': 'daily', 'days': 1},
          'startDate': Timestamp.fromDate(testStartDate),
          'endDate': Timestamp.fromDate(testEndDate),
          'status': 0,
        };

        final ad = AdModel.fromMap(map, 'test-id');
        expect(ad.artworkUrls, hasLength(2));
        expect(ad.artworkUrls, contains('https://example.com/image1.jpg'));
        expect(ad.artworkUrls, contains('https://example.com/image2.jpg'));
      });
    });
  });
}

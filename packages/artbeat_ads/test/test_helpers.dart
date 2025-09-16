import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_ads/src/models/ad_model.dart';
import 'package:artbeat_ads/src/models/ad_type.dart';
import 'package:artbeat_ads/src/models/ad_size.dart';
import 'package:artbeat_ads/src/models/ad_status.dart';
import 'package:artbeat_ads/src/models/ad_location.dart';
import 'package:artbeat_ads/src/models/ad_duration.dart';
import 'package:artbeat_ads/src/models/image_fit.dart';
import 'package:artbeat_ads/src/models/ad_analytics_model.dart';
import 'package:artbeat_ads/src/models/payment_history_model.dart';

/// Test helpers and utilities for the artbeat_ads package tests
class AdTestHelpers {
  /// Creates a basic test ad model with default values
  static AdModel createTestAd({
    String id = 'test-ad-id',
    String ownerId = 'test-owner-id',
    AdType type = AdType.banner_ad,
    AdSize size = AdSize.medium,
    String imageUrl = 'https://example.com/test-image.jpg',
    List<String> artworkUrls = const [],
    String title = 'Test Ad Title',
    String description = 'Test ad description',
    AdLocation location = AdLocation.fluidDashboard,
    AdDuration duration = AdDuration.weekly,
    DateTime? startDate,
    DateTime? endDate,
    AdStatus status = AdStatus.pending,
    String? approvalId,
    String? destinationUrl,
    String? ctaText,
    ImageFit imageFit = ImageFit.cover,
  }) {
    final now = DateTime.now();
    return AdModel(
      id: id,
      ownerId: ownerId,
      type: type,
      size: size,
      imageUrl: imageUrl,
      artworkUrls: artworkUrls,
      title: title,
      description: description,
      location: location,
      duration: duration,
      startDate: startDate ?? now,
      endDate: endDate ?? now.add(Duration(days: duration.days)),
      status: status,
      approvalId: approvalId,
      destinationUrl: destinationUrl,
      ctaText: ctaText,
      imageFit: imageFit,
    );
  }

  /// Creates a test ad with multiple images for rotation testing
  static AdModel createTestAdWithMultipleImages({
    String id = 'test-ad-multi-id',
    int imageCount = 3,
  }) {
    final artworkUrls = List.generate(
      imageCount,
      (index) => 'https://example.com/image${index + 1}.jpg',
    );

    return createTestAd(
      id: id,
      artworkUrls: artworkUrls,
      imageUrl: artworkUrls.first,
    );
  }

  /// Creates a test analytics model
  static AdAnalyticsModel createTestAnalytics({
    String adId = 'test-ad-id',
    String ownerId = 'test-owner-id',
    int totalImpressions = 1000,
    int totalClicks = 50,
    double? clickThroughRate,
    double totalRevenue = 499.50,
    double averageViewDuration = 3.5,
    DateTime? firstImpressionDate,
    DateTime? lastImpressionDate,
    DateTime? lastUpdated,
    Map<String, Map<String, dynamic>>? locationBreakdown,
    Map<String, dynamic>? dailyImpressions,
    Map<String, dynamic>? dailyClicks,
  }) {
    final now = DateTime.now();
    return AdAnalyticsModel(
      adId: adId,
      ownerId: ownerId,
      totalImpressions: totalImpressions,
      totalClicks: totalClicks,
      clickThroughRate:
          clickThroughRate ??
          AdAnalyticsModel.calculateCTR(totalImpressions, totalClicks),
      totalRevenue: totalRevenue,
      averageViewDuration: averageViewDuration,
      firstImpressionDate:
          firstImpressionDate ?? now.subtract(const Duration(days: 7)),
      lastImpressionDate: lastImpressionDate ?? now,
      lastUpdated: lastUpdated ?? now,
      locationBreakdown:
          (locationBreakdown as Map<String, int>?) ??
          {'dashboard': 600, 'feed': 400},
      dailyImpressions:
          (dailyImpressions as Map<String, int>?) ??
          {'2024-01-01': 100, '2024-01-02': 150, '2024-01-03': 200},
      dailyClicks:
          (dailyClicks as Map<String, int>?) ??
          {'2024-01-01': 5, '2024-01-02': 8, '2024-01-03': 12},
    );
  }

  /// Creates a test payment history model
  static PaymentHistoryModel createTestPayment({
    String id = 'test-payment-id',
    String userId = 'test-user-id',
    String adId = 'test-ad-id',
    String adTitle = 'Test Ad Campaign',
    double amount = 99.99,
    String currency = 'USD',
    PaymentMethod paymentMethod = PaymentMethod.card,
    PaymentStatus status = PaymentStatus.completed,
    DateTime? transactionDate,
    String? stripePaymentIntentId,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentHistoryModel(
      id: id,
      userId: userId,
      adId: adId,
      adTitle: adTitle,
      amount: amount,
      currency: currency,
      paymentMethod: paymentMethod,
      status: status,
      transactionDate: transactionDate ?? DateTime.now(),
      stripePaymentIntentId: stripePaymentIntentId,
      metadata: metadata ?? {},
    );
  }

  /// Creates a list of test ads with different properties
  static List<AdModel> createTestAdList({
    int count = 5,
    String ownerIdPrefix = 'owner',
  }) {
    return List.generate(count, (index) {
      return createTestAd(
        id: 'test-ad-$index',
        ownerId: '$ownerIdPrefix-$index',
        title: 'Test Ad ${index + 1}',
        type: index % 2 == 0 ? AdType.banner_ad : AdType.feed_ad,
        size: AdSize.values[index % AdSize.values.length],
        status: AdStatus.values[index % AdStatus.values.length],
        location: AdLocation.values[index % AdLocation.values.length],
      );
    });
  }

  /// Creates test data for different ad sizes and their expected properties
  static Map<AdSize, Map<String, dynamic>> getAdSizeTestData() {
    return {
      AdSize.small: {
        'width': 320,
        'height': 50,
        'pricePerDay': 1.0,
        'displayName': 'Small (320x50)',
        'dimensions': '320x50',
      },
      AdSize.medium: {
        'width': 320,
        'height': 100,
        'pricePerDay': 5.0,
        'displayName': 'Medium (320x100)',
        'dimensions': '320x100',
      },
      AdSize.large: {
        'width': 320,
        'height': 250,
        'pricePerDay': 10.0,
        'displayName': 'Large (320x250)',
        'dimensions': '320x250',
      },
    };
  }

  /// Creates test data for different ad statuses and their expected properties
  static Map<AdStatus, Map<String, dynamic>> getAdStatusTestData() {
    return {
      AdStatus.draft: {
        'displayName': 'Draft',
        'isEditable': true,
        'isFinal': false,
      },
      AdStatus.pending: {
        'displayName': 'Pending Review',
        'isEditable': false,
        'isFinal': false,
      },
      AdStatus.approved: {
        'displayName': 'Approved',
        'isEditable': false,
        'isFinal': false,
      },
      AdStatus.rejected: {
        'displayName': 'Rejected',
        'isEditable': true,
        'isFinal': true,
      },
      AdStatus.active: {
        'displayName': 'Active',
        'isEditable': false,
        'isFinal': false,
      },
      AdStatus.expired: {
        'displayName': 'Expired',
        'isEditable': false,
        'isFinal': true,
      },
    };
  }

  /// Creates test widget wrapper for widget tests
  static Widget createTestWrapper({required Widget child, ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(body: child),
    );
  }

  /// Creates a constrained test wrapper for layout testing
  static Widget createConstrainedTestWrapper({
    required Widget child,
    double? width,
    double? height,
    BoxConstraints? constraints,
  }) {
    Widget constrainedChild = child;

    if (width != null || height != null) {
      constrainedChild = SizedBox(width: width, height: height, child: child);
    }

    if (constraints != null) {
      constrainedChild = ConstrainedBox(
        constraints: constraints,
        child: constrainedChild,
      );
    }

    return createTestWrapper(child: constrainedChild);
  }

  /// Validates that an ad model has all required fields
  static void validateAdModel(AdModel ad) {
    expect(ad.id, isNotEmpty);
    expect(ad.ownerId, isNotEmpty);
    expect(ad.title, isNotEmpty);
    expect(ad.description, isNotEmpty);
    expect(ad.imageUrl, isNotEmpty);
    expect(ad.startDate, isNotNull);
    expect(ad.endDate, isNotNull);
    expect(ad.endDate.isAfter(ad.startDate), isTrue);
    expect(ad.pricePerDay, greaterThan(0));
  }

  /// Validates that an analytics model has consistent data
  static void validateAnalyticsModel(AdAnalyticsModel analytics) {
    expect(analytics.adId, isNotEmpty);
    expect(analytics.ownerId, isNotEmpty);
    expect(analytics.totalImpressions, greaterThanOrEqualTo(0));
    expect(analytics.totalClicks, greaterThanOrEqualTo(0));
    expect(
      analytics.totalClicks,
      lessThanOrEqualTo(analytics.totalImpressions),
    );
    expect(analytics.clickThroughRate, greaterThanOrEqualTo(0));
    expect(analytics.clickThroughRate, lessThanOrEqualTo(100));
    expect(analytics.lastUpdated, isNotNull);
  }

  /// Validates that a payment model has all required fields
  static void validatePaymentModel(PaymentHistoryModel payment) {
    expect(payment.id, isNotEmpty);
    expect(payment.userId, isNotEmpty);
    expect(payment.adId, isNotEmpty);
    expect(payment.adTitle, isNotEmpty);
    expect(payment.amount, greaterThan(0));
    expect(payment.currency, isNotEmpty);
    expect(payment.transactionDate, isNotNull);
  }

  /// Creates mock Firestore data for an ad
  static Map<String, dynamic> createMockFirestoreAdData({AdModel? ad}) {
    final testAd = ad ?? createTestAd();
    return testAd.toMap();
  }

  /// Creates mock Firestore data for analytics
  static Map<String, dynamic> createMockFirestoreAnalyticsData({
    AdAnalyticsModel? analytics,
  }) {
    final testAnalytics = analytics ?? createTestAnalytics();
    return testAnalytics.toMap();
  }

  /// Creates mock Firestore data for payment
  static Map<String, dynamic> createMockFirestorePaymentData({
    PaymentHistoryModel? payment,
  }) {
    final testPayment = payment ?? createTestPayment();
    return testPayment.toFirestore();
  }

  /// Utility to wait for animations and async operations in tests
  static Future<void> pumpAndSettle(
    WidgetTester tester, {
    Duration duration = const Duration(milliseconds: 100),
  }) async {
    await tester.pump(duration);
    await tester.pumpAndSettle();
  }

  /// Utility to find widgets by type with optional matcher
  static Finder findWidgetByType<T extends Widget>({bool skipOffstage = true}) {
    return find.byType(T, skipOffstage: skipOffstage);
  }

  /// Utility to verify widget properties
  static void verifyWidgetProperties<T extends Widget>(
    WidgetTester tester,
    void Function(T widget) verifier,
  ) {
    final widget = tester.widget<T>(find.byType(T));
    verifier(widget);
  }

  /// Creates test data for error scenarios
  static Map<String, dynamic> createInvalidAdData() {
    return {
      'ownerId': '', // Empty owner ID
      'type': 999, // Invalid enum value
      'size': -1, // Invalid enum value
      'imageUrl': '', // Empty image URL
      'title': '', // Empty title
      'description': '', // Empty description
      'location': 100, // Invalid enum value
      'status': 50, // Invalid enum value
      'startDate': 'invalid-date', // Invalid date format
      'endDate': 'invalid-date', // Invalid date format
    };
  }

  /// Creates test data for edge cases
  static Map<String, dynamic> createEdgeCaseAdData() {
    return {
      'ownerId': 'a' * 1000, // Very long owner ID
      'type': 0,
      'size': 0,
      'imageUrl': 'https://example.com/${'a' * 2000}.jpg', // Very long URL
      'title': 'Title with special chars: äöü@#\$%^&*()',
      'description': 'Description with unicode: 🎨💰📊',
      'location': 0,
      'status': 0,
      'artworkUrls': List.generate(
        100,
        (i) => 'https://example.com/image$i.jpg',
      ).join(','), // Many URLs
    };
  }
}

/// Custom matchers for ad-specific testing
class AdMatchers {
  /// Matcher to verify an ad has valid pricing
  static Matcher hasValidPricing() {
    return predicate<AdModel>((ad) => ad.pricePerDay > 0, 'has valid pricing');
  }

  /// Matcher to verify an ad has valid date range
  static Matcher hasValidDateRange() {
    return predicate<AdModel>(
      (ad) => ad.endDate.isAfter(ad.startDate),
      'has valid date range',
    );
  }

  /// Matcher to verify analytics has consistent data
  static Matcher hasConsistentAnalytics() {
    return predicate<AdAnalyticsModel>(
      (analytics) => analytics.totalClicks <= analytics.totalImpressions,
      'has consistent analytics data',
    );
  }

  /// Matcher to verify payment has valid amount
  static Matcher hasValidPaymentAmount() {
    return predicate<PaymentHistoryModel>(
      (payment) => payment.amount > 0,
      'has valid payment amount',
    );
  }
}

/// Test constants for consistent testing
class AdTestConstants {
  static const String testImageUrl = 'https://example.com/test-image.jpg';
  static const String testDestinationUrl = 'https://example.com';
  static const String testOwnerId = 'test-owner-id';
  static const String testAdId = 'test-ad-id';
  static const String testUserId = 'test-user-id';
  static const String testTitle = 'Test Ad Title';
  static const String testDescription = 'Test ad description';
  static const String testCtaText = 'Shop Now';
  static const double testAmount = 99.99;
  static const String testCurrency = 'USD';

  static final DateTime testStartDate = DateTime(2024, 1, 1);
  static final DateTime testEndDate = DateTime(2024, 1, 31);

  static const List<String> testArtworkUrls = [
    'https://example.com/image1.jpg',
    'https://example.com/image2.jpg',
    'https://example.com/image3.jpg',
  ];

  static const Map<String, dynamic> testMetadata = {
    'campaign_type': 'promotional',
    'target_audience': 'artists',
    'budget_category': 'standard',
  };
}

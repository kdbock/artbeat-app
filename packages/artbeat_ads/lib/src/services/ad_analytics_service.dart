import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import '../models/ad_analytics_model.dart';
import '../models/ad_impression_model.dart';
import '../models/ad_click_model.dart';
import '../models/ad_location.dart';

/// Service for tracking and analyzing ad performance
class AdAnalyticsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _analyticsCollection =>
      _firestore.collection('ad_analytics');
  CollectionReference get _impressionsCollection =>
      _firestore.collection('ad_impressions');
  CollectionReference get _clicksCollection =>
      _firestore.collection('ad_clicks');

  /// Track an ad impression (view)
  Future<void> trackAdImpression(
    String adId,
    String ownerId, {
    String? viewerId,
    required AdLocation location,
    Duration? viewDuration,
    Map<String, dynamic>? metadata,
    String? userAgent,
    String? sessionId,
  }) async {
    try {
      // Create impression record
      final impression = AdImpressionModel.create(
        adId: adId,
        ownerId: ownerId,
        viewerId: viewerId,
        location: location,
        viewDuration: viewDuration,
        metadata: metadata,
        userAgent: userAgent,
        sessionId: sessionId,
      );

      // Store impression
      await _impressionsCollection.add(impression.toMap());

      // Update analytics aggregation asynchronously
      _updateAnalyticsAggregation(
        adId,
        ownerId,
        isImpression: true,
        location: location,
      );

      debugPrint('Ad impression tracked: $adId at ${location.name}');
    } catch (e) {
      debugPrint('Error tracking ad impression: $e');
      // Don't throw - analytics should not break app functionality
    }
  }

  /// Track an ad click/interaction
  Future<void> trackAdClick(
    String adId,
    String ownerId, {
    String? viewerId,
    required AdLocation location,
    String? destinationUrl,
    String clickType = 'general',
    Map<String, dynamic>? metadata,
    String? userAgent,
    String? sessionId,
    String? referrer,
  }) async {
    try {
      // Create click record
      final click = AdClickModel.create(
        adId: adId,
        ownerId: ownerId,
        viewerId: viewerId,
        location: location,
        destinationUrl: destinationUrl,
        clickType: clickType,
        metadata: metadata,
        userAgent: userAgent,
        sessionId: sessionId,
        referrer: referrer,
      );

      // Store click
      await _clicksCollection.add(click.toMap());

      // Update analytics aggregation asynchronously
      _updateAnalyticsAggregation(
        adId,
        ownerId,
        isClick: true,
        location: location,
      );

      debugPrint('Ad click tracked: $adId at ${location.name} ($clickType)');
    } catch (e) {
      debugPrint('Error tracking ad click: $e');
      // Don't throw - analytics should not break app functionality
    }
  }

  /// Get comprehensive analytics for a specific ad
  Future<AdAnalyticsModel?> getAdPerformanceMetrics(String adId) async {
    try {
      final doc = await _analyticsCollection.doc(adId).get();

      if (doc.exists && doc.data() != null) {
        return AdAnalyticsModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting ad performance metrics: $e');
      return null;
    }
  }

  /// Get analytics for all ads owned by a user
  Future<List<AdAnalyticsModel>> getUserAdAnalytics(String ownerId) async {
    try {
      final query = await _analyticsCollection
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('lastUpdated', descending: true)
          .get();

      return query.docs
          .map(
            (doc) =>
                AdAnalyticsModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting user ad analytics: $e');
      return [];
    }
  }

  /// Get performance data for a specific location
  Future<Map<String, dynamic>> getLocationPerformanceData(
    AdLocation location,
  ) async {
    try {
      // Get impressions for location
      final impressionsQuery = await _impressionsCollection
          .where('location', isEqualTo: location.name)
          .where(
            'timestamp',
            isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 30)),
            ),
          )
          .get();

      // Get clicks for location
      final clicksQuery = await _clicksCollection
          .where('location', isEqualTo: location.name)
          .where(
            'timestamp',
            isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 30)),
            ),
          )
          .get();

      final impressions = impressionsQuery.docs.length;
      final clicks = clicksQuery.docs.length;
      final ctr = AdAnalyticsModel.calculateCTR(impressions, clicks);

      return {
        'location': location.name,
        'impressions': impressions,
        'clicks': clicks,
        'clickThroughRate': ctr,
        'period': '30 days',
      };
    } catch (e) {
      debugPrint('Error getting location performance data: $e');
      return {
        'location': location.name,
        'impressions': 0,
        'clicks': 0,
        'clickThroughRate': 0.0,
        'period': '30 days',
      };
    }
  }

  /// Get raw impression data for an ad
  Future<List<AdImpressionModel>> getAdImpressions(
    String adId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _impressionsCollection.where('adId', isEqualTo: adId);

      if (startDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final snapshot = await query
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) => AdImpressionModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting ad impressions: $e');
      return [];
    }
  }

  /// Get raw click data for an ad
  Future<List<AdClickModel>> getAdClicks(
    String adId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _clicksCollection.where('adId', isEqualTo: adId);

      if (startDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final snapshot = await query
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) => AdClickModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting ad clicks: $e');
      return [];
    }
  }

  /// Calculate click-through rate for an ad
  Future<double> calculateClickThroughRate(String adId) async {
    try {
      final analytics = await getAdPerformanceMetrics(adId);

      if (analytics != null) {
        return analytics.clickThroughRate;
      }

      // Fallback to real-time calculation
      final impressions = await getAdImpressions(adId, limit: 1000);
      final clicks = await getAdClicks(adId, limit: 1000);

      return AdAnalyticsModel.calculateCTR(impressions.length, clicks.length);
    } catch (e) {
      debugPrint('Error calculating CTR: $e');
      return 0.0;
    }
  }

  /// Generate performance report for an ad
  Future<Map<String, dynamic>> generatePerformanceReport(
    String adId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final analytics = await getAdPerformanceMetrics(adId);
      final impressions = await getAdImpressions(
        adId,
        startDate: startDate,
        endDate: endDate,
      );
      final clicks = await getAdClicks(
        adId,
        startDate: startDate,
        endDate: endDate,
      );

      // Group data by day for trending
      final Map<String, int> dailyImpressions = {};
      final Map<String, int> dailyClicks = {};

      for (final impression in impressions) {
        final dateKey =
            '${impression.timestamp.year}-${impression.timestamp.month.toString().padLeft(2, '0')}-${impression.timestamp.day.toString().padLeft(2, '0')}';
        dailyImpressions[dateKey] = (dailyImpressions[dateKey] ?? 0) + 1;
      }

      for (final click in clicks) {
        final dateKey =
            '${click.timestamp.year}-${click.timestamp.month.toString().padLeft(2, '0')}-${click.timestamp.day.toString().padLeft(2, '0')}';
        dailyClicks[dateKey] = (dailyClicks[dateKey] ?? 0) + 1;
      }

      return {
        'adId': adId,
        'reportPeriod': {
          'startDate': startDate?.toIso8601String() ?? 'all_time',
          'endDate': endDate?.toIso8601String() ?? 'now',
        },
        'summary': {
          'totalImpressions': impressions.length,
          'totalClicks': clicks.length,
          'clickThroughRate': AdAnalyticsModel.calculateCTR(
            impressions.length,
            clicks.length,
          ),
        },
        'trending': {
          'dailyImpressions': dailyImpressions,
          'dailyClicks': dailyClicks,
        },
        'aggregatedData': analytics?.toMap(),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error generating performance report: $e');
      return {'error': 'Failed to generate report', 'message': e.toString()};
    }
  }

  /// Update analytics aggregation (called internally)
  Future<void> _updateAnalyticsAggregation(
    String adId,
    String ownerId, {
    bool isImpression = false,
    bool isClick = false,
    AdLocation? location,
  }) async {
    try {
      final docRef = _analyticsCollection.doc(adId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (snapshot.exists) {
          // Update existing analytics
          final data = snapshot.data() as Map<String, dynamic>;
          final analytics = AdAnalyticsModel.fromMap(data);

          final updatedAnalytics = analytics.copyWith(
            totalImpressions:
                analytics.totalImpressions + (isImpression ? 1 : 0),
            totalClicks: analytics.totalClicks + (isClick ? 1 : 0),
            clickThroughRate: AdAnalyticsModel.calculateCTR(
              analytics.totalImpressions + (isImpression ? 1 : 0),
              analytics.totalClicks + (isClick ? 1 : 0),
            ),
            lastUpdated: DateTime.now(),
            locationBreakdown: _updateLocationBreakdown(
              analytics.locationBreakdown,
              location,
              isImpression,
              isClick,
            ),
            dailyImpressions: _updateDailyData(
              analytics.dailyImpressions,
              isImpression,
            ),
            dailyClicks: _updateDailyData(analytics.dailyClicks, isClick),
          );

          transaction.update(docRef, updatedAnalytics.toMap());
        } else {
          // Create new analytics document
          final newAnalytics = AdAnalyticsModel(
            adId: adId,
            ownerId: ownerId,
            totalImpressions: isImpression ? 1 : 0,
            totalClicks: isClick ? 1 : 0,
            clickThroughRate: isClick && isImpression ? 100.0 : 0.0,
            totalRevenue: 0.0,
            averageViewDuration: 0.0,
            firstImpressionDate: DateTime.now(),
            lastImpressionDate: DateTime.now(),
            locationBreakdown: location != null
                ? {location.name: isImpression ? 1 : (isClick ? 1 : 0)}
                : {},
            dailyImpressions: isImpression ? {_getTodayKey(): 1} : {},
            dailyClicks: isClick ? {_getTodayKey(): 1} : {},
            lastUpdated: DateTime.now(),
          );

          transaction.set(docRef, newAnalytics.toMap());
        }
      });
    } catch (e) {
      debugPrint('Error updating analytics aggregation: $e');
    }
  }

  /// Helper method to update location breakdown
  Map<String, int> _updateLocationBreakdown(
    Map<String, int> current,
    AdLocation? location,
    bool isImpression,
    bool isClick,
  ) {
    if (location == null) return current;

    final updated = Map<String, int>.from(current);
    final key = location.name;
    final increment = (isImpression || isClick) ? 1 : 0;

    updated[key] = (updated[key] ?? 0) + increment;
    return updated;
  }

  /// Helper method to update daily data
  Map<String, int> _updateDailyData(
    Map<String, int> current,
    bool shouldIncrement,
  ) {
    if (!shouldIncrement) return current;

    final updated = Map<String, int>.from(current);
    final todayKey = _getTodayKey();

    updated[todayKey] = (updated[todayKey] ?? 0) + 1;
    return updated;
  }

  /// Get today's date key for daily tracking
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Stream analytics for real-time updates
  Stream<AdAnalyticsModel?> streamAdAnalytics(String adId) {
    return _analyticsCollection.doc(adId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AdAnalyticsModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// Clean up old analytics data (admin function)
  Future<void> cleanupOldAnalyticsData({int daysOld = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      // Clean up impressions
      final oldImpressions = await _impressionsCollection
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldImpressions.docs) {
        batch.delete(doc.reference);
      }

      // Clean up clicks
      final oldClicks = await _clicksCollection
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      for (final doc in oldClicks.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      debugPrint(
        'Cleaned up ${oldImpressions.docs.length + oldClicks.docs.length} old analytics records',
      );
    } catch (e) {
      debugPrint('Error cleaning up old analytics data: $e');
    }
  }
}

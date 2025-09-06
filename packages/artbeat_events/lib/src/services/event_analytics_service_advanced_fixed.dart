import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/artbeat_event.dart';

/// Advanced analytics service for comprehensive event data analysis
/// Phase 3 implementation with real-time metrics and detailed reporting
class EventAnalyticsServiceAdvanced {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  /// Get comprehensive analytics for events within a date range
  Future<Map<String, dynamic>> getAnalyticsData({
    String? artistId,
    DateTime? startDate,
    DateTime? endDate,
    String period = '30d',
  }) async {
    try {
      // Set default date range if not provided
      endDate ??= DateTime.now();
      startDate ??= _getStartDateFromPeriod(period);

      // Build base query
      Query query = _firestore.collection('events');

      // Add artist filter if specified
      if (artistId != null) {
        query = query.where('artistId', isEqualTo: artistId);
      }

      // Apply date range filter
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate);

      final QuerySnapshot eventsSnapshot = await query.get();
      final List<ArtbeatEvent> events = eventsSnapshot.docs
          .map(ArtbeatEvent.fromFirestore)
          .toList();

      return _calculateComprehensiveMetrics(events);
    } on FirebaseException catch (e) {
      _logger.e(
        'Firebase error fetching analytics data: ${e.message}',
        error: e,
      );
      return {
        'error': e.message,
        'totalEvents': 0,
        'totalViews': 0,
        'totalEngagements': 0,
        'totalRevenue': 0.0,
      };
    } catch (e) {
      _logger.e('Error fetching analytics data: $e', error: e);
      return {
        'error': e.toString(),
        'totalEvents': 0,
        'totalViews': 0,
        'totalEngagements': 0,
        'totalRevenue': 0.0,
      };
    }
  }

  /// Get today's key metrics for quick dashboard overview
  Future<Map<String, dynamic>> getTodayMetrics() async {
    try {
      final DateTime startOfDay = DateTime.now().subtract(
        Duration(
          hours: DateTime.now().hour,
          minutes: DateTime.now().minute,
          seconds: DateTime.now().second,
          milliseconds: DateTime.now().millisecond,
        ),
      );

      final QuerySnapshot eventsSnapshot = await _firestore
          .collection('events')
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .get();

      final List<ArtbeatEvent> events = eventsSnapshot.docs
          .map(ArtbeatEvent.fromFirestore)
          .toList();

      return {
        'date': startOfDay.toIso8601String(),
        'totalEvents': events.length,
        'eventsToday': events
            .where((e) => e.dateTime.isAfter(startOfDay))
            .length,
        'totalViews': _calculateTotalViews(events),
        'totalEngagements': _calculateTotalEngagements(events),
        'todayRevenue': _calculateTodayRevenue(events),
      };
    } on FirebaseException catch (e) {
      _logger.e(
        'Firebase error fetching today metrics: ${e.message}',
        error: e,
      );
      return {'error': e.message};
    } catch (e) {
      _logger.e('Error fetching today metrics: $e', error: e);
      return {'error': e.toString()};
    }
  }

  /// Get popular events based on engagement metrics
  Future<List<ArtbeatEvent>> getPopularEvents({int limit = 10}) async {
    try {
      final QuerySnapshot eventsSnapshot = await _firestore
          .collection('events')
          .where('isPublic', isEqualTo: true)
          .limit(limit * 2) // Get more to allow for filtering
          .get();

      final List<ArtbeatEvent> events = eventsSnapshot.docs
          .map(ArtbeatEvent.fromFirestore)
          .toList();

      // Sort by popularity score (views + likes + shares)
      events.sort(
        (a, b) => _calculatePopularityScore(
          b,
        ).compareTo(_calculatePopularityScore(a)),
      );

      return events.take(limit).toList();
    } on FirebaseException catch (e) {
      _logger.e(
        'Firebase error fetching popular events: ${e.message}',
        error: e,
      );
      return [];
    } catch (e) {
      _logger.e('Error fetching popular events: $e', error: e);
      return [];
    }
  }

  /// Calculate popularity score for an event
  int _calculatePopularityScore(ArtbeatEvent event) {
    return event.viewCount + (event.likeCount * 2) + (event.shareCount * 3);
  }

  /// Calculate total views across events
  int _calculateTotalViews(List<ArtbeatEvent> events) {
    return events.fold(0, (total, event) => total + event.viewCount);
  }

  /// Calculate total engagements (likes + shares + saves)
  int _calculateTotalEngagements(List<ArtbeatEvent> events) {
    return events.fold(
      0,
      (total, event) =>
          total + event.likeCount + event.shareCount + event.saveCount,
    );
  }

  /// Calculate today's revenue from events
  double _calculateTodayRevenue(List<ArtbeatEvent> events) {
    final today = DateTime.now();
    final todayEvents = events
        .where(
          (e) =>
              e.dateTime.day == today.day &&
              e.dateTime.month == today.month &&
              e.dateTime.year == today.year,
        )
        .toList();

    return _calculateEventsRevenue(todayEvents);
  }

  /// Calculate revenue from a list of events
  double _calculateEventsRevenue(List<ArtbeatEvent> events) {
    double totalRevenue = 0.0;
    for (final event in events) {
      for (final ticketType in event.ticketTypes) {
        totalRevenue += (ticketType.quantitySold ?? 0) * ticketType.price;
      }
    }
    return totalRevenue;
  }

  /// Calculate comprehensive metrics for events
  Map<String, dynamic> _calculateComprehensiveMetrics(
    List<ArtbeatEvent> events,
  ) {
    final totalViews = _calculateTotalViews(events);
    final totalEngagements = _calculateTotalEngagements(events);
    final totalRevenue = _calculateEventsRevenue(events);

    // Category distribution
    final Map<String, int> categoryDistribution = {};
    for (final event in events) {
      categoryDistribution[event.category] =
          (categoryDistribution[event.category] ?? 0) + 1;
    }

    return {
      'totalEvents': events.length,
      'totalViews': totalViews,
      'totalEngagements': totalEngagements,
      'totalRevenue': totalRevenue,
      'averageViewsPerEvent': events.isEmpty ? 0 : totalViews / events.length,
      'averageEngagementsPerEvent': events.isEmpty
          ? 0
          : totalEngagements / events.length,
      'averageRevenuePerEvent': events.isEmpty
          ? 0
          : totalRevenue / events.length,
      'categoryDistribution': categoryDistribution,
      'topCategories': _getTopCategories(categoryDistribution),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Get top categories by event count
  List<Map<String, dynamic>> _getTopCategories(Map<String, int> distribution) {
    final entries = distribution.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    return entries
        .take(5)
        .map((entry) => {'category': entry.key, 'count': entry.value})
        .toList();
  }

  /// Get start date from period string
  DateTime _getStartDateFromPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
      case '90d':
        return now.subtract(const Duration(days: 90));
      case '1y':
        return now.subtract(const Duration(days: 365));
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  /// Export analytics data for external analysis
  Future<Map<String, dynamic>> exportAnalyticsData({
    String? artistId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Use default date range if not provided
      endDate ??= DateTime.now();
      startDate ??= endDate.subtract(const Duration(days: 90));

      final analytics = await getAnalyticsData(
        artistId: artistId,
        startDate: startDate,
        endDate: endDate,
      );

      // Add metadata
      analytics['exportMetadata'] = {
        'exportedAt': DateTime.now().toIso8601String(),
        'exportedBy': _auth.currentUser?.uid ?? 'anonymous',
        'dateRange': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
        'filters': {'artistId': artistId},
      };

      return analytics;
    } on FirebaseException catch (e) {
      _logger.e(
        'Firebase error exporting analytics data: ${e.message}',
        error: e,
      );
      return {'error': 'Failed to export analytics data: ${e.message}'};
    } catch (e) {
      _logger.e('Error exporting analytics data: $e', error: e);
      return {'error': 'Failed to export analytics data: $e'};
    }
  }
}

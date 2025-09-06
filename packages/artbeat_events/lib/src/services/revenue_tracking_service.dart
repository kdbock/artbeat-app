import 'package:cloud_firestore/cloud_firestore.dart';

/// Real-time revenue tracking service for Phase 3 implementation
/// Provides live revenue monitoring, reporting, and notifications
class RevenueTrackingService {
  static final _instance = RevenueTrackingService._internal();
  factory RevenueTrackingService() => _instance;
  RevenueTrackingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get real-time revenue stream for live updates
  Stream<Map<String, dynamic>> getRealTimeRevenueStream({
    String? artistId,
    Duration? updateInterval,
  }) {
    // Base query for revenue data
    Query query = _firestore.collection('eventTickets');

    if (artistId != null) {
      query = query.where('artistId', isEqualTo: artistId);
    }

    return query.snapshots().asyncMap((snapshot) async {
      return await _calculateRevenueMetrics(snapshot.docs, artistId);
    });
  }

  /// Get revenue analytics for a specific time period
  Future<Map<String, dynamic>> getRevenueAnalytics({
    String? artistId,
    DateTime? startDate,
    DateTime? endDate,
    String groupBy = 'day', // day, week, month
  }) async {
    try {
      endDate ??= DateTime.now();
      startDate ??= endDate.subtract(const Duration(days: 30));

      Query query = _firestore
          .collection('eventTickets')
          .where('purchaseDate', isGreaterThanOrEqualTo: startDate)
          .where('purchaseDate', isLessThanOrEqualTo: endDate)
          .orderBy('purchaseDate', descending: false);

      if (artistId != null) {
        query = query.where('artistId', isEqualTo: artistId);
      }

      final snapshot = await query.get();
      return await _processRevenueData(snapshot.docs, groupBy);
    } catch (e) {
      throw Exception('Failed to get revenue analytics: $e');
    }
  }

  /// Get top revenue-generating events
  Future<List<Map<String, dynamic>>> getTopRevenueEvents({
    String? artistId,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      endDate ??= DateTime.now();
      startDate ??= endDate.subtract(const Duration(days: 30));

      Query query = _firestore
          .collection('eventTickets')
          .where('purchaseDate', isGreaterThanOrEqualTo: startDate)
          .where('purchaseDate', isLessThanOrEqualTo: endDate);

      if (artistId != null) {
        query = query.where('artistId', isEqualTo: artistId);
      }

      final snapshot = await query.get();

      // Group by event and calculate revenue
      final eventRevenue = <String, Map<String, dynamic>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final eventId = data['eventId'] as String?;
        final price = (data['price'] as num?)?.toDouble() ?? 0;
        final quantity = (data['quantity'] as int?) ?? 1;
        final revenue = price * quantity;

        if (eventId != null) {
          if (!eventRevenue.containsKey(eventId)) {
            eventRevenue[eventId] = {
              'eventId': eventId,
              'totalRevenue': 0.0,
              'ticketsSold': 0,
              'eventTitle': data['eventTitle'] ?? 'Unknown Event',
            };
          }

          eventRevenue[eventId]!['totalRevenue'] =
              (eventRevenue[eventId]!['totalRevenue'] as double) + revenue;
          eventRevenue[eventId]!['ticketsSold'] =
              (eventRevenue[eventId]!['ticketsSold'] as int) + quantity;
        }
      }

      // Sort by revenue and return top events
      final sortedEvents = eventRevenue.values.toList();
      sortedEvents.sort(
        (a, b) => (b['totalRevenue'] as double).compareTo(
          a['totalRevenue'] as double,
        ),
      );

      return sortedEvents.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get top revenue events: $e');
    }
  }

  /// Get revenue projections based on historical data
  Future<Map<String, dynamic>> getRevenueProjections({
    String? artistId,
    int projectionDays = 30,
  }) async {
    try {
      // Get historical data for trend analysis
      final endDate = DateTime.now();
      final startDate = endDate.subtract(
        const Duration(days: 90),
      ); // 3 months of data

      final historicalData = await getRevenueAnalytics(
        artistId: artistId,
        startDate: startDate,
        endDate: endDate,
      );

      final dailyRevenue =
          historicalData['dailyRevenue'] as List<Map<String, dynamic>>;

      // Calculate trend and projection
      final projection = _calculateRevenueProjection(
        dailyRevenue,
        projectionDays,
      );

      return {
        'projectionPeriod': projectionDays,
        'projectedRevenue': projection['totalProjected'],
        'dailyProjections': projection['dailyProjections'],
        'confidence': projection['confidence'],
        'basedOnDays': dailyRevenue.length,
        'trend': projection['trend'], // 'increasing', 'decreasing', 'stable'
      };
    } catch (e) {
      throw Exception('Failed to calculate revenue projections: $e');
    }
  }

  /// Get revenue alerts and notifications
  Future<List<Map<String, dynamic>>> getRevenueAlerts({
    String? artistId,
  }) async {
    try {
      final alerts = <Map<String, dynamic>>[];

      // Get recent revenue data for analysis
      final recentData = await getRevenueAnalytics(
        artistId: artistId,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );

      final totalRevenue = recentData['totalRevenue'] as double;
      final previousWeekData = await getRevenueAnalytics(
        artistId: artistId,
        startDate: DateTime.now().subtract(const Duration(days: 14)),
        endDate: DateTime.now().subtract(const Duration(days: 7)),
      );

      final previousRevenue = previousWeekData['totalRevenue'] as double;

      // Check for significant changes
      if (previousRevenue > 0) {
        final changePercent =
            ((totalRevenue - previousRevenue) / previousRevenue) * 100;

        if (changePercent > 50) {
          alerts.add({
            'type': 'revenue_spike',
            'severity': 'high',
            'message':
                'Revenue increased by ${changePercent.toStringAsFixed(1)}% this week!',
            'value': changePercent,
            'timestamp': DateTime.now(),
          });
        } else if (changePercent < -30) {
          alerts.add({
            'type': 'revenue_drop',
            'severity': 'medium',
            'message':
                'Revenue decreased by ${changePercent.abs().toStringAsFixed(1)}% this week',
            'value': changePercent,
            'timestamp': DateTime.now(),
          });
        }
      }

      // Check for milestone achievements
      if (totalRevenue >= 1000 && previousRevenue < 1000) {
        alerts.add({
          'type': 'milestone',
          'severity': 'high',
          'message':
              'Congratulations! You\'ve reached \$1,000 in weekly revenue!',
          'value': totalRevenue,
          'timestamp': DateTime.now(),
        });
      }

      return alerts;
    } catch (e) {
      throw Exception('Failed to get revenue alerts: $e');
    }
  }

  /// Export revenue data for reporting
  Future<Map<String, dynamic>> exportRevenueData({
    String? artistId,
    DateTime? startDate,
    DateTime? endDate,
    String format = 'json', // json, csv
  }) async {
    try {
      final analytics = await getRevenueAnalytics(
        artistId: artistId,
        startDate: startDate,
        endDate: endDate,
      );

      final topEvents = await getTopRevenueEvents(
        artistId: artistId,
        startDate: startDate,
        endDate: endDate,
      );

      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'artistId': artistId,
        'dateRange': {
          'start': startDate?.toIso8601String(),
          'end': endDate?.toIso8601String(),
        },
        'summary': analytics,
        'topEvents': topEvents,
        'format': format,
      };

      return exportData;
    } catch (e) {
      throw Exception('Failed to export revenue data: $e');
    }
  }

  // Private helper methods

  Future<Map<String, dynamic>> _calculateRevenueMetrics(
    List<QueryDocumentSnapshot> docs,
    String? artistId,
  ) async {
    double totalRevenue = 0;
    int totalTickets = 0;
    double todayRevenue = 0;
    int todayTickets = 0;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final price = (data['price'] as num?)?.toDouble() ?? 0;
      final quantity = (data['quantity'] as int?) ?? 1;
      final purchaseDate = (data['purchaseDate'] as Timestamp?)?.toDate();

      final revenue = price * quantity;
      totalRevenue += revenue;
      totalTickets += quantity;

      // Check if purchase was today
      if (purchaseDate != null &&
          purchaseDate.isAfter(startOfDay) &&
          purchaseDate.isBefore(endOfDay)) {
        todayRevenue += revenue;
        todayTickets += quantity;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'totalTickets': totalTickets,
      'todayRevenue': todayRevenue,
      'todayTickets': todayTickets,
      'averageTicketPrice': totalTickets > 0
          ? totalRevenue / totalTickets
          : 0.0,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _processRevenueData(
    List<QueryDocumentSnapshot> docs,
    String groupBy,
  ) async {
    double totalRevenue = 0;
    int totalTickets = 0;
    final periodData = <String, Map<String, dynamic>>{};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final price = (data['price'] as num?)?.toDouble() ?? 0;
      final quantity = (data['quantity'] as int?) ?? 1;
      final purchaseDate = (data['purchaseDate'] as Timestamp?)?.toDate();

      final revenue = price * quantity;
      totalRevenue += revenue;
      totalTickets += quantity;

      if (purchaseDate != null) {
        final periodKey = _getPeriodKey(purchaseDate, groupBy);

        if (!periodData.containsKey(periodKey)) {
          periodData[periodKey] = {
            'period': periodKey,
            'revenue': 0.0,
            'tickets': 0,
            'date': purchaseDate,
          };
        }

        periodData[periodKey]!['revenue'] =
            (periodData[periodKey]!['revenue'] as double) + revenue;
        periodData[periodKey]!['tickets'] =
            (periodData[periodKey]!['tickets'] as int) + quantity;
      }
    }

    // Convert to list and sort by date
    final dailyRevenue = periodData.values.toList();
    dailyRevenue.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );

    return {
      'totalRevenue': totalRevenue,
      'totalTickets': totalTickets,
      'averageTicketPrice': totalTickets > 0
          ? totalRevenue / totalTickets
          : 0.0,
      'dailyRevenue': dailyRevenue,
      'peakDay': _findPeakDay(dailyRevenue),
    };
  }

  String _getPeriodKey(DateTime date, String groupBy) {
    switch (groupBy) {
      case 'day':
        return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      case 'week':
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        return '${weekStart.year}-W${_getWeekNumber(weekStart)}';
      case 'month':
        return "${date.year}-${date.month.toString().padLeft(2, '0')}";
      default:
        return date.toIso8601String().split('T')[0];
    }
  }

  int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year);
    final daysDifference = date.difference(startOfYear).inDays;
    return (daysDifference / 7).floor() + 1;
  }

  Map<String, dynamic> _findPeakDay(List<Map<String, dynamic>> dailyData) {
    if (dailyData.isEmpty) return {};

    return dailyData.reduce(
      (a, b) => (a['revenue'] as double) > (b['revenue'] as double) ? a : b,
    );
  }

  Map<String, dynamic> _calculateRevenueProjection(
    List<Map<String, dynamic>> historicalData,
    int projectionDays,
  ) {
    if (historicalData.isEmpty) {
      return {
        'totalProjected': 0.0,
        'dailyProjections': <Map<String, dynamic>>[],
        'confidence': 0.0,
        'trend': 'unknown',
      };
    }

    // Calculate average daily revenue
    final totalRevenue = historicalData.fold(
      0.0,
      (total, day) => total + (day['revenue'] as double),
    );
    final averageDailyRevenue = totalRevenue / historicalData.length;

    // Simple trend analysis
    final recentDays = historicalData.length >= 7
        ? historicalData.sublist(historicalData.length - 7)
        : historicalData;
    final recentAverage =
        recentDays.fold(
          0.0,
          (total, day) => total + (day['revenue'] as double),
        ) /
        recentDays.length;

    String trend = 'stable';
    if (recentAverage > averageDailyRevenue * 1.1) {
      trend = 'increasing';
    } else if (recentAverage < averageDailyRevenue * 0.9) {
      trend = 'decreasing';
    }

    // Generate projections
    final projections = <Map<String, dynamic>>[];
    final baseDate = DateTime.now();

    for (int i = 1; i <= projectionDays; i++) {
      final projectedDate = baseDate.add(Duration(days: i));
      final projectedRevenue = trend == 'increasing'
          ? recentAverage * 1.05
          : trend == 'decreasing'
          ? recentAverage * 0.95
          : averageDailyRevenue;

      projections.add({
        'date': projectedDate.toIso8601String().split('T')[0],
        'projectedRevenue': projectedRevenue,
      });
    }

    final totalProjected = projections.fold(
      0.0,
      (total, day) => total + (day['projectedRevenue'] as double),
    );

    return {
      'totalProjected': totalProjected,
      'dailyProjections': projections,
      'confidence': historicalData.length >= 30
          ? 0.8
          : 0.5, // Higher confidence with more data
      'trend': trend,
    };
  }
}

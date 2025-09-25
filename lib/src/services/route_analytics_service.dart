import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for tracking route usage analytics
class RouteAnalyticsService {
  factory RouteAnalyticsService() => _instance;
  RouteAnalyticsService._internal();
  static final RouteAnalyticsService _instance =
      RouteAnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Track route visit
  Future<void> trackRouteVisit(
    String routeName, {
    Object? arguments,
    String? source,
    Duration? loadTime,
  }) async {
    try {
      final user = _auth.currentUser;
      final timestamp = DateTime.now();

      // Log to Firebase Analytics
      await _analytics.logEvent(
        name: 'route_visit',
        parameters: {
          'route_name': routeName,
          'has_arguments': arguments != null ? 1 : 0,
          'source': source ?? 'unknown',
          'load_time_ms': loadTime?.inMilliseconds ?? 0,
          'user_id': user?.uid ?? 'anonymous',
          'timestamp': timestamp.millisecondsSinceEpoch,
        },
      );

      // Store detailed analytics in Firestore
      await _firestore.collection('route_analytics').add({
        'route_name': routeName,
        'user_id': user?.uid,
        'timestamp': timestamp,
        'source': source,
        'load_time_ms': loadTime?.inMilliseconds,
        'has_arguments': arguments != null,
        'session_id': _generateSessionId(),
      });

      // Update route popularity counter
      await _updateRoutePopularity(routeName);
    } on Exception catch (error) {
      // Don't let analytics errors break the app
      if (kDebugMode) {
        AppLogger.error('Route analytics error: $error');
      }
    }
  }

  /// Track route performance
  Future<void> trackRoutePerformance(
    String routeName, {
    required Duration loadTime,
    required bool success,
    String? errorMessage,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'route_performance',
        parameters: {
          'route_name': routeName,
          'load_time_ms': loadTime.inMilliseconds,
          'success': success,
          'error_message': errorMessage ?? '',
        },
      );
    } on Exception catch (error) {
      if (kDebugMode) {
        AppLogger.error('Route performance tracking error: $error');
      }
    }
  }

  /// Get popular routes
  Future<List<Map<String, dynamic>>> getPopularRoutes({
    int limit = 10,
    DateTime? since,
  }) async {
    try {
      Query query = _firestore
          .collection('route_analytics')
          .orderBy('timestamp', descending: true);

      if (since != null) {
        query = query.where('timestamp', isGreaterThan: since);
      }

      final snapshot = await query.limit(limit * 10).get();

      // Count route visits
      final Map<String, int> routeCounts = {};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final routeName = data['route_name'] as String;
        routeCounts[routeName] = (routeCounts[routeName] ?? 0) + 1;
      }

      // Sort by popularity
      final sortedRoutes =
          routeCounts.entries
              .map(
                (entry) => {
                  'route_name': entry.key,
                  'visit_count': entry.value,
                },
              )
              .toList()
            ..sort(
              (a, b) =>
                  (b['visit_count'] as int).compareTo(a['visit_count'] as int),
            );

      return sortedRoutes.take(limit).toList();
    } on Exception catch (error) {
      if (kDebugMode) {
        AppLogger.error('Error getting popular routes: $error');
      }
      return [];
    }
  }

  /// Get route usage statistics
  Future<Map<String, dynamic>> getRouteStatistics(String routeName) async {
    try {
      final now = DateTime.now();
      final dayAgo = now.subtract(const Duration(days: 1));
      final weekAgo = now.subtract(const Duration(days: 7));

      final daySnapshot = await _firestore
          .collection('route_analytics')
          .where('route_name', isEqualTo: routeName)
          .where('timestamp', isGreaterThan: dayAgo)
          .get();

      final weekSnapshot = await _firestore
          .collection('route_analytics')
          .where('route_name', isEqualTo: routeName)
          .where('timestamp', isGreaterThan: weekAgo)
          .get();

      return {
        'route_name': routeName,
        'visits_today': daySnapshot.docs.length,
        'visits_this_week': weekSnapshot.docs.length,
        'last_visited': weekSnapshot.docs.isNotEmpty
            ? (weekSnapshot.docs.first.data()['timestamp'] as Timestamp)
                  .toDate()
            : null,
      };
    } on Exception catch (error) {
      if (kDebugMode) {
        AppLogger.error('Error getting route statistics: $error');
      }
      return {};
    }
  }

  /// Track navigation source
  Future<void> trackNavigationSource(String routeName, String source) async {
    try {
      await _analytics.logEvent(
        name: 'navigation_source',
        parameters: {'route_name': routeName, 'source': source},
      );
    } on Exception catch (error) {
      if (kDebugMode) {
        AppLogger.error('Navigation source tracking error: $error');
      }
    }
  }

  /// Update route popularity in real-time
  Future<void> _updateRoutePopularity(String routeName) async {
    try {
      final docRef = _firestore.collection('route_popularity').doc(routeName);
      await docRef.set({
        'route_name': routeName,
        'visit_count': FieldValue.increment(1),
        'last_visit': DateTime.now(),
      }, SetOptions(merge: true));
    } on Exception catch (error) {
      if (kDebugMode) {
        AppLogger.error('Error updating route popularity: $error');
      }
    }
  }

  /// Generate session ID
  String _generateSessionId() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}

/// Mixin for widgets to easily track route analytics
mixin RouteAnalyticsMixin {
  final RouteAnalyticsService _analytics = RouteAnalyticsService();

  void trackRouteVisit(
    String routeName, {
    Object? arguments,
    String? source,
    Duration? loadTime,
  }) {
    _analytics.trackRouteVisit(
      routeName,
      arguments: arguments,
      source: source,
      loadTime: loadTime,
    );
  }

  void trackNavigationSource(String routeName, String source) {
    _analytics.trackNavigationSource(routeName, source);
  }
}

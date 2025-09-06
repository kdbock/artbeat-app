import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

/// Basic event analytics data model
class EventAnalyticsData {
  final String eventId;
  final int viewCount;
  final int engagementCount;
  final int shareCount;
  final int saveCount;

  EventAnalyticsData({
    required this.eventId,
    this.viewCount = 0,
    this.engagementCount = 0,
    this.shareCount = 0,
    this.saveCount = 0,
  });
}

/// Service for tracking basic event analytics
class EventAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get analytics data for a specific date period
  Future<Map<String, dynamic>> getAnalyticsForPeriod(String period) async {
    try {
      final startDate = _getStartDateFromPeriod(period);

      final querySnapshot = await _firestore
          .collection('event_analytics')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .get();

      return _calculateComprehensiveMetrics(querySnapshot.docs);
    } on Exception catch (e) {
      developer.log(
        'Error getting analytics for period: $e',
        name: 'EventAnalyticsService',
      );
      return {'totalViews': 0, 'totalEngagements': 0, 'totalRevenue': 0.0};
    }
  }

  /// Get analytics for a specific event
  Future<EventAnalyticsData?> getEventAnalytics(String eventId) async {
    try {
      final viewsQuery = await _firestore
          .collection('event_views')
          .where('eventId', isEqualTo: eventId)
          .get();

      final engagementsQuery = await _firestore
          .collection('event_engagements')
          .where('eventId', isEqualTo: eventId)
          .get();

      return EventAnalyticsData(
        eventId: eventId,
        viewCount: viewsQuery.docs.length,
        engagementCount: engagementsQuery.docs.length,
      );
    } on Exception catch (e) {
      developer.log(
        'Error getting event analytics: $e',
        name: 'EventAnalyticsService',
      );
      return null;
    }
  }

  /// Get analytics for all events by an artist
  Future<List<EventAnalyticsData>> getArtistEventAnalytics(
    String artistId,
  ) async {
    try {
      final eventsQuery = await _firestore
          .collection('events')
          .where('artistId', isEqualTo: artistId)
          .get();

      final List<EventAnalyticsData> analyticsData = [];

      for (final eventDoc in eventsQuery.docs) {
        final analytics = await getEventAnalytics(eventDoc.id);
        if (analytics != null) {
          analyticsData.add(analytics);
        }
      }

      return analyticsData;
    } on Exception catch (e) {
      developer.log(
        'Error getting artist event analytics: $e',
        name: 'EventAnalyticsService',
      );
      return [];
    }
  }

  /// Track event view
  Future<void> trackEventView(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('event_views').add({
        'eventId': eventId,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': _getPlatform(),
      });

      // Update event view count
      await _firestore.collection('events').doc(eventId).update({
        'viewCount': FieldValue.increment(1),
      });
    } on Exception catch (e) {
      developer.log(
        'Error tracking event view: $e',
        name: 'EventAnalyticsService',
      );
    }
  }

  /// Track event engagement (like, comment, etc.)
  Future<void> trackEventEngagement(
    String eventId,
    String engagementType,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('event_engagements').add({
        'eventId': eventId,
        'userId': user.uid,
        'type': engagementType,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': _getPlatform(),
      });

      // Update event engagement count
      await _firestore.collection('events').doc(eventId).update({
        'engagementCount': FieldValue.increment(1),
      });
    } on Exception catch (e) {
      developer.log(
        'Error tracking event engagement: $e',
        name: 'EventAnalyticsService',
      );
    }
  }

  /// Track event save
  Future<void> trackEventSave(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('event_saves').add({
        'eventId': eventId,
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': _getPlatform(),
      });

      // Update event save count
      await _firestore.collection('events').doc(eventId).update({
        'saveCount': FieldValue.increment(1),
      });
    } on Exception catch (e) {
      developer.log(
        'Error tracking event save: $e',
        name: 'EventAnalyticsService',
      );
    }
  }

  /// Track event share
  Future<void> trackEventShare(String eventId, String shareMethod) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('event_shares').add({
        'eventId': eventId,
        'userId': user.uid,
        'shareMethod': shareMethod,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': _getPlatform(),
      });

      // Update event share count
      await _firestore.collection('events').doc(eventId).update({
        'shareCount': FieldValue.increment(1),
      });
    } on Exception catch (e) {
      developer.log(
        'Error tracking event share: $e',
        name: 'EventAnalyticsService',
      );
    }
  }

  // Helper methods
  DateTime _getStartDateFromPeriod(String period) {
    final now = DateTime.now();
    switch (period.toLowerCase()) {
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return DateTime(now.year, now.month - 1, now.day);
      case 'year':
        return DateTime(now.year - 1, now.month, now.day);
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  Map<String, dynamic> _calculateComprehensiveMetrics(
    List<QueryDocumentSnapshot> docs,
  ) {
    int totalViews = 0;
    int totalEngagements = 0;
    double totalRevenue = 0.0;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalViews += data['views'] as int? ?? 0;
      totalEngagements += data['engagements'] as int? ?? 0;
      totalRevenue += data['revenue'] as double? ?? 0.0;
    }

    return {
      'totalViews': totalViews,
      'totalEngagements': totalEngagements,
      'totalRevenue': totalRevenue,
    };
  }

  String _getPlatform() {
    return 'mobile'; // Default to mobile, could be made dynamic
  }
}

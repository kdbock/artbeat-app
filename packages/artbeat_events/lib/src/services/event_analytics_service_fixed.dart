import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/events_logger.dart';

/// Analytics service for event data analysis and insights
/// Provides basic analytics capabilities for event performance tracking
class EventAnalyticsServiceBasic {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Track when a user views an event
  Future<void> trackEventView(String eventId, String userId) async {
    try {
      // Record view in analytics collection
      await _firestore.collection('eventAnalytics').add({
        'eventId': eventId,
        'userId': userId,
        'action': 'view',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update event view count
      await _firestore.collection('events').doc(eventId).update({
        'viewCount': FieldValue.increment(1),
        'lastViewedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      EventsLogger.eventAnalytics('Failed to track event view', error: e);
    }
  }

  /// Get basic analytics for a specific event
  Future<Map<String, dynamic>> getEventAnalytics(String eventId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();

      if (!eventDoc.exists) {
        return {'error': 'Event not found', 'eventId': eventId};
      }

      final data = eventDoc.data() as Map<String, dynamic>;

      return {
        'eventId': eventId,
        'viewCount': data['viewCount'] ?? 0,
        'likeCount': data['likeCount'] ?? 0,
        'shareCount': data['shareCount'] ?? 0,
        'saveCount': data['saveCount'] ?? 0,
        'ticketsSold': _calculateTicketsSold(data),
        'revenue': _calculateRevenue(data),
        'lastViewedAt': data['lastViewedAt'],
        'createdAt': data['createdAt'],
      };
    } on FirebaseException catch (e) {
      EventsLogger.eventAnalytics('Failed to get event analytics', error: e);
      return {'error': e.toString(), 'eventId': eventId};
    }
  }

  /// Get analytics for all events by an artist
  Future<Map<String, dynamic>> getArtistEventAnalytics(String artistId) async {
    try {
      final eventsQuery = await _firestore
          .collection('events')
          .where('artistId', isEqualTo: artistId)
          .get();

      int totalViews = 0;
      int totalLikes = 0;
      int totalShares = 0;
      int totalSaves = 0;
      int totalTicketsSold = 0;
      double totalRevenue = 0.0;

      final eventAnalytics = <Map<String, dynamic>>[];

      for (final doc in eventsQuery.docs) {
        final data = doc.data();
        final viewCount = data['viewCount'] ?? 0;
        final likeCount = data['likeCount'] ?? 0;
        final shareCount = data['shareCount'] ?? 0;
        final saveCount = data['saveCount'] ?? 0;
        final ticketsSold = _calculateTicketsSold(data);
        final revenue = _calculateRevenue(data);

        totalViews += viewCount as int;
        totalLikes += likeCount as int;
        totalShares += shareCount as int;
        totalSaves += saveCount as int;
        totalTicketsSold += ticketsSold;
        totalRevenue += revenue;

        eventAnalytics.add({
          'eventId': doc.id,
          'title': data['title'] ?? 'Untitled Event',
          'viewCount': viewCount,
          'likeCount': likeCount,
          'shareCount': shareCount,
          'saveCount': saveCount,
          'ticketsSold': ticketsSold,
          'revenue': revenue,
          'createdAt': data['createdAt'],
        });
      }

      return {
        'artistId': artistId,
        'totalEvents': eventsQuery.docs.length,
        'totalViews': totalViews,
        'totalLikes': totalLikes,
        'totalShares': totalShares,
        'totalSaves': totalSaves,
        'totalTicketsSold': totalTicketsSold,
        'totalRevenue': totalRevenue,
        'averageViewsPerEvent': eventsQuery.docs.isEmpty
            ? 0
            : totalViews / eventsQuery.docs.length,
        'events': eventAnalytics,
      };
    } on Exception catch (e) {
      EventsLogger.eventAnalytics('Failed to get artist analytics', error: e);
      return {'error': e.toString(), 'artistId': artistId};
    }
  }

  /// Track event interaction (like, share, save)
  Future<void> trackEventInteraction(
    String eventId,
    String userId,
    String interactionType, // 'like', 'share', 'save'
  ) async {
    try {
      // Record interaction in analytics collection
      await _firestore.collection('eventAnalytics').add({
        'eventId': eventId,
        'userId': userId,
        'action': interactionType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update event interaction count
      await _firestore.collection('events').doc(eventId).update({
        '${interactionType}Count': FieldValue.increment(1),
        'lastInteraction': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      EventsLogger.eventAnalytics(
        'Failed to track event interaction',
        error: e,
      );
    }
  }

  /// Calculate total tickets sold for an event
  int _calculateTicketsSold(Map<String, dynamic> eventData) {
    try {
      final ticketTypes = eventData['ticketTypes'] as List<dynamic>?;
      if (ticketTypes == null) return 0;

      int totalSold = 0;
      for (final ticketType in ticketTypes) {
        if (ticketType is Map<String, dynamic>) {
          totalSold += (ticketType['sold'] as int?) ?? 0;
        }
      }
      return totalSold;
    } on Exception {
      return 0;
    }
  }

  /// Calculate total revenue for an event
  double _calculateRevenue(Map<String, dynamic> eventData) {
    try {
      final ticketTypes = eventData['ticketTypes'] as List<dynamic>?;
      if (ticketTypes == null) return 0.0;

      double totalRevenue = 0.0;
      for (final ticketType in ticketTypes) {
        if (ticketType is Map<String, dynamic>) {
          final sold = (ticketType['sold'] as int?) ?? 0;
          final price = (ticketType['price'] as num?)?.toDouble() ?? 0.0;
          totalRevenue += sold * price;
        }
      }
      return totalRevenue;
    } on Exception {
      return 0.0;
    }
  }

  /// Get top performing events
  Future<List<Map<String, dynamic>>> getTopPerformingEvents({
    int limit = 10,
    String sortBy = 'viewCount', // 'viewCount', 'likeCount', 'revenue'
  }) async {
    try {
      final eventsQuery = await _firestore
          .collection('events')
          .where('isPublic', isEqualTo: true)
          .orderBy(sortBy, descending: true)
          .limit(limit)
          .get();

      final events = <Map<String, dynamic>>[];

      for (final doc in eventsQuery.docs) {
        final data = doc.data();
        events.add({
          'eventId': doc.id,
          'title': data['title'] ?? 'Untitled Event',
          'artistId': data['artistId'],
          'viewCount': data['viewCount'] ?? 0,
          'likeCount': data['likeCount'] ?? 0,
          'shareCount': data['shareCount'] ?? 0,
          'ticketsSold': _calculateTicketsSold(data),
          'revenue': _calculateRevenue(data),
          'createdAt': data['createdAt'],
        });
      }

      return events;
    } on Exception catch (e) {
      EventsLogger.eventAnalytics(
        'Failed to get top performing events',
        error: e,
      );
      return [];
    }
  }

  /// Get recent event analytics activities
  Future<List<Map<String, dynamic>>> getRecentAnalytics({
    String? artistId,
    int limit = 50,
  }) async {
    try {
      final Query query = _firestore
          .collection('eventAnalytics')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      final analyticsQuery = await query.get();

      final activities = <Map<String, dynamic>>[];

      for (final doc in analyticsQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        activities.add({
          'id': doc.id,
          'eventId': data['eventId'],
          'userId': data['userId'],
          'action': data['action'],
          'timestamp': data['timestamp'],
        });
      }

      return activities;
    } on Exception catch (e) {
      EventsLogger.eventAnalytics('Failed to get recent analytics', error: e);
      return [];
    }
  }
}

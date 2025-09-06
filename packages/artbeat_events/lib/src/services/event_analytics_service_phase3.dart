import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/artbeat_event.dart';

/// Advanced analytics service for comprehensive event data analysis
/// Phase 3 implementation with real-time metrics and detailed reporting
class EventAnalyticsServicePhase3 {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get popular events based on view count and engagement
  Future<List<ArtbeatEvent>> getPopularEvents({
    int limit = 10,
    String? artistId,
    int daysBack = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: daysBack));

      Query query = _firestore
          .collection('events')
          .where('dateTime', isGreaterThan: startDate);

      if (artistId != null) {
        query = query.where('artistId', isEqualTo: artistId);
      }

      final snapshot = await query.get();
      final events = snapshot.docs.map(ArtbeatEvent.fromFirestore).toList();

      // Sort by creation date for now (could add engagement scoring later)
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return events.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get popular events: $e');
    }
  }

  /// Track event view with analytics
  Future<void> trackEventView(
    String eventId, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;

      await _firestore.collection('eventEngagements').add({
        'eventId': eventId,
        'userId': userId,
        'type': 'view',
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      });

      // Update event view count (if the field exists)
      await _firestore.collection('events').doc(eventId).update({
        'viewCount': FieldValue.increment(1),
        'lastViewed': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail for analytics - don't break user experience
      print('Failed to track event view: $e');
    }
  }

  /// Track event interaction (like, share, save, etc.)
  Future<void> trackEventInteraction(
    String eventId,
    String interactionType, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;

      await _firestore.collection('eventEngagements').add({
        'eventId': eventId,
        'userId': userId,
        'type': interactionType,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      });

      // Update event interaction counts (if the fields exist)
      await _firestore.collection('events').doc(eventId).update({
        '${interactionType}Count': FieldValue.increment(1),
        'lastInteraction': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to track event interaction: $e');
    }
  }

  /// Get basic engagement metrics
  Future<Map<String, dynamic>> getBasicMetrics({
    String? artistId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      endDate ??= DateTime.now();
      startDate ??= endDate.subtract(const Duration(days: 30));

      Query query = _firestore
          .collection('events')
          .where('dateTime', isGreaterThanOrEqualTo: startDate)
          .where('dateTime', isLessThanOrEqualTo: endDate);

      if (artistId != null) {
        query = query.where('artistId', isEqualTo: artistId);
      }

      final snapshot = await query.get();
      final events = snapshot.docs.map(ArtbeatEvent.fromFirestore).toList();

      // Calculate basic metrics
      final totalEvents = events.length;
      final activeEvents = events
          .where((e) => e.dateTime.isAfter(DateTime.now()))
          .length;
      final pastEvents = totalEvents - activeEvents;

      // Get engagement data from the engagement collection
      final engagementQuery = _firestore
          .collection('eventEngagements')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate);

      final engagementSnapshot = await engagementQuery.get();
      final totalEngagements = engagementSnapshot.docs.length;
      final totalViews = engagementSnapshot.docs
          .where((doc) => doc.data()['type'] == 'view')
          .length;

      return {
        'totalEvents': totalEvents,
        'activeEvents': activeEvents,
        'pastEvents': pastEvents,
        'totalViews': totalViews,
        'totalEngagements': totalEngagements,
        'averageViewsPerEvent': totalEvents > 0
            ? totalViews / totalEvents
            : 0.0,
        'engagementRate': totalViews > 0
            ? (totalEngagements / totalViews) * 100
            : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get basic metrics: $e');
    }
  }

  /// Get category distribution for events
  Future<Map<String, int>> getCategoryDistribution({
    String? artistId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      endDate ??= DateTime.now();
      startDate ??= endDate.subtract(const Duration(days: 30));

      Query query = _firestore
          .collection('events')
          .where('dateTime', isGreaterThanOrEqualTo: startDate)
          .where('dateTime', isLessThanOrEqualTo: endDate);

      if (artistId != null) {
        query = query.where('artistId', isEqualTo: artistId);
      }

      final snapshot = await query.get();
      final categoryCount = <String, int>{};

      for (final doc in snapshot.docs) {
        final event = ArtbeatEvent.fromFirestore(doc);
        final category = event.category;
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      return categoryCount;
    } catch (e) {
      throw Exception('Failed to get category distribution: $e');
    }
  }

  /// Get revenue analytics with basic calculations
  Future<Map<String, dynamic>> getRevenueAnalytics({
    String? artistId,
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

      final ticketsSnapshot = await query.get();

      double totalRevenue = 0;
      int totalTickets = 0;
      final Map<String, double> dailyRevenue = {};

      for (final doc in ticketsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final price = (data['price'] as num?)?.toDouble() ?? 0;
        final quantity = (data['quantity'] as int?) ?? 1;
        final purchaseDate = (data['purchaseDate'] as Timestamp).toDate();

        totalRevenue += price * quantity;
        totalTickets += quantity;

        // Daily revenue tracking
        final dateKey =
            "${purchaseDate.year}-${purchaseDate.month.toString().padLeft(2, '0')}-${purchaseDate.day.toString().padLeft(2, '0')}";
        dailyRevenue[dateKey] =
            (dailyRevenue[dateKey] ?? 0) + (price * quantity);
      }

      return {
        'totalRevenue': totalRevenue,
        'totalTickets': totalTickets,
        'averageTicketPrice': totalTickets > 0
            ? totalRevenue / totalTickets
            : 0,
        'dailyRevenue': dailyRevenue,
      };
    } catch (e) {
      throw Exception('Failed to get revenue analytics: $e');
    }
  }
}

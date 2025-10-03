import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Activity types for the social feed
enum SocialActivityType {
  discovery,
  walkCompleted,
  achievement,
  friendJoined,
  milestone,
}

/// Represents a social activity in the feed
class SocialActivity {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final SocialActivityType type;
  final String message;
  final DateTime timestamp;
  final Position? location;
  final Map<String, dynamic>? metadata;

  SocialActivity({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.type,
    required this.message,
    required this.timestamp,
    this.location,
    this.metadata,
  });

  factory SocialActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocialActivity(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Anonymous',
      userAvatar: data['userAvatar'] as String?,
      type: SocialActivityType.values.firstWhere(
        (e) => e.name == data['type'] as String?,
        orElse: () => SocialActivityType.discovery,
      ),
      message: data['message'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] != null
          ? Position(
              latitude:
                  (data['location']['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude:
                  (data['location']['longitude'] as num?)?.toDouble() ?? 0.0,
              timestamp: DateTime.now(),
              accuracy:
                  (data['location']['accuracy'] as num?)?.toDouble() ?? 0.0,
              altitude:
                  (data['location']['altitude'] as num?)?.toDouble() ?? 0.0,
              heading: (data['location']['heading'] as num?)?.toDouble() ?? 0.0,
              speed: (data['location']['speed'] as num?)?.toDouble() ?? 0.0,
              speedAccuracy:
                  (data['location']['speedAccuracy'] as num?)?.toDouble() ??
                  0.0,
              altitudeAccuracy:
                  (data['location']['altitudeAccuracy'] as num?)?.toDouble() ??
                  0.0,
              headingAccuracy:
                  (data['location']['headingAccuracy'] as num?)?.toDouble() ??
                  0.0,
            )
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'type': type.name,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'location': location != null
          ? {
              'latitude': location!.latitude,
              'longitude': location!.longitude,
              'accuracy': location!.accuracy,
              'altitude': location!.altitude,
              'heading': location!.heading,
              'speed': location!.speed,
              'speedAccuracy': location!.speedAccuracy,
            }
          : null,
      'metadata': metadata,
    };
  }
}

/// Service for managing social features and activity feeds
class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _activities =>
      _firestore.collection('socialActivities');
  CollectionReference get _userPresence =>
      _firestore.collection('userPresence');

  /// Get nearby social activities within a radius
  Future<List<SocialActivity>> getNearbyActivities({
    required Position userPosition,
    double radiusKm = 5.0,
    int limit = 20,
  }) async {
    try {
      // Calculate bounding box for geospatial query
      final lat = userPosition.latitude;
      final latDelta = radiusKm / 111.0; // ~111km per degree latitude

      final query = _activities
          .where('location.latitude', isGreaterThanOrEqualTo: lat - latDelta)
          .where('location.latitude', isLessThanOrEqualTo: lat + latDelta)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      final activities = snapshot.docs
          .map((doc) => SocialActivity.fromFirestore(doc))
          .where((activity) {
            // Additional filtering for longitude and exact distance
            if (activity.location == null) return false;
            final distance = Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              activity.location!.latitude,
              activity.location!.longitude,
            );
            return distance <= radiusKm * 1000; // Convert to meters
          })
          .toList();

      AppLogger.debug('Loaded ${activities.length} nearby activities');
      return activities;
    } catch (e) {
      AppLogger.error('Error loading nearby activities: $e');
      return [];
    }
  }

  /// Get activities from friends
  Future<List<SocialActivity>> getFriendsActivities({
    required List<String> friendIds,
    int limit = 10,
  }) async {
    if (friendIds.isEmpty) return [];

    try {
      final query = _activities
          .where(
            'userId',
            whereIn: friendIds.take(10).toList(),
          ) // Firestore limit
          .orderBy('timestamp', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      final activities = snapshot.docs
          .map((doc) => SocialActivity.fromFirestore(doc))
          .toList();

      AppLogger.error('Loaded ${activities.length} friends activities');
      return activities;
    } catch (e) {
      AppLogger.error('Error loading friends activities: $e');
      return [];
    }
  }

  /// Post a new social activity
  Future<void> postActivity({
    required String userId,
    required String userName,
    String? userAvatar,
    required SocialActivityType type,
    required String message,
    Position? location,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final activity = SocialActivity(
        id: '', // Will be set by Firestore
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        type: type,
        message: message,
        timestamp: DateTime.now(),
        location: location,
        metadata: metadata,
      );

      await _activities.add(activity.toFirestore());
      AppLogger.error('Posted social activity: ${type.name}');
    } catch (e) {
      AppLogger.error('Error posting activity: $e');
      rethrow;
    }
  }

  /// Update user presence (for active walkers count)
  Future<void> updateUserPresence({
    required String userId,
    required Position location,
    required bool isActive,
  }) async {
    try {
      await _userPresence.doc(userId).set({
        'userId': userId,
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'isActive': isActive,
        'lastSeen': Timestamp.now(),
      });
      AppLogger.error('Updated user presence for $userId');
    } catch (e) {
      AppLogger.error('Error updating user presence: $e');
    }
  }

  /// Get count of active walkers nearby
  Future<int> getActiveWalkersNearby({
    required Position userPosition,
    double radiusKm = 5.0,
  }) async {
    try {
      // Get users who were active in the last 30 minutes
      final thirtyMinutesAgo = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 30)),
      );

      final lat = userPosition.latitude;
      final latDelta = radiusKm / 111.0;

      final query = _userPresence
          .where('isActive', isEqualTo: true)
          .where('lastSeen', isGreaterThan: thirtyMinutesAgo)
          .where('location.latitude', isGreaterThanOrEqualTo: lat - latDelta)
          .where('location.latitude', isLessThanOrEqualTo: lat + latDelta);

      final snapshot = await query.get();

      // Filter by exact distance
      final nearbyUsers = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final userLat = data['location']['latitude'] as double;
        final userLng = data['location']['longitude'] as double;

        final distance = Geolocator.distanceBetween(
          lat,
          userPosition.longitude,
          userLat,
          userLng,
        );
        return distance <= radiusKm * 1000;
      }).toList();

      final count = nearbyUsers.length;
      AppLogger.error('Found $count active walkers nearby');
      return count;
    } catch (e) {
      AppLogger.error('Error getting active walkers count: $e');
      return 0;
    }
  }

  /// Get recent walks from friends (for dashboard)
  Future<List<String>> getFriendsRecentWalks({
    required List<String> friendIds,
    int limit = 5,
  }) async {
    if (friendIds.isEmpty) return [];

    try {
      final activities = await getFriendsActivities(
        friendIds: friendIds,
        limit: limit * 2, // Get more to filter
      );

      // Filter for walk completion activities
      final walkActivities = activities
          .where(
            (activity) => activity.type == SocialActivityType.walkCompleted,
          )
          .take(limit)
          .map((activity) => activity.message)
          .toList();

      return walkActivities;
    } catch (e) {
      AppLogger.error('Error getting friends recent walks: $e');
      return [];
    }
  }

  /// Clean up old activities (call periodically)
  Future<void> cleanupOldActivities({
    Duration maxAge = const Duration(days: 7),
  }) async {
    try {
      final cutoffDate = Timestamp.fromDate(DateTime.now().subtract(maxAge));

      final oldActivities = await _activities
          .where('timestamp', isLessThan: cutoffDate)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldActivities.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      AppLogger.error('Cleaned up ${oldActivities.docs.length} old activities');
    } catch (e) {
      AppLogger.error('Error cleaning up old activities: $e');
    }
  }

  /// Stream of nearby activities (real-time)
  Stream<List<SocialActivity>> streamNearbyActivities({
    required Position userPosition,
    double radiusKm = 5.0,
  }) {
    final lat = userPosition.latitude;
    final latDelta = radiusKm / 111.0;

    return _activities
        .where('location.latitude', isGreaterThanOrEqualTo: lat - latDelta)
        .where('location.latitude', isLessThanOrEqualTo: lat + latDelta)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SocialActivity.fromFirestore(doc))
              .where((activity) {
                if (activity.location == null) return false;
                final distance = Geolocator.distanceBetween(
                  userPosition.latitude,
                  userPosition.longitude,
                  activity.location!.latitude,
                  activity.location!.longitude,
                );
                return distance <= radiusKm * 1000;
              })
              .take(20)
              .toList();
        });
  }
}

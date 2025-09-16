import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/artbeat_event.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Enhanced social integration service for Phase 3 implementation
/// Provides social features, community engagement, and sharing capabilities
class SocialIntegrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Share an event to social media or within the app
  Future<void> shareEvent(
    String eventId, {
    String shareMethod = 'link', // link, social, email, app
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;

      // Record the share activity
      await _firestore.collection('eventShares').add({
        'eventId': eventId,
        'userId': userId,
        'shareMethod': shareMethod,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      });

      // Update event share count
      await _firestore.collection('events').doc(eventId).update({
        'shareCount': FieldValue.increment(1),
        'lastShared': FieldValue.serverTimestamp(),
      });

      // Track analytics
      await _trackSocialEngagement(eventId, 'share', {
        'method': shareMethod,
        ...?metadata,
      });
    } catch (e) {
      throw Exception('Failed to share event: $e');
    }
  }

  /// Like or unlike an event
  Future<void> toggleEventLike(String eventId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final likeRef = _firestore
          .collection('eventLikes')
          .doc('${eventId}_$userId');

      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Unlike the event
        await likeRef.delete();
        await _firestore.collection('events').doc(eventId).update({
          'likeCount': FieldValue.increment(-1),
        });

        await _trackSocialEngagement(eventId, 'unlike');
      } else {
        // Like the event
        await likeRef.set({
          'eventId': eventId,
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('events').doc(eventId).update({
          'likeCount': FieldValue.increment(1),
          'lastLiked': FieldValue.serverTimestamp(),
        });

        await _trackSocialEngagement(eventId, 'like');
      }
    } catch (e) {
      throw Exception('Failed to toggle event like: $e');
    }
  }

  /// Save or unsave an event to user's saved events
  Future<void> toggleEventSave(String eventId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final saveRef = _firestore
          .collection('userSavedEvents')
          .doc('${userId}_$eventId');

      final saveDoc = await saveRef.get();

      if (saveDoc.exists) {
        // Unsave the event
        await saveRef.delete();
        await _firestore.collection('events').doc(eventId).update({
          'saveCount': FieldValue.increment(-1),
        });

        await _trackSocialEngagement(eventId, 'unsave');
      } else {
        // Save the event
        await saveRef.set({
          'eventId': eventId,
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('events').doc(eventId).update({
          'saveCount': FieldValue.increment(1),
          'lastSaved': FieldValue.serverTimestamp(),
        });

        await _trackSocialEngagement(eventId, 'save');
      }
    } catch (e) {
      throw Exception('Failed to toggle event save: $e');
    }
  }

  /// Add a comment to an event
  Future<String> addEventComment(String eventId, String comment) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final commentRef = await _firestore.collection('eventComments').add({
        'eventId': eventId,
        'userId': userId,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
        'likeCount': 0,
        'isEdited': false,
      });

      // Update event comment count
      await _firestore.collection('events').doc(eventId).update({
        'commentCount': FieldValue.increment(1),
        'lastCommented': FieldValue.serverTimestamp(),
      });

      await _trackSocialEngagement(eventId, 'comment', {
        'commentId': commentRef.id,
        'commentLength': comment.length,
      });

      return commentRef.id;
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Get comments for an event
  Future<List<Map<String, dynamic>>> getEventComments(
    String eventId, {
    int limit = 50,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query query = _firestore
          .collection('eventComments')
          .where('eventId', isEqualTo: eventId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();

      final comments = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Get user info for the comment
        final userId = data['userId'] as String?;
        Map<String, dynamic>? userInfo;

        if (userId != null) {
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          if (userDoc.exists) {
            userInfo = userDoc.data();
          }
        }

        comments.add({
          'id': doc.id,
          'comment': data['comment'],
          'timestamp': data['timestamp'],
          'likeCount': data['likeCount'] ?? 0,
          'isEdited': data['isEdited'] ?? false,
          'user': userInfo != null
              ? {
                  'id': userId,
                  'name': userInfo['displayName'] ?? 'Anonymous',
                  'avatar': userInfo['photoURL'],
                }
              : null,
        });
      }

      return comments;
    } catch (e) {
      throw Exception('Failed to get event comments: $e');
    }
  }

  /// Follow or unfollow an artist
  Future<void> toggleFollowArtist(String artistId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final followRef = _firestore
          .collection('userFollows')
          .doc('${userId}_$artistId');

      final followDoc = await followRef.get();

      if (followDoc.exists) {
        // Unfollow the artist
        await followRef.delete();

        await _firestore.collection('artists').doc(artistId).update({
          'followerCount': FieldValue.increment(-1),
        });

        await _trackSocialEngagement(null, 'unfollow_artist', {
          'artistId': artistId,
        });
      } else {
        // Follow the artist
        await followRef.set({
          'artistId': artistId,
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('artists').doc(artistId).update({
          'followerCount': FieldValue.increment(1),
        });

        await _trackSocialEngagement(null, 'follow_artist', {
          'artistId': artistId,
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle follow artist: $e');
    }
  }

  /// Get social feed for user (events from followed artists, recommended events)
  Future<List<Map<String, dynamic>>> getSocialFeed({
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get artists that user follows
      final followsSnapshot = await _firestore
          .collection('userFollows')
          .where('userId', isEqualTo: userId)
          .get();

      final followedArtistIds = followsSnapshot.docs
          .map((doc) => doc.data()['artistId'] as String)
          .toList();

      // Get events from followed artists and public events
      Query query = _firestore
          .collection('events')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (followedArtistIds.isNotEmpty) {
        query = query.where('artistId', whereIn: followedArtistIds);
      }

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();

      final feedItems = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final event = ArtbeatEvent.fromFirestore(doc);

        // Get artist info
        final artistDoc = await _firestore
            .collection('users')
            .doc(event.artistId)
            .get();
        Map<String, dynamic>? artistInfo;
        if (artistDoc.exists) {
          artistInfo = artistDoc.data();
        }

        // Get social stats
        final socialStats = await _getEventSocialStats(event.id);

        feedItems.add({
          'type': 'event',
          'event': {
            'id': event.id,
            'title': event.title,
            'description': event.description,
            'imageUrls': event.imageUrls,
            'dateTime': event.dateTime,
            'location': event.location,
            'category': event.category,
          },
          'artist': artistInfo != null
              ? {
                  'id': event.artistId,
                  'name': artistInfo['displayName'] ?? 'Unknown Artist',
                  'avatar': artistInfo['photoURL'],
                }
              : null,
          'socialStats': socialStats,
          'isFollowing': followedArtistIds.contains(event.artistId),
          'timestamp': event.createdAt,
        });
      }

      return feedItems;
    } catch (e) {
      throw Exception('Failed to get social feed: $e');
    }
  }

  /// Get trending events based on social engagement
  Future<List<Map<String, dynamic>>> getTrendingEvents({
    int limit = 10,
    int daysBack = 7,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: daysBack));

      // Get events with their social engagement metrics
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('isPublic', isEqualTo: true)
          .where('createdAt', isGreaterThan: startDate)
          .get();

      final eventScores = <Map<String, dynamic>>[];

      for (final doc in eventsSnapshot.docs) {
        final event = ArtbeatEvent.fromFirestore(doc);
        final socialStats = await _getEventSocialStats(event.id);

        // Calculate trending score based on engagement
        final engagementScore = _calculateEngagementScore(socialStats);

        eventScores.add({
          'event': event,
          'socialStats': socialStats,
          'engagementScore': engagementScore,
        });
      }

      // Sort by engagement score
      eventScores.sort(
        (a, b) => (b['engagementScore'] as double).compareTo(
          a['engagementScore'] as double,
        ),
      );

      return eventScores.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get trending events: $e');
    }
  }

  /// Get user's social activity stats
  Future<Map<String, dynamic>> getUserSocialStats(String userId) async {
    try {
      final futures = await Future.wait([
        _firestore
            .collection('eventLikes')
            .where('userId', isEqualTo: userId)
            .get(),
        _firestore
            .collection('userSavedEvents')
            .where('userId', isEqualTo: userId)
            .get(),
        _firestore
            .collection('eventComments')
            .where('userId', isEqualTo: userId)
            .get(),
        _firestore
            .collection('eventShares')
            .where('userId', isEqualTo: userId)
            .get(),
        _firestore
            .collection('userFollows')
            .where('userId', isEqualTo: userId)
            .get(),
      ]);

      return {
        'likesGiven': futures[0].docs.length,
        'eventsSaved': futures[1].docs.length,
        'commentsPosted': futures[2].docs.length,
        'eventsShared': futures[3].docs.length,
        'artistsFollowing': futures[4].docs.length,
        'lastActive': DateTime.now(),
      };
    } catch (e) {
      throw Exception('Failed to get user social stats: $e');
    }
  }

  // Private helper methods

  Future<void> _trackSocialEngagement(
    String? eventId,
    String engagementType, [
    Map<String, dynamic>? metadata,
  ]) async {
    try {
      await _firestore.collection('socialEngagements').add({
        'eventId': eventId,
        'userId': _auth.currentUser?.uid,
        'type': engagementType,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      });
    } catch (e) {
      // Silently fail for analytics
      AppLogger.info('Failed to track social engagement: $e');
    }
  }

  Future<Map<String, dynamic>> _getEventSocialStats(String eventId) async {
    try {
      final futures = await Future.wait([
        _firestore
            .collection('eventLikes')
            .where('eventId', isEqualTo: eventId)
            .get(),
        _firestore
            .collection('userSavedEvents')
            .where('eventId', isEqualTo: eventId)
            .get(),
        _firestore
            .collection('eventComments')
            .where('eventId', isEqualTo: eventId)
            .get(),
        _firestore
            .collection('eventShares')
            .where('eventId', isEqualTo: eventId)
            .get(),
      ]);

      return {
        'likes': futures[0].docs.length,
        'saves': futures[1].docs.length,
        'comments': futures[2].docs.length,
        'shares': futures[3].docs.length,
      };
    } catch (e) {
      return {'likes': 0, 'saves': 0, 'comments': 0, 'shares': 0};
    }
  }

  double _calculateEngagementScore(Map<String, dynamic> socialStats) {
    final likes = (socialStats['likes'] as int?) ?? 0;
    final saves = (socialStats['saves'] as int?) ?? 0;
    final comments = (socialStats['comments'] as int?) ?? 0;
    final shares = (socialStats['shares'] as int?) ?? 0;

    // Weighted scoring system
    return (likes * 1.0) + (saves * 2.0) + (comments * 3.0) + (shares * 4.0);
  }

  /// Check if user has liked an event
  Future<bool> hasUserLikedEvent(String eventId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore
          .collection('eventLikes')
          .doc('${eventId}_$userId')
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has saved an event
  Future<bool> hasUserSavedEvent(String eventId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore
          .collection('userSavedEvents')
          .doc('${userId}_$eventId')
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is following an artist
  Future<bool> isUserFollowingArtist(String artistId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore
          .collection('userFollows')
          .doc('${userId}_$artistId')
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}

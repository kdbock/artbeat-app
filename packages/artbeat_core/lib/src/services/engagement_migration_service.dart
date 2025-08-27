import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/engagement_model.dart';

/// Service to migrate from old engagement system to new universal system
/// Handles migration of likes, applause, follows, etc. to the new system
class EngagementMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate all engagement data from old system to new universal system
  Future<void> migrateAllEngagements() async {
    debugPrint('🔄 Starting engagement migration...');

    try {
      // Migrate in parallel for better performance
      await Future.wait([
        _migratePosts(),
        _migrateArtworks(),
        _migrateArtWalks(),
        _migrateEvents(),
        _migrateUserConnections(),
      ]);

      debugPrint('✅ Engagement migration completed successfully');
    } catch (e) {
      debugPrint('❌ Error during engagement migration: $e');
      rethrow;
    }
  }

  /// Migrate post engagements (applause, comments, shares)
  Future<void> _migratePosts() async {
    debugPrint('🔄 Migrating post engagements...');

    final postsQuery = _firestore.collection('posts');
    final postsSnapshot = await postsQuery.get();

    for (final postDoc in postsSnapshot.docs) {
      final postData = postDoc.data();
      final postId = postDoc.id;

      // Initialize engagement stats
      final stats = EngagementStats(
        appreciateCount: postData['applauseCount'] as int? ?? 0,
        discussCount: postData['commentCount'] as int? ?? 0,
        amplifyCount: postData['shareCount'] as int? ?? 0,
        lastUpdated: DateTime.now(),
      );

      // Update post with new engagement stats
      await postDoc.reference.update(stats.toFirestore());

      // Migrate individual applause records
      await _migratePostApplause(postId);

      debugPrint('✅ Migrated post: $postId');
    }
  }

  /// Migrate artwork engagements (likes, applause, comments)
  Future<void> _migrateArtworks() async {
    debugPrint('🔄 Migrating artwork engagements...');

    final artworksQuery = _firestore.collection('artworks');
    final artworksSnapshot = await artworksQuery.get();

    for (final artworkDoc in artworksSnapshot.docs) {
      final artworkData = artworkDoc.data();
      final artworkId = artworkDoc.id;

      // Initialize engagement stats
      final stats = EngagementStats(
        appreciateCount:
            (artworkData['likeCount'] as int? ?? 0) +
            (artworkData['applauseCount'] as int? ?? 0),
        discussCount: artworkData['commentCount'] as int? ?? 0,
        lastUpdated: DateTime.now(),
      );

      // Update artwork with new engagement stats
      await artworkDoc.reference.update(stats.toFirestore());

      debugPrint('✅ Migrated artwork: $artworkId');
    }
  }

  /// Migrate art walk engagements
  Future<void> _migrateArtWalks() async {
    debugPrint('🔄 Migrating art walk engagements...');

    final artWalksQuery = _firestore.collection('art_walks');
    final artWalksSnapshot = await artWalksQuery.get();

    for (final artWalkDoc in artWalksSnapshot.docs) {
      final artWalkId = artWalkDoc.id;

      // Initialize engagement stats (art walks mainly have views)
      final stats = EngagementStats(
        appreciateCount: 0, // Start fresh for art walks
        discussCount: 0,
        amplifyCount: 0,
        lastUpdated: DateTime.now(),
      );

      // Update art walk with new engagement stats
      await artWalkDoc.reference.update(stats.toFirestore());

      debugPrint('✅ Migrated art walk: $artWalkId');
    }
  }

  /// Migrate event engagements
  Future<void> _migrateEvents() async {
    debugPrint('🔄 Migrating event engagements...');

    final eventsQuery = _firestore.collection('events');
    final eventsSnapshot = await eventsQuery.get();

    for (final eventDoc in eventsSnapshot.docs) {
      final eventId = eventDoc.id;

      // Initialize engagement stats
      final stats = EngagementStats(
        appreciateCount: 0, // Start fresh for events
        discussCount: 0,
        amplifyCount: 0,
        lastUpdated: DateTime.now(),
      );

      // Update event with new engagement stats
      await eventDoc.reference.update(stats.toFirestore());

      debugPrint('✅ Migrated event: $eventId');
    }
  }

  /// Migrate user connections (followers/following to connections)
  Future<void> _migrateUserConnections() async {
    debugPrint('🔄 Migrating user connections...');

    final usersQuery = _firestore.collection('users');
    final usersSnapshot = await usersQuery.get();

    for (final userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      final userId = userDoc.id;

      // Get followers and following lists
      final followers = List<String>.from(userData['followers'] as List? ?? []);
      final following = List<String>.from(userData['following'] as List? ?? []);

      // Create connection engagements for following relationships
      for (final followedUserId in following) {
        await _createConnectionEngagement(userId, followedUserId);
      }

      // Initialize engagement stats for user profile
      final stats = EngagementStats(
        connectCount: followers.length,
        lastUpdated: DateTime.now(),
      );

      // Update user with new engagement stats
      await userDoc.reference.update(stats.toFirestore());

      debugPrint('✅ Migrated user connections: $userId');
    }
  }

  /// Migrate individual post applause records
  Future<void> _migratePostApplause(String postId) async {
    try {
      final applauseQuery = _firestore
          .collection('posts')
          .doc(postId)
          .collection('applause');

      final applauseSnapshot = await applauseQuery.get();

      for (final applauseDoc in applauseSnapshot.docs) {
        final applauseData = applauseDoc.data();
        final userId = applauseDoc.id;
        final count = applauseData['count'] as int? ?? 1;

        // Create individual engagement records for each applause
        for (int i = 0; i < count; i++) {
          await _createAppreciationEngagement(userId, postId, 'post');
        }
      }
    } catch (e) {
      debugPrint('Error migrating post applause for $postId: $e');
    }
  }

  /// Create a connection engagement record
  Future<void> _createConnectionEngagement(
    String fromUserId,
    String toUserId,
  ) async {
    try {
      final engagementId = '${toUserId}_${fromUserId}_connect';

      final engagement = EngagementModel(
        id: engagementId,
        contentId: toUserId,
        contentType: 'profile',
        userId: fromUserId,
        type: EngagementType.connect,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('engagements')
          .doc(engagementId)
          .set(engagement.toFirestore());
    } catch (e) {
      debugPrint('Error creating connection engagement: $e');
    }
  }

  /// Create an appreciation engagement record
  Future<void> _createAppreciationEngagement(
    String userId,
    String contentId,
    String contentType,
  ) async {
    try {
      final engagementId =
          '${contentId}_${userId}_appreciate_${DateTime.now().millisecondsSinceEpoch}';

      final engagement = EngagementModel(
        id: engagementId,
        contentId: contentId,
        contentType: contentType,
        userId: userId,
        type: EngagementType.appreciate,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('engagements')
          .doc(engagementId)
          .set(engagement.toFirestore());
    } catch (e) {
      debugPrint('Error creating appreciation engagement: $e');
    }
  }

  /// Clean up old engagement fields after migration
  Future<void> cleanupOldEngagementFields() async {
    debugPrint('🧹 Cleaning up old engagement fields...');

    try {
      // Clean up posts
      await _cleanupPostFields();

      // Clean up artworks
      await _cleanupArtworkFields();

      // Clean up users
      await _cleanupUserFields();

      debugPrint('✅ Cleanup completed successfully');
    } catch (e) {
      debugPrint('❌ Error during cleanup: $e');
      rethrow;
    }
  }

  Future<void> _cleanupPostFields() async {
    final postsQuery = _firestore.collection('posts');
    final postsSnapshot = await postsQuery.get();

    for (final postDoc in postsSnapshot.docs) {
      await postDoc.reference.update({
        'applauseCount': FieldValue.delete(),
        'commentCount': FieldValue.delete(),
        'shareCount': FieldValue.delete(),
      });
    }
  }

  Future<void> _cleanupArtworkFields() async {
    final artworksQuery = _firestore.collection('artworks');
    final artworksSnapshot = await artworksQuery.get();

    for (final artworkDoc in artworksSnapshot.docs) {
      await artworkDoc.reference.update({
        'likeCount': FieldValue.delete(),
        'applauseCount': FieldValue.delete(),
        'commentCount': FieldValue.delete(),
      });
    }
  }

  Future<void> _cleanupUserFields() async {
    final usersQuery = _firestore.collection('users');
    final usersSnapshot = await usersQuery.get();

    for (final userDoc in usersSnapshot.docs) {
      await userDoc.reference.update({
        'followers': FieldValue.delete(),
        'following': FieldValue.delete(),
        'followersCount': FieldValue.delete(),
        'followingCount': FieldValue.delete(),
      });
    }
  }

  /// Verify migration integrity
  Future<bool> verifyMigration() async {
    debugPrint('🔍 Verifying migration integrity...');

    try {
      // Check if engagement collection exists and has data
      final engagementsQuery = _firestore.collection('engagements').limit(1);
      final engagementsSnapshot = await engagementsQuery.get();

      if (engagementsSnapshot.docs.isEmpty) {
        debugPrint('❌ No engagements found in new collection');
        return false;
      }

      // Check if posts have new engagement stats
      final postsQuery = _firestore.collection('posts').limit(1);
      final postsSnapshot = await postsQuery.get();

      if (postsSnapshot.docs.isNotEmpty) {
        final postData = postsSnapshot.docs.first.data();
        if (!postData.containsKey('appreciateCount')) {
          debugPrint('❌ Posts missing new engagement stats');
          return false;
        }
      }

      debugPrint('✅ Migration verification passed');
      return true;
    } catch (e) {
      debugPrint('❌ Error during migration verification: $e');
      return false;
    }
  }
}

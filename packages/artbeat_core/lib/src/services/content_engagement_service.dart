import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/engagement_model.dart';
import 'engagement_config_service.dart';

/// Content-specific engagement service for ARTbeat content types
/// Replaces UniversalEngagementService with content-specific engagement handling
class ContentEngagementService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Toggle engagement for any content type
  Future<bool> toggleEngagement({
    required String contentId,
    required String contentType,
    required EngagementType engagementType,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to engage with content');
    }

    // Validate engagement type is allowed for content type
    if (!EngagementConfigService.isEngagementTypeAvailable(
      contentType,
      engagementType,
    )) {
      throw Exception(
        'Engagement type ${engagementType.value} not available for content type $contentType',
      );
    }

    try {
      final engagementRef = _firestore
          .collection('engagements')
          .doc('${contentId}_${user.uid}_${engagementType.value}');

      final contentRef = _firestore
          .collection(_getCollectionName(contentType))
          .doc(contentId);

      final engagementDoc = await engagementRef.get();
      final isCurrentlyEngaged = engagementDoc.exists;

      await _firestore.runTransaction((transaction) async {
        final contentSnapshot = await transaction.get(contentRef);
        if (!contentSnapshot.exists) {
          throw Exception('Content not found');
        }

        final contentData = contentSnapshot.data() as Map<String, dynamic>;
        final currentStats = EngagementStats.fromFirestore(
          contentData['engagementStats'] as Map<String, dynamic>? ??
              contentData,
        );

        if (isCurrentlyEngaged) {
          // Remove engagement
          transaction.delete(engagementRef);

          // Update content stats
          final newStats = _decrementStat(currentStats, engagementType);
          transaction.update(contentRef, {
            'engagementStats': newStats.toFirestore(),
          });
        } else {
          // Add engagement
          final engagement = EngagementModel(
            id: engagementRef.id,
            contentId: contentId,
            contentType: contentType,
            userId: user.uid,
            type: engagementType,
            createdAt: DateTime.now(),
            metadata: metadata,
          );

          transaction.set(engagementRef, engagement.toFirestore());

          // Update content stats
          final newStats = _incrementStat(currentStats, engagementType);
          transaction.update(contentRef, {
            'engagementStats': newStats.toFirestore(),
          });

          // Create notification for content owner (except for own content)
          final contentOwnerId = contentSnapshot.data()?['userId'] as String?;
          if (contentOwnerId != null && contentOwnerId != user.uid) {
            await _createEngagementNotification(
              contentId: contentId,
              contentType: contentType,
              engagementType: engagementType,
              fromUserId: user.uid,
              toUserId: contentOwnerId,
            );
          }
        }
      });

      notifyListeners();
      return !isCurrentlyEngaged; // Return new engagement state
    } catch (e) {
      debugPrint('Error toggling engagement: $e');
      rethrow;
    }
  }

  /// Check if user has engaged with content
  Future<bool> hasUserEngaged({
    required String contentId,
    required EngagementType engagementType,
    String? userId,
  }) async {
    final targetUserId = userId ?? _auth.currentUser?.uid;
    if (targetUserId == null) return false;

    try {
      final engagementRef = _firestore
          .collection('engagements')
          .doc('${contentId}_${targetUserId}_${engagementType.value}');

      final doc = await engagementRef.get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking engagement: $e');
      return false;
    }
  }

  /// Get engagement stats for content
  Future<EngagementStats> getEngagementStats({
    required String contentId,
    required String contentType,
  }) async {
    try {
      final contentRef = _firestore
          .collection(_getCollectionName(contentType))
          .doc(contentId);

      final doc = await contentRef.get();
      if (!doc.exists) {
        return EngagementStats(lastUpdated: DateTime.now());
      }

      final data = doc.data() as Map<String, dynamic>;
      return EngagementStats.fromFirestore(
        data['engagementStats'] as Map<String, dynamic>? ?? data,
      );
    } catch (e) {
      debugPrint('Error getting engagement stats: $e');
      return EngagementStats(lastUpdated: DateTime.now());
    }
  }

  /// Get users who engaged with content
  Future<List<EngagementModel>> getEngagements({
    required String contentId,
    required EngagementType engagementType,
    int limit = 50,
  }) async {
    try {
      final query = _firestore
          .collection('engagements')
          .where('contentId', isEqualTo: contentId)
          .where('type', isEqualTo: engagementType.value)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => EngagementModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting engagements: $e');
      return [];
    }
  }

  /// Track 'seen' engagement automatically
  Future<void> trackSeenEngagement({
    required String contentId,
    required String contentType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Only track if 'seen' is available for this content type
    if (!EngagementConfigService.isEngagementTypeAvailable(
      contentType,
      EngagementType.seen,
    )) {
      return;
    }

    try {
      final engagementRef = _firestore
          .collection('engagements')
          .doc('${contentId}_${user.uid}_seen');

      // Check if already seen
      final existingDoc = await engagementRef.get();
      if (existingDoc.exists) return;

      final contentRef = _firestore
          .collection(_getCollectionName(contentType))
          .doc(contentId);

      await _firestore.runTransaction((transaction) async {
        final contentSnapshot = await transaction.get(contentRef);
        if (!contentSnapshot.exists) return;

        final contentData = contentSnapshot.data() as Map<String, dynamic>;
        final currentStats = EngagementStats.fromFirestore(
          contentData['engagementStats'] as Map<String, dynamic>? ??
              contentData,
        );

        // Create seen engagement
        final engagement = EngagementModel(
          id: engagementRef.id,
          contentId: contentId,
          contentType: contentType,
          userId: user.uid,
          type: EngagementType.seen,
          createdAt: DateTime.now(),
        );

        transaction.set(engagementRef, engagement.toFirestore());

        // Update content stats
        final newStats = currentStats.copyWith(
          seenCount: currentStats.seenCount + 1,
          lastUpdated: DateTime.now(),
        );
        transaction.update(contentRef, {
          'engagementStats': newStats.toFirestore(),
        });
      });
    } catch (e) {
      debugPrint('Error tracking seen engagement: $e');
      // Don't throw - seen tracking is not critical
    }
  }

  /// Get user's followers (people who follow them)
  Future<List<String>> getUserFollowers(String userId) async {
    try {
      final query = _firestore
          .collection('engagements')
          .where('contentId', isEqualTo: userId)
          .where('type', isEqualTo: EngagementType.follow.value)
          .where('contentType', isEqualTo: 'profile');

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error getting user followers: $e');
      return [];
    }
  }

  /// Get user's following (people they follow)
  Future<List<String>> getUserFollowing(String userId) async {
    try {
      final query = _firestore
          .collection('engagements')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: EngagementType.follow.value)
          .where('contentType', isEqualTo: 'profile');

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data()['contentId'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error getting user following: $e');
      return [];
    }
  }

  /// Private helper methods

  String _getCollectionName(String contentType) {
    switch (contentType) {
      case 'post':
        return 'posts';
      case 'artwork':
        return 'artwork';
      case 'capture':
        return 'captures'; // Assuming captures have their own collection
      case 'art_walk':
        return 'artWalks';
      case 'event':
        return 'events';
      case 'profile':
      case 'artist':
        return 'users';
      case 'comment':
        return 'comments';
      default:
        throw Exception('Unknown content type: $contentType');
    }
  }

  EngagementStats _incrementStat(EngagementStats stats, EngagementType type) {
    switch (type) {
      case EngagementType.like:
        return stats.copyWith(
          likeCount: stats.likeCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.comment:
        return stats.copyWith(
          commentCount: stats.commentCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.reply:
        return stats.copyWith(
          replyCount: stats.replyCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.share:
        return stats.copyWith(
          shareCount: stats.shareCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.seen:
        return stats.copyWith(
          seenCount: stats.seenCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.rate:
        return stats.copyWith(
          rateCount: stats.rateCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.review:
        return stats.copyWith(
          reviewCount: stats.reviewCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.follow:
        return stats.copyWith(
          followCount: stats.followCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.gift:
        return stats.copyWith(
          giftCount: stats.giftCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.sponsor:
        return stats.copyWith(
          sponsorCount: stats.sponsorCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.message:
        return stats.copyWith(
          messageCount: stats.messageCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.commission:
        return stats.copyWith(
          commissionCount: stats.commissionCount + 1,
          lastUpdated: DateTime.now(),
        );
    }
  }

  EngagementStats _decrementStat(EngagementStats stats, EngagementType type) {
    switch (type) {
      case EngagementType.like:
        return stats.copyWith(
          likeCount: (stats.likeCount - 1).clamp(0, double.infinity).toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.comment:
        return stats.copyWith(
          commentCount: (stats.commentCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.reply:
        return stats.copyWith(
          replyCount: (stats.replyCount - 1).clamp(0, double.infinity).toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.share:
        return stats.copyWith(
          shareCount: (stats.shareCount - 1).clamp(0, double.infinity).toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.seen:
        return stats.copyWith(
          seenCount: (stats.seenCount - 1).clamp(0, double.infinity).toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.rate:
        return stats.copyWith(
          rateCount: (stats.rateCount - 1).clamp(0, double.infinity).toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.review:
        return stats.copyWith(
          reviewCount: (stats.reviewCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.follow:
        return stats.copyWith(
          followCount: (stats.followCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.gift:
        return stats.copyWith(
          giftCount: (stats.giftCount - 1).clamp(0, double.infinity).toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.sponsor:
        return stats.copyWith(
          sponsorCount: (stats.sponsorCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.message:
        return stats.copyWith(
          messageCount: (stats.messageCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.commission:
        return stats.copyWith(
          commissionCount: (stats.commissionCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          lastUpdated: DateTime.now(),
        );
    }
  }

  Future<void> _createEngagementNotification({
    required String contentId,
    required String contentType,
    required EngagementType engagementType,
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'engagement',
        'contentId': contentId,
        'contentType': contentType,
        'engagementType': engagementType.value,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'message': 'Someone ${engagementType.pastTense} your $contentType',
      });
    } catch (e) {
      debugPrint('Error creating engagement notification: $e');
      // Don't throw - notifications are not critical
    }
  }
}

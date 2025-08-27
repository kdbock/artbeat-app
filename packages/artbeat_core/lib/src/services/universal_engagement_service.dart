import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/engagement_model.dart';

/// Universal engagement service for all ARTbeat content types
/// Handles Appreciate, Connect, Discuss, Amplify, and Gift actions
class UniversalEngagementService extends ChangeNotifier {
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

  /// Get user's connections (people they've connected with)
  Future<List<String>> getUserConnections(String userId) async {
    try {
      final query = _firestore
          .collection('engagements')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: EngagementType.connect.value)
          .where('contentType', isEqualTo: 'profile');

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data()['contentId'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error getting user connections: $e');
      return [];
    }
  }

  /// Get user's connection count
  Future<int> getUserConnectionCount(String userId) async {
    try {
      final connections = await getUserConnections(userId);
      return connections.length;
    } catch (e) {
      debugPrint('Error getting connection count: $e');
      return 0;
    }
  }

  /// Private helper methods

  String _getCollectionName(String contentType) {
    switch (contentType) {
      case 'post':
        return 'posts';
      case 'artwork':
        return 'artwork'; // Fixed: should be singular to match actual collection
      case 'art_walk':
        return 'artWalks'; // Fixed: should match Firestore collection name (camelCase)
      case 'event':
        return 'events';
      case 'profile':
        return 'users';
      default:
        throw Exception('Unknown content type: $contentType');
    }
  }

  EngagementStats _incrementStat(EngagementStats stats, EngagementType type) {
    switch (type) {
      case EngagementType.appreciate:
        return stats.copyWith(
          appreciateCount: stats.appreciateCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.connect:
        return stats.copyWith(
          connectCount: stats.connectCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.discuss:
        return stats.copyWith(
          discussCount: stats.discussCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.amplify:
        return stats.copyWith(
          amplifyCount: stats.amplifyCount + 1,
          lastUpdated: DateTime.now(),
        );
      case EngagementType.gift:
        return stats.copyWith(
          giftCount: stats.giftCount + 1,
          lastUpdated: DateTime.now(),
        );
    }
  }

  EngagementStats _decrementStat(EngagementStats stats, EngagementType type) {
    switch (type) {
      case EngagementType.appreciate:
        return stats.copyWith(
          appreciateCount: (stats.appreciateCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.connect:
        return stats.copyWith(
          connectCount: (stats.connectCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.discuss:
        return stats.copyWith(
          discussCount: (stats.discussCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.amplify:
        return stats.copyWith(
          amplifyCount: (stats.amplifyCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
          lastUpdated: DateTime.now(),
        );
      case EngagementType.gift:
        return stats.copyWith(
          giftCount: (stats.giftCount - 1).clamp(0, double.infinity).toInt(),
          lastUpdated: DateTime.now(),
        );
    }
  }

  /// Send a gift engagement (requires payment processing)
  Future<bool> sendGift({
    required String contentId,
    required String contentType,
    required String recipientUserId,
    required String giftType,
    required double amount,
    String? message,
    String? paymentMethodId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to send gifts');
    }

    try {
      // Create engagement record with gift metadata
      final engagementRef = _firestore
          .collection('engagements')
          .doc(
            '${contentId}_${user.uid}_gift_${DateTime.now().millisecondsSinceEpoch}',
          );

      final contentRef = _firestore
          .collection(_getCollectionName(contentType))
          .doc(contentId);

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

        // Create gift engagement record
        final engagement = EngagementModel(
          id: engagementRef.id,
          contentId: contentId,
          contentType: contentType,
          userId: user.uid,
          type: EngagementType.gift,
          createdAt: DateTime.now(),
          metadata: {
            'giftType': giftType,
            'amount': amount,
            'message': message,
            'paymentMethodId': paymentMethodId,
            'recipientUserId': recipientUserId,
          },
        );

        // Update engagement stats
        final updatedStats = currentStats.copyWith(
          giftCount: currentStats.giftCount + 1,
          totalGiftValue: currentStats.totalGiftValue + amount,
          lastUpdated: DateTime.now(),
        );

        // Save engagement and update content stats
        transaction.set(engagementRef, engagement.toFirestore());
        transaction.update(contentRef, {
          'engagementStats': updatedStats.toFirestore(),
        });
      });

      // Create notification
      await _createEngagementNotification(
        contentId: contentId,
        contentType: contentType,
        engagementType: EngagementType.gift,
        fromUserId: user.uid,
        toUserId: recipientUserId,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error sending gift: $e');
      return false;
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

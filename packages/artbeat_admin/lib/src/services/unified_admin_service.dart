import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/content_model.dart';

/// Unified Admin Service
///
/// Provides content management specifically for the unified admin dashboard
/// Avoids conflicts with existing ContentReviewService
class UnifiedAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get all content for admin dashboard
  Future<List<ContentModel>> getAllContent({
    AdminContentType? contentType,
    AdminContentStatus? status,
    int? limit,
  }) async {
    try {
      List<ContentModel> allContent = [];

      // Get artworks
      if (contentType == null ||
          contentType == AdminContentType.all ||
          contentType == AdminContentType.artwork) {
        final artworksQuery = _firestore
            .collection('artworks')
            .orderBy('createdAt', descending: true);

        final artworksSnapshot = await (limit != null
            ? artworksQuery.limit(limit).get()
            : artworksQuery.get());

        for (final doc in artworksSnapshot.docs) {
          final content = ContentModel.fromArtwork(doc);
          if (status == null ||
              status == AdminContentStatus.all ||
              content.status == status.value) {
            allContent.add(content);
          }
        }
      }

      // Get posts
      if (contentType == null ||
          contentType == AdminContentType.all ||
          contentType == AdminContentType.post) {
        final postsQuery = _firestore
            .collection('posts')
            .orderBy('createdAt', descending: true);

        final postsSnapshot = await (limit != null
            ? postsQuery.limit(limit).get()
            : postsQuery.get());

        for (final doc in postsSnapshot.docs) {
          final content = ContentModel.fromPost(doc);
          if (status == null ||
              status == AdminContentStatus.all ||
              content.status == status.value) {
            allContent.add(content);
          }
        }
      }

      // Get events
      if (contentType == null ||
          contentType == AdminContentType.all ||
          contentType == AdminContentType.event) {
        final eventsQuery = _firestore
            .collection('events')
            .orderBy('createdAt', descending: true);

        final eventsSnapshot = await (limit != null
            ? eventsQuery.limit(limit).get()
            : eventsQuery.get());

        for (final doc in eventsSnapshot.docs) {
          final content = ContentModel.fromEvent(doc);
          if (status == null ||
              status == AdminContentStatus.all ||
              content.status == status.value) {
            allContent.add(content);
          }
        }
      }

      // Sort by creation date (most recent first)
      allContent.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply limit if specified
      if (limit != null && allContent.length > limit) {
        allContent = allContent.take(limit).toList();
      }

      return allContent;
    } catch (e) {
      throw Exception('Failed to get all content: $e');
    }
  }

  /// Approve content by ID
  Future<void> approveContent(String contentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Try to find and update the content in different collections
      final collections = ['artworks', 'posts', 'events', 'captures'];

      for (final collection in collections) {
        final doc =
            await _firestore.collection(collection).doc(contentId).get();
        if (doc.exists) {
          await doc.reference.update({
            'status': 'approved',
            'moderatedBy': user.uid,
            'moderatedAt': FieldValue.serverTimestamp(),
            'isFlagged': false,
          });

          // Log the moderation action
          await _logModerationAction(
            contentId: contentId,
            action: 'approved',
            moderatorId: user.uid,
            contentType: collection,
          );

          return;
        }
      }

      throw Exception('Content not found');
    } catch (e) {
      throw Exception('Failed to approve content: $e');
    }
  }

  /// Reject content by ID
  Future<void> rejectContent(String contentId, {String? reason}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Try to find and update the content in different collections
      final collections = ['artworks', 'posts', 'events', 'captures'];

      for (final collection in collections) {
        final doc =
            await _firestore.collection(collection).doc(contentId).get();
        if (doc.exists) {
          await doc.reference.update({
            'status': 'rejected',
            'moderatedBy': user.uid,
            'moderatedAt': FieldValue.serverTimestamp(),
            'rejectionReason':
                reason ?? 'Content does not meet community guidelines',
            'isFlagged': false,
          });

          // Log the moderation action
          await _logModerationAction(
            contentId: contentId,
            action: 'rejected',
            moderatorId: user.uid,
            contentType: collection,
            reason: reason,
          );

          return;
        }
      }

      throw Exception('Content not found');
    } catch (e) {
      throw Exception('Failed to reject content: $e');
    }
  }

  /// Log moderation action for audit trail
  Future<void> _logModerationAction({
    required String contentId,
    required String action,
    required String moderatorId,
    required String contentType,
    String? reason,
  }) async {
    try {
      await _firestore.collection('moderation_logs').add({
        'contentId': contentId,
        'contentType': contentType,
        'action': action,
        'moderatorId': moderatorId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but don't throw - moderation action should still succeed
      // Failed to log moderation action: $e
    }
  }

  /// Bulk approve multiple content items
  Future<void> bulkApproveContent(List<String> contentIds) async {
    final futures = contentIds.map((id) => approveContent(id));
    await Future.wait(futures);
  }

  /// Bulk reject multiple content items
  Future<void> bulkRejectContent(List<String> contentIds,
      {String? reason}) async {
    final futures = contentIds.map((id) => rejectContent(id, reason: reason));
    await Future.wait(futures);
  }

  /// Get content statistics for dashboard
  Future<Map<String, dynamic>> getContentStatistics() async {
    try {
      final results = await Future.wait([
        _firestore.collection('artworks').get(),
        _firestore.collection('posts').get(),
        _firestore.collection('events').get(),
        _firestore
            .collection('artworks')
            .where('status', isEqualTo: 'pending')
            .get(),
        _firestore
            .collection('posts')
            .where('status', isEqualTo: 'pending')
            .get(),
        _firestore
            .collection('events')
            .where('status', isEqualTo: 'pending')
            .get(),
        _firestore
            .collection('artworks')
            .where('isFlagged', isEqualTo: true)
            .get(),
        _firestore
            .collection('posts')
            .where('isFlagged', isEqualTo: true)
            .get(),
        _firestore
            .collection('events')
            .where('isFlagged', isEqualTo: true)
            .get(),
      ]);

      final totalArtworks = results[0].docs.length;
      final totalPosts = results[1].docs.length;
      final totalEvents = results[2].docs.length;
      final pendingArtworks = results[3].docs.length;
      final pendingPosts = results[4].docs.length;
      final pendingEvents = results[5].docs.length;
      final flaggedArtworks = results[6].docs.length;
      final flaggedPosts = results[7].docs.length;
      final flaggedEvents = results[8].docs.length;

      return {
        'total': totalArtworks + totalPosts + totalEvents,
        'artworks': totalArtworks,
        'posts': totalPosts,
        'events': totalEvents,
        'pending': pendingArtworks + pendingPosts + pendingEvents,
        'flagged': flaggedArtworks + flaggedPosts + flaggedEvents,
        'breakdown': {
          'artworks': {
            'total': totalArtworks,
            'pending': pendingArtworks,
            'flagged': flaggedArtworks,
          },
          'posts': {
            'total': totalPosts,
            'pending': pendingPosts,
            'flagged': flaggedPosts,
          },
          'events': {
            'total': totalEvents,
            'pending': pendingEvents,
            'flagged': flaggedEvents,
          },
        },
      };
    } catch (e) {
      throw Exception('Failed to get content statistics: $e');
    }
  }
}

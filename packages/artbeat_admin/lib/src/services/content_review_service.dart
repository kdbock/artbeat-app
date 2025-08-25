import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/content_review_model.dart';
import '../models/content_model.dart';

/// Service for content review operations
class ContentReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get pending content reviews
  Future<List<ContentReviewModel>> getPendingReviews({
    ContentType? contentType,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection('content_reviews')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true);

      if (contentType != null && contentType != ContentType.all) {
        query = query.where('contentType', isEqualTo: contentType.name);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ContentReviewModel.fromDocument(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending reviews: $e');
    }
  }

  /// Get all content reviews with optional filtering
  Future<List<ContentReviewModel>> getContentReviews({
    ContentType? contentType,
    ReviewStatus? status,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('content_reviews');

      if (contentType != null && contentType != ContentType.all) {
        query = query.where('contentType', isEqualTo: contentType.name);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }

      query = query.orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ContentReviewModel.fromDocument(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get content reviews: $e');
    }
  }

  /// Approve content
  Future<void> approveContent(String contentId, ContentType contentType) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update the content review record
      await _firestore.collection('content_reviews').doc(contentId).update({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': user.uid,
      });

      // Update the actual content record based on type
      await _updateContentStatus(contentId, contentType, true);

      // Log the approval action
      await _logReviewAction(contentId, contentType, 'approved', user.uid);
    } catch (e) {
      throw Exception('Failed to approve content: $e');
    }
  }

  /// Reject content
  Future<void> rejectContent(
    String contentId,
    ContentType contentType,
    String reason,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update the content review record
      await _firestore.collection('content_reviews').doc(contentId).update({
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': user.uid,
        'rejectionReason': reason,
      });

      // Update the actual content record based on type
      await _updateContentStatus(contentId, contentType, false);

      // Log the rejection action
      await _logReviewAction(contentId, contentType, 'rejected', user.uid,
          reason: reason);
    } catch (e) {
      throw Exception('Failed to reject content: $e');
    }
  }

  /// Create a new content review entry
  Future<void> createContentReview({
    required String contentId,
    required ContentType contentType,
    required String title,
    required String description,
    required String authorId,
    required String authorName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final review = ContentReviewModel(
        id: contentId,
        contentId: contentId,
        contentType: contentType,
        title: title,
        description: description,
        authorId: authorId,
        authorName: authorName,
        status: ReviewStatus.pending,
        createdAt: DateTime.now(),
        metadata: metadata ?? {},
      );

      await _firestore
          .collection('content_reviews')
          .doc(contentId)
          .set(review.toDocument());
    } catch (e) {
      throw Exception('Failed to create content review: $e');
    }
  }

  /// Update content status based on content type
  Future<void> _updateContentStatus(
    String contentId,
    ContentType contentType,
    bool isApproved,
  ) async {
    String collectionName;
    switch (contentType) {
      case ContentType.ads:
        collectionName = 'ads';
        break;
      case ContentType.captures:
        collectionName = 'captures';
        break;
      case ContentType.all:
        return; // Cannot update all content types
    }

    await _firestore.collection(collectionName).doc(contentId).update({
      'isApproved': isApproved,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Log review action for audit trail
  Future<void> _logReviewAction(
    String contentId,
    ContentType contentType,
    String action,
    String reviewerId, {
    String? reason,
  }) async {
    await _firestore.collection('content_review_logs').add({
      'contentId': contentId,
      'contentType': contentType.name,
      'action': action,
      'reviewerId': reviewerId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Get content review statistics
  Future<Map<String, int>> getReviewStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('content_reviews');

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      final reviews = snapshot.docs
          .map((doc) => ContentReviewModel.fromDocument(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      final stats = <String, int>{
        'total': reviews.length,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
      };

      for (final contentType in ContentType.values) {
        if (contentType != ContentType.all) {
          stats[contentType.name] = 0;
        }
      }

      for (final review in reviews) {
        stats[review.status.name] = (stats[review.status.name] ?? 0) + 1;
        stats[review.contentType.name] =
            (stats[review.contentType.name] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get review stats: $e');
    }
  }

  /// Get content review by ID
  Future<ContentReviewModel?> getContentReviewById(String id) async {
    try {
      final doc = await _firestore.collection('content_reviews').doc(id).get();
      if (doc.exists) {
        return ContentReviewModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get content review: $e');
    }
  }

  /// Delete content review
  Future<void> deleteContentReview(String id) async {
    try {
      await _firestore.collection('content_reviews').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete content review: $e');
    }
  }

  /// Bulk approve content
  Future<void> bulkApproveContent(List<String> contentIds) async {
    try {
      final batch = _firestore.batch();
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      for (final contentId in contentIds) {
        final docRef = _firestore.collection('content_reviews').doc(contentId);
        batch.update(docRef, {
          'status': 'approved',
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': user.uid,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk approve content: $e');
    }
  }

  /// Bulk reject content
  Future<void> bulkRejectContent(List<String> contentIds, String reason) async {
    try {
      final batch = _firestore.batch();
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      for (final contentId in contentIds) {
        final docRef = _firestore.collection('content_reviews').doc(contentId);
        batch.update(docRef, {
          'status': 'rejected',
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': user.uid,
          'rejectionReason': reason,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk reject content: $e');
    }
  }

  /// Get all content for admin management
  Future<List<ContentModel>> getAllContent({
    String? contentType,
    String? status,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection('content')
          .orderBy('createdAt', descending: true);

      if (contentType != null && contentType != 'all') {
        query = query.where('type', isEqualTo: contentType);
      }

      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ContentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get content: $e');
    }
  }

  /// Get content analytics
  Future<Map<String, dynamic>> getContentAnalytics({
    String? contentType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // This is a simplified version - in production you'd calculate real analytics
      final content = await getAllContent(contentType: contentType);

      return {
        'totalContent': content.length,
        'pendingReviews':
            content.where((c) => c.moderationStatus == 'pending').length,
        'approvedContent':
            content.where((c) => c.moderationStatus == 'approved').length,
        'rejectedContent':
            content.where((c) => c.moderationStatus == 'rejected').length,
        'averageEngagement': content.isNotEmpty
            ? content.map((c) => c.engagementScore).reduce((a, b) => a + b) /
                content.length
            : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get content analytics: $e');
    }
  }
}

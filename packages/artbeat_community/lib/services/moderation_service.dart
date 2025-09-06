import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class ModerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Profanity filter - basic implementation
  static const List<String> _profanityList = [
    'damn', 'hell', 'crap', 'shit', 'fuck', 'ass', 'bitch', 'bastard',
    'dick', 'pussy', 'cunt', 'cock', 'tits', 'boobs', 'asshole',
    // Add more as needed
  ];

  // Spam detection patterns
  static const List<String> _spamPatterns = [
    r'http[s]?://[^\s]+', // URLs
    r'\b\d{10,}\b', // Long numbers (potentially phone numbers)
    r'[A-Z]{5,}', // Excessive caps
    r'(.)\1{4,}', // Repeated characters
  ];

  /// Check content for automated moderation
  ModerationResult checkContent(String content) {
    final violations = <ModerationViolation>[];

    // Check for profanity
    final lowerContent = content.toLowerCase();
    for (final word in _profanityList) {
      if (lowerContent.contains(word)) {
        violations.add(
          ModerationViolation(
            type: ModerationViolationType.profanity,
            severity: ModerationSeverity.medium,
            description: 'Contains profanity: $word',
          ),
        );
      }
    }

    // Check for spam patterns
    for (final pattern in _spamPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      if (regex.hasMatch(content)) {
        violations.add(
          const ModerationViolation(
            type: ModerationViolationType.spam,
            severity: ModerationSeverity.low,
            description: 'Matches spam pattern',
          ),
        );
      }
    }

    // Check content length
    if (content.length < 10) {
      violations.add(
        const ModerationViolation(
          type: ModerationViolationType.shortContent,
          severity: ModerationSeverity.low,
          description: 'Content too short',
        ),
      );
    }

    return ModerationResult(
      shouldFlag: violations.isNotEmpty,
      violations: violations,
      recommendedAction: _getRecommendedAction(violations),
    );
  }

  ModerationAction _getRecommendedAction(List<ModerationViolation> violations) {
    if (violations.any((v) => v.severity == ModerationSeverity.high)) {
      return ModerationAction.remove;
    } else if (violations.any((v) => v.severity == ModerationSeverity.medium)) {
      return ModerationAction.flag;
    } else {
      return ModerationAction.approve;
    }
  }

  /// Get flagged content for moderation
  Future<List<PostModel>> getFlaggedPosts() async {
    try {
      final query = await _firestore
          .collection('posts')
          .where('flagged', isEqualTo: true)
          .orderBy('flaggedAt', descending: true)
          .get();

      return query.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting flagged posts: $e');
      return [];
    }
  }

  Future<List<CommentModel>> getFlaggedComments() async {
    try {
      final query = await _firestore
          .collection('comments')
          .where('flagged', isEqualTo: true)
          .orderBy('flaggedAt', descending: true)
          .get();

      return query.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting flagged comments: $e');
      return [];
    }
  }

  /// Bulk moderation actions
  Future<void> bulkApprove(
    List<String> postIds,
    List<String> commentIds,
  ) async {
    final batch = _firestore.batch();

    // Approve posts
    for (final postId in postIds) {
      final postRef = _firestore.collection('posts').doc(postId);
      batch.update(postRef, {
        'flagged': false,
        'moderationStatus': 'approved',
        'moderatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Approve comments
    for (final commentId in commentIds) {
      final commentRef = _firestore.collection('comments').doc(commentId);
      batch.update(commentRef, {
        'flagged': false,
        'moderationStatus': 'approved',
        'moderatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> bulkRemove(List<String> postIds, List<String> commentIds) async {
    final batch = _firestore.batch();

    // Remove posts
    for (final postId in postIds) {
      final postRef = _firestore.collection('posts').doc(postId);
      batch.update(postRef, {
        'isPublic': false,
        'flagged': false,
        'moderationStatus': 'removed',
        'moderatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Remove comments
    for (final commentId in commentIds) {
      final commentRef = _firestore.collection('comments').doc(commentId);
      batch.update(commentRef, {
        'isPublic': false,
        'flagged': false,
        'moderationStatus': 'removed',
        'moderatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Moderate individual content
  Future<void> approvePost(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'flagged': false,
      'moderationStatus': 'approved',
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removePost(String postId) async {
    await _firestore.collection('posts').doc(postId).update({
      'isPublic': false,
      'flagged': false,
      'moderationStatus': 'removed',
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> approveComment(String commentId) async {
    await _firestore.collection('comments').doc(commentId).update({
      'flagged': false,
      'moderationStatus': 'approved',
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeComment(String commentId) async {
    await _firestore.collection('comments').doc(commentId).update({
      'isPublic': false,
      'flagged': false,
      'moderationStatus': 'removed',
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get moderation statistics
  Future<ModerationStats> getModerationStats() async {
    try {
      final postsQuery = await _firestore.collection('posts').get();
      final commentsQuery = await _firestore.collection('comments').get();

      final totalPosts = postsQuery.docs.length;
      final totalComments = commentsQuery.docs.length;

      final flaggedPosts = postsQuery.docs
          .where((doc) => doc.data()['flagged'] == true)
          .length;

      final flaggedComments = commentsQuery.docs
          .where((doc) => doc.data()['flagged'] == true)
          .length;

      return ModerationStats(
        totalPosts: totalPosts,
        totalComments: totalComments,
        flaggedPosts: flaggedPosts,
        flaggedComments: flaggedComments,
        pendingModeration: flaggedPosts + flaggedComments,
      );
    } catch (e) {
      debugPrint('Error getting moderation stats: $e');
      return ModerationStats.empty();
    }
  }

  /// Stream moderation queue updates
  Stream<List<PostModel>> streamFlaggedPosts() {
    return _firestore
        .collection('posts')
        .where('flagged', isEqualTo: true)
        .orderBy('flaggedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<CommentModel>> streamFlaggedComments() {
    return _firestore
        .collection('comments')
        .where('flagged', isEqualTo: true)
        .orderBy('flaggedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList(),
        );
  }
}

/// Moderation result from automated checking
class ModerationResult {
  final bool shouldFlag;
  final List<ModerationViolation> violations;
  final ModerationAction recommendedAction;

  const ModerationResult({
    required this.shouldFlag,
    required this.violations,
    required this.recommendedAction,
  });
}

/// Individual moderation violation
class ModerationViolation {
  final ModerationViolationType type;
  final ModerationSeverity severity;
  final String description;

  const ModerationViolation({
    required this.type,
    required this.severity,
    required this.description,
  });
}

/// Types of moderation violations
enum ModerationViolationType {
  profanity,
  spam,
  shortContent,
  harassment,
  inappropriate,
}

/// Severity levels for violations
enum ModerationSeverity { low, medium, high }

/// Recommended moderation actions
enum ModerationAction { approve, flag, remove }

/// Moderation statistics
class ModerationStats {
  final int totalPosts;
  final int totalComments;
  final int flaggedPosts;
  final int flaggedComments;
  final int pendingModeration;

  const ModerationStats({
    required this.totalPosts,
    required this.totalComments,
    required this.flaggedPosts,
    required this.flaggedComments,
    required this.pendingModeration,
  });

  factory ModerationStats.empty() {
    return const ModerationStats(
      totalPosts: 0,
      totalComments: 0,
      flaggedPosts: 0,
      flaggedComments: 0,
      pendingModeration: 0,
    );
  }
}

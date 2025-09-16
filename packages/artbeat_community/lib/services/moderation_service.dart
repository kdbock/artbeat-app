import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

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

  /// Enhanced content moderation for multimedia posts
  Future<EnhancedModerationResult> moderateContent({
    required String content,
    List<File>? imageFiles,
    File? videoFile,
    File? audioFile,
  }) async {
    final violations = <ModerationViolation>[];

    // Check text content
    final textResult = checkContent(content);
    violations.addAll(textResult.violations);

    // Check image content
    if (imageFiles != null && imageFiles.isNotEmpty) {
      for (int i = 0; i < imageFiles.length; i++) {
        final imageViolations = await _checkImageContent(imageFiles[i], i);
        violations.addAll(imageViolations);
      }
    }

    // Check video content
    if (videoFile != null) {
      final videoViolations = await _checkVideoContent(videoFile);
      violations.addAll(videoViolations);
    }

    // Check audio content
    if (audioFile != null) {
      final audioViolations = await _checkAudioContent(audioFile);
      violations.addAll(audioViolations);
    }

    final status = _determinePostStatus(violations);

    return EnhancedModerationResult(
      isApproved: status == PostModerationStatus.approved,
      status: status,
      violations: violations,
      reason: violations.isNotEmpty
          ? violations.map((v) => v.description).join(', ')
          : null,
    );
  }

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

    // Check content length - allow empty content if media is present
    if (content.trim().isEmpty) {
      violations.add(
        const ModerationViolation(
          type: ModerationViolationType.shortContent,
          severity: ModerationSeverity.low,
          description: 'No text content provided',
        ),
      );
    }

    return ModerationResult(
      shouldFlag: violations.isNotEmpty,
      violations: violations,
      recommendedAction: _getRecommendedAction(violations),
    );
  }

  /// Check image content for violations
  Future<List<ModerationViolation>> _checkImageContent(
    File imageFile,
    int index,
  ) async {
    final violations = <ModerationViolation>[];

    try {
      // Check file size (max 15MB as per storage service)
      final fileSize = await imageFile.length();
      if (fileSize > 15 * 1024 * 1024) {
        violations.add(
          ModerationViolation(
            type: ModerationViolationType.inappropriate,
            severity: ModerationSeverity.medium,
            description: 'Image ${index + 1} exceeds size limit',
          ),
        );
      }

      // Basic image validation
      if (!await imageFile.exists()) {
        violations.add(
          ModerationViolation(
            type: ModerationViolationType.inappropriate,
            severity: ModerationSeverity.high,
            description: 'Image ${index + 1} file not found',
          ),
        );
      }

      // TODO: Add AI-based image content analysis here
      // This could include:
      // - NSFW content detection
      // - Violence detection
      // - Copyright infringement detection
      // - Face recognition for privacy
    } catch (e) {
      violations.add(
        ModerationViolation(
          type: ModerationViolationType.inappropriate,
          severity: ModerationSeverity.medium,
          description: 'Error processing image ${index + 1}: $e',
        ),
      );
    }

    return violations;
  }

  /// Check video content for violations
  Future<List<ModerationViolation>> _checkVideoContent(File videoFile) async {
    final violations = <ModerationViolation>[];

    try {
      // Check file size (max 50MB)
      final fileSize = await videoFile.length();
      if (fileSize > 50 * 1024 * 1024) {
        violations.add(
          const ModerationViolation(
            type: ModerationViolationType.inappropriate,
            severity: ModerationSeverity.medium,
            description: 'Video exceeds size limit (50MB)',
          ),
        );
      }

      // Basic video validation
      if (!await videoFile.exists()) {
        violations.add(
          const ModerationViolation(
            type: ModerationViolationType.inappropriate,
            severity: ModerationSeverity.high,
            description: 'Video file not found',
          ),
        );
      }

      // TODO: Add AI-based video content analysis here
      // This could include:
      // - NSFW content detection
      // - Violence detection
      // - Audio analysis for inappropriate content
      // - Duration limits
    } catch (e) {
      violations.add(
        ModerationViolation(
          type: ModerationViolationType.inappropriate,
          severity: ModerationSeverity.medium,
          description: 'Error processing video: $e',
        ),
      );
    }

    return violations;
  }

  /// Check audio content for violations
  Future<List<ModerationViolation>> _checkAudioContent(File audioFile) async {
    final violations = <ModerationViolation>[];

    try {
      // Check file size (max 10MB)
      final fileSize = await audioFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        violations.add(
          const ModerationViolation(
            type: ModerationViolationType.inappropriate,
            severity: ModerationSeverity.medium,
            description: 'Audio exceeds size limit (10MB)',
          ),
        );
      }

      // Basic audio validation
      if (!await audioFile.exists()) {
        violations.add(
          const ModerationViolation(
            type: ModerationViolationType.inappropriate,
            severity: ModerationSeverity.high,
            description: 'Audio file not found',
          ),
        );
      }

      // TODO: Add AI-based audio content analysis here
      // This could include:
      // - Speech-to-text analysis for inappropriate language
      // - Music copyright detection
      // - Duration limits
      // - Volume level checks
    } catch (e) {
      violations.add(
        ModerationViolation(
          type: ModerationViolationType.inappropriate,
          severity: ModerationSeverity.medium,
          description: 'Error processing audio: $e',
        ),
      );
    }

    return violations;
  }

  /// Determine post moderation status based on violations
  PostModerationStatus _determinePostStatus(
    List<ModerationViolation> violations,
  ) {
    if (violations.isEmpty) {
      return PostModerationStatus.approved;
    }

    final hasHighSeverity = violations.any(
      (v) => v.severity == ModerationSeverity.high,
    );
    final hasMediumSeverity = violations.any(
      (v) => v.severity == ModerationSeverity.medium,
    );

    if (hasHighSeverity) {
      return PostModerationStatus.rejected;
    } else if (hasMediumSeverity) {
      return PostModerationStatus.pending;
    } else {
      return PostModerationStatus.approved;
    }
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
      AppLogger.error('Error getting flagged posts: $e');
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
      AppLogger.error('Error getting flagged comments: $e');
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
      AppLogger.error('Error getting moderation stats: $e');
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

/// Enhanced moderation result for multimedia content
class EnhancedModerationResult {
  final bool isApproved;
  final PostModerationStatus status;
  final List<ModerationViolation> violations;
  final String? reason;

  const EnhancedModerationResult({
    required this.isApproved,
    required this.status,
    required this.violations,
    this.reason,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;

enum ReportReason {
  harassment('harassment', 'Harassment or bullying'),
  hateSpeech('hate_speech', 'Hate speech or discrimination'),
  inappropriateContent('inappropriate_content', 'Inappropriate content'),
  spam('spam', 'Spam or scam'),
  copyright('copyright', 'Copyright infringement'),
  misinformation('misinformation', 'Misinformation'),
  other('other', 'Other');

  final String value;
  final String displayName;
  const ReportReason(this.value, this.displayName);
}

/// Service for handling user reports and blocks
class ModerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Report a user or piece of content
  Future<bool> reportContent({
    required String reportedUserId,
    required String contentId,
    required String contentType,
    required ReportReason reason,
    String? description,
    String? reportingUserId,
  }) async {
    try {
      AppLogger.info('📋 Creating report for $contentType: $contentId');

      await _firestore.collection('reports').add({
        'reportedUserId': reportedUserId,
        'contentId': contentId,
        'contentType': contentType,
        'reason': reason.value,
        'reasonDisplay': reason.displayName,
        'description': description ?? '',
        'reportingUserId': reportingUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'resolved': false,
      });

      AppLogger.info('✅ Report created successfully');
      return true;
    } catch (e) {
      AppLogger.error('❌ Failed to create report: $e');
      return false;
    }
  }

  /// Block a user
  Future<bool> blockUser({
    required String blockingUserId,
    required String blockedUserId,
  }) async {
    try {
      AppLogger.info('🚫 Blocking user $blockedUserId');

      // Fetch user details to store with block relationship
      String blockedUserName = 'Unknown User';
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(blockedUserId)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          AppLogger.info('🔍 User data for $blockedUserId: $userData');

          // Use same priority order as community service
          blockedUserName =
              userData['fullName'] as String? ??
              userData['displayName'] as String? ??
              userData['name'] as String? ??
              'Unknown User';
          AppLogger.info('📝 Resolved user name: $blockedUserName');
        }
      } catch (e) {
        AppLogger.error(
          '⚠️ Could not fetch user details for $blockedUserId: $e',
        );
      }

      // Create block relationship with user name
      await _firestore
          .collection('users')
          .doc(blockingUserId)
          .collection('blockedUsers')
          .doc(blockedUserId)
          .set({
            'blockedUserId': blockedUserId,
            'blockedUserName': blockedUserName,
            'blockedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.info('✅ User blocked successfully with name: $blockedUserName');
      return true;
    } catch (e) {
      AppLogger.error('❌ Failed to block user: $e');
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser({
    required String blockingUserId,
    required String blockedUserId,
  }) async {
    try {
      AppLogger.info('🔓 Unblocking user $blockedUserId');

      await _firestore
          .collection('users')
          .doc(blockingUserId)
          .collection('blockedUsers')
          .doc(blockedUserId)
          .delete();

      AppLogger.info('✅ User unblocked successfully');
      return true;
    } catch (e) {
      AppLogger.error('❌ Failed to unblock user: $e');
      return false;
    }
  }

  /// Get list of blocked users
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blockedUsers')
          .get();

      return snapshot.docs
          .map((doc) => doc['blockedUserId'] as String)
          .toList();
    } catch (e) {
      AppLogger.error('❌ Failed to get blocked users: $e');
      return [];
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked({
    required String blockingUserId,
    required String checkedUserId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(blockingUserId)
          .collection('blockedUsers')
          .doc(checkedUserId)
          .get();

      return doc.exists;
    } catch (e) {
      AppLogger.error('❌ Failed to check if user is blocked: $e');
      return false;
    }
  }
}

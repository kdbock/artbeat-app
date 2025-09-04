import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:logging/logging.dart';
import '../models/content_review_model.dart';

/// Service for real-time content moderation updates
/// Implements 2025 industry standards for live content monitoring
class RealtimeContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('RealtimeContentService');

  StreamSubscription<QuerySnapshot>? _pendingContentSubscription;
  StreamSubscription<QuerySnapshot>? _flaggedContentSubscription;
  StreamSubscription<QuerySnapshot>? _moderationActionsSubscription;

  final StreamController<int> _pendingCountController =
      StreamController<int>.broadcast();
  final StreamController<ContentReviewModel> _newContentController =
      StreamController<ContentReviewModel>.broadcast();
  final StreamController<ModerationAction> _moderationActionController =
      StreamController<ModerationAction>.broadcast();

  /// Stream of pending content count for real-time UI updates
  Stream<int> get pendingContentCount => _pendingCountController.stream;

  /// Stream of new content requiring review
  Stream<ContentReviewModel> get newContentStream =>
      _newContentController.stream;

  /// Stream of moderation actions for audit trail
  Stream<ModerationAction> get moderationActionStream =>
      _moderationActionController.stream;

  /// Initialize real-time listeners
  Future<void> initialize() async {
    try {
      await _startPendingContentListener();
      await _startModerationActionsListener();

      _logger.info('Realtime content service initialized');
    } catch (e) {
      _logger.severe('Failed to initialize realtime content service', e);
      rethrow;
    }
  }

  /// Start listening for pending content updates
  Future<void> _startPendingContentListener() async {
    // Listen for new pending captures
    _pendingContentSubscription = _firestore
        .collection('captures')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(_handlePendingContentUpdate);

    // Also listen for posts and comments that get flagged
    _flaggedContentSubscription = _firestore
        .collection('posts')
        .where('flagged', isEqualTo: true)
        .snapshots()
        .listen(_handleFlaggedContentUpdate);
  }

  /// Start listening for moderation actions
  Future<void> _startModerationActionsListener() async {
    _moderationActionsSubscription = _firestore
        .collection('moderation_actions')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen(_handleModerationActionUpdate);
  }

  /// Handle updates to pending content
  void _handlePendingContentUpdate(QuerySnapshot snapshot) {
    try {
      final pendingCount = snapshot.docs.length;
      _pendingCountController.add(pendingCount);

      // Check for new content (compared to previous state)
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          _handleNewPendingContent(change.doc.id, data, ContentType.captures);
        }
      }
    } catch (e) {
      _logger.warning('Error handling pending content update', e);
    }
  }

  /// Handle updates to flagged content
  void _handleFlaggedContentUpdate(QuerySnapshot snapshot) {
    try {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>;
          final wasFlagged = data['flagged'] == true;

          if (wasFlagged && !_isAlreadyProcessed(change.doc.id)) {
            _handleNewFlaggedContent(change.doc.id, data, ContentType.posts);
          }
        }
      }
    } catch (e) {
      _logger.warning('Error handling flagged content update', e);
    }
  }

  /// Handle moderation action updates
  void _handleModerationActionUpdate(QuerySnapshot snapshot) {
    try {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final action = ModerationAction.fromJson(data);
          _moderationActionController.add(action);
        }
      }
    } catch (e) {
      _logger.warning('Error handling moderation action update', e);
    }
  }

  /// Handle new pending content
  Future<void> _handleNewPendingContent(
    String contentId,
    Map<String, dynamic> data,
    ContentType contentType,
  ) async {
    try {
      // Get user info for author name
      String authorName = 'Unknown User';
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(data['userId'] as String?)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          authorName = (userData['fullName'] as String?) ??
              (userData['username'] as String?) ??
              'Unknown User';
        }
      } catch (e) {
        // Continue with default name if user lookup fails
      }

      final review = ContentReviewModel(
        id: contentId,
        contentId: contentId,
        contentType: contentType,
        title: (data['title'] as String?) ?? 'Untitled Content',
        description:
            (data['description'] as String?) ?? 'No description provided',
        authorId: (data['userId'] as String?) ?? '',
        authorName: authorName,
        status: ReviewStatus.pending,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        metadata: {
          'imageUrl': data['imageUrl'],
          'thumbnailUrl': data['thumbnailUrl'],
          'location': data['location'],
          'tags': data['tags'],
        },
      );

      _newContentController.add(review);

      // Send urgent notification for high-priority content
      await _sendUrgentNotification(review);
    } catch (e) {
      _logger.warning('Error handling new pending content', e);
    }
  }

  /// Handle new flagged content
  Future<void> _handleNewFlaggedContent(
    String contentId,
    Map<String, dynamic> data,
    ContentType contentType,
  ) async {
    try {
      // Get user info for author name
      String authorName = 'Unknown User';
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(data['userId'] as String?)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          authorName = (userData['fullName'] as String?) ??
              (userData['username'] as String?) ??
              'Unknown User';
        }
      } catch (e) {
        // Continue with default name if user lookup fails
      }

      final review = ContentReviewModel(
        id: contentId,
        contentId: contentId,
        contentType: contentType,
        title: 'Flagged Post by $authorName',
        description: (data['content'] as String?) ?? 'No content provided',
        authorId: (data['userId'] as String?) ?? '',
        authorName: authorName,
        status: ReviewStatus.flagged,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        metadata: {
          'content': data['content'],
          'imageUrls': data['imageUrls'],
          'tags': data['tags'],
          'flaggedAt': data['flaggedAt'],
          'moderationStatus': data['moderationStatus'],
        },
      );

      _newContentController.add(review);

      // Send high-priority notification for flagged content
      await _sendHighPriorityNotification(review);
    } catch (e) {
      _logger.warning('Error handling new flagged content', e);
    }
  }

  /// Send urgent notification for new pending content
  Future<void> _sendUrgentNotification(ContentReviewModel review) async {
    try {
      // Get admin users who have push notifications enabled
      final adminUsers = await _getAdminUsersWithNotifications();

      for (final adminId in adminUsers) {
        await _firestore.collection('notifications').add({
          'userId': adminId,
          'title': 'New Content Requires Review',
          'body': '${review.contentType.displayName}: ${review.title}',
          'type': 'content_review',
          'priority': 'urgent',
          'data': {
            'contentId': review.contentId,
            'contentType': review.contentType.name,
            'authorName': review.authorName,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      // Send push notification
      await _sendPushNotification(
        title: '🚨 New Content Requires Review',
        body: '${review.contentType.displayName} from ${review.authorName}',
        data: {
          'type': 'content_review',
          'contentId': review.contentId,
          'contentType': review.contentType.name,
        },
      );
    } catch (e) {
      _logger.warning('Error sending urgent notification', e);
    }
  }

  /// Send high-priority notification for flagged content
  Future<void> _sendHighPriorityNotification(ContentReviewModel review) async {
    try {
      final adminUsers = await _getAdminUsersWithNotifications();

      for (final adminId in adminUsers) {
        await _firestore.collection('notifications').add({
          'userId': adminId,
          'title': 'Content Flagged for Review',
          'body': 'Flagged ${review.contentType.displayName}: ${review.title}',
          'type': 'content_flagged',
          'priority': 'high',
          'data': {
            'contentId': review.contentId,
            'contentType': review.contentType.name,
            'authorName': review.authorName,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      await _sendPushNotification(
        title: '⚠️ Content Flagged',
        body: '${review.contentType.displayName} flagged by community',
        data: {
          'type': 'content_flagged',
          'contentId': review.contentId,
          'contentType': review.contentType.name,
        },
      );
    } catch (e) {
      _logger.warning('Error sending high priority notification', e);
    }
  }

  /// Send push notification to all admin devices
  Future<void> _sendPushNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // This would integrate with FCM to send push notifications
      // For now, we'll use the existing notification service
      final adminUsers = await _getAdminUsersWithNotifications();

      for (final adminId in adminUsers) {
        // The notification service will handle sending push notifications
        // when new notifications are added to Firestore
        await _firestore.collection('notifications').add({
          'userId': adminId,
          'title': title,
          'body': body,
          'type': 'admin_alert',
          'priority': 'normal',
          'data': data,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    } catch (e) {
      _logger.warning('Error sending push notification', e);
    }
  }

  /// Get admin users who have push notifications enabled
  Future<List<String>> _getAdminUsersWithNotifications() async {
    try {
      final adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      final adminUsers = <String>[];

      for (final doc in adminQuery.docs) {
        final userData = doc.data();
        final settings = userData['settings'] as Map<String, dynamic>?;
        final pushEnabled = settings?['pushNotifications'] as bool? ?? true;

        if (pushEnabled) {
          adminUsers.add(doc.id);
        }
      }

      return adminUsers;
    } catch (e) {
      _logger.warning('Error getting admin users', e);
      return [];
    }
  }

  /// Check if content has already been processed to avoid duplicate notifications
  bool _isAlreadyProcessed(String contentId) {
    // This would typically check a cache or local storage
    // For now, we'll use a simple in-memory set
    return _processedContentIds.contains(contentId);
  }

  final Set<String> _processedContentIds = {};

  /// Get real-time content statistics
  Stream<Map<String, dynamic>> getRealtimeStatistics() {
    return Stream<void>.periodic(const Duration(seconds: 30))
        .asyncMap((_) async {
      try {
        final pendingCaptures = await _firestore
            .collection('captures')
            .where('status', isEqualTo: 'pending')
            .count()
            .get();

        final flaggedPosts = await _firestore
            .collection('posts')
            .where('flagged', isEqualTo: true)
            .count()
            .get();

        final recentActions = await _firestore
            .collection('moderation_actions')
            .where('timestamp',
                isGreaterThan:
                    DateTime.now().subtract(const Duration(hours: 24)))
            .count()
            .get();

        return {
          'pendingCaptures': pendingCaptures.count,
          'flaggedPosts': flaggedPosts.count,
          'recentActions': recentActions.count,
          'timestamp': DateTime.now(),
        };
      } catch (e) {
        _logger.warning('Error getting realtime statistics', e);
        return <String, dynamic>{};
      }
    });
  }

  /// Record moderation action for audit trail
  Future<void> recordModerationAction({
    required String adminId,
    required String contentId,
    required ContentType contentType,
    required ModerationActionType actionType,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final action = ModerationAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        adminId: adminId,
        contentId: contentId,
        contentType: contentType,
        actionType: actionType,
        reason: reason,
        metadata: metadata,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('moderation_actions')
          .doc(action.id)
          .set(action.toJson());
    } catch (e) {
      _logger.warning('Error recording moderation action', e);
    }
  }

  /// Dispose of all listeners
  void dispose() {
    _pendingContentSubscription?.cancel();
    _flaggedContentSubscription?.cancel();
    _moderationActionsSubscription?.cancel();
    _pendingCountController.close();
    _newContentController.close();
    _moderationActionController.close();
  }
}

/// Moderation action for audit trail
class ModerationAction {
  final String id;
  final String adminId;
  final String contentId;
  final ContentType contentType;
  final ModerationActionType actionType;
  final String? reason;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  ModerationAction({
    required this.id,
    required this.adminId,
    required this.contentId,
    required this.contentType,
    required this.actionType,
    this.reason,
    this.metadata,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adminId': adminId,
      'contentId': contentId,
      'contentType': contentType.name,
      'actionType': actionType.name,
      'reason': reason,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static ModerationAction fromJson(Map<String, dynamic> json) {
    return ModerationAction(
      id: json['id'] as String,
      adminId: json['adminId'] as String,
      contentId: json['contentId'] as String,
      contentType: ContentType.fromString(json['contentType'] as String),
      actionType: ModerationActionType.values.firstWhere(
        (type) => type.name == json['actionType'] as String,
      ),
      reason: json['reason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Types of moderation actions
enum ModerationActionType {
  approve,
  reject,
  delete,
  flag,
  unflag,
  edit,
  bulkApprove,
  bulkReject,
  bulkDelete;

  String get displayName {
    switch (this) {
      case ModerationActionType.approve:
        return 'Approved';
      case ModerationActionType.reject:
        return 'Rejected';
      case ModerationActionType.delete:
        return 'Deleted';
      case ModerationActionType.flag:
        return 'Flagged';
      case ModerationActionType.unflag:
        return 'Unflagged';
      case ModerationActionType.edit:
        return 'Edited';
      case ModerationActionType.bulkApprove:
        return 'Bulk Approved';
      case ModerationActionType.bulkReject:
        return 'Bulk Rejected';
      case ModerationActionType.bulkDelete:
        return 'Bulk Deleted';
    }
  }
}

import 'package:artbeat_artwork/artbeat_artwork.dart'
    show ArtworkCleanupService;
import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

/// Basic Notifications Screen for ARTbeat
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        appBar: EnhancedUniversalHeader(
          title: 'Notifications',
          showLogo: false,
          showSearch: false,
          showBackButton: true,
        ),
        body: Center(child: Text('Please log in to view notifications.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await _notificationService.markAllNotificationsAsRead();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          // Debug button to create test notification (only in debug mode)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add test notification',
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await _notificationService.sendNotification(
                    userId: user.uid,
                    title: 'Test Notification',
                    message:
                        'This is a test notification to verify the system is working!',
                    type: NotificationType.achievement,
                    data: {'testData': 'This is test data'},
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification created'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                SizedBox(height: 40),
                Icon(Icons.notifications, size: 64, color: Colors.grey),
                SizedBox(height: 24),
                Center(
                  child: Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    'You’ll see updates, messages, and alerts here.',
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }
          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] is String
                  ? data['title'] as String
                  : 'Notification';
              final message = data['message'] is String
                  ? data['message'] as String
                  : (data['body'] is String ? data['body'] as String : '');
              final type = data['type'] is String ? data['type'] as String : '';
              final isRead = data['read'] == true;
              final ts = data['createdAt'] as Timestamp?;
              final date = ts?.toDate();
              final hasMessage = message.isNotEmpty;

              return Card(
                elevation: isRead ? 1 : 3,
                color: isRead
                    ? null
                    : Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.05),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead
                        ? Colors.grey[300]
                        : Theme.of(context).colorScheme.primary,
                    child: Icon(
                      _getNotificationIcon(type),
                      color: isRead ? Colors.grey[600] : Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasMessage)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            message,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      if (date != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _formatNotificationDate(date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: hasMessage,
                  onTap: () => _handleNotificationTap(doc.id, data),
                  trailing: !isRead
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
      // Debug functionality for admin users
      floatingActionButton: _isAdminUser(user.uid) && kDebugMode
          ? FloatingActionButton.extended(
              onPressed: _runImageCleanup,
              label: const Text('Fix Images'),
              icon: const Icon(Icons.build),
            )
          : null,
    );
  }

  /// Handle notification tap - mark as read and navigate if needed
  Future<void> _handleNotificationTap(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    // Mark notification as read if it's unread
    if (data['read'] != true) {
      await _notificationService.markNotificationAsRead(notificationId);
    }

    // Handle navigation based on notification type and data
    final type = data['type'] as String?;
    final notificationData = data['data'] as Map<String, dynamic>?;

    if (type != null && notificationData != null && mounted) {
      _navigateBasedOnNotificationType(type, notificationData);
    }
  }

  /// Navigate to appropriate screen based on notification type
  void _navigateBasedOnNotificationType(
    String type,
    Map<String, dynamic> data,
  ) {
    switch (type) {
      case 'achievement':
        // Navigate to achievements screen
        Navigator.pushNamed(context, '/profile/achievements');
        break;
      case 'galleryInvitation':
        // Navigate to gallery invitations
        Navigator.pushNamed(context, '/artist/invitations');
        break;
      case 'follow':
        // Navigate to follower's profile
        final userId = data['fromUserId'] as String?;
        if (userId != null) {
          Navigator.pushNamed(context, '/profile/$userId');
        }
        break;
      case 'like':
      case 'comment':
        // Navigate to the post or artwork
        final postId = data['postId'] as String?;
        final artworkId = data['artworkId'] as String?;
        if (postId != null) {
          Navigator.pushNamed(context, '/post/$postId');
        } else if (artworkId != null) {
          Navigator.pushNamed(context, '/artwork/$artworkId');
        }
        break;
      case 'message':
        // Navigate to chat
        final chatId = data['chatId'] as String?;
        if (chatId != null) {
          Navigator.pushNamed(context, '/chat/$chatId');
        }
        break;
      default:
        // For other types, just mark as read (already done above)
        break;
    }
  }

  /// Get appropriate icon for notification type
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'follow':
        return Icons.person_add;
      case 'message':
        return Icons.message;
      case 'mention':
        return Icons.alternate_email;
      case 'artworkPurchase':
        return Icons.shopping_cart;
      case 'subscription':
        return Icons.star;
      case 'subscriptionExpiration':
        return Icons.warning;
      case 'galleryInvitation':
        return Icons.business;
      case 'invitationResponse':
        return Icons.check_circle;
      case 'invitationCancelled':
        return Icons.cancel;
      case 'achievement':
        return Icons.emoji_events;
      default:
        return Icons.notifications;
    }
  }

  /// Format notification date in a user-friendly way
  String _formatNotificationDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return intl.DateFormat('MMM d, y').format(date);
    }
  }

  /// Check if user is admin - moved to database-based check for security
  bool _isAdminUser(String userId) {
    // TODO: Replace with proper database-based admin role check
    // For now, returning false for security - enable admin features via database
    return false;
  }

  /// Run image cleanup service
  Future<void> _runImageCleanup() async {
    final cleanupService = ArtworkCleanupService();

    // First check the specific problematic image
    await cleanupService.checkSpecificImage();

    // Then run general cleanup (dry run first to see what would be fixed)
    await cleanupService.cleanupBrokenArtworkImages();

    // Now actually fix the broken images
    await cleanupService.cleanupBrokenArtworkImages(dryRun: false);
  }
}

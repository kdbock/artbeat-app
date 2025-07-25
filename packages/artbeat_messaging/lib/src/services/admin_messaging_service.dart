import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';

/// Admin Messaging Service for real-time messaging analytics and management
///
/// This service provides admin-specific functionality for monitoring and managing
/// the messaging system, including real-time statistics, user activity tracking,
/// and moderation tools.
class AdminMessagingService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AdminMessagingService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Get real-time messaging statistics
  Future<Map<String, dynamic>> getMessagingStats() async {
    try {
      // Get total messages count
      final messagesQuery = await _firestore
          .collectionGroup('messages')
          .count()
          .get();
      final totalMessages = messagesQuery.count ?? 0;

      // Get total chats count
      final chatsQuery = await _firestore.collection('chats').count().get();
      final totalChats = chatsQuery.count ?? 0;

      // Get active users (users with recent activity)
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      // Get users active in last 24 hours
      final dailyActiveQuery = await _firestore
          .collection('users')
          .where('lastSeen', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .count()
          .get();
      final dailyActiveUsers = dailyActiveQuery.count ?? 0;

      // Get users active in last week
      final weeklyActiveQuery = await _firestore
          .collection('users')
          .where('lastSeen', isGreaterThan: Timestamp.fromDate(oneWeekAgo))
          .count()
          .get();
      final weeklyActiveUsers = weeklyActiveQuery.count ?? 0;

      // Get currently online users
      final onlineUsersQuery = await _firestore
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .count()
          .get();
      final onlineUsers = onlineUsersQuery.count ?? 0;

      // Get reported messages count
      final reportedQuery = await _firestore
          .collection('reports')
          .where('type', isEqualTo: 'message')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      final reportedMessages = reportedQuery.count ?? 0;

      // Get blocked users count
      final blockedQuery = await _firestore
          .collection('users')
          .where('isBlocked', isEqualTo: true)
          .count()
          .get();
      final blockedUsers = blockedQuery.count ?? 0;

      // Get messages sent today
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayMessagesQuery = await _firestore
          .collectionGroup('messages')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(todayStart))
          .count()
          .get();
      final messagesSentToday = todayMessagesQuery.count ?? 0;

      // Get group chats count
      final groupChatsQuery = await _firestore
          .collection('chats')
          .where('isGroup', isEqualTo: true)
          .count()
          .get();
      final groupChats = groupChatsQuery.count ?? 0;

      // Calculate growth (simplified - you might want to store historical data)
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));
      final yesterdayMessagesQuery = await _firestore
          .collectionGroup('messages')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterdayStart))
          .where('timestamp', isLessThan: Timestamp.fromDate(todayStart))
          .count()
          .get();
      final yesterdayMessages = yesterdayMessagesQuery.count ?? 1;

      final growthRate = yesterdayMessages > 0
          ? ((messagesSentToday - yesterdayMessages) / yesterdayMessages * 100)
                .round()
          : 0;

      return {
        'totalMessages': totalMessages,
        'totalChats': totalChats,
        'activeUsers': dailyActiveUsers,
        'onlineNow': onlineUsers,
        'reportedMessages': reportedMessages,
        'blockedUsers': blockedUsers,
        'dailyGrowth': '${growthRate > 0 ? '+' : ''}$growthRate%',
        'weeklyActive': weeklyActiveUsers,
        'messagesSentToday': messagesSentToday,
        'peakHour': await _getPeakHour(),
        'topEmoji': await _getTopEmoji(),
        'groupChats': groupChats,
        'averageResponseTime': await _getAverageResponseTime(),
      };
    } catch (e) {
      debugPrint('Error getting messaging stats: $e');
      rethrow;
    }
  }

  /// Get recent activity for admin monitoring
  Stream<List<Map<String, dynamic>>> getRecentActivityStream() {
    return _firestore
        .collection('admin_activity')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .handleError((error) {
          debugPrint('Error in getRecentActivityStream: $error');
          return const Stream.empty();
        })
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            try {
              final data = doc.data();
              final type = data['type'] as String? ?? 'unknown';
              final severity = data['severity'] as String? ?? 'low';

              return {
                'id': doc.id,
                'type': type,
                'user': data['user'] ?? 'System',
                'action': data['action'] ?? 'Unknown action',
                'timestamp': _formatTimestamp(data['timestamp'] as Timestamp?),
                'severity': severity,
                'icon': _getIconForActivityType(type),
                'color': _getColorForSeverity(severity),
              };
            } catch (e) {
              debugPrint('Error processing activity document ${doc.id}: $e');
              // Return a safe fallback activity
              return {
                'id': doc.id,
                'type': 'unknown',
                'user': 'System',
                'action': 'Unknown action',
                'timestamp': 'Unknown time',
                'severity': 'low',
                'icon': Icons.info,
                'color': Colors.grey,
              };
            }
          }).toList(),
        );
  }

  /// Get online users with real data
  Stream<List<Map<String, dynamic>>> getOnlineUsersStream() {
    return _firestore
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .orderBy('lastSeen', descending: true)
        .limit(50)
        .snapshots()
        .handleError((error) {
          debugPrint('Error in getOnlineUsersStream: $error');
          return const Stream.empty();
        })
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            try {
              final data = doc.data();
              return {
                'id': doc.id,
                'name':
                    data['displayName'] ??
                    data['fullName'] ??
                    data['username'] ??
                    'Unknown',
                'avatar':
                    data['photoUrl'] ??
                    data['profileImageUrl'] ??
                    'https://i.pravatar.cc/150?u=${doc.id}',
                'isOnline': data['isOnline'] ?? false,
                'status': _getUserStatus(data),
                'lastSeen': _formatTimestamp(data['lastSeen'] as Timestamp?),
                'role': data['role'] ?? 'User',
              };
            } catch (e) {
              debugPrint('Error processing user document ${doc.id}: $e');
              // Return a safe fallback user
              return {
                'id': doc.id,
                'name': 'Unknown User',
                'avatar': 'https://i.pravatar.cc/150?u=${doc.id}',
                'isOnline': false,
                'status': 'Unknown',
                'lastSeen': 'Unknown',
                'role': 'User',
              };
            }
          }).toList(),
        );
  }

  /// Get top conversations by message count
  Future<List<Map<String, dynamic>>> getTopConversations() async {
    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .orderBy('updatedAt', descending: true)
          .limit(10)
          .get();

      final conversations = <Map<String, dynamic>>[];

      for (final doc in chatsSnapshot.docs) {
        final chat = ChatModel.fromFirestore(doc);

        // Get message count for this chat
        final messagesCount = await _firestore
            .collection('chats')
            .doc(chat.id)
            .collection('messages')
            .count()
            .get();

        final participants = <String>[];
        final avatars = <String>[];

        if (chat.isGroup) {
          participants.add(chat.groupName ?? 'Group Chat');
          avatars.add(
            chat.groupImage ?? 'https://i.pravatar.cc/150?u=group${chat.id}',
          );
        } else {
          // Get participant names for direct chats
          for (final participantId in chat.participantIds) {
            final userDoc = await _firestore
                .collection('users')
                .doc(participantId)
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data();
              if (userData != null) {
                participants.add(
                  (userData['displayName'] ?? userData['fullName'] ?? 'Unknown')
                      as String,
                );
                avatars.add(
                  (userData['photoUrl'] ??
                          'https://i.pravatar.cc/150?u=$participantId')
                      as String,
                );
              } else {
                participants.add('Unknown');
                avatars.add('https://i.pravatar.cc/150?u=$participantId');
              }
            }
          }
        }

        conversations.add({
          'participants': participants,
          'messageCount': messagesCount.count ?? 0,
          'lastActive': _formatTimestamp(Timestamp.fromDate(chat.updatedAt)),
          'type': chat.isGroup ? 'group' : 'direct',
          'avatars': avatars,
          'memberCount': chat.isGroup ? chat.participantIds.length : null,
        });
      }

      // Sort by message count
      conversations.sort(
        (a, b) =>
            (b['messageCount'] as int).compareTo(a['messageCount'] as int),
      );

      return conversations;
    } catch (e) {
      debugPrint('Error getting top conversations: $e');
      return [];
    }
  }

  /// Send broadcast message to all active users
  Future<void> sendBroadcastMessage(String message) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Admin not authenticated');

      // Get all active users
      final usersSnapshot = await _firestore
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      final timestamp = DateTime.now();

      // Create broadcast message document
      final broadcastRef = _firestore.collection('broadcasts').doc();
      batch.set(broadcastRef, {
        'message': message,
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Admin',
        'timestamp': Timestamp.fromDate(timestamp),
        'recipientCount': usersSnapshot.docs.length,
      });

      // Log admin activity
      final activityRef = _firestore.collection('admin_activity').doc();
      batch.set(activityRef, {
        'type': 'broadcast',
        'user': currentUser.displayName ?? 'Admin',
        'action':
            'Sent broadcast message to ${usersSnapshot.docs.length} users',
        'timestamp': Timestamp.fromDate(timestamp),
        'severity': 'low',
      });

      await batch.commit();

      // Trigger notifications (you might want to use Cloud Functions for this)
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending broadcast message: $e');
      rethrow;
    }
  }

  /// Block/unblock a user
  Future<void> toggleUserBlock(String userId, bool block) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBlocked': block,
        'blockedAt': block ? Timestamp.now() : null,
      });

      // Log admin activity
      final currentUser = _auth.currentUser;
      await _firestore.collection('admin_activity').add({
        'type': 'moderation',
        'user': currentUser?.displayName ?? 'Admin',
        'action': '${block ? 'Blocked' : 'Unblocked'} user $userId',
        'timestamp': Timestamp.now(),
        'severity': 'medium',
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling user block: $e');
      rethrow;
    }
  }

  /// Helper methods
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  String _getUserStatus(Map<String, dynamic> userData) {
    final isOnline = userData['isOnline'] ?? false;
    final lastSeen = userData['lastSeen'] as Timestamp?;

    if (!(isOnline as bool)) return 'Offline';

    if (lastSeen != null) {
      final difference = DateTime.now().difference(lastSeen.toDate());
      if (difference.inMinutes < 5) {
        return 'Active';
      } else if (difference.inMinutes < 30) {
        return 'Away';
      }
    }

    return 'Online';
  }

  IconData _getIconForActivityType(String? type) {
    switch (type) {
      case 'report':
        return Icons.report_problem;
      case 'block':
        return Icons.block;
      case 'milestone':
        return Icons.celebration;
      case 'feature':
        return Icons.new_releases;
      case 'user':
        return Icons.person_add;
      case 'broadcast':
        return Icons.campaign;
      case 'moderation':
        return Icons.admin_panel_settings;
      default:
        return Icons.info;
    }
  }

  Color _getColorForSeverity(String? severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return Colors.green;
    }
  }

  Future<String> _getPeakHour() async {
    // This would require more complex analytics
    // For now, return a placeholder
    return '2-3 PM';
  }

  Future<String> _getTopEmoji() async {
    // This would require analyzing message content
    // For now, return a placeholder
    return '🎨';
  }

  Future<String> _getAverageResponseTime() async {
    // This would require analyzing conversation patterns
    // For now, return a placeholder
    return '2.3 min';
  }
}

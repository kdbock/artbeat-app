import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Consolidated Admin Service for ARTbeat
///
/// This service consolidates admin functions from across all modules into a single
/// centralized service for better maintainability and consistency.
class ConsolidatedAdminService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ConsolidatedAdminService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ==========================================
  // MESSAGING ADMINISTRATION
  // ==========================================

  /// Get comprehensive messaging statistics
  Future<Map<String, dynamic>> getMessagingStats() async {
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      // Get total messages count across all chats
      final messagesQuery =
          await _firestore.collectionGroup('messages').count().get();
      final totalMessages = messagesQuery.count ?? 0;

      // Get total active chats
      final chatsQuery = await _firestore
          .collection('chats')
          .where('lastMessage', isGreaterThan: Timestamp.fromDate(oneWeekAgo))
          .count()
          .get();
      final activeChats = chatsQuery.count ?? 0;

      // Get daily active messaging users
      final dailyActiveQuery = await _firestore
          .collection('users')
          .where('lastMessageActivity',
              isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .count()
          .get();
      final dailyActiveUsers = dailyActiveQuery.count ?? 0;

      // Get messages sent today
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayMessagesQuery = await _firestore
          .collectionGroup('messages')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(todayStart))
          .count()
          .get();
      final todayMessages = todayMessagesQuery.count ?? 0;

      return {
        'totalMessages': totalMessages,
        'activeChats': activeChats,
        'dailyActiveUsers': dailyActiveUsers,
        'todayMessages': todayMessages,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting messaging stats: $e');
      return {
        'totalMessages': 0,
        'activeChats': 0,
        'dailyActiveUsers': 0,
        'todayMessages': 0,
        'error': e.toString(),
      };
    }
  }

  /// Get flagged messages for review
  Future<List<Map<String, dynamic>>> getFlaggedMessages(
      {int limit = 50}) async {
    try {
      final query = await _firestore
          .collectionGroup('messages')
          .where('flagged', isEqualTo: true)
          .where('moderationStatus', isEqualTo: 'pending')
          .orderBy('flaggedAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'messageId': doc.id,
          'chatPath': doc.reference.parent.parent?.path,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting flagged messages: $e');
      return [];
    }
  }

  /// Moderate a message (approve/reject)
  Future<bool> moderateMessage(String chatId, String messageId, bool approve,
      {String? reason}) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'moderationStatus': approve ? 'approved' : 'rejected',
        'moderatedAt': FieldValue.serverTimestamp(),
        'moderatedBy': _auth.currentUser?.uid,
        'moderationReason': reason,
        'flagged': false,
      });

      if (!approve) {
        // Hide rejected messages
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .update({'hidden': true});
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error moderating message: $e');
      return false;
    }
  }

  // ==========================================
  // CONTENT MODERATION
  // ==========================================

  /// Get content pending moderation (captures, posts, artwork)
  Future<Map<String, List<Map<String, dynamic>>>> getPendingContent() async {
    try {
      // Get pending captures
      final capturesQuery = await _firestore
          .collection('captures')
          .where('moderationStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final pendingCaptures = capturesQuery.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id, 'type': 'capture'};
      }).toList();

      // Get pending posts
      final postsQuery = await _firestore
          .collection('posts')
          .where('moderationStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final pendingPosts = postsQuery.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id, 'type': 'post'};
      }).toList();

      // Get pending artwork
      final artworkQuery = await _firestore
          .collection('artwork')
          .where('moderationStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final pendingArtwork = artworkQuery.docs.map((doc) {
        final data = doc.data();
        return {...data, 'id': doc.id, 'type': 'artwork'};
      }).toList();

      return {
        'captures': pendingCaptures,
        'posts': pendingPosts,
        'artwork': pendingArtwork,
      };
    } catch (e) {
      debugPrint('Error getting pending content: $e');
      return {
        'captures': [],
        'posts': [],
        'artwork': [],
      };
    }
  }

  /// Moderate content item
  Future<bool> moderateContent(
      String contentType, String contentId, bool approve,
      {String? reason}) async {
    try {
      final collection = contentType == 'capture'
          ? 'captures'
          : contentType == 'post'
              ? 'posts'
              : 'artwork';

      await _firestore.collection(collection).doc(contentId).update({
        'moderationStatus': approve ? 'approved' : 'rejected',
        'moderatedAt': FieldValue.serverTimestamp(),
        'moderatedBy': _auth.currentUser?.uid,
        'moderationReason': reason,
      });

      if (!approve) {
        // Hide rejected content
        await _firestore.collection(collection).doc(contentId).update({
          'hidden': true,
          'visibility': 'private',
        });
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error moderating content: $e');
      return false;
    }
  }

  // ==========================================
  // USER MANAGEMENT
  // ==========================================

  /// Get users requiring admin attention (flagged, reported, etc.)
  Future<List<Map<String, dynamic>>> getFlaggedUsers({int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('flagged', isEqualTo: true)
          .orderBy('flaggedAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {...data, 'userId': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('Error getting flagged users: $e');
      return [];
    }
  }

  /// Suspend or warn a user
  Future<bool> moderateUser(String userId, String action,
      {String? reason, Duration? duration}) async {
    try {
      final updates = <String, dynamic>{
        'moderationStatus': action,
        'moderatedAt': FieldValue.serverTimestamp(),
        'moderatedBy': _auth.currentUser?.uid,
        'moderationReason': reason,
        'flagged': false,
      };

      if (action == 'suspended' && duration != null) {
        updates['suspendedUntil'] =
            Timestamp.fromDate(DateTime.now().add(duration));
      }

      if (action == 'warned') {
        updates['warnings'] = FieldValue.increment(1);
        updates['lastWarningAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('users').doc(userId).update(updates);

      // Create moderation log entry
      await _firestore.collection('moderationLogs').add({
        'targetType': 'user',
        'targetId': userId,
        'action': action,
        'reason': reason,
        'moderatorId': _auth.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'duration': duration?.inHours,
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error moderating user: $e');
      return false;
    }
  }

  // ==========================================
  // ANALYTICS & REPORTING
  // ==========================================

  /// Get comprehensive admin dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Get user metrics
      final totalUsersQuery =
          await _firestore.collection('users').count().get();
      final totalUsers = totalUsersQuery.count ?? 0;

      final newUsersQuery = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(todayStart))
          .count()
          .get();
      final newUsers = newUsersQuery.count ?? 0;

      // Get content metrics
      final totalContentQuery =
          await _firestore.collection('captures').count().get();
      final totalContent = totalContentQuery.count ?? 0;

      final pendingModerationQuery = await _firestore
          .collectionGroup('captures')
          .where('moderationStatus', isEqualTo: 'pending')
          .count()
          .get();
      final pendingModeration = pendingModerationQuery.count ?? 0;

      // Get activity metrics
      final activeUsersQuery = await _firestore
          .collection('users')
          .where('lastSeen', isGreaterThan: Timestamp.fromDate(todayStart))
          .count()
          .get();
      final activeUsers = activeUsersQuery.count ?? 0;

      return {
        'users': {
          'total': totalUsers,
          'newToday': newUsers,
          'activeToday': activeUsers,
        },
        'content': {
          'total': totalContent,
          'pendingModeration': pendingModeration,
        },
        'system': {
          'lastUpdated': DateTime.now().toIso8601String(),
          'uptime': 'N/A', // Would be calculated from server start time
        }
      };
    } catch (e) {
      debugPrint('Error getting dashboard stats: $e');
      return {
        'users': {'total': 0, 'newToday': 0, 'activeToday': 0},
        'content': {'total': 0, 'pendingModeration': 0},
        'system': {
          'lastUpdated': DateTime.now().toIso8601String(),
          'uptime': 'Error'
        },
        'error': e.toString(),
      };
    }
  }

  // ==========================================
  // AD MANAGEMENT
  // ==========================================

  /// Get ad refund requests pending admin approval
  Future<List<Map<String, dynamic>>> getPendingRefundRequests() async {
    try {
      final query = await _firestore
          .collection('adRefundRequests')
          .where('status', isEqualTo: 'pending')
          .orderBy('requestedAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {...data, 'requestId': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('Error getting refund requests: $e');
      return [];
    }
  }

  /// Process ad refund request
  Future<bool> processRefundRequest(String requestId, bool approve,
      {String? reason}) async {
    try {
      final status = approve ? 'approved' : 'rejected';

      await _firestore.collection('adRefundRequests').doc(requestId).update({
        'status': status,
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': _auth.currentUser?.uid,
        'adminReason': reason,
      });

      if (approve) {
        // Here would integrate with payment processor to issue refund
        // For now, just mark as processed
        debugPrint('Refund approved for request: $requestId');
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error processing refund request: $e');
      return false;
    }
  }

  // ==========================================
  // SYSTEM MAINTENANCE
  // ==========================================

  /// Get moderation activity log
  Future<List<Map<String, dynamic>>> getModerationLog({int limit = 100}) async {
    try {
      final query = await _firestore
          .collection('moderationLogs')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {...data, 'logId': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('Error getting moderation log: $e');
      return [];
    }
  }

  /// Clean up old data (placeholder for maintenance tasks)
  Future<bool> performMaintenanceTasks() async {
    try {
      // Example: Clean up old flagged content that was resolved
      final oldFlaggedQuery = await _firestore
          .collectionGroup('messages')
          .where('moderationStatus', whereIn: ['approved', 'rejected'])
          .where('moderatedAt',
              isLessThan: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(days: 30))))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldFlaggedQuery.docs) {
        batch.update(doc.reference, {'flagged': false});
      }

      await batch.commit();

      debugPrint('Maintenance tasks completed');
      return true;
    } catch (e) {
      debugPrint('Error performing maintenance: $e');
      return false;
    }
  }

  /// Get current admin user info
  User? get currentAdmin => _auth.currentUser;

  /// Check if current user has admin privileges
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      return userData?['role'] == 'admin' || userData?['isAdmin'] == true;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  // ==========================================
  // SYSTEM MONITORING METHODS
  // ==========================================

  /// Get comprehensive system metrics for monitoring dashboard
  Future<Map<String, dynamic>> getSystemMetrics() async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final oneDayAgo = now.subtract(const Duration(days: 1));

      // Simulate system metrics (in production, these would come from actual monitoring)
      final random = DateTime.now().millisecondsSinceEpoch % 100;

      // Get active users count
      final activeUsersQuery = await _firestore
          .collection('users')
          .where('lastActivity', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .count()
          .get();
      final activeUsers = activeUsersQuery.count ?? 0;

      // Get peak users today
      final peakUsersQuery = await _firestore
          .collection('users')
          .where('lastActivity', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .count()
          .get();
      final peakUsers = peakUsersQuery.count ?? 0;

      return {
        'systemHealth': random > 20 ? 'healthy' : 'warning',
        'cpuUsage': 45.0 + (random % 30), // Simulate 45-75% CPU usage
        'memoryUsage': 60.0 + (random % 25), // Simulate 60-85% memory usage
        'networkThroughput':
            150.0 + (random % 100), // Simulate network throughput
        'responseTime':
            200 + (random % 300), // Simulate 200-500ms response time
        'activeUsers': activeUsers,
        'onlineUsers': (activeUsers * 0.7).round(), // Estimate online users
        'peakUsers': peakUsers,
        'avgSession': 12.5 + (random % 10), // Average session time in minutes
        'cpuTrend': (random % 3) - 1, // -1, 0, or 1 for trend
        'memoryTrend': (random % 3) - 1,
        'usersTrend': (random % 3) - 1,
        'responseTrend': (random % 3) - 1,
        'lastUpdated': now.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting system metrics: $e');
      final now = DateTime.now();
      return {
        'systemHealth': 'error',
        'cpuUsage': 0.0,
        'memoryUsage': 0.0,
        'networkThroughput': 0.0,
        'responseTime': 0,
        'activeUsers': 0,
        'onlineUsers': 0,
        'peakUsers': 0,
        'avgSession': 0.0,
        'cpuTrend': 0,
        'memoryTrend': 0,
        'usersTrend': 0,
        'responseTrend': 0,
        'lastUpdated': now.toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  /// Get performance metrics for monitoring
  Future<List<Map<String, dynamic>>> getPerformanceMetrics() async {
    try {
      // Simulate performance metrics (in production, these would come from actual monitoring)
      final random = DateTime.now().millisecondsSinceEpoch % 100;

      return [
        {
          'name': 'Database Response Time',
          'current': '${150 + (random % 100)}ms',
          'average': '${180 + (random % 50)}ms',
          'peak': '${300 + (random % 200)}ms',
          'status': random > 30 ? 'healthy' : 'warning',
        },
        {
          'name': 'API Throughput',
          'current': '${500 + (random % 200)} req/min',
          'average': '${450 + (random % 150)} req/min',
          'peak': '${800 + (random % 300)} req/min',
          'status': random > 20 ? 'healthy' : 'warning',
        },
        {
          'name': 'Storage Usage',
          'current': '${65 + (random % 20)}%',
          'average': '${60 + (random % 15)}%',
          'peak': '${85 + (random % 10)}%',
          'status': random > 25 ? 'healthy' : 'warning',
        },
        {
          'name': 'Cache Hit Rate',
          'current': '${85 + (random % 10)}%',
          'average': '${88 + (random % 8)}%',
          'peak': '${95 + (random % 5)}%',
          'status': 'healthy',
        },
        {
          'name': 'Error Rate',
          'current': '${0.1 + (random % 5) / 10}%',
          'average': '${0.2 + (random % 3) / 10}%',
          'peak': '${1.0 + (random % 10) / 10}%',
          'status': random > 40 ? 'healthy' : 'warning',
        },
      ];
    } catch (e) {
      debugPrint('Error getting performance metrics: $e');
      return [];
    }
  }

  /// Get system alerts
  Future<List<Map<String, dynamic>>> getSystemAlerts() async {
    try {
      // Get actual alerts from Firestore (if they exist)
      final alertsQuery = await _firestore
          .collection('system_alerts')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      final alerts = <Map<String, dynamic>>[];

      for (final doc in alertsQuery.docs) {
        final data = doc.data();
        alerts.add({
          'id': doc.id,
          'message': data['message'] ?? 'Unknown alert',
          'severity': data['severity'] ?? 'info',
          'timestamp': data['timestamp']?.toDate().toString() ?? 'Unknown',
          'details': data['details'] ?? 'No details available',
          'status': data['status'] ?? 'active',
          'source': data['source'] ?? 'system',
        });
      }

      // If no alerts in database, simulate some for demo
      if (alerts.isEmpty) {
        final now = DateTime.now();
        final random = now.millisecondsSinceEpoch % 100;

        if (random > 70) {
          alerts.add({
            'id': 'alert_1',
            'message': 'High CPU usage detected',
            'severity': 'warning',
            'timestamp': now.subtract(const Duration(minutes: 5)).toString(),
            'details': 'CPU usage has been above 80% for the last 5 minutes',
            'status': 'active',
            'source': 'system_monitor',
          });
        }

        if (random > 85) {
          alerts.add({
            'id': 'alert_2',
            'message': 'Database connection timeout',
            'severity': 'critical',
            'timestamp': now.subtract(const Duration(minutes: 2)).toString(),
            'details': 'Multiple database connection timeouts detected',
            'status': 'active',
            'source': 'database_monitor',
          });
        }
      }

      return alerts;
    } catch (e) {
      debugPrint('Error getting system alerts: $e');
      return [];
    }
  }

  /// Get active users for monitoring
  Future<List<Map<String, dynamic>>> getActiveUsers() async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      final activeUsersQuery = await _firestore
          .collection('users')
          .where('lastActivity', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .orderBy('lastActivity', descending: true)
          .limit(50)
          .get();

      final activeUsers = <Map<String, dynamic>>[];

      for (final doc in activeUsersQuery.docs) {
        final data = doc.data();
        final lastActivity =
            (data['lastActivity'] as Timestamp?)?.toDate() ?? now;
        final sessionTime = now.difference(lastActivity).inMinutes;

        activeUsers.add({
          'id': doc.id,
          'name': data['fullName'] ?? data['displayName'] ?? 'Unknown User',
          'email': data['email'] ?? 'No email',
          'status': sessionTime < 5 ? 'online' : 'away',
          'location': data['location'] ?? 'Unknown',
          'sessionTime': '${sessionTime}m',
          'actions': data['todayActions'] ?? 0,
          'lastActivity': lastActivity.toString(),
          'userType': data['userType'] ?? 'regular',
        });
      }

      return activeUsers;
    } catch (e) {
      debugPrint('Error getting active users: $e');
      return [];
    }
  }

  /// Get server status information
  Future<List<Map<String, dynamic>>> getServerStatus() async {
    try {
      // Simulate server status (in production, this would come from actual server monitoring)
      final random = DateTime.now().millisecondsSinceEpoch % 100;

      return [
        {
          'name': 'Web Server (Primary)',
          'status': random > 10 ? 'healthy' : 'warning',
          'location': 'US-East-1',
          'load': 45 + (random % 30),
          'responseTime': 150 + (random % 100),
          'uptime': '99.9%',
        },
        {
          'name': 'Database Server',
          'status': random > 15 ? 'healthy' : 'warning',
          'location': 'US-East-1',
          'load': 60 + (random % 25),
          'responseTime': 80 + (random % 50),
          'uptime': '99.8%',
        },
        {
          'name': 'File Storage',
          'status': random > 5 ? 'healthy' : 'error',
          'location': 'US-West-2',
          'load': 35 + (random % 40),
          'responseTime': 200 + (random % 150),
          'uptime': '99.7%',
        },
        {
          'name': 'CDN',
          'status': 'healthy',
          'location': 'Global',
          'load': 25 + (random % 20),
          'responseTime': 50 + (random % 30),
          'uptime': '99.9%',
        },
      ];
    } catch (e) {
      debugPrint('Error getting server status: $e');
      return [];
    }
  }

  /// Create system alert
  Future<void> createSystemAlert({
    required String message,
    required String severity,
    String? details,
    String? source,
  }) async {
    try {
      await _firestore.collection('system_alerts').add({
        'message': message,
        'severity': severity,
        'details': details,
        'source': source ?? 'admin',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'createdBy': _auth.currentUser?.uid,
      });
    } catch (e) {
      debugPrint('Error creating system alert: $e');
      rethrow;
    }
  }

  /// Resolve system alert
  Future<void> resolveSystemAlert(String alertId) async {
    try {
      await _firestore.collection('system_alerts').doc(alertId).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': _auth.currentUser?.uid,
      });
    } catch (e) {
      debugPrint('Error resolving system alert: $e');
      rethrow;
    }
  }

  /// Get system health summary
  Future<Map<String, dynamic>> getSystemHealthSummary() async {
    try {
      final metrics = await getSystemMetrics();
      final alerts = await getSystemAlerts();
      final servers = await getServerStatus();

      final criticalAlerts =
          alerts.where((a) => a['severity'] == 'critical').length;
      final warningAlerts =
          alerts.where((a) => a['severity'] == 'warning').length;
      final healthyServers =
          servers.where((s) => s['status'] == 'healthy').length;

      String overallHealth = 'healthy';
      if (criticalAlerts > 0) {
        overallHealth = 'critical';
      } else if (warningAlerts > 2 || healthyServers < servers.length * 0.8) {
        overallHealth = 'warning';
      }

      return {
        'overallHealth': overallHealth,
        'criticalAlerts': criticalAlerts,
        'warningAlerts': warningAlerts,
        'healthyServers': healthyServers,
        'totalServers': servers.length,
        'systemUptime': '99.8%',
        'lastCheck': DateTime.now().toIso8601String(),
        'metrics': metrics,
      };
    } catch (e) {
      debugPrint('Error getting system health summary: $e');
      return {
        'overallHealth': 'error',
        'criticalAlerts': 0,
        'warningAlerts': 0,
        'healthyServers': 0,
        'totalServers': 0,
        'systemUptime': '0%',
        'lastCheck': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }
}

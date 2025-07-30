import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Service to handle user presence (online/offline status)
class PresenceService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  Timer? _presenceTimer;
  StreamSubscription<User?>? _authSubscription;
  bool _isOnline = false;

  PresenceService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance {
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _startPresenceUpdates();
      } else {
        _stopPresenceUpdates();
      }
    });
  }

  /// Start updating user presence
  void _startPresenceUpdates() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    debugPrint('PresenceService: Starting presence updates for user $userId');

    // Set user as online immediately
    _setUserOnline(userId);

    // Update presence every 30 seconds
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _setUserOnline(userId);
    });

    _isOnline = true;
  }

  /// Stop updating user presence
  void _stopPresenceUpdates() {
    final userId = _auth.currentUser?.uid;
    if (userId != null && _isOnline) {
      _setUserOffline(userId);
    }

    _presenceTimer?.cancel();
    _presenceTimer = null;
    _isOnline = false;

    debugPrint('PresenceService: Stopped presence updates');
  }

  /// Set user as online
  Future<void> _setUserOnline(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': true,
        'lastSeen': Timestamp.now(),
        'lastActive': Timestamp.now(),
      });

      debugPrint('PresenceService: Set user $userId as online');
    } catch (e) {
      debugPrint('PresenceService: Error setting user online: $e');
    }
  }

  /// Set user as offline
  Future<void> _setUserOffline(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': false,
        'lastSeen': Timestamp.now(),
        'lastActive': Timestamp.now(),
      });

      debugPrint('PresenceService: Set user $userId as offline');
    } catch (e) {
      debugPrint('PresenceService: Error setting user offline: $e');
    }
  }

  /// Manually update user activity (call when user interacts with the app)
  Future<void> updateActivity() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': true,
        'lastSeen': Timestamp.now(),
        'lastActive': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('PresenceService: Error updating activity: $e');
    }
  }

  /// Get online users stream
  Stream<List<Map<String, dynamic>>> getOnlineUsersStream() {
    return _firestore
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .orderBy('lastSeen', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          final currentUserId = _auth.currentUser?.uid;
          return snapshot.docs
              .where((doc) => doc.id != currentUserId) // Exclude current user
              .map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'name':
                      data['displayName'] ??
                      data['fullName'] ??
                      data['username'] ??
                      'Unknown User',
                  'avatar': data['photoUrl'] ?? data['profileImageUrl'],
                  'isOnline': data['isOnline'] ?? false,
                  'lastSeen':
                      (data['lastSeen'] as Timestamp?)?.toDate() ??
                      DateTime.now(),
                  'role': data['role'] ?? 'User',
                };
              })
              .toList();
        });
  }

  /// Check if a specific user is online
  Future<bool> isUserOnline(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final isOnline = data['isOnline'] as bool? ?? false;
      final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();

      // Consider user offline if last seen was more than 5 minutes ago
      if (lastSeen != null) {
        final now = DateTime.now();
        final difference = now.difference(lastSeen);
        if (difference.inMinutes > 5) {
          return false;
        }
      }

      return isOnline;
    } catch (e) {
      debugPrint('PresenceService: Error checking if user is online: $e');
      return false;
    }
  }

  /// Get user's last seen time
  Future<DateTime?> getUserLastSeen(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return (data['lastSeen'] as Timestamp?)?.toDate() ??
          (data['lastActive'] as Timestamp?)?.toDate();
    } catch (e) {
      debugPrint('PresenceService: Error getting user last seen: $e');
      return null;
    }
  }

  /// Dispose the service
  void dispose() {
    debugPrint('PresenceService: Disposing');
    _stopPresenceUpdates();
    _authSubscription?.cancel();
  }
}

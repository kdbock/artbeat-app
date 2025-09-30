import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class CommunityProvider extends ChangeNotifier {
  int _unreadCount = 0;
  User? _currentUser;
  Stream<int>? _unreadStream;
  StreamSubscription<int>? _unreadSubscription;
  StreamSubscription<User?>? _authSubscription;
  bool _mounted = true;

  int get unreadCount => _unreadCount;
  bool get mounted => _mounted;

  CommunityProvider() {
    _initializeUser();
  }

  void _initializeUser() {
    _currentUser = FirebaseAuth.instance.currentUser;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!_mounted) return; // Check if still mounted
      _currentUser = user;
      if (user != null) {
        _listenToUnreadCount();
      } else {
        _unreadSubscription?.cancel();
        _unreadCount = 0;
        notifyListeners();
      }
    });

    if (_currentUser != null) {
      _listenToUnreadCount();
    }
  }

  void _listenToUnreadCount() {
    if (_currentUser == null) return;

    // Cancel existing subscription
    _unreadSubscription?.cancel();

    _unreadStream = _getUnreadPostsCount(_currentUser!.uid);
    _unreadSubscription = _unreadStream!.listen(
      (count) {
        if (!mounted) return; // Check if still mounted
        _unreadCount = count;
        notifyListeners();
      },
      onError: (Object error) {
        AppLogger.error('Error listening to unread count: $error');
        if (!mounted) return; // Check if still mounted
        _unreadCount = 0;
        notifyListeners();
      },
    );
  }

  Stream<int> _getUnreadPostsCount(String userId) {
    try {
      return FirebaseFirestore.instance
          .collection('user_activity')
          .doc(userId)
          .snapshots()
          .asyncMap((doc) async {
            if (!doc.exists) {
              // If no user activity doc exists, return a reasonable default
              return 3; // Show a small number to indicate there might be new content
            }

            final data = doc.data()!;
            final lastSeenTimestamp = data['lastCommunityVisit'] as Timestamp?;

            if (lastSeenTimestamp == null) {
              // If never visited, return a reasonable default
              return 3;
            }

            // For now, return 0 to avoid the index requirement
            // TODO(community): Implement proper unread count once the required index is created
            // The required index is: posts collection with fields [isPublic, createdAt]
            return 0;
          });
    } catch (e) {
      AppLogger.error('Error getting unread posts count: $e');
      return Stream.value(0);
    }
  }

  Future<void> markCommunityAsVisited() async {
    if (_currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('user_activity')
          .doc(_currentUser!.uid)
          .set({
            'lastCommunityVisit': FieldValue.serverTimestamp(),
            'userId': _currentUser!.uid,
          }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('Error marking community as visited: $e');
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _unreadSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}

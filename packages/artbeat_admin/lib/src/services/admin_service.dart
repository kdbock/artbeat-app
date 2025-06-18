import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/admin_user_model.dart';

/// Service class for handling administrator operations
class AdminService extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  User? _currentAdmin;
  bool _isInitialized = false;

  AdminService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Initialize the admin service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _currentAdmin = user;
      notifyListeners();
    });

    _isInitialized = true;
  }

  /// Get the current admin user
  User? get currentAdmin => _currentAdmin;

  /// Check if the current user has admin privileges
  Future<bool> hasAdminPrivileges() async {
    if (_currentAdmin == null) return false;

    try {
      final userDoc =
          await _firestore.collection('users').doc(_currentAdmin!.uid).get();

      if (!userDoc.exists) return false;

      final role = userDoc.data()?['role'] as String?;
      return role == 'admin' || role == 'superAdmin';
    } catch (e) {
      debugPrint('Error checking admin privileges: $e');
      return false;
    }
  }

  /// Get all users with pagination
  Future<List<AdminUserModel>> getUsers({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? searchQuery,
    UserRole? roleFilter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      if (roleFilter != null) {
        query = query.where(
          'role',
          isEqualTo: roleFilter.toString().split('.').last,
        );
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query
            .where('email', isGreaterThanOrEqualTo: searchQuery)
            .where('email', isLessThan: '$searchQuery\uf8ff');
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => AdminUserModel.fromFirestore(doc, null))
          .toList();
    } catch (e) {
      debugPrint('Error getting users: $e');
      rethrow;
    }
  }

  /// Update user role
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole.toString().split('.').last,
      });
    } catch (e) {
      debugPrint('Error updating user role: $e');
      rethrow;
    }
  }

  /// Enable or disable a user
  Future<void> setUserEnabled(String userId, bool enabled) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isEnabled': enabled,
      });
    } catch (e) {
      debugPrint('Error updating user status: $e');
      rethrow;
    }
  }

  /// Delete a user
  Future<void> deleteUser(String userId) async {
    try {
      // Start a batch operation
      final batch = _firestore.batch();

      // Delete user document
      batch.delete(_firestore.collection('users').doc(userId));

      // Delete related data
      batch.delete(_firestore.collection('userSettings').doc(userId));
      batch.delete(_firestore.collection('userProfiles').doc(userId));

      // Commit the batch
      await batch.commit();

      // Delete the user from Firebase Auth
      await _auth.currentUser?.delete();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  /// Get user activity history
  Future<List<Map<String, dynamic>>> getUserActivity(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('userActivity')
          .doc(userId)
          .collection('events')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting user activity: $e');
      rethrow;
    }
  }

  /// Get user payment history
  Future<List<Map<String, dynamic>>> getUserPayments(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting user payments: $e');
      rethrow;
    }
  }

  /// Sign out the current admin
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}

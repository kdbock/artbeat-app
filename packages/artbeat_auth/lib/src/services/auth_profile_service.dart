import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../constants/routes.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Service for authentication and user profile management
class AuthProfileService {
  static final AuthProfileService _instance = AuthProfileService._internal();
  factory AuthProfileService() => _instance;
  AuthProfileService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check authentication status and return appropriate route
  Future<String> checkAuthStatus({
    bool requireEmailVerification = false,
  }) async {
    try {
      if (!isAuthenticated) {
        AppLogger.auth('👤 User not authenticated - redirecting to login');
        return AuthRoutes.login;
      }

      final user = currentUser!;
      AppLogger.auth('👤 Authenticated user: ${user.uid}');

      // Check email verification if required
      if (requireEmailVerification && !user.emailVerified) {
        AppLogger.info('👤 User email not verified - redirecting to verification');
        return AuthRoutes.emailVerification;
      }

      // Check if user profile exists in Firestore
      final profile = await _firestore.collection('users').doc(user.uid).get();
      AppLogger.info('👤 Firestore profile data: ${profile.data()}');

      if (!profile.exists) {
        debugPrint(
          '👤 User authenticated but no profile - need to create profile',
        );
        return AuthRoutes.profileCreate;
      }

      debugPrint(
        '👤 User authenticated with profile - redirecting to dashboard',
      );
      return AuthRoutes.dashboard;
    } catch (e) {
      AppLogger.error('❌ Error checking authentication status: $e');
      return AuthRoutes.login;
    }
  }

  /// Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (!isAuthenticated) return null;

      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      return doc.data();
    } catch (e) {
      AppLogger.error('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      AppLogger.error('❌ Error signing out: $e');
      rethrow;
    }
  }
}

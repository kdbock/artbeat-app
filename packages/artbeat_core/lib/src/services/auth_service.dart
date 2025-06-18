import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for authentication-related operations
class AuthService {
  static AuthService? _instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  factory AuthService() {
    _instance ??= AuthService._internal();
    return _instance!;
  }

  AuthService._internal();

  /// Get current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credentials = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credentials;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  /// Register new user with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credentials = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credentials;
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password reset error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }
}

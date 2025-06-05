import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Authentication service for handling user authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Get the current authenticated user (async)
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Register with email, password, and name
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String fullName, {
    required String zipCode, // Add this parameter
  }) async {
    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set display name
      await userCredential.user?.updateDisplayName(fullName);

      // Create user document in Firestore with zipCode
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'fullName': fullName,
        'email': email,
        'zipCode': zipCode,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return userCredential;
    } catch (e) {
      debugPrint('Error in registerWithEmailAndPassword: $e');
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Listen to auth state changes
  Stream<User?> authStateChanges() => _auth.authStateChanges();
}

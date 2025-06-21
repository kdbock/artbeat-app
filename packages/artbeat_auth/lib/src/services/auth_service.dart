import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Authentication service for handling user authentication
class AuthService {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// For dependency injection in tests
  void setDependenciesForTesting(
    FirebaseAuth auth,
    FirebaseFirestore firestore,
  ) {
    _auth = auth;
    _firestore = firestore;
  }

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
    String email,
    String password,
  ) async {
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
    required String zipCode, // Required parameter
  }) async {
    try {
      debugPrint('📝 Starting registration for email: $email');

      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      debugPrint('✅ Authentication account created with UID: $uid');

      // Set display name
      await userCredential.user?.updateDisplayName(fullName);
      debugPrint('✅ Display name set to: $fullName');

      try {
        // Create user document in Firestore with zipCode
        await _firestore.collection('users').doc(uid).set({
          'id': uid,
          'fullName': fullName,
          'email': email,
          'zipCode': zipCode,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userType': 'regular',
          'posts': <String>[],
          'followers': <String>[],
          'following': <String>[],
          'captures': <String>[],
          'followersCount': 0,
          'followingCount': 0,
          'postsCount': 0,
          'capturesCount': 0,
          'isVerified': false,
        }, SetOptions(merge: true));

        debugPrint('✅ User document created in Firestore');
      } catch (firestoreError) {
        debugPrint(
          '❌ Failed to create user document in Firestore: $firestoreError',
        );
        // Continue to return the userCredential even if Firestore fails
        // The RegisterScreen will attempt to create the document as a fallback
      }

      return userCredential;
    } catch (e) {
      debugPrint('❌ Error in registerWithEmailAndPassword: $e');
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

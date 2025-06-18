import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../models/user_model.dart';

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  final _log = Logger('UserService');

  factory UserService() {
    return _instance;
  }

  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  late final FirebaseStorage _storage;

  UserService._internal() {
    _initializeFirebase();
  }

  void _initializeFirebase() {
    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
    } catch (e, s) {
      _log.severe('Error initializing Firebase in UserService', e, s);
    }
  }

  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _followersCollection =>
      _firestore.collection('followers');
  CollectionReference get _followingCollection =>
      _firestore.collection('following');

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> createNewUser({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    try {
      final UserModel userData = UserModel(
        id: uid,
        email: email,
        fullName: displayName ?? '',
        createdAt: DateTime.now(),
      );
      await _usersCollection.doc(uid).set(userData.toMap());
    } catch (e, s) {
      _log.severe('Error creating new user', e, s);
    }
  }

  // Get current user
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _usersCollection.doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromDocumentSnapshot(doc);
      }
      return null;
    } catch (e, s) {
      _log.severe('Error getting current user model', e, s);
      return null;
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromDocumentSnapshot(doc);
      }
      return null;
    } catch (e, s) {
      _log.severe('Error getting user by ID', e, s);
      return null;
    }
  }

  /// Refresh current user data from Firestore
  Future<void> refreshUserData() async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.reload();
      }
      notifyListeners();
    } catch (e, s) {
      _log.warning('Error refreshing user data', e, s);
    }
  }

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e, s) {
      _log.severe('Error getting user profile', e, s);
      return null;
    }
  }

  // Update display name
  Future<void> updateDisplayName(String displayName) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _usersCollection.doc(userId).set({
        'fullName': displayName,
      }, SetOptions(merge: true));
      await currentUser?.updateDisplayName(displayName);
      notifyListeners();
    } catch (e, s) {
      _log.severe('Error updating display name', e, s);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? fullName,
    String? bio,
    String? location,
    String? gender,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final Map<String, dynamic> updates = {};
      if (fullName != null) updates['fullName'] = fullName;
      if (bio != null) updates['bio'] = bio;
      if (location != null) updates['location'] = location;
      if (gender != null) updates['gender'] = gender;

      await _usersCollection.doc(userId).set(updates, SetOptions(merge: true));
      notifyListeners();
    } catch (e, s) {
      _log.severe('Error updating user profile', e, s);
    }
  }

  // Upload and update profile photo
  Future<void> uploadAndUpdateProfilePhoto(File imageFile) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final ref = _storage.ref().child('profile_images/$userId/profile.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      await _usersCollection.doc(userId).set({
        'profileImageUrl': url,
      }, SetOptions(merge: true));
      await currentUser?.updatePhotoURL(url);
      notifyListeners();
    } catch (e, s) {
      _log.severe('Error uploading profile photo', e, s);
    }
  }

  // Upload and update cover photo
  Future<void> uploadAndUpdateCoverPhoto(File imageFile) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final ref = _storage.ref().child('cover_photos/$userId/cover.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      await _usersCollection.doc(userId).set({
        'coverImageUrl': url,
      }, SetOptions(merge: true));
      notifyListeners();
    } catch (e, s) {
      _log.severe('Error uploading cover photo', e, s);
    }
  }

  /// Follow another user
  Future<void> followUser(String targetUserId) async {
    final userId = currentUserId;
    if (userId == null || userId == targetUserId) return;

    try {
      final batch = _firestore.batch();
      // Add to following list of current user
      batch.set(
        _followingCollection.doc(userId).collection('users').doc(targetUserId),
        {'timestamp': FieldValue.serverTimestamp()},
      );
      // Add to followers list of target user
      batch.set(
        _followersCollection.doc(targetUserId).collection('users').doc(userId),
        {'timestamp': FieldValue.serverTimestamp()},
      );
      // Increment following count for current user
      batch.update(_usersCollection.doc(userId), {
        'followingCount': FieldValue.increment(1),
      });
      // Increment followers count for target user
      batch.update(_usersCollection.doc(targetUserId), {
        'followersCount': FieldValue.increment(1),
      });
      await batch.commit();
      notifyListeners();
    } catch (e, s) {
      _log.severe('Error following user', e, s);
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String targetUserId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();
      // Remove from following list of current user
      batch.delete(
        _followingCollection.doc(userId).collection('users').doc(targetUserId),
      );
      // Remove from followers list of target user
      batch.delete(
        _followersCollection.doc(targetUserId).collection('users').doc(userId),
      );
      // Decrement following count for current user
      batch.update(_usersCollection.doc(userId), {
        'followingCount': FieldValue.increment(-1),
      });
      // Decrement followers count for target user
      batch.update(_usersCollection.doc(targetUserId), {
        'followersCount': FieldValue.increment(-1),
      });
      await batch.commit();
      notifyListeners();
    } catch (e, s) {
      _log.severe('Error unfollowing user', e, s);
    }
  }

  // Get followers
  Future<List<UserModel>> getFollowers(String userId) async {
    try {
      final snapshot = await _followersCollection
          .doc(userId)
          .collection('users')
          .get();
      final userIds = snapshot.docs.map((doc) => doc.id).toList();
      if (userIds.isEmpty) return [];
      final usersSnapshot = await _usersCollection
          .where(FieldPath.documentId, whereIn: userIds)
          .get();
      return usersSnapshot.docs
          .map((doc) => UserModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e, s) {
      _log.severe('Error getting followers', e, s);
      return [];
    }
  }

  // Get following
  Future<List<UserModel>> getFollowing(String userId) async {
    try {
      final snapshot = await _followingCollection
          .doc(userId)
          .collection('users')
          .get();
      final userIds = snapshot.docs.map((doc) => doc.id).toList();
      if (userIds.isEmpty) return [];
      final usersSnapshot = await _usersCollection
          .where(FieldPath.documentId, whereIn: userIds)
          .get();
      return usersSnapshot.docs
          .map((doc) => UserModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e, s) {
      _log.severe('Error getting following', e, s);
      return [];
    }
  }

  /// Check if the current user is following another user
  Future<bool> isFollowing(String targetUserId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      final doc = await _followingCollection
          .doc(userId)
          .collection('users')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e, s) {
      _log.severe('Error checking if following', e, s);
      return false;
    }
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    try {
      final snapshot = await _usersCollection
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e, s) {
      _log.severe('Error searching users', e, s);
      return [];
    }
  }

  // Get suggested users
  Future<List<UserModel>> getSuggestedUsers() async {
    try {
      // This is a simple suggestion logic, can be improved
      final snapshot = await _usersCollection.limit(10).get();
      return snapshot.docs
          .map((doc) => UserModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e, s) {
      _log.severe('Error getting suggested users', e, s);
      return [];
    }
  }

  // Get user favorites
  Future<List<Map<String, dynamic>>> getUserFavorites() async {
    final userId = currentUserId;
    if (userId == null) return [];
    try {
      final snapshot = await _usersCollection
          .doc(userId)
          .collection('favorites')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e, s) {
      _log.severe('Error getting user favorites', e, s);
      return [];
    }
  }

  // Add to favorites
  Future<void> addToFavorites({
    required String itemId,
    required String itemType,
    String? imageUrl,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _usersCollection.doc(userId).collection('favorites').add({
        'itemId': itemId,
        'itemType': itemType,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e, s) {
      _log.severe('Error adding to favorites', e, s);
    }
  }

  // Remove from favorites
  Future<void> removeFromFavorites(String favoriteId) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _usersCollection
          .doc(userId)
          .collection('favorites')
          .doc(favoriteId)
          .delete();
      notifyListeners();
    } catch (e, s) {
      _log.severe('Error removing from favorites', e, s);
    }
  }

  // Get favorite by ID
  Future<Map<String, dynamic>?> getFavoriteById(String favoriteId) async {
    final userId = currentUserId;
    if (userId == null) return null;
    try {
      final doc = await _usersCollection
          .doc(userId)
          .collection('favorites')
          .doc(favoriteId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        data?['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e, s) {
      _log.severe('Error getting favorite by ID', e, s);
      return null;
    }
  }

  // Check if item is favorited
  Future<bool> isFavorited(String itemId, String itemType) async {
    final userId = currentUserId;
    if (userId == null) return false;
    try {
      final snapshot = await _usersCollection
          .doc(userId)
          .collection('favorites')
          .where('itemId', isEqualTo: itemId)
          .where('itemType', isEqualTo: itemType)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e, s) {
      _log.severe('Error checking if favorited', e, s);
      return false;
    }
  }

  // Example: Update user profile with a map of updates and notify listeners
  Future<void> updateUserProfileWithMap(Map<String, dynamic> updates) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _usersCollection.doc(userId).update(updates);
      notifyListeners();
    } catch (e, s) {
      _log.severe('Error updating user profile with map', e, s);
    }
  }
}

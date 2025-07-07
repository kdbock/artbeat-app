import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../models/user_model.dart';
import '../storage/enhanced_storage_service.dart';

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  final _log = Logger('UserService');

  factory UserService() {
    return _instance;
  }

  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  late final FirebaseStorage _storage;
  bool _firebaseInitialized = false;

  UserService._internal() {
    // Don't initialize Firebase instances immediately
    // Let them be initialized lazily when first accessed
  }

  void _initializeFirebase() {
    if (_firebaseInitialized) return;

    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      _firebaseInitialized = true;
    } catch (e, s) {
      _log.severe('Error initializing Firebase in UserService', e, s);
    }
  }

  // Lazy getters that initialize Firebase when first accessed
  FirebaseAuth get auth {
    _initializeFirebase();
    return _auth;
  }

  FirebaseFirestore get firestore {
    _initializeFirebase();
    return _firestore;
  }

  FirebaseStorage get storage {
    _initializeFirebase();
    return _storage;
  }

  CollectionReference get _usersCollection => firestore.collection('users');
  CollectionReference get _followersCollection =>
      firestore.collection('followers');
  CollectionReference get _followingCollection =>
      firestore.collection('following');

  User? get currentUser => auth.currentUser;
  String? get currentUserId => currentUser?.uid;

  Stream<User?> get authStateChanges => auth.authStateChanges();

  Future<void> createNewUser({
    required String uid,
    required String email,
    String? displayName,
    String? zipCode,
  }) async {
    try {
      _log.info('Creating new user document for UID: $uid, email: $email');

      // Check if user document already exists
      final userDoc = await _usersCollection.doc(uid).get();
      if (userDoc.exists) {
        _log.info('User document already exists for UID: $uid. Updating...');
        // Update any missing fields
        await _usersCollection.doc(uid).set({
          'email': email,
          'fullName': displayName ?? '',
          if (zipCode != null) 'zipCode': zipCode,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      }

      final UserModel userData = UserModel(
        id: uid,
        email: email,
        username: displayName ?? '',
        fullName: displayName ?? '',
        createdAt: DateTime.now(),
        experiencePoints: 0,
        level: 1,
      );

      _log.info('Creating new document with data: ${userData.toJson()}');
      await _usersCollection.doc(uid).set(userData.toJson());
      _log.info('✅ User document successfully created.');

      // Verify document creation
      final verifyDoc = await _usersCollection.doc(uid).get();
      if (verifyDoc.exists) {
        _log.info('✅ Document verification successful');
      } else {
        _log.severe(
          '❌ Document verification failed - document not found after creation',
        );
      }
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
    String? zipCode,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final Map<String, dynamic> updates = {};
      if (fullName != null) updates['fullName'] = fullName;
      if (bio != null) updates['bio'] = bio;
      if (location != null) updates['location'] = location;
      if (gender != null) updates['gender'] = gender;
      if (zipCode != null) updates['zipCode'] = zipCode;

      await _usersCollection.doc(userId).set(updates, SetOptions(merge: true));
      notifyListeners();
    } catch (e, s) {
      _log.severe('Error updating user profile', e, s);
    }
  }

  // Update user ZIP code specifically
  Future<void> updateUserZipCode(String zipCode) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _usersCollection.doc(userId).set({
        'zipCode': zipCode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      notifyListeners();
      debugPrint('✅ Updated user ZIP code to: $zipCode');
    } catch (e, s) {
      _log.severe('Error updating user ZIP code', e, s);
    }
  }

  // Upload and update profile photo with optimization
  Future<void> uploadAndUpdateProfilePhoto(File imageFile) async {
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('❌ uploadAndUpdateProfilePhoto: No current user ID');
      return;
    }

    try {
      debugPrint(
        '📤 uploadAndUpdateProfilePhoto: Starting optimized upload for user $userId',
      );

      // Use enhanced storage service for optimized upload
      final enhancedStorage = EnhancedStorageService();
      final result = await enhancedStorage.uploadImageWithOptimization(
        imageFile: imageFile,
        category: 'profile',
        generateThumbnail: true,
      );

      final url = result['imageUrl']!;
      debugPrint('🔗 uploadAndUpdateProfilePhoto: Download URL: $url');
      debugPrint('📊 Original size: ${result['originalSize']}');
      debugPrint('📊 Compressed size: ${result['compressedSize']}');

      // Update Firestore with both main image and thumbnail
      final updateData = {'profileImageUrl': url};

      if (result['thumbnailUrl'] != null) {
        updateData['profileImageThumbnailUrl'] = result['thumbnailUrl']!;
      }

      await _usersCollection
          .doc(userId)
          .set(updateData, SetOptions(merge: true));
      debugPrint('✅ uploadAndUpdateProfilePhoto: Firestore document updated');

      await currentUser?.updatePhotoURL(url);
      debugPrint(
        '✅ uploadAndUpdateProfilePhoto: Firebase Auth profile updated',
      );

      notifyListeners();
      debugPrint('✅ uploadAndUpdateProfilePhoto: Listeners notified');
    } catch (e, s) {
      debugPrint('❌ uploadAndUpdateProfilePhoto: Error occurred: $e');
      _log.severe('Error uploading profile photo', e, s);
    }
  }

  // Upload and update cover photo with optimization
  Future<void> uploadAndUpdateCoverPhoto(File imageFile) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      debugPrint(
        '📤 uploadAndUpdateCoverPhoto: Starting optimized upload for user $userId',
      );

      // Use enhanced storage service for optimized upload
      final enhancedStorage = EnhancedStorageService();
      final result = await enhancedStorage.uploadImageWithOptimization(
        imageFile: imageFile,
        category:
            'artwork', // Use artwork category for cover photos (larger dimensions)
        generateThumbnail: true,
      );

      final url = result['imageUrl']!;
      debugPrint('🔗 uploadAndUpdateCoverPhoto: Download URL: $url');
      debugPrint('📊 Original size: ${result['originalSize']}');
      debugPrint('📊 Compressed size: ${result['compressedSize']}');

      // Update Firestore with both main image and thumbnail
      final updateData = {'coverImageUrl': url};

      if (result['thumbnailUrl'] != null) {
        updateData['coverImageThumbnailUrl'] = result['thumbnailUrl']!;
      }

      await _usersCollection
          .doc(userId)
          .set(updateData, SetOptions(merge: true));
      debugPrint('✅ uploadAndUpdateCoverPhoto: Firestore document updated');

      notifyListeners();
      debugPrint('✅ uploadAndUpdateCoverPhoto: Listeners notified');
    } catch (e, s) {
      debugPrint('❌ uploadAndUpdateCoverPhoto: Error occurred: $e');
      _log.severe('Error uploading cover photo', e, s);
    }
  }

  /// Follow another user
  Future<void> followUser(String targetUserId) async {
    final userId = currentUserId;
    if (userId == null || userId == targetUserId) return;

    try {
      final batch = firestore.batch();
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
      final batch = firestore.batch();
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

  // Update user experience points and level
  Future<void> updateExperiencePoints(
    int points, {
    String? activityType,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final currentXP = userData['experiencePoints'] as int? ?? 0;
      final currentLevel = userData['level'] as int? ?? 0;

      final newXP = currentXP + points;
      int newLevel = currentLevel;

      // Calculate new level (every 100 XP = 1 level)
      final calculatedLevel = newXP ~/ 100;
      if (calculatedLevel > currentLevel) {
        newLevel = calculatedLevel;
      }

      await _usersCollection.doc(userId).set({
        'experiencePoints': newXP,
        'level': newLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
        '✅ Updated XP: +$points (${activityType ?? 'unknown'}), Total: $newXP, Level: $newLevel',
      );
      notifyListeners();
    } catch (e, s) {
      _log.severe('Error updating experience points', e, s);
    }
  }
}

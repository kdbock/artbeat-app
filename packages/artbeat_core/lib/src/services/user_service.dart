import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../models/user_type.dart';
import 'package:artbeat_art_walk/src/models/achievement_model.dart';
import '../storage/enhanced_storage_service.dart';

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();

  factory UserService() {
    return _instance;
  }

  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  late final FirebaseStorage _storage;
  bool _firebaseInitialized = false;

  UserService._internal() {
    _logDebug('Initializing UserService');
  }

  Future<UserModel> getUserModel(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw Exception('User document not found');
      }
      return UserModel.fromFirestore(doc);
    } catch (e, stack) {
      _logError('Error getting user model', e, stack);
      rethrow;
    }
  }

  void _logDebug(String message) {
    debugPrint('👤 UserService: $message');
  }

  void _logError(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('❌ UserService Error: $message');
    if (error != null) debugPrint('Error details: $error');
    if (stackTrace != null) debugPrint('Stack trace: $stackTrace');
  }

  @override
  void dispose() {
    // Since this is a singleton, we try to prevent disposal but handle it gracefully
    try {
      _logDebug('Dispose called - attempting to prevent for singleton');
      // For singleton pattern, we don't want to dispose, but Flutter requires it
      // So we call super but catch any subsequent usage errors
      super.dispose();
    } catch (e) {
      _logDebug('Dispose error caught (expected for singleton): $e');
    }
  }

  @override
  void notifyListeners() {
    // For singleton, always notify listeners
    super.notifyListeners();
  }

  // Firebase initialization
  void _initializeFirebase() {
    if (_firebaseInitialized) return;

    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      _firebaseInitialized = true;
      _logDebug('Firebase initialized successfully');
    } catch (e, s) {
      _logError('Error initializing Firebase', e, s);
    }
  }

  // Getters
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

  // Cache for current user model
  UserModel? _cachedUserModel;
  String? _cachedUserId;

  // User operations
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await getUserModel(user.uid);
  }

  Future<List<AchievementModel>> getUserAchievements(String userId) async {
    try {
      final achievements = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .orderBy('unlockedAt', descending: true)
          .get();

      return achievements.docs
          .map((doc) => AchievementModel.fromFirestore(doc))
          .toList();
    } catch (e, stack) {
      _logError('Error getting user achievements', e, stack);
      rethrow;
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      _logDebug('Getting user document for ID: $userId');
      final doc = await _usersCollection.doc(userId).get();
      _logDebug('Document exists: ${doc.exists}');
      if (doc.exists) {
        _logDebug('Document data: ${doc.data()}');
        return UserModel.fromDocumentSnapshot(doc);
      }
      _logDebug('No document found for user ID: $userId');
      return null;
    } catch (e, s) {
      _logError('Error getting user by ID', e, s);
      return null;
    }
  }

  Future<void> refreshUserData() async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.reload();
        // Clear cache to force fresh fetch
        _cachedUserModel = null;
        _cachedUserId = null;
      }
      notifyListeners();
    } catch (e, s) {
      _logError('Error refreshing user data', e, s);
    }
  }

  /// Clear the cached user model
  void clearUserCache() {
    _cachedUserModel = null;
    _cachedUserId = null;
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e, s) {
      _logError('Error getting user profile', e, s);
      return null;
    }
  }

  // Profile updates
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
      _logError('Error updating display name', e, s);
    }
  }

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
      _logError('Error updating user profile', e, s);
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
      _logError('Error updating user ZIP code', e, s);
    }
  }

  // Upload photo methods
  Future<void> uploadAndUpdateProfilePhoto(File imageFile) async {
    final userId = currentUserId;
    if (userId == null) {
      _logError('No current user ID');
      return;
    }

    try {
      _logDebug('Starting optimized profile photo upload for user $userId');

      // Use enhanced storage service for optimized upload
      final enhancedStorage = EnhancedStorageService();
      final result = await enhancedStorage.uploadImageWithOptimization(
        imageFile: imageFile,
        category: 'profile',
        generateThumbnail: true,
      );

      final url = result['imageUrl']!;
      _logDebug('Download URL: $url');
      _logDebug('Original size: ${result['originalSize']}');
      _logDebug('Compressed size: ${result['compressedSize']}');

      // Update Firestore with both main image and thumbnail
      final updateData = {'profileImageUrl': url};

      if (result['thumbnailUrl'] != null) {
        updateData['profileImageThumbnailUrl'] = result['thumbnailUrl']!;
      }

      await _usersCollection
          .doc(userId)
          .set(updateData, SetOptions(merge: true));
      _logDebug('Firestore document updated');

      await currentUser?.updatePhotoURL(url);
      _logDebug('Firebase Auth profile updated');

      notifyListeners();
      _logDebug('Listeners notified');
    } catch (e, s) {
      _logError('Error uploading profile photo', e, s);
    }
  }

  Future<void> uploadAndUpdateCoverPhoto(File imageFile) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      _logDebug('Starting optimized cover photo upload for user $userId');

      final enhancedStorage = EnhancedStorageService();
      final result = await enhancedStorage.uploadImageWithOptimization(
        imageFile: imageFile,
        category: 'artwork',
        generateThumbnail: true,
      );

      final url = result['imageUrl']!;
      _logDebug('Download URL: $url');
      _logDebug('Original size: ${result['originalSize']}');
      _logDebug('Compressed size: ${result['compressedSize']}');

      final updateData = {'coverImageUrl': url};
      if (result['thumbnailUrl'] != null) {
        updateData['coverImageThumbnailUrl'] = result['thumbnailUrl']!;
      }

      await _usersCollection
          .doc(userId)
          .set(updateData, SetOptions(merge: true));
      _logDebug('Firestore document updated');

      notifyListeners();
      _logDebug('Listeners notified');
    } catch (e, s) {
      _logError('Error uploading cover photo', e, s);
    }
  }

  /// Follow another user
  Future<void> followUser(String targetUserId) async {
    final userId = currentUserId;
    if (userId == null || userId == targetUserId) return;

    try {
      _logDebug('Following user: $targetUserId');
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
      _logDebug('Successfully followed user: $targetUserId');
      notifyListeners();
    } catch (e, s) {
      _logError('Error following user', e, s);
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String targetUserId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      _logDebug('Unfollowing user: $targetUserId');
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
      _logDebug('Successfully unfollowed user: $targetUserId');
      notifyListeners();
    } catch (e, s) {
      _logError('Error unfollowing user', e, s);
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
      _logError('Error getting followers', e, s);
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
      _logError('Error getting following', e, s);
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
      _logError('Error checking if following', e, s);
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
      _logError('Error searching users', e, s);
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
      _logError('Error getting suggested users', e, s);
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
      _logError('Error getting user favorites', e, s);
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
      _logError('Error adding to favorites', e, s);
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
      _logError('Error removing from favorites', e, s);
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
      _logError('Error getting favorite by ID', e, s);
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
      _logError('Error checking if favorited', e, s);
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
      _logError('Error updating user profile with map', e, s);
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
        _logDebug('Level up! New level: $newLevel');
      }

      await _usersCollection.doc(userId).set({
        'experiencePoints': newXP,
        'level': newLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _logDebug(
        'Updated XP: +$points (${activityType ?? 'unknown'}), Total: $newXP, Level: $newLevel',
      );
      notifyListeners();
    } catch (e, s) {
      _logError('Error updating experience points', e, s);
    }
  }

  // Create a new user document in Firestore
  Future<UserModel?> createNewUser({
    required String uid,
    required String email,
    required String displayName,
    String? zipCode,
    String? username,
    String? bio,
    String? location,
  }) async {
    try {
      _logDebug('Creating new user document for uid: $uid');
      _logDebug('Email: $email, DisplayName: $displayName');

      final finalUsername =
          username ??
          email
              .split('@')[0]
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]'), '');

      _logDebug('Generated username: $finalUsername');

      final newUser = UserModel(
        id: uid,
        email: email,
        username: finalUsername,
        fullName: displayName,
        createdAt: DateTime.now(),
        userType: UserType.regular.value,
        zipCode: zipCode,
        bio: bio ?? '',
        location: location ?? '',
      );

      _logDebug('User model created, attempting to save to Firestore...');
      _logDebug('UserType: ${newUser.userType}');

      await _usersCollection
          .doc(uid)
          .set(newUser.toMap(), SetOptions(merge: true));

      _logDebug('Successfully created new user document for uid: $uid');
      notifyListeners();

      return newUser;
    } catch (e, s) {
      _logError('Error creating new user', e, s);
      _logError('Full error details: $e');
      _logError('Stack trace: $s');
      return null;
    }
  }

  /// Update user profile image
  Future<bool> updateUserProfileImage(String userId, File imageFile) async {
    try {
      final storageService = EnhancedStorageService();

      // Upload image with optimization
      final uploadResult = await storageService.uploadImageWithOptimization(
        imageFile: imageFile,
        category: 'profile',
        generateThumbnail: true,
      );

      final imageUrl = uploadResult['imageUrl']!;
      final thumbnailUrl = uploadResult['thumbnailUrl'];

      // Update user document with new profile image
      await _usersCollection.doc(userId).update({
        'profileImageUrl': imageUrl,
        if (thumbnailUrl != null) 'profileThumbnailUrl': thumbnailUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _logDebug('Successfully updated profile image for user: $userId');
      notifyListeners();

      return true;
    } catch (e, s) {
      _logError('Error updating profile image', e, s);
      return false;
    }
  }

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final query = await _usersCollection
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      return query.docs.isEmpty;
    } catch (e, s) {
      _logError('Error checking username availability', e, s);
      return false;
    }
  }
}

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Service for user-related operations
class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _followersCollection =>
      _firestore.collection('followers');
  CollectionReference get _followingCollection =>
      _firestore.collection('following');

  /// Get the current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new user profile in Firestore
  Future<void> createNewUser({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    try {
      final now = DateTime.now();

      // Create a minimal user model with required fields
      final userModel = UserModel(
        id: uid,
        email: email,
        fullName: displayName ??
            email.split(
                '@')[0], // Use email prefix as fullName if no displayName
        createdAt: now,
      );

      // Add additional metadata in the map to avoid constructor compatibility issues
      final userData = userModel.toMap();
      userData.addAll({
        'phoneNumber': '',
        'authProvider': 'email',
        'isOnline': false,
        'lastSeen': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      await _usersCollection.doc(uid).set(userData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // Get current user model
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _usersCollection.doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromDocumentSnapshot(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user model: $e');
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
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Update display name
  Future<void> updateDisplayName(String displayName) async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      // Update Firebase Auth profile
      await user.updateDisplayName(displayName);
      await user.reload();

      // Update Firestore document
      await _usersCollection.doc(user.uid).set({
        'fullName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating display name: $e');
      rethrow;
    }
  }

  // Remove the duplicate updateUserProfile method and keep only this one:
  Future<void> updateUserProfile({
    String? fullName,
    String? bio,
    String? zipCode,
    String? profileImageUrl,
    String? coverImageUrl,
    bool? isVerified,
    String? userType,
    String? userId,
    String? location,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    final targetUserId = userId ?? user.uid;

    try {
      final userData = <String, dynamic>{};

      if (fullName != null) {
        userData['fullName'] = fullName;
        if (targetUserId == user.uid) {
          await user.updateDisplayName(fullName);
        }
      }

      if (bio != null) userData['bio'] = bio;
      if (zipCode != null) userData['zipCode'] = zipCode;
      if (profileImageUrl != null) {
        userData['profileImageUrl'] = profileImageUrl;
      }
      if (coverImageUrl != null) userData['coverImageUrl'] = coverImageUrl;
      if (isVerified != null) userData['isVerified'] = isVerified;
      if (userType != null) userData['userType'] = userType;
      if (location != null) userData['location'] = location;
      if (gender != null) userData['gender'] = gender;
      if (dateOfBirth != null) {
        userData['birthDate'] = Timestamp.fromDate(dateOfBirth);
      }

      // Update Firestore document
      await _usersCollection
          .doc(targetUserId)
          .set(userData, SetOptions(merge: true));

      // Update local state if needed
      notifyListeners();
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Upload and update profile photo
  Future<void> uploadAndUpdateProfilePhoto(File imageFile) async {
    final user = currentUser;
    if (user == null) {
      debugPrint('❌ No user logged in at upload time!');
      throw Exception('No user logged in');
    }
    debugPrint('👤 Profile upload: currentUser.uid = ${user.uid}');
    try {
      // Create directory structure if it doesn't exist
      final fileName =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('profile_images/${user.uid}/$fileName');
      debugPrint(
          '⬆️ Uploading profile photo to: profile_images/${user.uid}/$fileName');
      final uploadTask = ref.putFile(imageFile);
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint(
            '⬆️ Profile photo upload progress: ${progress.toStringAsFixed(2)}%');
      });
      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('✅ Profile photo uploaded successfully. URL: $downloadUrl');
      await _usersCollection.doc(user.uid).set({
        'profileImageUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await user.updatePhotoURL(downloadUrl);
    } catch (e) {
      debugPrint('❌ Error uploading profile photo: $e');
      rethrow;
    }
  }

  // Upload and update cover photo
  Future<void> uploadAndUpdateCoverPhoto(File imageFile) async {
    final user = currentUser;
    if (user == null) {
      debugPrint('❌ No user logged in at upload time!');
      throw Exception('No user logged in');
    }
    debugPrint('👤 Cover upload: currentUser.uid = ${user.uid}');
    try {
      if (!imageFile.existsSync()) {
        debugPrint('❌ Cover image file does not exist: ${imageFile.path}');
        throw Exception('Cover image file does not exist');
      }
      final fileSize = await imageFile.length();
      debugPrint('Cover image file size: $fileSize bytes');
      if (fileSize == 0) {
        debugPrint('❌ Cover image file is empty');
        throw Exception('Cover image file is empty');
      }
      final fileName =
          '${user.uid}_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('cover_images/${user.uid}/$fileName');
      debugPrint(
          '⬆️ Attempting to upload cover photo to: cover_images/${user.uid}/$fileName');
      final uploadTask = ref.putFile(imageFile);
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint(
            '⬆️ Cover photo upload progress: ${progress.toStringAsFixed(2)}%');
      });
      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('✅ Cover photo uploaded successfully. URL: $downloadUrl');
      await _usersCollection.doc(user.uid).set({
        'coverImageUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Error uploading cover photo: $e');
      rethrow;
    }
  }

  /// Follow another user
  Future<void> followUser(String targetUserId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Must be logged in to follow users');
      if (user.uid == targetUserId) throw Exception('Cannot follow yourself');

      // Get the target user to ensure they exist
      final targetUserDoc = await _usersCollection.doc(targetUserId).get();
      if (!targetUserDoc.exists) throw Exception('User not found');

      // Start a batch write
      final batch = _firestore.batch();

      // Add to following collection
      batch.set(
        _followingCollection.doc('${user.uid}_$targetUserId'),
        {
          'followerId': user.uid,
          'followingId': targetUserId,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Add to followers collection
      batch.set(
        _followersCollection.doc('${targetUserId}_${user.uid}'),
        {
          'followerId': user.uid,
          'followingId': targetUserId,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Increment counts
      batch.update(_usersCollection.doc(user.uid), {
        'followingCount': FieldValue.increment(1),
      });
      batch.update(_usersCollection.doc(targetUserId), {
        'followersCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error following user: $e');
      rethrow;
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String targetUserId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Must be logged in to unfollow users');

      // Start a batch write
      final batch = _firestore.batch();

      // Remove from following collection
      batch.delete(_followingCollection.doc('${user.uid}_$targetUserId'));

      // Remove from followers collection
      batch.delete(_followersCollection.doc('${targetUserId}_${user.uid}'));

      // Decrement counts if the documents existed
      final followingDoc =
          await _followingCollection.doc('${user.uid}_$targetUserId').get();
      if (followingDoc.exists) {
        batch.update(_usersCollection.doc(user.uid), {
          'followingCount': FieldValue.increment(-1),
        });
        batch.update(_usersCollection.doc(targetUserId), {
          'followersCount': FieldValue.increment(-1),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      rethrow;
    }
  }

  // Get followers
  Future<List<UserModel>> getFollowers(String userId) async {
    try {
      final snapshot = await _followersCollection
          .where('followingId', isEqualTo: userId)
          .get();

      final List<UserModel> followers = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final followerId = data['followerId'] as String;
        final followerDoc = await _usersCollection.doc(followerId).get();

        if (followerDoc.exists) {
          followers.add(UserModel.fromDocumentSnapshot(followerDoc));
        }
      }

      return followers;
    } catch (e) {
      print('Error getting followers: $e');
      return [];
    }
  }

  // Get following
  Future<List<UserModel>> getFollowing(String userId) async {
    try {
      final snapshot = await _followingCollection
          .where('followerId', isEqualTo: userId)
          .get();

      final List<UserModel> following = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final followingId = data['followingId'] as String;
        final followingDoc = await _usersCollection.doc(followingId).get();

        if (followingDoc.exists) {
          following.add(UserModel.fromDocumentSnapshot(followingDoc));
        }
      }

      return following;
    } catch (e) {
      print('Error getting following: $e');
      return [];
    }
  }

  /// Check if the current user is following another user
  Future<bool> isFollowing(String targetUserId) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final doc =
          await _followingCollection.doc('${user.uid}_$targetUserId').get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _usersCollection
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThan: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Get suggested users
  Future<List<UserModel>> getSuggestedUsers() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _usersCollection
          .where('id', isNotEqualTo: user.uid)
          .orderBy('id')
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromDocumentSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error getting suggested users: $e');
      return [];
    }
  }

  // Get user favorites
  Future<List<Map<String, dynamic>>> getUserFavorites() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error getting user favorites: $e');
      return [];
    }
  }

  // Add to favorites
  Future<void> addToFavorites({
    required String itemId,
    required String itemType,
    String? title,
    String? description,
    String? imageUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      await _firestore.collection('favorites').add({
        'userId': user.uid,
        'itemId': itemId,
        'itemType': itemType,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  // Remove from favorites
  Future<void> removeFromFavorites(String favoriteId) async {
    try {
      await _firestore.collection('favorites').doc(favoriteId).delete();
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  // Get favorite by ID
  Future<Map<String, dynamic>?> getFavoriteById(String favoriteId) async {
    try {
      final doc =
          await _firestore.collection('favorites').doc(favoriteId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      print('Error getting favorite by ID: $e');
      return null;
    }
  }

  // Check if item is favorited
  Future<bool> isFavorited(String itemId, String itemType) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .where('itemId', isEqualTo: itemId)
          .where('itemType', isEqualTo: itemType)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  void notifyListenersOnChange() {
    notifyListeners();
  }

  // Example: Update user profile with a map of updates and notify listeners
  Future<void> updateUserProfileWithMap(Map<String, dynamic> updates) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _usersCollection.doc(userId).update(updates);
      notifyListeners();
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:artbeat/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference _followersCollection =
      FirebaseFirestore.instance.collection('followers');
  final CollectionReference _followingCollection =
      FirebaseFirestore.instance.collection('following');

  // Create a new user document in Firestore
  Future<void> createNewUser(User firebaseUser, String firstName,
      String lastName, String email, String zipCode) async {
    print('UserService: createNewUser started for email: $email'); // DEBUG
    try {
      // Construct the full name for the UserModel
      String fullName = ("$firstName $lastName").trim();
      print('UserService: FullName constructed: $fullName'); // DEBUG

      // Create a map for Firestore, using FieldValue.serverTimestamp() for time fields
      Map<String, dynamic> userData = {
        'uid': firebaseUser.uid,
        'username': email, // Or generate a unique username
        'email': email,
        'phoneNumber': '', // Default empty
        'authProvider': 'email', // Assuming email/password auth
        'isVerified': firebaseUser.emailVerified,
        'fullName': fullName,
        'bio': '', // Default empty
        'profileImageUrl': firebaseUser.photoURL ??
            '', // Use Firebase Auth photoURL if available
        'coverImageUrl': '', // Default empty
        'gender': '', // Default empty or ask later
        'birthDate': null, // Explicitly null
        'location': zipCode, // Using zipCode as location
        'website': '', // Default empty
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(), // Use server timestamp
        'createdAt': FieldValue.serverTimestamp(), // Use server timestamp
        'updatedAt': FieldValue.serverTimestamp(), // Use server timestamp
        'status': 'active', // Default status
        'followers': [],
        'following': [],
        'blockedUsers': [],
        'friendRequestsSent': [],
        'friendRequestsReceived': [],
        'allowMessagesFrom': 'everyone', // Default
        'chatMutedUsers': [],
        'notificationsEnabled': true, // Default
        'emailNotifications': false, // Default
        'themePreference': 'system', // Default
        'language': 'en', // Default
        'privacySettings': {
          'showEmail': false,
          'showBirthDate': false
        }, // Default
        'contentFilters': {'matureContent': false}, // Default
        'posts': [],
        'likedPosts': [],
        'savedPosts': [],
        'comments': [],
        'sharedPosts': [],
        'favoriteUsers': [],
        'isBanned': false,
        'banReason': '',
        'reportedBy': [],
        'reportCount': 0,
        'subscriptionStatus': 'Regular User', // Set default account type
        'subscriptionExpiry': null, // Default null
        'payoutInfo': null, // Default null
        'donationsReceived': [],
        'adRevenue': 0.0,
      };
      print('UserService: UserData map constructed: $userData'); // DEBUG

      print(
          'UserService: Attempting to set document in Firestore for UID: ${firebaseUser.uid}'); // DEBUG
      // Use merge option to prevent conflicts if document already exists
      await _usersCollection
          .doc(firebaseUser.uid)
          .set(userData, SetOptions(merge: true));
      print(
          'UserService: Document successfully set in Firestore for UID: ${firebaseUser.uid}'); // DEBUG
    } catch (e, s) {
      // Added stack trace
      print('Error creating new user in Firestore: $e');
      print('Stack trace: $s'); // DEBUG: Print stack trace
      rethrow; // Rethrow the exception to be handled by the caller
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get a user model for the current user
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      // Get user document from Firestore
      DocumentSnapshot userDoc = await _usersCollection.doc(user.uid).get();

      // If the user document exists, create a UserModel from it
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return UserModel.fromFirebase(userData, user.uid);
      }
      // If the user document doesn't exist, create it with default values
      else {
        final now = Timestamp.now();
        final newUser = UserModel(
          uid: user.uid,
          username: 'wordnerd_${user.uid.substring(0, 5)}',
          fullName: user.displayName ?? 'WordNerd User',
          email: user.email ?? '',
          phoneNumber: '',
          profileImageUrl: user.photoURL ?? '',
          coverImageUrl: '',
          authProvider: 'email',
          isVerified: false,
          bio: '',
          gender: '',
          birthDate: null,
          location: '',
          website: '',
          isOnline: true,
          lastSeen: now,
          createdAt: now,
          updatedAt: now,
          status: '',
          followers: [],
          following: [],
          blockedUsers: [],
          friendRequestsSent: [],
          friendRequestsReceived: [],
          allowMessagesFrom: 'everyone',
          chatMutedUsers: [],
          notificationsEnabled: true,
          emailNotifications: true,
          themePreference: 'system',
          language: 'en',
          privacySettings: {'showEmail': false, 'showBirthDate': false},
          contentFilters: {'matureContent': false, 'hideAds': true},
          posts: [],
          likedPosts: [],
          savedPosts: [],
          comments: [],
          sharedPosts: [],
          favoriteUsers: [],
          isBanned: false,
          banReason: '',
          reportedBy: [],
          reportCount: 0,
          subscriptionStatus: 'free',
          subscriptionExpiry: null,
          payoutInfo: null,
          donationsReceived: [],
          adRevenue: 0.0,
        );

        // Save the new user to Firestore
        await _usersCollection.doc(user.uid).set(newUser.toMap());
        return newUser;
      }
    } catch (e) {
      print('Error getting current user model: $e');
      // Fallback to basic info if there's an error
      final now = Timestamp.now();
      return UserModel(
        uid: user.uid,
        username: 'wordnerd_user',
        fullName: user.displayName ?? 'WordNerd User',
        email: user.email ?? '',
        phoneNumber: '',
        profileImageUrl: user.photoURL ?? '',
        coverImageUrl: '',
        authProvider: 'email',
        isVerified: false,
        bio: '',
        gender: '',
        birthDate: null,
        location: '',
        website: '',
        isOnline: true,
        lastSeen: now,
        createdAt: now,
        updatedAt: now,
        status: '',
        followers: [],
        following: [],
        blockedUsers: [],
        friendRequestsSent: [],
        friendRequestsReceived: [],
        allowMessagesFrom: 'everyone',
        chatMutedUsers: [],
        notificationsEnabled: true,
        emailNotifications: true,
        themePreference: 'system',
        language: 'en',
        privacySettings: {'showEmail': false, 'showBirthDate': false},
        contentFilters: {'matureContent': false, 'hideAds': true},
        posts: [],
        likedPosts: [],
        savedPosts: [],
        comments: [],
        sharedPosts: [],
        favoriteUsers: [],
        isBanned: false,
        banReason: '',
        reportedBy: [],
        reportCount: 0,
        subscriptionStatus: 'free',
        subscriptionExpiry: null,
        payoutInfo: null,
        donationsReceived: [],
        adRevenue: 0.0,
      );
    }
  }

  // Get a user model by ID
  Future<UserModel> getUserById(String userId) async {
    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Check if the current user is following this user
        bool isFollowing = false;
        User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          DocumentSnapshot followDoc = await _followingCollection
              .doc(currentUser.uid)
              .collection('userFollowing')
              .doc(userId)
              .get();
          isFollowing = followDoc.exists;
        }

        userData['isFollowedByCurrentUser'] = isFollowing;
        return UserModel.fromFirebase(userData, userId);
      } else {
        // If user not found, return placeholder
        return UserModel.placeholder(userId);
      }
    } catch (e) {
      print('Error getting user by ID: $e');
      return UserModel.placeholder(userId);
    }
  }

  // Update user display name
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        debugPrint('🔧 UserService: Updating display name to: $displayName');
        
        // Update Firebase Auth display name
        await user.updateDisplayName(displayName);
        debugPrint('✅ UserService: Firebase Auth display name updated');

        // Update in Firestore
        await _usersCollection.doc(user.uid).set({
          'fullName': displayName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('✅ UserService: Firestore fullName updated');
      } catch (e) {
        debugPrint('❌ UserService: Error updating display name: $e');
        print('Error updating display name: $e');
        rethrow; // Re-throw to allow UI to handle
      }
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? username,
    String? bio,
    String? location,
    DateTime? birthDate,
    String? gender,
  }) async {
    try {
      debugPrint('🔧 UserService: Starting updateUserProfile for userId: $userId');
      
      Map<String, dynamic> updates = {};

      if (username != null) updates['username'] = username;
      if (bio != null) updates['bio'] = bio;
      if (location != null) updates['location'] = location;
      if (birthDate != null) {
        updates['birthDate'] = Timestamp.fromDate(birthDate);
      }
      if (gender != null) updates['gender'] = gender;
      
      // Always update the updatedAt timestamp
      updates['updatedAt'] = FieldValue.serverTimestamp();

      debugPrint('🔧 UserService: Updates to apply: $updates');

      if (updates.isNotEmpty) {
        debugPrint('🔧 UserService: Applying updates to Firestore...');
        await _usersCollection
            .doc(userId)
            .set(updates, SetOptions(merge: true));
        debugPrint('✅ UserService: Profile updates successfully applied to Firestore');
      } else {
        debugPrint('⚠️ UserService: No updates to apply');
      }
    } catch (e) {
      debugPrint('❌ UserService: Error updating user profile: $e');
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Upload and update user profile photo
  Future<String> uploadAndUpdateProfilePhoto(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      debugPrint('🔧 UserService: Starting profile photo upload...');
      // Create a reference to the storage location
      String fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = _storage.ref().child('profile_images/${user.uid}/$fileName');

      // Upload the file
      debugPrint('🔧 UserService: Uploading profile image to Firebase Storage...');
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;

      // Get download URL
      debugPrint('🔧 UserService: Getting download URL...');
      String photoURL = await taskSnapshot.ref.getDownloadURL();

      // Update Firebase Auth photoURL
      debugPrint('🔧 UserService: Updating Firebase Auth photoURL...');
      await user.updatePhotoURL(photoURL);

      // Update Firestore
      debugPrint('🔧 UserService: Updating Firestore with profile image URL...');
      await _usersCollection.doc(user.uid).update({
        'profileImageUrl': photoURL,
      });

      debugPrint('✅ UserService: Profile photo upload completed successfully');
      return photoURL;
    } catch (e) {
      debugPrint('❌ UserService: Error uploading profile photo: $e');
      print('Error uploading profile photo: $e');
      rethrow;
    }
  }

  // Upload and update user cover photo
  Future<String> uploadAndUpdateCoverPhoto(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      debugPrint('🔧 UserService: Starting cover photo upload...');
      // Create a reference to the storage location with proper path structure
      String fileName =
          'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = _storage.ref().child('cover_images/${user.uid}/$fileName');

      // Upload the file
      debugPrint('🔧 UserService: Uploading cover image to Firebase Storage...');
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;

      // Get download URL
      debugPrint('🔧 UserService: Getting cover image download URL...');
      String coverURL = await taskSnapshot.ref.getDownloadURL();

      // Update Firestore
      debugPrint('🔧 UserService: Updating Firestore with cover image URL...');
      await _usersCollection.doc(user.uid).update({'coverImageUrl': coverURL});

      debugPrint('✅ UserService: Cover photo upload completed successfully');
      return coverURL;
    } catch (e) {
      debugPrint('❌ UserService: Error uploading cover photo: $e');
      print('Error uploading cover photo: $e');
      rethrow;
    }
  }

  // Get followers list
  Future<List<UserModel>> getFollowers(String userId) async {
    try {
      // Get the followers collection for this user
      QuerySnapshot followersSnapshot = await _followersCollection
          .doc(userId)
          .collection('userFollowers')
          .get();

      List<UserModel> followers = [];

      // Get current user to check if user is being followed
      User? currentUser = _auth.currentUser;

      // For each follower, get their user data
      for (var doc in followersSnapshot.docs) {
        String followerId = doc.id;

        DocumentSnapshot userDoc = await _usersCollection.doc(followerId).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          // Check if the current user follows this user
          bool isFollowed = false;
          if (currentUser != null) {
            DocumentSnapshot followDoc = await _followingCollection
                .doc(currentUser.uid)
                .collection('userFollowing')
                .doc(followerId)
                .get();
            isFollowed = followDoc.exists;
          }

          userData['isFollowedByCurrentUser'] = isFollowed;
          followers.add(UserModel.fromFirebase(userData, followerId));
        }
      }

      return followers;
    } catch (e) {
      print('Error getting followers: $e');
      return [];
    }
  }

  // Get following list
  Future<List<UserModel>> getFollowing(String userId) async {
    try {
      // Get the following collection for this user
      QuerySnapshot followingSnapshot = await _followingCollection
          .doc(userId)
          .collection('userFollowing')
          .get();

      List<UserModel> following = [];

      // For each followed user, get their data
      for (var doc in followingSnapshot.docs) {
        String followedId = doc.id;

        DocumentSnapshot userDoc = await _usersCollection.doc(followedId).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          // Users in the following list are followed by definition
          userData['isFollowedByCurrentUser'] = true;
          following.add(UserModel.fromFirebase(userData, followedId));
        }
      }

      return following;
    } catch (e) {
      print('Error getting following: $e');
      return [];
    }
  }

  // Follow a user
  Future<void> followUser(String userId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    String currentUserId = currentUser.uid;

    // Don't allow following yourself
    if (currentUserId == userId) return;

    try {
      // Transaction to ensure consistency
      await _firestore.runTransaction((transaction) async {
        // Add to current user's following collection
        transaction.set(
          _followingCollection
              .doc(currentUserId)
              .collection('userFollowing')
              .doc(userId),
          {'timestamp': FieldValue.serverTimestamp()},
        );

        // Add to target user's followers collection
        transaction.set(
          _followersCollection
              .doc(userId)
              .collection('userFollowers')
              .doc(currentUserId),
          {'timestamp': FieldValue.serverTimestamp()},
        );

        // Update follower count for target user
        DocumentSnapshot userDoc = await transaction.get(
          _usersCollection.doc(userId),
        );
        if (userDoc.exists) {
          int currentCount =
              (userDoc.data() as Map<String, dynamic>)['followersCount'] ?? 0;
          transaction.update(_usersCollection.doc(userId), {
            'followersCount': currentCount + 1,
          });
        }

        // Update following count for current user
        DocumentSnapshot currentUserDoc = await transaction.get(
          _usersCollection.doc(currentUserId),
        );
        if (currentUserDoc.exists) {
          int currentCount = (currentUserDoc.data()
                  as Map<String, dynamic>)['followingCount'] ??
              0;
          transaction.update(_usersCollection.doc(currentUserId), {
            'followingCount': currentCount + 1,
          });
        }
      });
    } catch (e) {
      print('Error following user: $e');
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String userId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    String currentUserId = currentUser.uid;

    try {
      // Transaction to ensure consistency
      await _firestore.runTransaction((transaction) async {
        // Remove from current user's following collection
        transaction.delete(
          _followingCollection
              .doc(currentUserId)
              .collection('userFollowing')
              .doc(userId),
        );

        // Remove from target user's followers collection
        transaction.delete(
          _followersCollection
              .doc(userId)
              .collection('userFollowers')
              .doc(currentUserId),
        );

        // Update follower count for target user
        DocumentSnapshot userDoc = await transaction.get(
          _usersCollection.doc(userId),
        );
        if (userDoc.exists) {
          int currentCount =
              (userDoc.data() as Map<String, dynamic>)['followersCount'] ?? 0;
          transaction.update(_usersCollection.doc(userId), {
            'followersCount': (currentCount - 1) < 0 ? 0 : currentCount - 1,
          });
        }

        // Update following count for current user
        DocumentSnapshot currentUserDoc = await transaction.get(
          _usersCollection.doc(currentUserId),
        );
        if (currentUserDoc.exists) {
          int currentCount = (currentUserDoc.data()
                  as Map<String, dynamic>)['followingCount'] ??
              0;
          transaction.update(_usersCollection.doc(currentUserId), {
            'followingCount': (currentCount - 1) < 0 ? 0 : currentCount - 1,
          });
        }
      });
    } catch (e) {
      print('Error unfollowing user: $e');
    }
  }

  // Search users by username or name
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    query = query.toLowerCase();
    try {
      // Search by username
      QuerySnapshot usernameSnapshot = await _usersCollection
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      // Search by name
      QuerySnapshot nameSnapshot = await _usersCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      // Combine results and remove duplicates
      Set<String> userIds = {};
      List<UserModel> users = [];

      User? currentUser = _auth.currentUser;
      String currentUserId = currentUser?.uid ?? '';

      // Process username matches
      for (var doc in usernameSnapshot.docs) {
        String userId = doc.id;
        if (!userIds.contains(userId) && userId != currentUserId) {
          userIds.add(userId);
          Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

          // Check if the current user follows this user
          bool isFollowing = false;
          if (currentUser != null) {
            DocumentSnapshot followDoc = await _followingCollection
                .doc(currentUser.uid)
                .collection('userFollowing')
                .doc(userId)
                .get();
            isFollowing = followDoc.exists;
          }

          userData['isFollowedByCurrentUser'] = isFollowing;
          users.add(UserModel.fromFirebase(userData, userId));
        }
      }

      // Process name matches
      for (var doc in nameSnapshot.docs) {
        String userId = doc.id;
        if (!userIds.contains(userId) && userId != currentUserId) {
          userIds.add(userId);
          Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

          // Check if the current user follows this user
          bool isFollowing = false;
          if (currentUser != null) {
            DocumentSnapshot followDoc = await _followingCollection
                .doc(currentUser.uid)
                .collection('userFollowing')
                .doc(userId)
                .get();
            isFollowing = followDoc.exists;
          }

          userData['isFollowedByCurrentUser'] = isFollowing;
          users.add(UserModel.fromFirebase(userData, userId));
        }
      }

      return users;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Get suggested users to follow
  Future<List<UserModel>> getSuggestedUsers({int limit = 10}) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      // Get users the current user isn't already following
      QuerySnapshot usersSnapshot = await _usersCollection
          .limit(
            limit * 2,
          ) // Fetch more than needed to account for filtering
          .get();

      List<UserModel> suggestions = [];

      // Get the IDs of users the current user is already following
      QuerySnapshot followingSnapshot = await _followingCollection
          .doc(currentUser.uid)
          .collection('userFollowing')
          .get();

      Set<String> followingIds =
          followingSnapshot.docs.map((doc) => doc.id).toSet();

      // Don't include the current user
      followingIds.add(currentUser.uid);

      // Filter out users the current user is already following
      for (var doc in usersSnapshot.docs) {
        if (!followingIds.contains(doc.id) && suggestions.length < limit) {
          Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
          userData['isFollowedByCurrentUser'] = false;
          suggestions.add(UserModel.fromFirebase(userData, doc.id));
        }
      }

      return suggestions;
    } catch (e) {
      print('Error getting suggested users: $e');
      return [];
    }
  }

  // Favorites management
  Future<List<Map<String, dynamic>>> getUserFavorites(String userId) async {
    try {
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .orderBy('timestamp', descending: true)
          .get();

      return favoritesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Untitled',
          'description': data['description'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
          'timestamp': data['timestamp'] ?? Timestamp.now(),
        };
      }).toList();
    } catch (e) {
      print('Error getting user favorites: $e');
      return [];
    }
  }

  Future<void> addToFavorites({
    required String title,
    required String description,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .add({
        'title': title,
        'description': description,
        'imageUrl': imageUrl ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String favoriteId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(favoriteId)
          .delete();
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  Future<bool> checkIfFavorite(String itemId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(itemId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking if favorite: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getFavoriteById(
    String favoriteId,
    String userId,
  ) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(favoriteId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Untitled',
          'description': data['description'] ?? '',
          'content': data['content'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
          'sourceUrl': data['sourceUrl'] ?? '',
          'type': data['type'] ?? 'unknown',
          'createdAt': data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch,
        };
      }
      return null;
    } catch (e) {
      print('Error getting favorite by ID: $e');
      return null;
    }
  }
}

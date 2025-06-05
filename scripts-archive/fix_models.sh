#!/bin/bash

# Script to fix model files

# Add imports to user_model.dart
cat > /Users/kristybock/artbeat/packages/artbeat_core/lib/src/models/user_model.dart << 'EOL'
// filepath: /Users/kristybock/artbeat/packages/artbeat_core/lib/src/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum UserType {
  regular,
  artist,
  gallery,
  admin,
}

class UserModel extends ChangeNotifier {
  final String id; // Document ID
  final String email;
  final String fullName;
  final String? username;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final String? bio;
  final String? location;
  final String? zipCode;
  final UserType userType;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime lastActive;
  final String? phoneNumber;
  final String? authProvider;
  final String? gender;
  final String? website;
  final bool? isOnline;
  final DateTime? lastSeen;
  final DateTime? updatedAt;
  final String? status;
  final List<String>? followers;
  final List<String>? following;
  final List<String>? blockedUsers;
  final List<String>? friendRequestsSent;
  final List<String>? friendRequestsReceived;
  final String? allowMessagesFrom;
  final List<String>? chatMutedUsers;
  final bool? notificationsEnabled;
  final bool? emailNotifications;
  final String? themePreference;
  final String? language;
  final Map<String, dynamic>? privacySettings;
  final Map<String, dynamic>? contentFilters;
  final List<String>? posts;
  final List<String>? likedPosts;
  final List<String>? savedPosts;
  final List<String>? comments;
  final List<String>? sharedPosts;
  final List<String>? favoriteUsers;
  final bool? isBanned;
  final String? banReason;
  final List<String>? reportedBy;
  final int? reportCount;
  final String? subscriptionStatus;
  final List<Map<String, dynamic>>? donationsReceived;
  final double? adRevenue;

  // Current user ID shortcut property
  String get uid => id;
  String? get currentUserId => id;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.username,
    this.profileImageUrl,
    this.coverImageUrl,
    this.bio,
    this.location,
    this.zipCode,
    this.userType = UserType.regular,
    this.isVerified = false,
    DateTime? createdAt,
    DateTime? lastActive,
    this.phoneNumber,
    this.authProvider,
    this.gender,
    this.website,
    this.isOnline,
    Timestamp? lastSeen,
    Timestamp? updatedAt,
    this.status,
    this.followers,
    this.following,
    this.blockedUsers,
    this.friendRequestsSent,
    this.friendRequestsReceived,
    this.allowMessagesFrom,
    this.chatMutedUsers,
    this.notificationsEnabled,
    this.emailNotifications,
    this.themePreference,
    this.language,
    this.privacySettings,
    this.contentFilters,
    this.posts,
    this.likedPosts,
    this.savedPosts,
    this.comments,
    this.sharedPosts,
    this.favoriteUsers,
    this.isBanned,
    this.banReason,
    this.reportedBy,
    this.reportCount,
    this.subscriptionStatus,
    this.donationsReceived,
    this.adRevenue,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActive = lastActive ?? DateTime.now(),
        lastSeen = lastSeen != null ? lastSeen.toDate() : null,
        updatedAt = updatedAt != null ? updatedAt.toDate() : null;

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'coverImageUrl': coverImageUrl,
      'bio': bio,
      'location': location,
      'zipCode': zipCode,
      'userType': userType.index,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'phoneNumber': phoneNumber,
      'authProvider': authProvider,
      'gender': gender,
      'website': website,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status,
      'followers': followers,
      'following': following,
      'blockedUsers': blockedUsers,
      'friendRequestsSent': friendRequestsSent,
      'friendRequestsReceived': friendRequestsReceived,
      'allowMessagesFrom': allowMessagesFrom,
      'chatMutedUsers': chatMutedUsers,
      'notificationsEnabled': notificationsEnabled,
      'emailNotifications': emailNotifications,
      'themePreference': themePreference,
      'language': language,
      'privacySettings': privacySettings,
      'contentFilters': contentFilters,
      'posts': posts,
      'likedPosts': likedPosts,
      'savedPosts': savedPosts,
      'comments': comments,
      'sharedPosts': sharedPosts,
      'favoriteUsers': favoriteUsers,
      'isBanned': isBanned,
      'banReason': banReason,
      'reportedBy': reportedBy,
      'reportCount': reportCount,
      'subscriptionStatus': subscriptionStatus,
      'donationsReceived': donationsReceived,
      'adRevenue': adRevenue,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? map['name'] ?? '',
      username: map['username'],
      profileImageUrl: map['profileImageUrl'],
      coverImageUrl: map['coverImageUrl'],
      bio: map['bio'],
      location: map['location'],
      zipCode: map['zipCode'],
      userType: map['userType'] != null
          ? UserType.values[map['userType']]
          : UserType.regular,
      isVerified: map['isVerified'] ?? false,
      createdAt: map['createdAt'] != null
          ? map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
      lastActive: map['lastActive'] != null
          ? map['lastActive'] is Timestamp 
              ? (map['lastActive'] as Timestamp).toDate()
              : DateTime.parse(map['lastActive'].toString())
          : DateTime.now(),
      phoneNumber: map['phoneNumber'],
      authProvider: map['authProvider'],
      gender: map['gender'],
      website: map['website'],
      isOnline: map['isOnline'],
      lastSeen: map['lastSeen'] is Timestamp ? map['lastSeen'] : null,
      updatedAt: map['updatedAt'] is Timestamp ? map['updatedAt'] : null,
      status: map['status'],
      followers: _convertToStringList(map['followers']),
      following: _convertToStringList(map['following']),
      blockedUsers: _convertToStringList(map['blockedUsers']),
      friendRequestsSent: _convertToStringList(map['friendRequestsSent']),
      friendRequestsReceived: _convertToStringList(map['friendRequestsReceived']),
      allowMessagesFrom: map['allowMessagesFrom'],
      chatMutedUsers: _convertToStringList(map['chatMutedUsers']),
      notificationsEnabled: map['notificationsEnabled'],
      emailNotifications: map['emailNotifications'],
      themePreference: map['themePreference'],
      language: map['language'],
      privacySettings: map['privacySettings'],
      contentFilters: map['contentFilters'],
      posts: _convertToStringList(map['posts']),
      likedPosts: _convertToStringList(map['likedPosts']),
      savedPosts: _convertToStringList(map['savedPosts']),
      comments: _convertToStringList(map['comments']),
      sharedPosts: _convertToStringList(map['sharedPosts']),
      favoriteUsers: _convertToStringList(map['favoriteUsers']),
      isBanned: map['isBanned'],
      banReason: map['banReason'],
      reportedBy: _convertToStringList(map['reportedBy']),
      reportCount: map['reportCount'],
      subscriptionStatus: map['subscriptionStatus'],
      donationsReceived: map['donationsReceived'] != null 
          ? List<Map<String, dynamic>>.from(map['donationsReceived']) 
          : null,
      adRevenue: map['adRevenue'],
    );
  }
  
  // Helper method to convert dynamic lists to List<String>
  static List<String>? _convertToStringList(dynamic list) {
    if (list == null) return null;
    if (list is List) {
      return list.map((item) => item.toString()).toList();
    }
    return null;
  }
  
  // Create from Firestore document
  factory UserModel.fromFirebase(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw Exception('User document does not exist!');
    }
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  UserModel copyWith({
    String? email,
    String? fullName,
    String? username,
    String? profileImageUrl,
    String? coverImageUrl,
    String? bio,
    String? location,
    String? zipCode,
    UserType? userType,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastActive,
    String? phoneNumber,
    String? authProvider,
    String? gender,
    String? website,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? updatedAt,
    String? status,
    List<String>? followers,
    List<String>? following,
    List<String>? blockedUsers,
    List<String>? friendRequestsSent,
    List<String>? friendRequestsReceived,
    String? allowMessagesFrom,
    List<String>? chatMutedUsers,
    bool? notificationsEnabled,
    bool? emailNotifications,
    String? themePreference,
    String? language,
    Map<String, dynamic>? privacySettings,
    Map<String, dynamic>? contentFilters,
    List<String>? posts,
    List<String>? likedPosts,
    List<String>? savedPosts,
    List<String>? comments,
    List<String>? sharedPosts,
    List<String>? favoriteUsers,
    bool? isBanned,
    String? banReason,
    List<String>? reportedBy,
    int? reportCount,
    String? subscriptionStatus,
    List<Map<String, dynamic>>? donationsReceived,
    double? adRevenue,
  }) {
    return UserModel(
      id: this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      zipCode: zipCode ?? this.zipCode,
      userType: userType ?? this.userType,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      authProvider: authProvider ?? this.authProvider,
      gender: gender ?? this.gender,
      website: website ?? this.website,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      friendRequestsSent: friendRequestsSent ?? this.friendRequestsSent,
      friendRequestsReceived: friendRequestsReceived ?? this.friendRequestsReceived,
      allowMessagesFrom: allowMessagesFrom ?? this.allowMessagesFrom,
      chatMutedUsers: chatMutedUsers ?? this.chatMutedUsers,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      themePreference: themePreference ?? this.themePreference,
      language: language ?? this.language,
      privacySettings: privacySettings ?? this.privacySettings,
      contentFilters: contentFilters ?? this.contentFilters,
      posts: posts ?? this.posts,
      likedPosts: likedPosts ?? this.likedPosts,
      savedPosts: savedPosts ?? this.savedPosts,
      comments: comments ?? this.comments,
      sharedPosts: sharedPosts ?? this.sharedPosts,
      favoriteUsers: favoriteUsers ?? this.favoriteUsers,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      reportedBy: reportedBy ?? this.reportedBy,
      reportCount: reportCount ?? this.reportCount,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      donationsReceived: donationsReceived ?? this.donationsReceived,
      adRevenue: adRevenue ?? this.adRevenue,
    );
  }
  
  // Utility methods for profile display
  String placeholder(String name) {
    if (name.isEmpty) return '';
    
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.length == 1 && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }
  
  bool get isFollowedByCurrentUser => false; // Implementation would check if current user ID is in followers
}
EOL

# Fix subscription model in artist package
cat > /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/models/subscription_model.dart << 'EOL'
// filepath: /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/models/subscription_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionTier {
  free, // previously artistBasic
  standard, // previously artistPro
  premium, // previously gallery
}

class SubscriptionModel {
  final String id;
  final String userId;
  final SubscriptionTier tier;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? stripeSubscriptionId;
  final String? stripePriceId;
  final bool autoRenew;
  
  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.tier,
    required this.startDate,
    this.endDate,
    required this.isActive,
    this.stripeSubscriptionId,
    this.stripePriceId,
    this.autoRenew = true,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tier': tier.index,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'stripeSubscriptionId': stripeSubscriptionId,
      'stripePriceId': stripePriceId,
      'autoRenew': autoRenew,
    };
  }
  
  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionModel(
      id: id,
      userId: map['userId'] ?? '',
      tier: SubscriptionTier.values[map['tier'] ?? 0],
      startDate: map['startDate'] != null 
          ? map['startDate'] is Timestamp
              ? (map['startDate'] as Timestamp).toDate()
              : DateTime.parse(map['startDate']) 
          : DateTime.now(),
      endDate: map['endDate'] != null 
          ? map['endDate'] is Timestamp
              ? (map['endDate'] as Timestamp).toDate()
              : DateTime.parse(map['endDate']) 
          : null,
      isActive: map['isActive'] ?? false,
      stripeSubscriptionId: map['stripeSubscriptionId'],
      stripePriceId: map['stripePriceId'],
      autoRenew: map['autoRenew'] ?? true,
    );
  }

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw Exception('Subscription document does not exist!');
    }
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SubscriptionModel.fromMap(data, doc.id);
  }

  // Helper method to map legacy tiers to new tiers
  static SubscriptionTier mapLegacyTier(String legacyTier) {
    switch (legacyTier) {
      case 'artistBasic':
        return SubscriptionTier.free;
      case 'artistPro':
        return SubscriptionTier.standard;
      case 'gallery':
        return SubscriptionTier.premium;
      default:
        return SubscriptionTier.free;
    }
  }
  
  SubscriptionModel copyWith({
    String? userId,
    SubscriptionTier? tier,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? stripeSubscriptionId,
    String? stripePriceId,
    bool? autoRenew,
  }) {
    return SubscriptionModel(
      id: this.id,
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      stripePriceId: stripePriceId ?? this.stripePriceId,
      autoRenew: autoRenew ?? this.autoRenew,
    );
  }
}
EOL

# Fix artist profile model 
cat > /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/models/artist_profile_model.dart << 'EOL'
// filepath: /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/models/artist_profile_model.dart
import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'subscription_model.dart';

class ArtistProfileModel {
  final String id;
  final String userId;
  final String displayName;
  final String? bio;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final String? website;
  final String? storeUrl;
  final String? location;
  final String? zipCode;
  final List<String>? styles;
  final List<String>? mediums;
  final List<String>? awards;
  final List<String>? education;
  final List<String>? exhibitions;
  final bool isVerified;
  final bool isFeatured;
  final UserType userType;
  final SubscriptionTier subscriptionTier;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ArtistProfileModel({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    this.profileImageUrl,
    this.coverImageUrl,
    this.website,
    this.storeUrl,
    this.location,
    this.zipCode,
    this.styles,
    this.mediums,
    this.awards,
    this.education,
    this.exhibitions,
    this.isVerified = false,
    this.isFeatured = false,
    required this.userType,
    required this.subscriptionTier,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'coverImageUrl': coverImageUrl,
      'website': website,
      'storeUrl': storeUrl,
      'location': location,
      'zipCode': zipCode,
      'styles': styles,
      'mediums': mediums,
      'awards': awards,
      'education': education,
      'exhibitions': exhibitions,
      'isVerified': isVerified,
      'isFeatured': isFeatured,
      'userType': userType.index,
      'subscriptionTier': subscriptionTier.index,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ArtistProfileModel.fromMap(Map<String, dynamic> map, String id) {
    return ArtistProfileModel(
      id: id,
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      bio: map['bio'],
      profileImageUrl: map['profileImageUrl'],
      coverImageUrl: map['coverImageUrl'],
      website: map['website'],
      storeUrl: map['storeUrl'],
      location: map['location'],
      zipCode: map['zipCode'],
      styles: map['styles'] != null ? List<String>.from(map['styles']) : null,
      mediums: map['mediums'] != null ? List<String>.from(map['mediums']) : null,
      awards: map['awards'] != null ? List<String>.from(map['awards']) : null,
      education: map['education'] != null ? List<String>.from(map['education']) : null,
      exhibitions: map['exhibitions'] != null ? List<String>.from(map['exhibitions']) : null,
      isVerified: map['isVerified'] ?? false,
      isFeatured: map['isFeatured'] ?? false,
      userType: map['userType'] != null ? UserType.values[map['userType']] : UserType.artist,
      subscriptionTier: map['subscriptionTier'] != null 
          ? SubscriptionTier.values[map['subscriptionTier']] 
          : SubscriptionTier.free,
      createdAt: map['createdAt'] != null 
          ? map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate() 
              : DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? map['updatedAt'] is Timestamp 
              ? (map['updatedAt'] as Timestamp).toDate() 
              : DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  factory ArtistProfileModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw Exception('Artist profile document does not exist!');
    }
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ArtistProfileModel.fromMap(data, doc.id);
  }

  String getSubscriptionName() {
    switch (subscriptionTier) {
      case SubscriptionTier.free:
        return 'Artist Basic';
      case SubscriptionTier.standard:
        return 'Artist Pro';
      case SubscriptionTier.premium:
        return 'Gallery';
      default:
        return 'Unknown';
    }
  }

  double getSubscriptionPrice() {
    switch (subscriptionTier) {
      case SubscriptionTier.free:
        return 0.0;
      case SubscriptionTier.standard:
        return 9.99;
      case SubscriptionTier.premium:
        return 49.99;
      default:
        return 0.0;
    }
  }

  UserType getUserType() {
    switch (subscriptionTier) {
      case SubscriptionTier.free:
      case SubscriptionTier.standard:
        return UserType.artist;
      case SubscriptionTier.premium:
        return UserType.gallery;
      default:
        return UserType.regular;
    }
  }

  String getUserTypeDisplayName() {
    switch (userType) {
      case UserType.artist:
        return 'Artist';
      case UserType.gallery:
        return 'Gallery';
      case UserType.admin:
        return 'Admin';
      default:
        return 'User';
    }
  }
}
EOL

# Fix CommunityService 
cat > /Users/kristybock/artbeat/packages/artbeat_community/lib/src/services/community_service.dart << 'EOL'
// filepath: /Users/kristybock/artbeat/packages/artbeat_community/lib/src/services/community_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CommunityService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
  
  // Get all posts
  Future<List<dynamic>> getPosts({int limit = 10, String? lastPostId}) async {
    try {
      Query query = _firestore.collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);
          
      if (lastPostId != null) {
        // Get the last post doc for pagination
        DocumentSnapshot lastDocSnapshot = 
            await _firestore.collection('posts').doc(lastPostId).get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      final QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('Error getting posts: $e');
      return [];
    }
  }
  
  // Get post by ID
  Future<Map<String, dynamic>?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      if (doc.exists && doc.data() != null) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      debugPrint('Error getting post: $e');
      return null;
    }
  }
  
  // Create post
  Future<String?> createPost({
    required String content,
    List<File>? images,
    String? location,
    String? zipCode,
    List<String>? tags,
    bool isPublic = true,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return null;
      }
      
      final List<String> imageUrls = [];
      
      // Upload images if any
      if (images != null && images.isNotEmpty) {
        for (var i = 0; i < images.length; i++) {
          final File image = images[i];
          final String fileName = 'post_${userId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final Reference ref = _storage.ref().child('post_images').child(fileName);
          
          final UploadTask uploadTask = ref.putFile(image);
          final TaskSnapshot taskSnapshot = await uploadTask;
          final String imageUrl = await taskSnapshot.ref.getDownloadURL();
          imageUrls.add(imageUrl);
        }
      }
      
      final docRef = await _firestore.collection('posts').add({
        'userId': userId,
        'content': content,
        'images': imageUrls,
        'location': location,
        'zipCode': zipCode,
        'tags': tags ?? [],
        'isPublic': isPublic,
        'likes': 0,
        'comments': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating post: $e');
      return null;
    }
  }
  
  // Update post
  Future<bool> updatePost(String postId, Map<String, dynamic> postData) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        ...postData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating post: $e');
      return false;
    }
  }
  
  // Delete post
  Future<bool> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return false;
    }
  }
  
  // Check if user liked a post
  Future<bool> hasUserLikedPost(String postId, String userId) async {
    try {
      final likeDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();
      return likeDoc.exists;
    } catch (e) {
      debugPrint('Error checking user like: $e');
      return false;
    }
  }
  
  // Like or unlike a post
  Future<bool> toggleLikePost(String postId, String userId) async {
    try {
      // Check if user already liked the post
      final likeDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();
      
      final batch = _firestore.batch();
      final postRef = _firestore.collection('posts').doc(postId);
      final likeRef = postRef.collection('likes').doc(userId);
      
      if (likeDoc.exists) {
        // Unlike post
        batch.delete(likeRef);
        batch.update(postRef, {'likes': FieldValue.increment(-1)});
      } else {
        // Like post
        batch.set(likeRef, {
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        batch.update(postRef, {'likes': FieldValue.increment(1)});
      }
      
      await batch.commit();
      return !likeDoc.exists;
    } catch (e) {
      debugPrint('Error toggling post like: $e');
      return false;
    }
  }
  
  // Get comments for post
  Future<List<Map<String, dynamic>>> getCommentsForPost(
    String postId, {
    String? parentCommentId,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .where('parentCommentId', isEqualTo: parentCommentId)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      final QuerySnapshot snapshot = await query.get();
      
      final List<Map<String, dynamic>> comments = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'];
        
        // Get user data
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get();
        
        String username = 'Unknown User';
        String? profileImage;
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          username = userData['fullName'] ?? userData['username'] ?? 'Unknown User';
          profileImage = userData['profileImageUrl'];
        }
        
        comments.add({
          'id': doc.id,
          ...data,
          'username': username,
          'profileImageUrl': profileImage,
        });
      }
      
      return comments;
    } catch (e) {
      debugPrint('Error getting comments: $e');
      return [];
    }
  }
  
  // Add a comment
  Future<String?> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentCommentId,
    List<String>? mentionedUsers,
  }) async {
    try {
      final commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments');
      
      final docRef = await commentRef.add({
        'userId': userId,
        'content': content,
        'parentCommentId': parentCommentId,
        'mentionedUsers': mentionedUsers ?? [],
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update comment count on post
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(1),
      });
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }
  
  // Get replies to a comment
  Future<List<Map<String, dynamic>>> getCommentReplies(
    String postId,
    String commentId,
    {int limit = 10}
  ) async {
    return getCommentsForPost(
      postId,
      parentCommentId: commentId,
      limit: limit,
    );
  }
  
  // Share post (create a new post referencing the original)
  Future<String?> sharePost(String postId, String content) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return null;
      }
      
      // Get original post
      final originalPost = await getPostById(postId);
      if (originalPost == null) {
        return null;
      }
      
      // Create new shared post
      final docRef = await _firestore.collection('posts').add({
        'userId': userId,
        'content': content,
        'sharedPostId': postId,
        'sharedPostData': originalPost,
        'isShared': true,
        'likes': 0,
        'comments': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update share count on original post
      await _firestore.collection('posts').doc(postId).update({
        'shares': FieldValue.increment(1),
      });
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error sharing post: $e');
      return null;
    }
  }
  
  // Get user feed based on following
  Future<List<dynamic>> getPersonalFeed({int limit = 10, String? lastPostId}) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return [];
      }
      
      // Get user's following list
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final following = userData?['following'] as List<dynamic>? ?? [];
      
      if (following.isEmpty) {
        // Just return a standard feed if not following anyone
        return getCommunityFeed(limit: limit, lastPostId: lastPostId);
      }
      
      // Include own posts and followed users' posts
      final List<String> userIds = [...following.cast<String>(), userId];
      
      Query query = _firestore.collection('posts')
          .where('userId', whereIn: userIds)
          .orderBy('createdAt', descending: true)
          .limit(limit);
          
      if (lastPostId != null) {
        DocumentSnapshot lastDocSnapshot = 
            await _firestore.collection('posts').doc(lastPostId).get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      final QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('Error getting personal feed: $e');
      return [];
    }
  }
  
  // Get community feed
  Future<List<dynamic>> getCommunityFeed({int limit = 10, String? lastPostId, String? filter}) async {
    try {
      Query query = _firestore.collection('posts')
          .where('isPublic', isEqualTo: true);
          
      if (filter == 'local' && getCurrentUserId() != null) {
        // Get user's zip code
        final userDoc = await _firestore.collection('users').doc(getCurrentUserId()!).get();
        final userData = userDoc.data() as Map<String, dynamic>?;
        final zipCode = userData?['zipCode'];
        
        if (zipCode != null && zipCode.isNotEmpty) {
          query = query.where('zipCode', isEqualTo: zipCode);
        }
      }
      
      query = query.orderBy('createdAt', descending: true).limit(limit);
          
      if (lastPostId != null) {
        DocumentSnapshot lastDocSnapshot = 
            await _firestore.collection('posts').doc(lastPostId).get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      final QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('Error getting community feed: $e');
      return [];
    }
  }
  
  // Get trending posts
  Future<List<dynamic>> getTrendingPosts({int limit = 10, String? lastPostId}) async {
    try {
      Query query = _firestore.collection('posts')
          .where('isPublic', isEqualTo: true)
          .where('trending', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);
          
      if (lastPostId != null) {
        DocumentSnapshot lastDocSnapshot = 
            await _firestore.collection('posts').doc(lastPostId).get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      final QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('Error getting trending posts: $e');
      return [];
    }
  }

  // Pick images for post
  Future<List<File>> pickPostImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      return pickedFiles.map((xfile) => File(xfile.path)).toList();
    } catch (e) {
      debugPrint('Error picking images: $e');
      return [];
    }
  }
}
EOL

# Fix ImageModerationService
cat > /Users/kristybock/artbeat/packages/artbeat_artwork/lib/src/services/image_moderation_service.dart << 'EOL'
// filepath: /Users/kristybock/artbeat/packages/artbeat_artwork/lib/src/services/image_moderation_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImageModerationService {
  final String apiKey;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ImageModerationService({required this.apiKey});

  // Check if image is appropriate using third-party API
  Future<Map<String, dynamic>> checkImage(File imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Call API (using placeholder API for demonstration)
      final response = await http.post(
        Uri.parse('https://api.moderatecontent.com/moderate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Api-Key $apiKey',
        },
        body: jsonEncode({
          'image_base64': base64Image,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Log the moderation result
        await _logModerationResult(data, bytes.length);
        
        // Return formatted result
        return {
          'isAppropriate': data['rating_index'] < 2, // 0-1 are appropriate, 2+ are inappropriate
          'confidence': data['rating_confidence'],
          'classification': data['rating_label'],
          'details': data,
        };
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        return {
          'isAppropriate': true, // Fail open - allow if API fails
          'confidence': 0,
          'classification': 'unknown',
          'error': 'API error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Image moderation error: $e');
      return {
        'isAppropriate': true, // Fail open - allow if error occurs
        'confidence': 0,
        'classification': 'error',
        'error': e.toString(),
      };
    }
  }
  
  // Log moderation results for audit and improvement
  Future<void> _logModerationResult(Map<String, dynamic> result, int imageSize) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      await _firestore.collection('moderation_logs').add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'result': result,
        'imageSize': imageSize,
      });
    } catch (e) {
      debugPrint('Error logging moderation result: $e');
    }
  }
  
  // Check batch of images
  Future<List<Map<String, dynamic>>> checkMultipleImages(List<File> images) async {
    final results = <Map<String, dynamic>>[];
    for (final image in images) {
      final result = await checkImage(image);
      results.add(result);
      
      // If any image is inappropriate, can return early
      if (!(result['isAppropriate'] as bool)) {
        break;
      }
    }
    return results;
  }
  
  // Simulate API call for development purposes
  Map<String, dynamic> _simulateApiResult(File image) {
    // This is just a placeholder implementation
    final path = image.path.toLowerCase();
    final isLikelyAppropriate = !path.contains('nsfw') && 
                               !path.contains('violence') &&
                               !path.contains('adult');
                               
    return {
      'isAppropriate': isLikelyAppropriate,
      'confidence': 0.85,
      'classification': isLikelyAppropriate ? 'safe' : 'unsafe',
      'details': {
        'rating_index': isLikelyAppropriate ? 0 : 3,
        'rating_label': isLikelyAppropriate ? 'everyone' : 'adult',
        'rating_confidence': 0.85,
      },
    };
  }
}
EOL

# Make the script executable
chmod +x /Users/kristybock/artbeat/scripts/fix_models.sh

echo "Fixed model files created successfully!"

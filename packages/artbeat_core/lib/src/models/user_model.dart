// packages/artbeat_core/lib/src/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? username;
  final String? bio;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final String? zipCode;
  final String? location;
  final DateTime? birthDate;
  final String? gender;
  final List<String> posts;
  final List<String> followers;
  final List<String> following;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVerified;
  final String userType;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.username,
    this.bio,
    this.profileImageUrl,
    this.coverImageUrl,
    this.zipCode,
    this.location,
    this.birthDate,
    this.gender,
    this.posts = const [],
    this.followers = const [],
    this.following = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.isVerified = false,
    this.userType = 'regular',
  });

  factory UserModel.placeholder(String id) {
    return UserModel(
      id: id,
      email: '',
      fullName: 'WordNerd User',
      username: 'wordnerd_user',
      bio: 'Vocabulary enthusiast and language lover',
      location: 'United States',
      createdAt: DateTime.now(),
      posts: const [],
      followers: const [],
      following: const [],
    );
  }

  bool get isFollowedByCurrentUser {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return currentUserId != null && followers.contains(currentUserId);
  }

  factory UserModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      username: data['username'],
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'],
      coverImageUrl: data['coverImageUrl'],
      zipCode: data['zipCode'],
      location: data['location'],
      birthDate: data['birthDate'] != null
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      gender: data['gender'],
      posts: List<String>.from(data['posts'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      postsCount: data['postsCount'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isVerified: data['isVerified'] ?? false,
      userType: data['userType'] ?? 'regular',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'username': username,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'coverImageUrl': coverImageUrl,
      'zipCode': zipCode,
      'location': location,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'gender': gender,
      'posts': posts,
      'followers': followers,
      'following': following,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isVerified': isVerified,
      'userType': userType,
    };
  }
}

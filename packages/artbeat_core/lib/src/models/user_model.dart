// packages/artbeat_core/lib/src/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_type.dart';

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
  final List<String> captures;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int capturesCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVerified;
  final UserType userType;

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
    this.captures = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.capturesCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.isVerified = false,
    this.userType = UserType.regular,
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
      captures: List<String>.from(data['captures'] ?? []),
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      postsCount: data['postsCount'] ?? 0,
      capturesCount: data['capturesCount'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isVerified: data['isVerified'] ?? false,
      userType: UserType.fromString(
          data['userType'] as String? ?? UserType.regular.name),
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
      'captures': captures,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'capturesCount': capturesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isVerified': isVerified,
      'userType': userType.name,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? username,
    String? bio,
    String? profileImageUrl,
    String? coverImageUrl,
    String? zipCode,
    String? location,
    DateTime? birthDate,
    String? gender,
    List<String>? posts,
    List<String>? followers,
    List<String>? following,
    List<String>? captures,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    int? capturesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    UserType? userType,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      zipCode: zipCode ?? this.zipCode,
      location: location ?? this.location,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      posts: posts ?? this.posts,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      captures: captures ?? this.captures,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      capturesCount: capturesCount ?? this.capturesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      userType: userType ?? this.userType,
    );
  }

  /// Check if user is an artist
  bool get isArtist => userType == UserType.artist;

  /// Check if user is a gallery
  bool get isGallery => userType == UserType.gallery;

  /// Check if user is a moderator
  bool get isModerator => userType == UserType.moderator;

  /// Check if user is an admin
  bool get isAdmin => userType == UserType.admin;

  /// Check if user is a basic user
  bool get isRegularUser => userType == UserType.regular;
}

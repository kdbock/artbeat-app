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
  final int experiencePoints;
  final int level;
  final List<String> achievements;

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
    this.experiencePoints = 0,
    this.level = 1,
    this.achievements = const [],
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
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      username: data['username'] as String?,
      bio: data['bio'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      coverImageUrl: data['coverImageUrl'] as String?,
      zipCode: data['zipCode'] as String?,
      location: data['location'] as String?,
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      gender: data['gender'] as String?,
      posts: List<String>.from(data['posts'] as List<dynamic>? ?? []),
      followers: List<String>.from(data['followers'] as List<dynamic>? ?? []),
      following: List<String>.from(data['following'] as List<dynamic>? ?? []),
      captures: List<String>.from(data['captures'] as List<dynamic>? ?? []),
      followersCount: data['followersCount'] as int? ?? 0,
      followingCount: data['followingCount'] as int? ?? 0,
      postsCount: data['postsCount'] as int? ?? 0,
      capturesCount: data['capturesCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isVerified: data['isVerified'] as bool? ?? false,
      userType: UserType.fromString(
        data['userType'] as String? ?? UserType.regular.name,
      ),
      experiencePoints: data['experiencePoints'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      achievements: List<String>.from(
        data['achievements'] as List<dynamic>? ?? [],
      ),
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
      'experiencePoints': experiencePoints,
      'level': level,
      'achievements': achievements,
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
    int? experiencePoints,
    int? level,
    List<String>? achievements,
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
      experiencePoints: experiencePoints ?? this.experiencePoints,
      level: level ?? this.level,
      achievements: achievements ?? this.achievements,
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

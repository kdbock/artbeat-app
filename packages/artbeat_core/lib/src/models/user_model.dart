// packages/artbeat_core/lib/src/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_type.dart';
import 'capture_model.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String bio;
  final String location;
  final String profileImageUrl;
  final List<String> followers;
  final List<String> following;
  final List<CaptureModel> captures;
  final List<String> posts;
  final DateTime createdAt;
  final DateTime? lastActive;
  final String? userType;
  final Map<String, dynamic>? preferences;
  final int experiencePoints;
  final int level;
  final String? zipCode;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    this.bio = '',
    this.location = '',
    this.profileImageUrl = '',
    this.followers = const [],
    this.following = const [],
    this.captures = const [],
    this.posts = const [],
    required this.createdAt,
    this.lastActive,
    this.userType,
    this.preferences,
    this.experiencePoints = 0,
    this.level = 1,
    this.zipCode,
  });

  // Computed getters for counts
  int get followersCount => followers.length;
  int get followingCount => following.length;
  int get postsCount => posts.length;
  int get capturesCount => captures.length;

  factory UserModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(data)
        .copyWith(id: doc.id); // Use the document ID
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      location: json['location'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String? ?? '',
      followers: List<String>.from(json['followers'] as List<dynamic>? ?? []),
      following: List<String>.from(json['following'] as List<dynamic>? ?? []),
      captures: (json['captures'] as List<dynamic>? ?? [])
          .map((capture) => CaptureModel.fromJson(capture as Map<String, dynamic>))
          .toList(),
      posts: List<String>.from(json['posts'] as List<dynamic>? ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (json['lastActive'] as Timestamp?)?.toDate(),
      userType: json['userType'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
      experiencePoints: json['experiencePoints'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      zipCode: json['zipCode'] as String?,
    );
  }

  /// Placeholder constructor for use in UI development and testing
  factory UserModel.placeholder([String? id]) {
    return UserModel(
      id: id ?? 'placeholder_id',
      email: 'placeholder@example.com',
      username: 'placeholder_user',
      fullName: 'Placeholder User',
      bio: 'This is a placeholder bio for UI development',
      location: 'San Francisco, CA',
      profileImageUrl: '',
      followers: [],
      following: [],
      captures: [],
      posts: [],
      createdAt: DateTime.now(),
      userType: UserType.regular.value,
      preferences: {},
      experiencePoints: 0,
      level: 1,
      zipCode: '94102',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'fullName': fullName,
      'bio': bio,
      'location': location,
      'profileImageUrl': profileImageUrl,
      'followers': followers,
      'following': following,
      'captures': captures.map((capture) => capture.toJson()).toList(),
      'posts': posts,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'userType': userType,
      'preferences': preferences,
      'experiencePoints': experiencePoints,
      'level': level,
      'zipCode': zipCode,
    };
  }

  Map<String, dynamic> toFirestore() => toJson();

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    String? bio,
    String? location,
    String? profileImageUrl,
    List<String>? followers,
    List<String>? following,
    List<CaptureModel>? captures,
    List<String>? posts,
    DateTime? createdAt,
    DateTime? lastActive,
    String? userType,
    Map<String, dynamic>? preferences,
    int? experiencePoints,
    int? level,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      captures: captures ?? this.captures,
      posts: posts ?? this.posts,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      userType: userType ?? this.userType,
      preferences: preferences ?? this.preferences,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      level: level ?? this.level,
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

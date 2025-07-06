import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Extended user model with admin-specific functionality
class UserAdminModel extends UserModel {
  final DateTime? lastLoginAt;
  final DateTime? lastActiveAt;
  final bool isSuspended;
  final bool isDeleted;
  final String? suspensionReason;
  final DateTime? suspendedAt;
  final String? suspendedBy;
  final Map<String, dynamic> adminNotes;
  final List<String> adminFlags;
  final int reportCount;
  final DateTime? emailVerifiedAt;
  final bool requiresPasswordReset;
  final String? coverImageUrl;
  final String? zipCode;
  final DateTime? birthDate;
  final String? gender;
  final DateTime? updatedAt;
  final bool isVerified;
  final int experiencePoints;
  final int level;
  final List<String> achievements;

  UserAdminModel({
    required super.id,
    required super.email,
    required super.username,
    required super.fullName,
    super.bio,
    super.profileImageUrl,
    super.location,
    super.followers,
    super.following,
    super.captures,
    super.posts,
    required super.createdAt,
    super.lastActive,
    super.userType,
    super.preferences,
    this.lastLoginAt,
    this.lastActiveAt,
    this.isSuspended = false,
    this.isDeleted = false,
    this.suspensionReason,
    this.suspendedAt,
    this.suspendedBy,
    this.adminNotes = const {},
    this.adminFlags = const [],
    this.reportCount = 0,
    this.emailVerifiedAt,
    this.requiresPasswordReset = false,
    this.coverImageUrl,
    this.zipCode,
    this.birthDate,
    this.gender,
    this.updatedAt,
    this.isVerified = false,
    this.experiencePoints = 0,
    this.level = 1,
    this.achievements = const [],
  });

  factory UserAdminModel.fromUserModel(UserModel user) {
    return UserAdminModel(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      username: user.username,
      bio: user.bio,
      profileImageUrl: user.profileImageUrl,
      location: user.location,
      posts: user.posts,
      followers: user.followers,
      following: user.following,
      captures: user.captures,
      createdAt: user.createdAt,
      lastActive: user.lastActive,
      userType: user.userType,
      preferences: user.preferences,
    );
  }

  factory UserAdminModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserAdminModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      username: data['username'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      profileImageUrl: data['profileImageUrl'] as String? ?? '',
      location: data['location'] as String? ?? '',
      posts: List<String>.from(data['posts'] as List<dynamic>? ?? []),
      followers: List<String>.from(data['followers'] as List<dynamic>? ?? []),
      following: List<String>.from(data['following'] as List<dynamic>? ?? []),
      captures: (data['captures'] as List<dynamic>? ?? [])
          .map((capture) => CaptureModel.fromJson(capture as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      userType: data['userType'] as String?,
      preferences: data['preferences'] as Map<String, dynamic>?,
      // Admin-specific fields
      coverImageUrl: data['coverImageUrl'] as String?,
      zipCode: data['zipCode'] as String?,
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      gender: data['gender'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isVerified: data['isVerified'] as bool? ?? false,
      experiencePoints: data['experiencePoints'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      achievements: List<String>.from(
        data['achievements'] as List<dynamic>? ?? [],
      ),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate(),
      isSuspended: data['isSuspended'] as bool? ?? false,
      isDeleted: data['isDeleted'] as bool? ?? false,
      suspensionReason: data['suspensionReason'] as String?,
      suspendedAt: (data['suspendedAt'] as Timestamp?)?.toDate(),
      suspendedBy: data['suspendedBy'] as String?,
      adminNotes: Map<String, dynamic>.from(
        data['adminNotes'] as Map<String, dynamic>? ?? {},
      ),
      adminFlags: List<String>.from(
        data['adminFlags'] as List<dynamic>? ?? [],
      ),
      reportCount: data['reportCount'] as int? ?? 0,
      emailVerifiedAt: (data['emailVerifiedAt'] as Timestamp?)?.toDate(),
      requiresPasswordReset: data['requiresPasswordReset'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({
      // Admin-specific fields
      'coverImageUrl': coverImageUrl,
      'zipCode': zipCode,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'gender': gender,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isVerified': isVerified,
      'experiencePoints': experiencePoints,
      'level': level,
      'achievements': achievements,
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'lastActiveAt':
          lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'isSuspended': isSuspended,
      'isDeleted': isDeleted,
      'suspensionReason': suspensionReason,
      'suspendedAt':
          suspendedAt != null ? Timestamp.fromDate(suspendedAt!) : null,
      'suspendedBy': suspendedBy,
      'adminNotes': adminNotes,
      'adminFlags': adminFlags,
      'reportCount': reportCount,
      'emailVerifiedAt':
          emailVerifiedAt != null ? Timestamp.fromDate(emailVerifiedAt!) : null,
      'requiresPasswordReset': requiresPasswordReset,
    });
    return map;
  }

  Map<String, dynamic> toMap() => toJson();

  @override
  UserAdminModel copyWith({
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
    // Admin-specific fields
    String? coverImageUrl,
    String? zipCode,
    DateTime? birthDate,
    String? gender,
    DateTime? updatedAt,
    bool? isVerified,
    int? experiencePoints,
    int? level,
    List<String>? achievements,
    DateTime? lastLoginAt,
    DateTime? lastActiveAt,
    bool? isSuspended,
    bool? isDeleted,
    String? suspensionReason,
    DateTime? suspendedAt,
    String? suspendedBy,
    Map<String, dynamic>? adminNotes,
    List<String>? adminFlags,
    int? reportCount,
    DateTime? emailVerifiedAt,
    bool? requiresPasswordReset,
  }) {
    return UserAdminModel(
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
      // Admin-specific fields
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      zipCode: zipCode ?? this.zipCode,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      level: level ?? this.level,
      achievements: achievements ?? this.achievements,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isSuspended: isSuspended ?? this.isSuspended,
      isDeleted: isDeleted ?? this.isDeleted,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      suspendedBy: suspendedBy ?? this.suspendedBy,
      adminNotes: adminNotes ?? this.adminNotes,
      adminFlags: adminFlags ?? this.adminFlags,
      reportCount: reportCount ?? this.reportCount,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      requiresPasswordReset:
          requiresPasswordReset ?? this.requiresPasswordReset,
    );
  }

  /// Get user status text
  String get statusText {
    if (isDeleted) return 'Deleted';
    if (isSuspended) return 'Suspended';
    if (!isVerified) return 'Unverified';
    return 'Active';
  }

  /// Get user status color
  String get statusColor {
    if (isDeleted) return 'red';
    if (isSuspended) return 'orange';
    if (!isVerified) return 'yellow';
    return 'green';
  }

  /// Check if user is active (logged in within last 30 days)
  bool get isActiveUser {
    if (lastActiveAt == null) return false;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return lastActiveAt!.isAfter(thirtyDaysAgo);
  }
}

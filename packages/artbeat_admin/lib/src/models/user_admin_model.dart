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

  UserAdminModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.username,
    super.bio,
    super.profileImageUrl,
    super.coverImageUrl,
    super.zipCode,
    super.location,
    super.birthDate,
    super.gender,
    super.posts,
    super.followers,
    super.following,
    super.captures,
    super.followersCount,
    super.followingCount,
    super.postsCount,
    super.capturesCount,
    required super.createdAt,
    super.updatedAt,
    super.isVerified,
    super.userType,
    super.experiencePoints,
    super.level,
    super.achievements,
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
  });

  factory UserAdminModel.fromUserModel(UserModel user) {
    return UserAdminModel(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      username: user.username,
      bio: user.bio,
      profileImageUrl: user.profileImageUrl,
      coverImageUrl: user.coverImageUrl,
      zipCode: user.zipCode,
      location: user.location,
      birthDate: user.birthDate,
      gender: user.gender,
      posts: user.posts,
      followers: user.followers,
      following: user.following,
      captures: user.captures,
      followersCount: user.followersCount,
      followingCount: user.followingCount,
      postsCount: user.postsCount,
      capturesCount: user.capturesCount,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isVerified: user.isVerified,
      userType: user.userType,
      experiencePoints: user.experiencePoints,
      level: user.level,
      achievements: user.achievements,
    );
  }

  factory UserAdminModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserAdminModel(
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
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
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

  UserAdminModel copyWith({
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

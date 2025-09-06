/// Account settings model for user account information
/// Implementation Date: September 5, 2025
class AccountSettingsModel {
  final String userId;
  final String email;
  final String username;
  final String displayName;
  final String phoneNumber;
  final String profileImageUrl;
  final String bio;
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountSettingsModel({
    required this.userId,
    required this.email,
    required this.username,
    required this.displayName,
    this.phoneNumber = '',
    this.profileImageUrl = '',
    this.bio = '',
    this.emailVerified = false,
    this.phoneVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountSettingsModel.fromMap(Map<String, dynamic> map) {
    return AccountSettingsModel(
      userId: map['userId'] as String? ?? '',
      email: map['email'] as String? ?? '',
      username: map['username'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      profileImageUrl: map['profileImageUrl'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      emailVerified: map['emailVerified'] as bool? ?? false,
      phoneVerified: map['phoneVerified'] as bool? ?? false,
      createdAt: DateTime.parse(
        map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'username': username,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AccountSettingsModel copyWith({
    String? userId,
    String? email,
    String? username,
    String? displayName,
    String? phoneNumber,
    String? profileImageUrl,
    String? bio,
    bool? emailVerified,
    bool? phoneVerified,
    DateTime? createdAt,
  }) {
    return AccountSettingsModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool isValid() =>
      userId.isNotEmpty &&
      email.isNotEmpty &&
      username.isNotEmpty &&
      displayName.isNotEmpty;
}

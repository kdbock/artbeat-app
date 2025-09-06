/// Blocked user model
/// Implementation Date: September 5, 2025
class BlockedUserModel {
  final String blockedUserId;
  final String blockedUserName;
  final String blockedUserProfileImage;
  final String reason;
  final DateTime blockedAt;
  final String blockedBy;

  const BlockedUserModel({
    required this.blockedUserId,
    required this.blockedUserName,
    this.blockedUserProfileImage = '',
    this.reason = '',
    required this.blockedAt,
    required this.blockedBy,
  });

  factory BlockedUserModel.fromMap(Map<String, dynamic> map) {
    return BlockedUserModel(
      blockedUserId: map['blockedUserId'] as String? ?? '',
      blockedUserName: map['blockedUserName'] as String? ?? '',
      blockedUserProfileImage: map['blockedUserProfileImage'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      blockedAt: DateTime.parse(
        map['blockedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      blockedBy: map['blockedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blockedUserId': blockedUserId,
      'blockedUserName': blockedUserName,
      'blockedUserProfileImage': blockedUserProfileImage,
      'reason': reason,
      'blockedAt': blockedAt.toIso8601String(),
      'blockedBy': blockedBy,
    };
  }

  BlockedUserModel copyWith({
    String? blockedUserId,
    String? blockedUserName,
    String? blockedUserProfileImage,
    String? reason,
    DateTime? blockedAt,
    String? blockedBy,
  }) {
    return BlockedUserModel(
      blockedUserId: blockedUserId ?? this.blockedUserId,
      blockedUserName: blockedUserName ?? this.blockedUserName,
      blockedUserProfileImage:
          blockedUserProfileImage ?? this.blockedUserProfileImage,
      reason: reason ?? this.reason,
      blockedAt: blockedAt ?? this.blockedAt,
      blockedBy: blockedBy ?? this.blockedBy,
    );
  }

  bool isValid() => blockedUserId.isNotEmpty && blockedBy.isNotEmpty;
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user role in the system
enum UserRole { user, artist, gallery, admin, superAdmin }

/// Represents the admin-viewable user data
class AdminUserModel {
  final String id;
  final String email;
  final String? displayName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastSignIn;
  final bool isEnabled;
  final Map<String, dynamic>? metadata;

  AdminUserModel({
    required this.id,
    required this.email,
    this.displayName,
    required this.role,
    required this.createdAt,
    this.lastSignIn,
    this.isEnabled = true,
    this.metadata,
  });

  /// Create from Firestore document
  factory AdminUserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return AdminUserModel(
      id: snapshot.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.user,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastSignIn:
          data['lastSignIn'] != null
              ? (data['lastSignIn'] as Timestamp).toDate()
              : null,
      isEnabled: data['isEnabled'] as bool? ?? true,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      if (displayName != null) 'displayName': displayName,
      'role': role.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastSignIn != null) 'lastSignIn': Timestamp.fromDate(lastSignIn!),
      'isEnabled': isEnabled,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create a copy of this model with some fields replaced
  AdminUserModel copyWith({
    String? email,
    String? displayName,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastSignIn,
    bool? isEnabled,
    Map<String, dynamic>? metadata,
  }) {
    return AdminUserModel(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      isEnabled: isEnabled ?? this.isEnabled,
      metadata: metadata ?? this.metadata,
    );
  }
}

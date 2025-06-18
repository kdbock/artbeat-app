import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String fullName;
  final String username;
  final String avatarUrl;
  final String bio;
  final String location;
  final Timestamp createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.avatarUrl,
    required this.bio,
    required this.location,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      fullName: (data['fullName'] as String?) ?? '',
      username: (data['username'] as String?) ?? '',
      avatarUrl: (data['avatarUrl'] as String?) ?? '',
      bio: (data['bio'] as String?) ?? '',
      location: (data['location'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'username': username,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'location': location,
      'createdAt': createdAt,
    };
  }
}

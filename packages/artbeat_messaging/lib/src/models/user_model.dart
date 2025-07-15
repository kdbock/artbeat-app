import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String displayName;
  final String? photoUrl;
  final DateTime lastSeen;
  final bool isOnline;
  final List<String> deviceTokens;
  final String? username;
  final String? fullName;
  final String? location;
  final String? zipCode;
  DateTime? blockedAt;

  UserModel({
    required this.id,
    required this.displayName,
    this.photoUrl,
    required this.lastSeen,
    this.isOnline = false,
    this.deviceTokens = const [],
    this.username,
    this.fullName,
    this.location,
    this.zipCode,
    this.blockedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      displayName:
          data['displayName'] as String? ??
          data['fullName'] as String? ??
          data['username'] as String? ??
          'Unknown User',
      photoUrl:
          data['photoUrl'] as String? ?? data['profileImageUrl'] as String?,
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen:
          (data['lastSeen'] as Timestamp?)?.toDate() ??
          (data['lastActive'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      deviceTokens: List<String>.from(
        data['deviceTokens'] as Iterable<dynamic>? ?? [],
      ),
      username: data['username'] as String?,
      fullName: data['fullName'] as String?,
      location: data['location'] as String?,
      zipCode: data['zipCode'] as String?,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] as String,
      displayName:
          data['displayName'] as String? ??
          data['fullName'] as String? ??
          data['username'] as String? ??
          'Unknown User',
      photoUrl:
          data['photoUrl'] as String? ?? data['profileImageUrl'] as String?,
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen:
          (data['lastSeen'] as Timestamp?)?.toDate() ??
          (data['lastActive'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      deviceTokens: List<String>.from(
        data['deviceTokens'] as Iterable<dynamic>? ?? [],
      ),
      username: data['username'] as String?,
      fullName: data['fullName'] as String?,
      location: data['location'] as String?,
      zipCode: data['zipCode'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isOnline': isOnline,
      'deviceTokens': deviceTokens,
      'username': username,
      'fullName': fullName,
      'location': location,
      'zipCode': zipCode,
    };
  }
}

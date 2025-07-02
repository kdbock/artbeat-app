import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String displayName;
  final String? photoUrl;
  final DateTime lastSeen;
  final bool isOnline;
  final List<String> deviceTokens;

  const UserModel({
    required this.id,
    required this.displayName,
    this.photoUrl,
    required this.lastSeen,
    this.isOnline = false,
    this.deviceTokens = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      displayName: data['displayName'] as String,
      photoUrl: data['photoUrl'] as String?,
      isOnline: data['isOnline'] as bool,
      lastSeen: (data['lastSeen'] as Timestamp).toDate(),
      deviceTokens: List<String>.from(data['deviceTokens'] as Iterable<dynamic>),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] as String,
      displayName: data['displayName'] as String,
      photoUrl: data['photoUrl'] as String?,
      isOnline: data['isOnline'] as bool,
      lastSeen: (data['lastSeen'] as Timestamp).toDate(),
      deviceTokens: List<String>.from(data['deviceTokens'] as Iterable<dynamic>),
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
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class ArtistModel {
  final String id;
  final String name;
  String? profileImageUrl;
  bool isVerified;
  DateTime createdAt;
  DateTime updatedAt;

  ArtistModel({
    required this.id,
    required this.name,
    this.profileImageUrl,
    this.isVerified = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory ArtistModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return ArtistModel(
      id: snapshot.id,
      name: data['name'] as String,
      profileImageUrl: data['profileImageUrl'] as String?,
      isVerified: data['isVerified'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'profileImageUrl': profileImageUrl,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

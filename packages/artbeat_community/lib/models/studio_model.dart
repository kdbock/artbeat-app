import 'package:cloud_firestore/cloud_firestore.dart';

class StudioModel {
  final String id;
  final String name;
  final String description;
  final List<String> tags;
  final String privacyType; // public, private
  final List<String> memberList;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  StudioModel({
    required this.id,
    required this.name,
    required this.description,
    required this.tags,
    required this.privacyType,
    required this.memberList,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudioModel(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      tags: List<String>.from(data['tags'] as Iterable? ?? []),
      privacyType: (data['privacyType'] as String?) ?? 'public',
      memberList: List<String>.from(data['memberList'] as Iterable? ?? []),
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
      updatedAt: (data['updatedAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  StudioModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? tags,
    String? privacyType,
    List<String>? memberList,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return StudioModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      privacyType: privacyType ?? this.privacyType,
      memberList: memberList ?? this.memberList,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'tags': tags,
      'privacyType': privacyType,
      'memberList': memberList,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

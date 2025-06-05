import 'package:cloud_firestore/cloud_firestore.dart';

class CaptureModel {
  final String id;
  final String userId;
  final String? title;
  final List<String>? textAnnotations;
  final String imageUrl;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final String? location;
  final String? description;
  final bool isProcessed;
  final List<String>? tags;

  CaptureModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.createdAt,
    this.title,
    this.textAnnotations,
    this.thumbnailUrl,
    this.location,
    this.description,
    this.isProcessed = false,
    this.tags,
  });

  factory CaptureModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CaptureModel(
      id: documentId,
      userId: map['userId'] as String,
      title: map['title'] as String?,
      textAnnotations: map['textAnnotations'] != null
          ? List<String>.from(map['textAnnotations'] as List<dynamic>)
          : null,
      imageUrl: map['imageUrl'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      location: map['location'] as String?,
      description: map['description'] as String?,
      isProcessed: map['isProcessed'] as bool? ?? false,
      tags: map['tags'] != null
          ? List<String>.from(map['tags'] as List<dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'textAnnotations': textAnnotations,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'location': location,
      'description': description,
      'isProcessed': isProcessed,
      'tags': tags,
    };
  }

  CaptureModel copyWith({
    String? id,
    String? userId,
    String? title,
    List<String>? textAnnotations,
    String? imageUrl,
    String? thumbnailUrl,
    DateTime? createdAt,
    String? location,
    String? description,
    bool? isProcessed,
    List<String>? tags,
  }) {
    return CaptureModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      textAnnotations: textAnnotations ?? this.textAnnotations,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      description: description ?? this.description,
      isProcessed: isProcessed ?? this.isProcessed,
      tags: tags ?? this.tags,
    );
  }
}

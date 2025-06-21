import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CaptureModel {
  final String id;
  final String userId;
  final String? title;
  final List<String>? textAnnotations;
  final String imageUrl;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final GeoPoint? location;
  final String? locationName;
  final String? description;
  final bool isProcessed;
  final List<String>? tags;
  final String? artistId;
  final String? artistName;
  final bool isPublic;
  final String? artType;
  final String? artMedium;

  CaptureModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.createdAt,
    this.title,
    this.textAnnotations,
    this.thumbnailUrl,
    this.updatedAt,
    this.location,
    this.locationName,
    this.description,
    this.isProcessed = false,
    this.tags,
    this.artistId,
    this.artistName,
    this.isPublic = false,
    this.artType,
    this.artMedium,
  });

  factory CaptureModel.fromJson(Map<String, dynamic> json) {
    return CaptureModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      imageUrl: json['imageUrl'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      title: json['title'] as String?,
      textAnnotations: (json['textAnnotations'] as List<dynamic>?)?.cast<String>(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      location: json['location'] as GeoPoint?,
      locationName: json['locationName'] as String?,
      description: json['description'] as String?,
      isProcessed: json['isProcessed'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      artistId: json['artistId'] as String?,
      artistName: json['artistName'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      artType: json['artType'] as String?,
      artMedium: json['artMedium'] as String?,
    );
  }

  factory CaptureModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return CaptureModel.fromJson({
      ...data,
      'id': snapshot.id,
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'textAnnotations': textAnnotations,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'location': location,
      'locationName': locationName,
      'description': description,
      'isProcessed': isProcessed,
      'tags': tags,
      'artistId': artistId,
      'artistName': artistName,
      'isPublic': isPublic,
      'artType': artType,
      'artMedium': artMedium,
    };
  }

  Map<String, dynamic> toFirestore() => toJson();

  CaptureModel copyWith({
    String? id,
    String? userId,
    String? title,
    List<String>? textAnnotations,
    String? imageUrl,
    String? thumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    GeoPoint? location,
    String? locationName,
    String? description,
    bool? isProcessed,
    List<String>? tags,
    String? artistId,
    String? artistName,
    bool? isPublic,
    String? artType,
    String? artMedium,
  }) {
    return CaptureModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      textAnnotations: textAnnotations ?? this.textAnnotations,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
      description: description ?? this.description,
      isProcessed: isProcessed ?? this.isProcessed,
      tags: tags ?? this.tags,
      artistId: artistId ?? this.artistId,
      artistName: artistName ?? this.artistName,
      isPublic: isPublic ?? this.isPublic,
      artType: artType ?? this.artType,
      artMedium: artMedium ?? this.artMedium,
    );
  }

  @override
  String toString() {
    return 'CaptureModel(id: $id, userId: $userId, title: $title, imageUrl: $imageUrl)';
  }
}

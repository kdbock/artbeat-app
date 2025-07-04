import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for captured art entries
class CaptureModel {
  final String id;
  final String userId;
  final String? title;
  final String? description;
  final String imageUrl;
  final String? artistName;
  final GeoPoint? location;
  final String? locationName;
  final List<String>? tags;
  final String? artType;
  final bool isPublic;
  final bool isProcessed;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CaptureModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.isPublic,
    required this.isProcessed,
    required this.createdAt,
    this.title,
    this.description,
    this.artistName,
    this.location,
    this.locationName,
    this.tags,
    this.artType,
    this.updatedAt,
  });

  /// Create a CaptureModel from Firestore document
  factory CaptureModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    [SnapshotOptions? options]
  ) {
    final data = doc.data()!;
    return CaptureModel(
      id: doc.id,
      userId: data['userId'] as String,
      imageUrl: data['imageUrl'] as String,
      isPublic: data['isPublic'] as bool? ?? false,
      isProcessed: data['isProcessed'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      title: data['title'] as String?,
      description: data['description'] as String?,
      artistName: data['artistName'] as String?,
      location: data['location'] as GeoPoint?,
      locationName: data['locationName'] as String?,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>(),
      artType: data['artType'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert CaptureModel to a Map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'isPublic': isPublic,
      'isProcessed': isProcessed,
      'createdAt': Timestamp.fromDate(createdAt),
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (artistName != null) 'artistName': artistName,
      if (location != null) 'location': location,
      if (locationName != null) 'locationName': locationName,
      if (tags != null) 'tags': tags,
      if (artType != null) 'artType': artType,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

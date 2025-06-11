import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory CaptureModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return CaptureModel(
      id: snapshot.id,
      userId: data['userId'] as String,
      imageUrl: data['imageUrl'] as String,
      title: data['title'] as String?,
      description: data['description'] as String?,
      artistId: data['artistId'] as String?,
      artistName: data['artistName'] as String?,
      location: data['location'] as GeoPoint?,
      locationName: data['locationName'] as String?,
      isPublic: data['isPublic'] as bool? ?? false,
      artType: data['artType'] as String?,
      artMedium: data['artMedium'] as String?,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>(),
      textAnnotations:
          (data['textAnnotations'] as List<dynamic>?)?.cast<String>(),
      thumbnailUrl: data['thumbnailUrl'] as String?,
      isProcessed: data['isProcessed'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'artistId': artistId,
      'artistName': artistName,
      'location': location,
      'locationName': locationName,
      'isPublic': isPublic,
      'artType': artType,
      'artMedium': artMedium,
      'tags': tags,
      'textAnnotations': textAnnotations,
      'thumbnailUrl': thumbnailUrl,
      'isProcessed': isProcessed,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  CaptureModel copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? title,
    String? description,
    String? artistId,
    String? artistName,
    GeoPoint? location,
    String? locationName,
    bool? isPublic,
    String? artType,
    String? artMedium,
    List<String>? tags,
    List<String>? textAnnotations,
    String? thumbnailUrl,
    bool? isProcessed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CaptureModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      artistId: artistId ?? this.artistId,
      artistName: artistName ?? this.artistName,
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
      isPublic: isPublic ?? this.isPublic,
      artType: artType ?? this.artType,
      artMedium: artMedium ?? this.artMedium,
      tags: tags ?? this.tags,
      textAnnotations: textAnnotations ?? this.textAnnotations,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isProcessed: isProcessed ?? this.isProcessed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

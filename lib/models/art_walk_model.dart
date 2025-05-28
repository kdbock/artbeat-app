import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing an Art Walk
class ArtWalkModel {
  final String id;
  final String title;
  final String description;
  final String userId;
  final List<String> publicArtIds;
  final DateTime createdAt;
  final bool isPublic;
  final int viewCount;
  final List<String> imageUrls; // Added for map preview and list view
  final String? zipCode; // Added for NC Region filtering

  ArtWalkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.publicArtIds,
    required this.createdAt,
    this.isPublic = false,
    this.viewCount = 0,
    this.imageUrls = const [],
    this.zipCode, // Added
  });

  factory ArtWalkModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ArtWalkModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      userId: data['userId'] ?? '',
      publicArtIds: List<String>.from(data['publicArtIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublic: data['isPublic'] ?? false,
      viewCount: data['viewCount'] ?? 0,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      zipCode: data['zipCode'], // Added
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'userId': userId,
      'publicArtIds': publicArtIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPublic': isPublic,
      'viewCount': viewCount,
      'imageUrls': imageUrls,
      'zipCode': zipCode, // Added
    };
  }

  ArtWalkModel copyWith({
    String? id,
    String? title,
    String? description,
    String? userId,
    List<String>? publicArtIds,
    DateTime? createdAt,
    bool? isPublic,
    int? viewCount,
    List<String>? imageUrls,
    String? zipCode, // Added
  }) {
    return ArtWalkModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      publicArtIds: publicArtIds ?? this.publicArtIds,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      viewCount: viewCount ?? this.viewCount,
      imageUrls: imageUrls ?? this.imageUrls,
      zipCode: zipCode ?? this.zipCode, // Added
    );
  }
}

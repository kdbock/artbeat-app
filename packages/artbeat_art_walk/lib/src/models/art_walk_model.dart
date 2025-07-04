import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing an Art Walk
class ArtWalkModel {
  final String id;
  final String title;
  final String description;
  final String userId;
  final List<String> artworkIds;
  final DateTime createdAt;
  final bool isPublic;
  final int viewCount;
  final List<String> imageUrls; // Added for map preview and list view
  final String? zipCode; // Added for NC Region filtering
  final double? estimatedDuration; // Duration in minutes
  final double? estimatedDistance; // Distance in miles
  final String? coverImageUrl; // Cover image URL
  final String? routeData; // Encoded route data for map display
  final List<String>? tags; // Tags for categorization
  final String? difficulty; // Difficulty level (Easy, Medium, Hard)
  final bool? isAccessible; // Accessibility information

  ArtWalkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.artworkIds,
    required this.createdAt,
    this.isPublic = false,
    this.viewCount = 0,
    this.imageUrls = const [],
    this.zipCode, // Added
    this.estimatedDuration,
    this.estimatedDistance,
    this.coverImageUrl,
    this.routeData,
    this.tags,
    this.difficulty,
    this.isAccessible,
  });

  factory ArtWalkModel.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ArtWalkModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      artworkIds: List<String>.from(data['artworkIds'] as List<dynamic>? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublic: data['isPublic'] as bool? ?? false,
      viewCount: data['viewCount'] as int? ?? 0,
      imageUrls: List<String>.from(data['imageUrls'] as List<dynamic>? ?? []),
      zipCode: data['zipCode'] as String?, // Added
      estimatedDuration: data['estimatedDuration'] as double?,
      estimatedDistance: data['estimatedDistance'] as double?,
      coverImageUrl: data['coverImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'userId': userId,
      'artworkIds': artworkIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPublic': isPublic,
      'viewCount': viewCount,
      'imageUrls': imageUrls,
      'zipCode': zipCode, // Added
      'estimatedDuration': estimatedDuration,
      'estimatedDistance': estimatedDistance,
      'coverImageUrl': coverImageUrl,
    };
  }

  ArtWalkModel copyWith({
    String? id,
    String? title,
    String? description,
    String? userId,
    List<String>? artworkIds,
    DateTime? createdAt,
    bool? isPublic,
    int? viewCount,
    List<String>? imageUrls,
    String? zipCode, // Added
    double? estimatedDuration,
    double? estimatedDistance,
    String? coverImageUrl,
  }) {
    return ArtWalkModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      artworkIds: artworkIds ?? this.artworkIds,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      viewCount: viewCount ?? this.viewCount,
      imageUrls: imageUrls ?? this.imageUrls,
      zipCode: zipCode ?? this.zipCode, // Added
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }

  List<String> get artPieces => artworkIds;
}

import 'package:cloud_firestore/cloud_firestore.dart';

class ArtworkModel {
  final String id;
  final String title;
  final String description;
  final String artistId;
  final String imageUrl;
  final double price;
  final String medium;
  final List<String> tags;
  final DateTime createdAt;
  final bool isSold;
  final String? galleryId;
  final int applauseCount;
  final int viewsCount;
  final String artistName;

  ArtworkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.artistId,
    required this.imageUrl,
    required this.price,
    required this.medium,
    required this.tags,
    required this.createdAt,
    required this.isSold,
    this.galleryId,
    required this.applauseCount,
    this.viewsCount = 0,
    this.artistName = 'Unknown Artist',
  });

  factory ArtworkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ArtworkModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      artistId: data['artistId'] as String? ?? data['userId'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      medium: data['medium'] as String? ?? '',
      tags: List<String>.from(data['tags'] as List<dynamic>? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSold: data['isSold'] as bool? ?? false,
      galleryId: data['galleryId'] as String?,
      applauseCount: data['applauseCount'] as int? ?? 0,
      viewsCount: data['viewsCount'] as int? ?? data['viewCount'] as int? ?? 0,
      artistName: data['artistName'] as String? ?? 'Unknown Artist',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'artistId': artistId,
      'imageUrl': imageUrl,
      'price': price,
      'medium': medium,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'isSold': isSold,
      if (galleryId != null) 'galleryId': galleryId,
      'applauseCount': applauseCount,
      'viewsCount': viewsCount,
      'artistName': artistName,
    };
  }

  // Compatibility getter for dashboard
  int get likesCount => applauseCount;
}

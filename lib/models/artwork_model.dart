import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing an artwork
class ArtworkModel {
  final String id;
  final String userId;
  final String artistProfileId;
  final String title;
  final String description;
  final String imageUrl;
  final String medium; // e.g., "Oil", "Acrylic"
  final String style; // e.g., "Abstract", "Realism"
  final List<String> tags;
  final String? dimensions;
  final double? price; // null if not for sale
  final bool isForSale;
  final int? year;
  final Timestamp createdAt;
  final bool isFeatured;
  final int viewCount;
  final int likeCount;
  final int commentCount;

  ArtworkModel({
    required this.id,
    required this.userId,
    required this.artistProfileId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.medium,
    required this.style,
    required this.tags,
    this.dimensions,
    this.price,
    required this.isForSale,
    this.year,
    required this.createdAt,
    this.isFeatured = false,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  /// Create ArtworkModel from Firestore document
  factory ArtworkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ArtworkModel(
      id: doc.id,
      userId: data['userId'] as String,
      artistProfileId: data['artistProfileId'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      imageUrl: data['imageUrl'] as String,
      medium: data['medium'] as String,
      style: data['style'] as String,
      tags: List<String>.from(data['tags'] ?? []),
      dimensions: data['dimensions'] as String?,
      price: data['price'] as double?,
      isForSale: data['isForSale'] as bool? ?? false,
      year: data['year'] as int?,
      createdAt: data['createdAt'] as Timestamp,
      isFeatured: data['isFeatured'] as bool? ?? false,
      viewCount: data['viewCount'] as int? ?? 0,
      likeCount: data['likeCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
    );
  }

  /// Convert ArtworkModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'artistProfileId': artistProfileId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'medium': medium,
      'style': style,
      'tags': tags,
      'dimensions': dimensions,
      'price': price,
      'isForSale': isForSale,
      'year': year,
      'createdAt': createdAt,
      'isFeatured': isFeatured,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy of the artwork model with updated fields
  ArtworkModel copyWith({
    String? id,
    String? userId,
    String? artistProfileId,
    String? title,
    String? description,
    String? imageUrl,
    String? medium,
    String? style,
    List<String>? tags,
    String? dimensions,
    double? price,
    bool? isForSale,
    int? year,
    Timestamp? createdAt,
    bool? isFeatured,
    int? viewCount,
    int? likeCount,
    int? commentCount,
  }) {
    return ArtworkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      artistProfileId: artistProfileId ?? this.artistProfileId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      medium: medium ?? this.medium,
      style: style ?? this.style,
      tags: tags ?? this.tags,
      dimensions: dimensions ?? this.dimensions,
      price: price ?? this.price,
      isForSale: isForSale ?? this.isForSale,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      isFeatured: isFeatured ?? this.isFeatured,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}

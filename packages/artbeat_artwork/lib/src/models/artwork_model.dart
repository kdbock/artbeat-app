import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing an artwork item in the ARTbeat platform
class ArtworkModel {
  /// Unique identifier for the artwork
  final String id;

  /// ID of the user who created the artwork
  final String userId;

  /// ID of the artist profile associated with this artwork
  final String artistProfileId;

  /// Title of the artwork
  final String title;

  /// Detailed description of the artwork
  final String description;

  /// URL to the artwork's image in Firebase Storage
  final String imageUrl;

  /// Primary art medium used (e.g., "Oil Paint", "Digital", etc.)
  final String medium;

  /// Artwork styles (e.g., "Abstract", "Modern", "Minimalist")
  final List<String> styles;

  /// Physical dimensions of the artwork (e.g., "24x36 inches")
  final String? dimensions;

  /// Materials used in the artwork
  final String? materials;

  /// Location where the artwork is displayed/stored
  final String? location;

  /// Custom tags for searching and categorization
  final List<String>? tags;

  /// Price of the artwork in the default currency (USD)
  final double? price;

  /// Whether the artwork is currently for sale
  final bool isForSale;

  /// Whether the artwork has been sold
  final bool isSold;

  /// The year the artwork was created
  final int? yearCreated;

  /// Commission rate for galleries (as a percentage)
  final double? commissionRate;

  /// Whether the artwork is featured in the app
  final bool isFeatured;

  /// Whether the artwork is publicly visible
  final bool isPublic;

  /// External link (e.g., to artist's website or shop)
  final String? externalLink;

  /// Number of times the artwork has been viewed
  final int viewCount;

  /// Number of likes the artwork has received
  final int likeCount;

  /// Number of comments on the artwork
  final int commentCount;

  /// Timestamp when the artwork was created
  final DateTime createdAt;

  /// Timestamp of the last update
  final DateTime updatedAt;

  ArtworkModel({
    required this.id,
    required this.userId,
    required this.artistProfileId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.medium,
    required this.styles,
    this.dimensions,
    this.materials,
    this.location,
    this.tags,
    this.price,
    required this.isForSale,
    this.isSold = false,
    this.yearCreated,
    this.commissionRate,
    this.isFeatured = false,
    this.isPublic = true,
    this.externalLink,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ArtworkModel from Firestore document
  factory ArtworkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ArtworkModel(
      id: doc.id,
      // Handle legacy documents that have artistId instead of userId/artistProfileId
      userId: data['userId'] as String? ?? data['artistId'] as String? ?? '',
      artistProfileId: data['artistProfileId'] as String? ??
          data['artistId'] as String? ??
          '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      medium: data['medium'] as String? ?? '',
      styles: (data['styles'] as List<dynamic>? ?? []).cast<String>(),
      dimensions: data['dimensions'] as String?,
      materials: data['materials'] as String?,
      location: data['location'] as String?,
      tags: data['tags'] != null
          ? (data['tags'] as List<dynamic>).cast<String>()
          : null,
      price: data['price'] != null ? (data['price'] as num).toDouble() : null,
      isForSale: data['isForSale'] as bool? ?? false,
      isSold: data['isSold'] as bool? ?? false,
      yearCreated: data['yearCreated'] as int?,
      commissionRate: data['commissionRate'] != null
          ? (data['commissionRate'] as num).toDouble()
          : null,
      isFeatured: data['isFeatured'] as bool? ?? false,
      isPublic: data['isPublic'] as bool? ?? true,
      externalLink: data['externalLink'] as String?,
      viewCount: data['viewCount'] as int? ?? 0,
      likeCount: data['likeCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      'styles': styles,
      'dimensions': dimensions,
      'materials': materials,
      'location': location,
      'tags': tags,
      'price': price,
      'isForSale': isForSale,
      'isSold': isSold,
      'yearCreated': yearCreated,
      'commissionRate': commissionRate,
      'isFeatured': isFeatured,
      'isPublic': isPublic,
      'externalLink': externalLink,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
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
    List<String>? styles,
    String? dimensions,
    String? materials,
    String? location,
    List<String>? tags,
    double? price,
    bool? isForSale,
    bool? isSold,
    int? yearCreated,
    double? commissionRate,
    bool? isFeatured,
    bool? isPublic,
    String? externalLink,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArtworkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      artistProfileId: artistProfileId ?? this.artistProfileId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      medium: medium ?? this.medium,
      styles: styles ?? this.styles,
      dimensions: dimensions ?? this.dimensions,
      materials: materials ?? this.materials,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      price: price ?? this.price,
      isForSale: isForSale ?? this.isForSale,
      isSold: isSold ?? this.isSold,
      yearCreated: yearCreated ?? this.yearCreated,
      commissionRate: commissionRate ?? this.commissionRate,
      isFeatured: isFeatured ?? this.isFeatured,
      isPublic: isPublic ?? this.isPublic,
      externalLink: externalLink ?? this.externalLink,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

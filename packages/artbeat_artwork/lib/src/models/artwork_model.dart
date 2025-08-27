import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

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

  /// URL to the artwork's main image in Firebase Storage
  final String imageUrl;

  /// List of additional image URLs for multiple photos
  final List<String> additionalImageUrls;

  /// List of video URLs for the artwork
  final List<String> videoUrls;

  /// List of audio file URLs for the artwork
  final List<String> audioUrls;

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

  /// Hashtags for social media integration
  final List<String>? hashtags;

  /// Keywords for enhanced search functionality
  final List<String>? keywords;

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

  /// Universal engagement statistics
  final EngagementStats engagementStats;

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
    List<String> additionalImageUrls = const [],
    List<String> videoUrls = const [],
    List<String> audioUrls = const [],
    required this.medium,
    required List<String> styles,
    this.dimensions,
    this.materials,
    this.location,
    List<String>? tags,
    List<String>? hashtags,
    List<String>? keywords,
    this.price,
    required this.isForSale,
    this.isSold = false,
    this.yearCreated,
    this.commissionRate,
    this.isFeatured = false,
    this.isPublic = true,
    this.externalLink,
    this.viewCount = 0,
    EngagementStats? engagementStats,
    required this.createdAt,
    required this.updatedAt,
  })  :
        // Create defensive copies of all lists to prevent external modification
        additionalImageUrls = List.unmodifiable(additionalImageUrls),
        videoUrls = List.unmodifiable(videoUrls),
        audioUrls = List.unmodifiable(audioUrls),
        styles = List.unmodifiable(styles),
        tags = tags != null ? List.unmodifiable(tags) : null,
        hashtags = hashtags != null ? List.unmodifiable(hashtags) : null,
        keywords = keywords != null ? List.unmodifiable(keywords) : null,
        engagementStats =
            engagementStats ?? EngagementStats(lastUpdated: DateTime.now());

  /// Create ArtworkModel from Firestore document
  factory ArtworkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
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
      additionalImageUrls:
          (data['additionalImageUrls'] as List<dynamic>? ?? []).cast<String>(),
      videoUrls: (data['videoUrls'] as List<dynamic>? ?? []).cast<String>(),
      audioUrls: (data['audioUrls'] as List<dynamic>? ?? []).cast<String>(),
      medium: data['medium'] as String? ?? '',
      styles: (data['styles'] as List<dynamic>? ?? []).cast<String>(),
      dimensions: data['dimensions'] as String?,
      materials: data['materials'] as String?,
      location: data['location'] as String?,
      tags: data['tags'] != null
          ? (data['tags'] as List<dynamic>).cast<String>()
          : null,
      hashtags: data['hashtags'] != null
          ? (data['hashtags'] as List<dynamic>).cast<String>()
          : null,
      keywords: data['keywords'] != null
          ? (data['keywords'] as List<dynamic>).cast<String>()
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
      engagementStats: EngagementStats.fromFirestore(data),
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
      'additionalImageUrls': additionalImageUrls,
      'videoUrls': videoUrls,
      'audioUrls': audioUrls,
      'medium': medium,
      'styles': styles,
      'dimensions': dimensions,
      'materials': materials,
      'location': location,
      'tags': tags,
      'hashtags': hashtags,
      'keywords': keywords,
      'price': price,
      'isForSale': isForSale,
      'isSold': isSold,
      'yearCreated': yearCreated,
      'commissionRate': commissionRate,
      'isFeatured': isFeatured,
      'isPublic': isPublic,
      'externalLink': externalLink,
      'viewCount': viewCount,
      ...engagementStats.toFirestore(),
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
    List<String>? additionalImageUrls,
    List<String>? videoUrls,
    List<String>? audioUrls,
    String? medium,
    List<String>? styles,
    String? dimensions,
    String? materials,
    String? location,
    List<String>? tags,
    List<String>? hashtags,
    List<String>? keywords,
    double? price,
    bool? isForSale,
    bool? isSold,
    int? yearCreated,
    double? commissionRate,
    bool? isFeatured,
    bool? isPublic,
    String? externalLink,
    int? viewCount,
    EngagementStats? engagementStats,
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
      additionalImageUrls: additionalImageUrls ?? this.additionalImageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      audioUrls: audioUrls ?? this.audioUrls,
      medium: medium ?? this.medium,
      styles: styles ?? this.styles,
      dimensions: dimensions ?? this.dimensions,
      materials: materials ?? this.materials,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      hashtags: hashtags ?? this.hashtags,
      keywords: keywords ?? this.keywords,
      price: price ?? this.price,
      isForSale: isForSale ?? this.isForSale,
      isSold: isSold ?? this.isSold,
      yearCreated: yearCreated ?? this.yearCreated,
      commissionRate: commissionRate ?? this.commissionRate,
      isFeatured: isFeatured ?? this.isFeatured,
      isPublic: isPublic ?? this.isPublic,
      externalLink: externalLink ?? this.externalLink,
      viewCount: viewCount ?? this.viewCount,
      engagementStats: engagementStats ?? this.engagementStats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Backward compatibility getters for migration period
  int get likeCount => engagementStats.appreciateCount;
  int get commentCount => engagementStats.discussCount;
  int get applauseCount => engagementStats.appreciateCount;

  // Dashboard compatibility getters
  int get likesCount => engagementStats.appreciateCount;
  int get viewsCount => viewCount;

  // Artist name getter - this would need to be populated from artist profile data
  // For now, return a placeholder that can be overridden when artist data is available
  String get artistName => 'Unknown Artist';
}

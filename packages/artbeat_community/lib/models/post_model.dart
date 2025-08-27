import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'group_models.dart';

/// Model class for posts in the community feed
class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String content;
  final List<String> imageUrls;
  final List<String> tags;
  final String location;
  final GeoPoint? geoPoint;
  final String? zipCode;
  final DateTime createdAt;
  final EngagementStats engagementStats;
  final bool isPublic;
  final List<String>? mentionedUsers;
  final Map<String, dynamic>? metadata;
  final bool isUserVerified;

  // Legacy constant for backward compatibility during migration
  static const int maxApplausePerUser = 5;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.content,
    required this.imageUrls,
    required this.tags,
    required this.location,
    this.geoPoint,
    this.zipCode,
    required this.createdAt,
    EngagementStats? engagementStats,
    this.isPublic = true,
    this.mentionedUsers,
    this.metadata,
    this.isUserVerified = false,
  }) : engagementStats =
           engagementStats ?? EngagementStats(lastUpdated: DateTime.now());

  /// Create from BaseGroupPost
  factory PostModel.fromBaseGroupPost(BaseGroupPost post) {
    return PostModel(
      id: post.id,
      userId: post.userId,
      userName: post.userName,
      userPhotoUrl: post.userPhotoUrl,
      content: post.content,
      imageUrls: post.imageUrls,
      tags: post.tags, // tags map to tags
      location: post.location,
      createdAt: post.createdAt,
      engagementStats: EngagementStats(
        appreciateCount: post.applauseCount,
        discussCount: post.commentCount,
        amplifyCount: post.shareCount,
        lastUpdated: post.createdAt,
      ),
      isPublic: post.isPublic,
      isUserVerified: post.isUserVerified,
    );
  }

  /// Create from Firestore document - newer convention
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    return PostModel.fromDocument(doc);
  }

  /// Create from document - older convention
  factory PostModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final result = PostModel(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      userName: (data['userName'] as String?) ?? '',
      userPhotoUrl: (data['userPhotoUrl'] as String?) ?? '',
      content: (data['content'] as String?) ?? '',
      imageUrls: List<String>.from(data['imageUrls'] as Iterable? ?? []),
      tags: List<String>.from(data['tags'] as Iterable? ?? []),
      location: (data['location'] as String?) ?? '',
      geoPoint: data['geoPoint'] as GeoPoint?,
      zipCode: data['zipCode'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      engagementStats: EngagementStats.fromFirestore(data),
      isPublic: (data['isPublic'] as bool?) ?? true,
      mentionedUsers: data['mentionedUsers'] != null
          ? List<String>.from(data['mentionedUsers'] as Iterable)
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
      isUserVerified: (data['isUserVerified'] as bool?) ?? false,
    );

    return result;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'imageUrls': imageUrls,
      'tags': tags,
      'location': location,
      'geoPoint': geoPoint,
      'zipCode': zipCode,
      'createdAt': Timestamp.fromDate(createdAt),
      ...engagementStats.toFirestore(),
      'isPublic': isPublic,
      'mentionedUsers': mentionedUsers,
      'metadata': metadata,
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? content,
    List<String>? imageUrls,
    List<String>? tags,
    String? location,
    GeoPoint? geoPoint,
    String? zipCode,
    DateTime? createdAt,
    EngagementStats? engagementStats,
    bool? isPublic,
    bool? isUserVerified,
    List<String>? mentionedUsers,
    Map<String, dynamic>? metadata,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      geoPoint: geoPoint ?? this.geoPoint,
      zipCode: zipCode ?? this.zipCode,
      createdAt: createdAt ?? this.createdAt,
      engagementStats: engagementStats ?? this.engagementStats,
      isPublic: isPublic ?? this.isPublic,
      isUserVerified: isUserVerified ?? this.isUserVerified,
      mentionedUsers: mentionedUsers ?? this.mentionedUsers,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Getter for authorUsername - returns userName for compatibility
  String get authorUsername => userName;

  /// Getter for authorName - returns userName for compatibility
  String get authorName => userName;

  /// Getter for authorProfileImageUrl - returns userPhotoUrl for compatibility
  String get authorProfileImageUrl => userPhotoUrl;

  // Backward compatibility getters for migration period
  int get applauseCount => engagementStats.appreciateCount;
  int get commentCount => engagementStats.discussCount;
  int get shareCount => engagementStats.amplifyCount;

  // Dashboard compatibility getters
  int get likesCount => engagementStats.appreciateCount;
  int get commentsCount => engagementStats.discussCount;
  int get sharesCount => engagementStats.amplifyCount;
}

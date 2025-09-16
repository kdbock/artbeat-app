import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'group_models.dart';

/// Moderation status for posts
enum PostModerationStatus {
  pending,
  approved,
  rejected,
  flagged,
  underReview;

  String get displayName {
    switch (this) {
      case PostModerationStatus.pending:
        return 'Pending Review';
      case PostModerationStatus.approved:
        return 'Approved';
      case PostModerationStatus.rejected:
        return 'Rejected';
      case PostModerationStatus.flagged:
        return 'Flagged';
      case PostModerationStatus.underReview:
        return 'Under Review';
    }
  }

  String get value {
    switch (this) {
      case PostModerationStatus.pending:
        return 'pending';
      case PostModerationStatus.approved:
        return 'approved';
      case PostModerationStatus.rejected:
        return 'rejected';
      case PostModerationStatus.flagged:
        return 'flagged';
      case PostModerationStatus.underReview:
        return 'underReview';
    }
  }

  static PostModerationStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return PostModerationStatus.approved;
      case 'rejected':
        return PostModerationStatus.rejected;
      case 'flagged':
        return PostModerationStatus.flagged;
      case 'underreview':
        return PostModerationStatus.underReview;
      case 'pending':
      default:
        return PostModerationStatus.pending;
    }
  }
}

/// Model class for posts in the community feed
class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String content;
  final List<String> imageUrls;
  final String? videoUrl;
  final String? audioUrl;
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
  final PostModerationStatus moderationStatus;
  final bool flagged;
  final DateTime? flaggedAt;
  final String? moderationNotes;
  final bool isLikedByCurrentUser;

  // Legacy constant for backward compatibility during migration
  static const int maxApplausePerUser = 5;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.content,
    required this.imageUrls,
    this.videoUrl,
    this.audioUrl,
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
    this.moderationStatus = PostModerationStatus.approved,
    this.flagged = false,
    this.flaggedAt,
    this.moderationNotes,
    this.isLikedByCurrentUser = false,
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
      videoUrl: null, // BaseGroupPost doesn't have video
      audioUrl: null, // BaseGroupPost doesn't have audio
      tags: post.tags, // tags map to tags
      location: post.location,
      createdAt: post.createdAt,
      engagementStats: EngagementStats(
        likeCount: post.applauseCount,
        commentCount: post.commentCount,
        shareCount: post.shareCount,
        lastUpdated: post.createdAt,
      ),
      isPublic: post.isPublic,
      isUserVerified: post.isUserVerified,
      moderationStatus: PostModerationStatus.approved,
      flagged: false,
      isLikedByCurrentUser: false, // This will be set separately when loading
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
      videoUrl: data['videoUrl'] as String?,
      audioUrl: data['audioUrl'] as String?,
      tags: List<String>.from(data['tags'] as Iterable? ?? []),
      location: (data['location'] as String?) ?? '',
      geoPoint: data['geoPoint'] as GeoPoint?,
      zipCode: data['zipCode'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      engagementStats: EngagementStats.fromFirestore(
        data['engagementStats'] as Map<String, dynamic>? ?? data,
      ),
      isPublic: (data['isPublic'] as bool?) ?? true,
      mentionedUsers: data['mentionedUsers'] != null
          ? List<String>.from(data['mentionedUsers'] as Iterable)
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
      isUserVerified: (data['isUserVerified'] as bool?) ?? false,
      moderationStatus: PostModerationStatus.fromString(
        data['moderationStatus'] as String? ?? 'approved',
      ),
      flagged: (data['flagged'] as bool?) ?? false,
      flaggedAt: (data['flaggedAt'] as Timestamp?)?.toDate(),
      moderationNotes: data['moderationNotes'] as String?,
      isLikedByCurrentUser:
          false, // This will be set separately when loading posts with user context
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
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'tags': tags,
      'location': location,
      'geoPoint': geoPoint,
      'zipCode': zipCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'engagementStats': engagementStats.toFirestore(),
      'isPublic': isPublic,
      'mentionedUsers': mentionedUsers,
      'metadata': metadata,
      'moderationStatus': moderationStatus.value,
      'flagged': flagged,
      'flaggedAt': flaggedAt != null ? Timestamp.fromDate(flaggedAt!) : null,
      'moderationNotes': moderationNotes,
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? content,
    List<String>? imageUrls,
    String? videoUrl,
    String? audioUrl,
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
    PostModerationStatus? moderationStatus,
    bool? flagged,
    DateTime? flaggedAt,
    String? moderationNotes,
    bool? isLikedByCurrentUser,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
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
      moderationStatus: moderationStatus ?? this.moderationStatus,
      flagged: flagged ?? this.flagged,
      flaggedAt: flaggedAt ?? this.flaggedAt,
      moderationNotes: moderationNotes ?? this.moderationNotes,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }

  /// Getter for authorUsername - returns userName for compatibility
  String get authorUsername => userName;

  /// Getter for authorName - returns userName for compatibility
  String get authorName => userName;

  /// Getter for authorProfileImageUrl - returns userPhotoUrl for compatibility
  String get authorProfileImageUrl => userPhotoUrl;

  // Backward compatibility getters for migration period
  int get applauseCount => engagementStats.likeCount;
  int get commentCount => engagementStats.commentCount;
  int get shareCount => engagementStats.shareCount;

  // Dashboard compatibility getters
  int get likesCount => engagementStats.likeCount;
  int get commentsCount => engagementStats.commentCount;
  int get sharesCount => engagementStats.shareCount;
}

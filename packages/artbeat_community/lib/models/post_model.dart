import 'package:cloud_firestore/cloud_firestore.dart';

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
  final int applauseCount;
  final int commentCount;
  final int shareCount;
  final bool isPublic;
  final List<String>? mentionedUsers;
  final Map<String, dynamic>? metadata;
  final bool isUserVerified;

  // Maximum applause per user is always 5
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
    this.applauseCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isPublic = true,
    this.mentionedUsers,
    this.metadata,
    this.isUserVerified = false,
  });

  /// Create from Firestore document - newer convention
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    return PostModel.fromDocument(doc);
  }

  /// Create from document - older convention
  factory PostModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PostModel(
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
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      applauseCount: (data['applauseCount'] as int?) ?? 0,
      commentCount: (data['commentCount'] as int?) ?? 0,
      shareCount: (data['shareCount'] as int?) ?? 0,
      isPublic: (data['isPublic'] as bool?) ?? true,
      mentionedUsers: data['mentionedUsers'] != null
          ? List<String>.from(data['mentionedUsers'] as Iterable)
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
      isUserVerified: (data['isUserVerified'] as bool?) ?? false,
    );
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
      'applauseCount': applauseCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
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
    int? applauseCount,
    int? commentCount,
    int? shareCount,
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
      applauseCount: applauseCount ?? this.applauseCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isPublic: isPublic ?? this.isPublic,
      isUserVerified: isUserVerified ?? this.isUserVerified,
      mentionedUsers: mentionedUsers ?? this.mentionedUsers,
      metadata: metadata ?? this.metadata,
    );
  }
}

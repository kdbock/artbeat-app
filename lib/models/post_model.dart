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
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isPublic;
  final List<String>? mentionedUsers;
  final Map<String, dynamic>? metadata;
  
  /// Constructor
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
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.isPublic,
    this.mentionedUsers,
    this.metadata,
  });
  
  /// Create a PostModel from Firestore document
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      location: data['location'] ?? '',
      geoPoint: data['geoPoint'],
      zipCode: data['zipCode'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      shareCount: data['shareCount'] ?? 0,
      isPublic: data['isPublic'] ?? true,
      mentionedUsers: data['mentionedUsers'] != null 
          ? List<String>.from(data['mentionedUsers']) 
          : null,
      metadata: data['metadata'],
    );
  }
  
  /// Convert PostModel to a map for Firestore
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
      'likeCount': likeCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'isPublic': isPublic,
      'mentionedUsers': mentionedUsers,
      'metadata': metadata,
    };
  }
  
  /// Create a copy of this PostModel with updated values
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
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? isPublic,
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
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isPublic: isPublic ?? this.isPublic,
      mentionedUsers: mentionedUsers ?? this.mentionedUsers,
      metadata: metadata ?? this.metadata,
    );
  }
}
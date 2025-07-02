import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final List<String> tags;
  final int likes;
  final int comments;
  final String? artworkId;
  final String? eventId;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.imageUrls,
    required this.createdAt,
    required this.tags,
    required this.likes,
    required this.comments,
    this.artworkId,
    this.eventId,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      imageUrls: List<String>.from(data['imageUrls'] as List<dynamic>? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: List<String>.from(data['tags'] as List<dynamic>? ?? []),
      likes: data['likes'] as int? ?? 0,
      comments: data['comments'] as int? ?? 0,
      artworkId: data['artworkId'] as String?,
      eventId: data['eventId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'content': content,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'tags': tags,
      'likes': likes,
      'comments': comments,
      if (artworkId != null) 'artworkId': artworkId,
      if (eventId != null) 'eventId': eventId,
    };
  }
}

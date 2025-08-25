import 'package:cloud_firestore/cloud_firestore.dart';

/// Content model for admin management
/// Represents various types of content (posts, artworks, events, etc.)
class ContentModel {
  final String id;
  final String title;
  final String description;
  final String type; // 'post', 'artwork', 'event', etc.
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final String status; // 'active', 'inactive', 'draft'
  final String moderationStatus; // 'pending', 'approved', 'rejected'
  final double engagementScore;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final String? thumbnailUrl;

  ContentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.status = 'active',
    this.moderationStatus = 'pending',
    this.engagementScore = 0.0,
    this.tags = const [],
    this.metadata = const {},
    this.thumbnailUrl,
  });

  factory ContentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContentModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: data['type'] as String? ?? 'post',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'active',
      moderationStatus: data['moderationStatus'] as String? ?? 'pending',
      engagementScore: ((data['engagementScore'] as num?) ?? 0.0).toDouble(),
      tags: List<String>.from(data['tags'] as List<dynamic>? ?? []),
      metadata: Map<String, dynamic>.from(
          data['metadata'] as Map<dynamic, dynamic>? ?? {}),
      thumbnailUrl: data['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'moderationStatus': moderationStatus,
      'engagementScore': engagementScore,
      'tags': tags,
      'metadata': metadata,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  ContentModel copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    String? status,
    String? moderationStatus,
    double? engagementScore,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    String? thumbnailUrl,
  }) {
    return ContentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      engagementScore: engagementScore ?? this.engagementScore,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Content type enumeration for content review
enum ContentType {
  all,
  artwork,
  post,
  comment,
  profile,
  event;

  String get displayName {
    switch (this) {
      case ContentType.all:
        return 'All Content';
      case ContentType.artwork:
        return 'Artworks';
      case ContentType.post:
        return 'Posts';
      case ContentType.comment:
        return 'Comments';
      case ContentType.profile:
        return 'Profiles';
      case ContentType.event:
        return 'Events';
    }
  }

  static ContentType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'artwork':
        return ContentType.artwork;
      case 'post':
        return ContentType.post;
      case 'comment':
        return ContentType.comment;
      case 'profile':
        return ContentType.profile;
      case 'event':
        return ContentType.event;
      default:
        return ContentType.all;
    }
  }
}

/// Content review status
enum ReviewStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case ReviewStatus.pending:
        return 'Pending';
      case ReviewStatus.approved:
        return 'Approved';
      case ReviewStatus.rejected:
        return 'Rejected';
    }
  }

  static ReviewStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'approved':
        return ReviewStatus.approved;
      case 'rejected':
        return ReviewStatus.rejected;
      default:
        return ReviewStatus.pending;
    }
  }
}

/// Model for content review items
class ContentReviewModel {
  final String id;
  final String contentId;
  final ContentType contentType;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final ReviewStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final Map<String, dynamic> metadata;

  ContentReviewModel({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.metadata = const {},
  });

  /// Create from Firestore document
  factory ContentReviewModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    String _asString(dynamic value, [String fallback = '']) {
      if (value is String) return value;
      if (value == null) return fallback;
      return value.toString();
    }

    String? _asNullableString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    Map<String, dynamic> _asMap(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return {};
    }

    return ContentReviewModel(
      id: doc.id,
      contentId: _asString(data['contentId']),
      contentType: ContentType.fromString(_asString(data['contentType'])),
      title: _asString(data['title']),
      description: _asString(data['description']),
      authorId: _asString(data['authorId']),
      authorName: _asString(data['authorName']),
      status: ReviewStatus.fromString(_asString(data['status'], 'pending')),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      reviewedAt: (data['reviewedAt'] is Timestamp)
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: _asNullableString(data['reviewedBy']),
      rejectionReason: _asNullableString(data['rejectionReason']),
      metadata: _asMap(data['metadata']),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toDocument() {
    return {
      'contentId': contentId,
      'contentType': contentType.name,
      'title': title,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  ContentReviewModel copyWith({
    String? id,
    String? contentId,
    ContentType? contentType,
    String? title,
    String? description,
    String? authorId,
    String? authorName,
    ReviewStatus? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    Map<String, dynamic>? metadata,
  }) {
    return ContentReviewModel(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      title: title ?? this.title,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      metadata: metadata ?? this.metadata,
    );
  }
}

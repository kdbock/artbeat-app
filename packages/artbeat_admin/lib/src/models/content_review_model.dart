import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of content that can be reviewed
enum ContentType {
  ads,
  captures,
  all;

  String get displayName {
    switch (this) {
      case ContentType.ads:
        return 'Ads';
      case ContentType.captures:
        return 'Captures';
      case ContentType.all:
        return 'All Content';
    }
  }

  static ContentType fromString(String value) {
    return ContentType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ContentType.captures,
    );
  }
}

/// Review status for content
enum ReviewStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case ReviewStatus.pending:
        return 'Pending Review';
      case ReviewStatus.approved:
        return 'Approved';
      case ReviewStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Model for content that needs admin review
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
  final Map<String, dynamic>? metadata;

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
    this.metadata,
  });

  factory ContentReviewModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ContentReviewModel(
      id: doc.id,
      contentId: (data['contentId'] as String?) ?? '',
      contentType: ContentType.values.firstWhere(
        (type) => type.name == data['contentType'],
        orElse: () => ContentType.captures,
      ),
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      authorId: (data['authorId'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? '',
      status: ReviewStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => ReviewStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: data['reviewedBy'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Alias for fromFirestore to maintain compatibility
  factory ContentReviewModel.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return ContentReviewModel.fromFirestore(doc);
  }

  Map<String, dynamic> toFirestore() {
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

  // Alias for toFirestore to maintain compatibility
  Map<String, dynamic> toDocument() {
    return toFirestore();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:logging/logging.dart';
import '../models/content_review_model.dart';

/// Result of a paginated query
class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final int totalCount;

  PaginatedResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
    required this.totalCount,
  });
}

/// Service for handling pagination of content reviews
/// Implements efficient cursor-based pagination for large datasets
class ContentPaginationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('ContentPaginationService');

  static const int _defaultPageSize = 20;
  static const int _maxPageSize = 100;

  /// Get paginated pending content reviews
  Future<PaginatedResult<ContentReviewModel>> getPendingReviewsPaginated({
    ContentType? contentType,
    int pageSize = _defaultPageSize,
    DocumentSnapshot? startAfter,
    ModerationFilters? filters,
  }) async {
    try {
      // Validate page size
      final actualPageSize = pageSize.clamp(1, _maxPageSize);

      final allReviews = <ContentReviewModel>[];
      DocumentSnapshot? lastDoc;

      // Get pending captures if contentType is captures or all
      if (contentType == null ||
          contentType == ContentType.all ||
          contentType == ContentType.captures) {
        final result = await _getPendingCapturesPaginated(
          pageSize: actualPageSize,
          startAfter: startAfter,
          filters: filters,
        );
        allReviews.addAll(result.items);
        lastDoc = result.lastDocument;
      }

      // Get pending posts if contentType is posts or all
      if (contentType == null ||
          contentType == ContentType.all ||
          contentType == ContentType.posts) {
        final result = await _getPendingPostsPaginated(
          pageSize: actualPageSize,
          startAfter: startAfter,
          filters: filters,
        );
        allReviews.addAll(result.items);
        if (lastDoc == null ||
            (result.lastDocument != null &&
                result.lastDocument!.data() != null)) {
          lastDoc = result.lastDocument;
        }
      }

      // Get pending comments if contentType is comments or all
      if (contentType == null ||
          contentType == ContentType.all ||
          contentType == ContentType.comments) {
        final result = await _getPendingCommentsPaginated(
          pageSize: actualPageSize,
          startAfter: startAfter,
          filters: filters,
        );
        allReviews.addAll(result.items);
        if (lastDoc == null ||
            (result.lastDocument != null &&
                result.lastDocument!.data() != null)) {
          lastDoc = result.lastDocument;
        }
      }

      // Get pending artwork if contentType is artwork or all
      if (contentType == null ||
          contentType == ContentType.all ||
          contentType == ContentType.artwork) {
        final result = await _getPendingArtworkPaginated(
          pageSize: actualPageSize,
          startAfter: startAfter,
          filters: filters,
        );
        allReviews.addAll(result.items);
        if (lastDoc == null ||
            (result.lastDocument != null &&
                result.lastDocument!.data() != null)) {
          lastDoc = result.lastDocument;
        }
      }

      // Sort by creation date (most recent first)
      allReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply limit after combining and sorting
      final limitedReviews = allReviews.take(actualPageSize).toList();

      return PaginatedResult(
        items: limitedReviews,
        lastDocument: lastDoc,
        hasMore: allReviews.length > actualPageSize,
        totalCount: allReviews.length,
      );
    } catch (e) {
      _logger.severe('Error getting paginated pending reviews', e);
      return PaginatedResult(
        items: [],
        hasMore: false,
        totalCount: 0,
      );
    }
  }

  /// Get paginated pending captures
  Future<PaginatedResult<ContentReviewModel>> _getPendingCapturesPaginated({
    required int pageSize,
    DocumentSnapshot? startAfter,
    ModerationFilters? filters,
  }) async {
    try {
      Query query = _firestore
          .collection('captures')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true);

      // Apply filters
      if (filters != null) {
        query = _applyFiltersToQuery(query, filters);
      }

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      } else {
        query = query.limit(pageSize);
      }

      final snapshot = await query.get();
      final reviews = <ContentReviewModel>[];

      for (final doc in snapshot.docs) {
        final review = await _createCaptureReviewModel(doc);
        if (review != null) {
          reviews.add(review);
        }
      }

      return PaginatedResult(
        items: reviews,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == pageSize,
        totalCount: reviews.length,
      );
    } catch (e) {
      _logger.warning('Error getting paginated captures', e);
      return PaginatedResult(
        items: [],
        hasMore: false,
        totalCount: 0,
      );
    }
  }

  /// Get paginated pending posts
  Future<PaginatedResult<ContentReviewModel>> _getPendingPostsPaginated({
    required int pageSize,
    DocumentSnapshot? startAfter,
    ModerationFilters? filters,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .where('flagged', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      // Apply filters
      if (filters != null) {
        query = _applyFiltersToQuery(query, filters);
      }

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      } else {
        query = query.limit(pageSize);
      }

      final snapshot = await query.get();
      final reviews = <ContentReviewModel>[];

      for (final doc in snapshot.docs) {
        final review = await _createPostReviewModel(doc);
        if (review != null) {
          reviews.add(review);
        }
      }

      return PaginatedResult(
        items: reviews,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == pageSize,
        totalCount: reviews.length,
      );
    } catch (e) {
      _logger.warning('Error getting paginated posts', e);
      return PaginatedResult(
        items: [],
        hasMore: false,
        totalCount: 0,
      );
    }
  }

  /// Get paginated pending comments
  Future<PaginatedResult<ContentReviewModel>> _getPendingCommentsPaginated({
    required int pageSize,
    DocumentSnapshot? startAfter,
    ModerationFilters? filters,
  }) async {
    try {
      Query query = _firestore
          .collection('comments')
          .where('flagged', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      // Apply filters
      if (filters != null) {
        query = _applyFiltersToQuery(query, filters);
      }

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      } else {
        query = query.limit(pageSize);
      }

      final snapshot = await query.get();
      final reviews = <ContentReviewModel>[];

      for (final doc in snapshot.docs) {
        final review = await _createCommentReviewModel(doc);
        if (review != null) {
          reviews.add(review);
        }
      }

      return PaginatedResult(
        items: reviews,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == pageSize,
        totalCount: reviews.length,
      );
    } catch (e) {
      _logger.warning('Error getting paginated comments', e);
      return PaginatedResult(
        items: [],
        hasMore: false,
        totalCount: 0,
      );
    }
  }

  /// Get paginated pending artwork
  Future<PaginatedResult<ContentReviewModel>> _getPendingArtworkPaginated({
    required int pageSize,
    DocumentSnapshot? startAfter,
    ModerationFilters? filters,
  }) async {
    try {
      Query query = _firestore
          .collection('artwork')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true);

      // Apply filters
      if (filters != null) {
        query = _applyFiltersToQuery(query, filters);
      }

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      } else {
        query = query.limit(pageSize);
      }

      final snapshot = await query.get();
      final reviews = <ContentReviewModel>[];

      for (final doc in snapshot.docs) {
        final review = await _createArtworkReviewModel(doc);
        if (review != null) {
          reviews.add(review);
        }
      }

      return PaginatedResult(
        items: reviews,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == pageSize,
        totalCount: reviews.length,
      );
    } catch (e) {
      _logger.warning('Error getting paginated artwork', e);
      return PaginatedResult(
        items: [],
        hasMore: false,
        totalCount: 0,
      );
    }
  }

  /// Apply filters to Firestore query
  Query _applyFiltersToQuery(Query query, ModerationFilters filters) {
    // Apply date range filter
    if (filters.dateFrom != null) {
      query =
          query.where('createdAt', isGreaterThanOrEqualTo: filters.dateFrom);
    }
    if (filters.dateTo != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: filters.dateTo);
    }

    // Apply priority filter
    if (filters.priority != null) {
      query = query.where('priority', isEqualTo: filters.priority);
    }

    // Apply flag reason filter
    if (filters.flagReason != null) {
      query = query.where('flagReason', isEqualTo: filters.flagReason);
    }

    return query;
  }

  /// Create ContentReviewModel from capture document
  Future<ContentReviewModel?> _createCaptureReviewModel(
      DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Get user info for author name
      String authorName = 'Unknown User';
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(data['userId'] as String?)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          authorName = (userData['fullName'] as String?) ??
              (userData['username'] as String?) ??
              'Unknown User';
        }
      } catch (e) {
        // Continue with default name if user lookup fails
      }

      return ContentReviewModel(
        id: doc.id,
        contentId: doc.id,
        contentType: ContentType.captures,
        title: (data['title'] as String?) ?? 'Untitled Capture',
        description:
            (data['description'] as String?) ?? 'No description provided',
        authorId: (data['userId'] as String?) ?? '',
        authorName: authorName,
        status: ReviewStatus.pending,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        metadata: {
          'imageUrl': data['imageUrl'],
          'thumbnailUrl': data['thumbnailUrl'],
          'location': data['location'],
          'locationName': data['locationName'],
          'tags': data['tags'],
          'artistId': data['artistId'],
          'artistName': data['artistName'],
        },
      );
    } catch (e) {
      _logger.warning('Error creating capture review model', e);
      return null;
    }
  }

  /// Create ContentReviewModel from post document
  Future<ContentReviewModel?> _createPostReviewModel(
      DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Get user info for author name
      String authorName = 'Unknown User';
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(data['userId'] as String?)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          authorName = (userData['fullName'] as String?) ??
              (userData['username'] as String?) ??
              'Unknown User';
        }
      } catch (e) {
        // Continue with default name if user lookup fails
      }

      return ContentReviewModel(
        id: doc.id,
        contentId: doc.id,
        contentType: ContentType.posts,
        title: 'Post by $authorName',
        description: (data['content'] as String?) ?? 'No content provided',
        authorId: (data['userId'] as String?) ?? '',
        authorName: authorName,
        status: ReviewStatus.flagged,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        metadata: {
          'content': data['content'],
          'imageUrls': data['imageUrls'],
          'tags': data['tags'],
          'location': data['location'],
          'userName': data['userName'],
          'userPhotoUrl': data['userPhotoUrl'],
          'isPublic': data['isPublic'],
          'flaggedAt': data['flaggedAt'],
          'moderationStatus': data['moderationStatus'],
        },
      );
    } catch (e) {
      _logger.warning('Error creating post review model', e);
      return null;
    }
  }

  /// Create ContentReviewModel from comment document
  Future<ContentReviewModel?> _createCommentReviewModel(
      DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Get user info for author name
      String authorName = 'Unknown User';
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(data['userId'] as String?)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          authorName = (userData['fullName'] as String?) ??
              (userData['username'] as String?) ??
              'Unknown User';
        }
      } catch (e) {
        // Continue with default name if user lookup fails
      }

      return ContentReviewModel(
        id: doc.id,
        contentId: doc.id,
        contentType: ContentType.comments,
        title: 'Comment by $authorName',
        description: (data['content'] as String?) ?? 'No content provided',
        authorId: (data['userId'] as String?) ?? '',
        authorName: authorName,
        status: ReviewStatus.flagged,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        metadata: {
          'content': data['content'],
          'postId': data['postId'],
          'parentId': data['parentId'],
          'flaggedAt': data['flaggedAt'],
          'moderationStatus': data['moderationStatus'],
        },
      );
    } catch (e) {
      _logger.warning('Error creating comment review model', e);
      return null;
    }
  }

  /// Create ContentReviewModel from artwork document
  Future<ContentReviewModel?> _createArtworkReviewModel(
      DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Get user info for author name
      String authorName = 'Unknown User';
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(data['artistId'] as String?)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          authorName = (userData['fullName'] as String?) ??
              (userData['username'] as String?) ??
              'Unknown User';
        }
      } catch (e) {
        // Continue with default name if user lookup fails
      }

      return ContentReviewModel(
        id: doc.id,
        contentId: doc.id,
        contentType: ContentType.artwork,
        title: (data['title'] as String?) ?? 'Untitled Artwork',
        description:
            (data['description'] as String?) ?? 'No description provided',
        authorId: (data['artistId'] as String?) ?? '',
        authorName: authorName,
        status: ReviewStatus.pending,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        metadata: {
          'imageUrl': data['imageUrl'],
          'thumbnailUrl': data['thumbnailUrl'],
          'medium': data['medium'],
          'dimensions': data['dimensions'],
          'year': data['year'],
          'price': data['price'],
          'tags': data['tags'],
          'isPublic': data['isPublic'],
        },
      );
    } catch (e) {
      _logger.warning('Error creating artwork review model', e);
      return null;
    }
  }

  /// Get total count of pending content for pagination info
  Future<int> getTotalPendingCount({
    ContentType? contentType,
    ModerationFilters? filters,
  }) async {
    try {
      int totalCount = 0;

      // Count pending captures
      if (contentType == null ||
          contentType == ContentType.all ||
          contentType == ContentType.captures) {
        final capturesCount = await _firestore
            .collection('captures')
            .where('status', isEqualTo: 'pending')
            .count()
            .get();
        totalCount += capturesCount.count ?? 0;
      }

      // Count flagged posts
      if (contentType == null ||
          contentType == ContentType.all ||
          contentType == ContentType.posts) {
        final postsCount = await _firestore
            .collection('posts')
            .where('flagged', isEqualTo: true)
            .count()
            .get();
        totalCount += postsCount.count ?? 0;
      }

      // Count flagged comments
      if (contentType == null ||
          contentType == ContentType.all ||
          contentType == ContentType.comments) {
        final commentsCount = await _firestore
            .collection('comments')
            .where('flagged', isEqualTo: true)
            .count()
            .get();
        totalCount += commentsCount.count ?? 0;
      }

      // Count pending artwork
      if (contentType == null ||
          contentType == ContentType.all ||
          contentType == ContentType.artwork) {
        final artworkCount = await _firestore
            .collection('artwork')
            .where('status', isEqualTo: 'pending')
            .count()
            .get();
        totalCount += artworkCount.count ?? 0;
      }

      return totalCount;
    } catch (e) {
      _logger.severe('Error getting total pending count', e);
      return 0;
    }
  }
}

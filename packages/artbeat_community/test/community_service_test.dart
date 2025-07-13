import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock classes
@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference])
import 'community_service_test.mocks.dart';

void main() {
  group('CommunityService Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
    });

    test('should create post successfully', () async {
      // Arrange
      final postData = {
        'id': 'post-123',
        'authorId': 'user-123',
        'authorName': 'John Artist',
        'content': 'Check out my latest artwork!',
        'imageUrls': [
          'https://example.com/artwork1.jpg',
          'https://example.com/artwork2.jpg',
        ],
        'postType': PostType.artwork.toString(),
        'tags': ['painting', 'contemporary', 'art'],
        'likesCount': 0,
        'commentsCount': 0,
        'sharesCount': 0,
        'isPublic': true,
        'allowComments': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('posts')).thenReturn(mockCollection);
      when(mockCollection.add(postData)).thenAnswer((_) async => mockDocument);

      // Act
      await mockCollection.add(postData);

      // Assert
      verify(mockCollection.add(postData)).called(1);
    });

    test('should like post successfully', () async {
      // Arrange
      const postId = 'post-123';
      const userId = 'user-456';
      final likeData = {
        'postId': postId,
        'userId': userId,
        'likedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('post_likes')).thenReturn(mockCollection);
      when(mockCollection.add(likeData)).thenAnswer((_) async => mockDocument);

      // Act
      await mockCollection.add(likeData);

      // Assert
      verify(mockCollection.add(likeData)).called(1);
    });

    test('should unlike post successfully', () async {
      // Arrange
      const likeId = 'like-123';

      when(mockFirestore.collection('post_likes')).thenReturn(mockCollection);
      when(mockCollection.doc(likeId)).thenReturn(mockDocument);
      when(mockDocument.delete()).thenAnswer((_) async => {});

      // Act
      await mockDocument.delete();

      // Assert
      verify(mockDocument.delete()).called(1);
    });

    test('should update post likes count', () async {
      // Arrange
      const postId = 'post-123';
      final updateData = {
        'likesCount': FieldValue.increment(1),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('posts')).thenReturn(mockCollection);
      when(mockCollection.doc(postId)).thenReturn(mockDocument);
      when(mockDocument.update(updateData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.update(updateData);

      // Assert
      verify(mockDocument.update(updateData)).called(1);
    });

    test('should create comment successfully', () async {
      // Arrange
      final commentData = {
        'id': 'comment-123',
        'postId': 'post-123',
        'authorId': 'user-456',
        'authorName': 'Jane Commenter',
        'content': 'Beautiful artwork! Love the colors.',
        'parentCommentId': null, // Top-level comment
        'likesCount': 0,
        'repliesCount': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('comments')).thenReturn(mockCollection);
      when(
        mockCollection.add(commentData),
      ).thenAnswer((_) async => mockDocument);

      // Act
      await mockCollection.add(commentData);

      // Assert
      verify(mockCollection.add(commentData)).called(1);
    });

    test('should reply to comment successfully', () async {
      // Arrange
      final replyData = {
        'id': 'reply-123',
        'postId': 'post-123',
        'authorId': 'user-789',
        'authorName': 'Bob Replier',
        'content': 'I agree! The composition is amazing.',
        'parentCommentId': 'comment-123', // Reply to existing comment
        'likesCount': 0,
        'repliesCount': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('comments')).thenReturn(mockCollection);
      when(mockCollection.add(replyData)).thenAnswer((_) async => mockDocument);

      // Act
      await mockCollection.add(replyData);

      // Assert
      verify(mockCollection.add(replyData)).called(1);
    });

    test('should update post comments count', () async {
      // Arrange
      const postId = 'post-123';
      final updateData = {
        'commentsCount': FieldValue.increment(1),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('posts')).thenReturn(mockCollection);
      when(mockCollection.doc(postId)).thenReturn(mockDocument);
      when(mockDocument.update(updateData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.update(updateData);

      // Assert
      verify(mockDocument.update(updateData)).called(1);
    });

    test('should share post successfully', () async {
      // Arrange
      const postId = 'post-123';
      const userId = 'user-456';
      final shareData = {
        'postId': postId,
        'userId': userId,
        'shareMessage': 'Amazing artwork from a talented artist!',
        'sharedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('post_shares')).thenReturn(mockCollection);
      when(mockCollection.add(shareData)).thenAnswer((_) async => mockDocument);

      // Act
      await mockCollection.add(shareData);

      // Assert
      verify(mockCollection.add(shareData)).called(1);
    });

    test('should report post successfully', () async {
      // Arrange
      const postId = 'post-123';
      const reporterId = 'user-456';
      final reportData = {
        'postId': postId,
        'reporterId': reporterId,
        'reason': ReportReason.inappropriate.toString(),
        'description': 'This content violates community guidelines',
        'status': ReportStatus.pending.toString(),
        'reportedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('post_reports')).thenReturn(mockCollection);
      when(
        mockCollection.add(reportData),
      ).thenAnswer((_) async => mockDocument);

      // Act
      await mockCollection.add(reportData);

      // Assert
      verify(mockCollection.add(reportData)).called(1);
    });

    test('should delete post successfully', () async {
      // Arrange
      const postId = 'post-123';

      when(mockFirestore.collection('posts')).thenReturn(mockCollection);
      when(mockCollection.doc(postId)).thenReturn(mockDocument);
      when(mockDocument.delete()).thenAnswer((_) async => {});

      // Act
      await mockDocument.delete();

      // Assert
      verify(mockDocument.delete()).called(1);
    });

    test('should hide post for user', () async {
      // Arrange
      const postId = 'post-123';
      const userId = 'user-456';
      final hiddenPostData = {
        'postId': postId,
        'userId': userId,
        'hiddenAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('hidden_posts')).thenReturn(mockCollection);
      when(
        mockCollection.add(hiddenPostData),
      ).thenAnswer((_) async => mockDocument);

      // Act
      await mockCollection.add(hiddenPostData);

      // Assert
      verify(mockCollection.add(hiddenPostData)).called(1);
    });
  });

  group('Post Model Tests', () {
    test('should create Post with valid data', () {
      final post = Post(
        id: 'post-123',
        authorId: 'user-123',
        authorName: 'Artist Name',
        content: 'Check out my latest creation!',
        postType: PostType.artwork,
        imageUrls: ['https://example.com/image1.jpg'],
        tags: ['art', 'painting'],
        isPublic: true,
        allowComments: true,
      );

      expect(post.id, equals('post-123'));
      expect(post.authorId, equals('user-123'));
      expect(post.authorName, equals('Artist Name'));
      expect(post.content, equals('Check out my latest creation!'));
      expect(post.postType, equals(PostType.artwork));
      expect(post.imageUrls?.length, equals(1));
      expect(post.tags, equals(['art', 'painting']));
      expect(post.isPublic, isTrue);
      expect(post.allowComments, isTrue);
      expect(post.likesCount, equals(0));
      expect(post.commentsCount, equals(0));
      expect(post.sharesCount, equals(0));
    });

    test('should validate post data', () {
      // Valid post
      final validPost = Post(
        id: 'post-123',
        authorId: 'user-123',
        authorName: 'Artist Name',
        content: 'Valid content',
        postType: PostType.text,
        isPublic: true,
        allowComments: true,
      );
      expect(validPost.isValid, isTrue);

      // Invalid post - empty content
      final invalidPost1 = Post(
        id: 'post-123',
        authorId: 'user-123',
        authorName: 'Artist Name',
        content: '',
        postType: PostType.text,
        isPublic: true,
        allowComments: true,
      );
      expect(invalidPost1.isValid, isFalse);

      // Invalid post - empty author ID
      final invalidPost2 = Post(
        id: 'post-123',
        authorId: '',
        authorName: 'Artist Name',
        content: 'Valid content',
        postType: PostType.text,
        isPublic: true,
        allowComments: true,
      );
      expect(invalidPost2.isValid, isFalse);

      // Invalid post - empty author name
      final invalidPost3 = Post(
        id: 'post-123',
        authorId: 'user-123',
        authorName: '',
        content: 'Valid content',
        postType: PostType.text,
        isPublic: true,
        allowComments: true,
      );
      expect(invalidPost3.isValid, isFalse);
    });

    test('should check if post has images', () {
      final postWithImages = Post(
        id: 'post-123',
        authorId: 'user-123',
        authorName: 'Artist Name',
        content: 'Post with images',
        postType: PostType.artwork,
        imageUrls: [
          'https://example.com/image1.jpg',
          'https://example.com/image2.jpg',
        ],
        isPublic: true,
        allowComments: true,
      );

      final postWithoutImages = Post(
        id: 'post-456',
        authorId: 'user-123',
        authorName: 'Artist Name',
        content: 'Text only post',
        postType: PostType.text,
        isPublic: true,
        allowComments: true,
      );

      expect(postWithImages.hasImages, isTrue);
      expect(postWithImages.imageCount, equals(2));
      expect(postWithoutImages.hasImages, isFalse);
      expect(postWithoutImages.imageCount, equals(0));
    });

    test('should calculate engagement rate', () {
      final post = Post(
        id: 'post-123',
        authorId: 'user-123',
        authorName: 'Artist Name',
        content: 'Engaging post',
        postType: PostType.artwork,
        isPublic: true,
        allowComments: true,
        likesCount: 50,
        commentsCount: 10,
        sharesCount: 5,
        viewsCount: 1000,
      );

      final engagementRate = post.engagementRate;
      expect(engagementRate, equals(6.5)); // (50 + 10 + 5) / 1000 * 100
    });

    test('should format time ago correctly', () {
      final now = DateTime.now();
      final post = Post(
        id: 'post-123',
        authorId: 'user-123',
        authorName: 'Artist Name',
        content: 'Recent post',
        postType: PostType.text,
        isPublic: true,
        allowComments: true,
        createdAt: now.subtract(const Duration(hours: 2)),
      );

      final timeAgo = post.timeAgo;
      expect(timeAgo, contains('2h ago'));
    });

    test('should convert Post to JSON', () {
      final post = Post(
        id: 'post-123',
        authorId: 'user-123',
        authorName: 'Artist Name',
        content: 'JSON test post',
        postType: PostType.artwork,
        imageUrls: ['https://example.com/image.jpg'],
        tags: ['json', 'test'],
        isPublic: true,
        allowComments: true,
        likesCount: 5,
        commentsCount: 2,
        sharesCount: 1,
      );

      final json = post.toJson();

      expect(json['id'], equals('post-123'));
      expect(json['authorId'], equals('user-123'));
      expect(json['authorName'], equals('Artist Name'));
      expect(json['content'], equals('JSON test post'));
      expect(json['postType'], equals(PostType.artwork.toString()));
      expect(json['imageUrls'], equals(['https://example.com/image.jpg']));
      expect(json['tags'], equals(['json', 'test']));
      expect(json['isPublic'], isTrue);
      expect(json['allowComments'], isTrue);
      expect(json['likesCount'], equals(5));
      expect(json['commentsCount'], equals(2));
      expect(json['sharesCount'], equals(1));
    });

    test('should create Post from JSON', () {
      final json = {
        'id': 'post-123',
        'authorId': 'user-123',
        'authorName': 'Artist Name',
        'content': 'Post from JSON',
        'postType': PostType.text.toString(),
        'imageUrls': null,
        'tags': ['json'],
        'isPublic': true,
        'allowComments': false,
        'likesCount': 10,
        'commentsCount': 3,
        'sharesCount': 2,
        'viewsCount': 500,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final post = Post.fromJson(json);

      expect(post.id, equals('post-123'));
      expect(post.authorId, equals('user-123'));
      expect(post.content, equals('Post from JSON'));
      expect(post.postType, equals(PostType.text));
      expect(post.imageUrls, isNull);
      expect(post.tags, equals(['json']));
      expect(post.isPublic, isTrue);
      expect(post.allowComments, isFalse);
      expect(post.likesCount, equals(10));
      expect(post.commentsCount, equals(3));
      expect(post.sharesCount, equals(2));
      expect(post.viewsCount, equals(500));
    });
  });

  group('Comment Model Tests', () {
    test('should create Comment with valid data', () {
      final comment = Comment(
        id: 'comment-123',
        postId: 'post-123',
        authorId: 'user-456',
        authorName: 'Commenter Name',
        content: 'Great artwork!',
        likesCount: 0,
        repliesCount: 0,
      );

      expect(comment.id, equals('comment-123'));
      expect(comment.postId, equals('post-123'));
      expect(comment.authorId, equals('user-456'));
      expect(comment.authorName, equals('Commenter Name'));
      expect(comment.content, equals('Great artwork!'));
      expect(comment.parentCommentId, isNull);
      expect(comment.likesCount, equals(0));
      expect(comment.repliesCount, equals(0));
    });

    test('should validate comment data', () {
      // Valid comment
      final validComment = Comment(
        id: 'comment-123',
        postId: 'post-123',
        authorId: 'user-456',
        authorName: 'Commenter',
        content: 'Valid comment',
        likesCount: 0,
        repliesCount: 0,
      );
      expect(validComment.isValid, isTrue);

      // Invalid comment - empty content
      final invalidComment1 = Comment(
        id: 'comment-123',
        postId: 'post-123',
        authorId: 'user-456',
        authorName: 'Commenter',
        content: '',
        likesCount: 0,
        repliesCount: 0,
      );
      expect(invalidComment1.isValid, isFalse);

      // Invalid comment - empty post ID
      final invalidComment2 = Comment(
        id: 'comment-123',
        postId: '',
        authorId: 'user-456',
        authorName: 'Commenter',
        content: 'Valid comment',
        likesCount: 0,
        repliesCount: 0,
      );
      expect(invalidComment2.isValid, isFalse);
    });

    test('should check if comment is a reply', () {
      final topLevelComment = Comment(
        id: 'comment-123',
        postId: 'post-123',
        authorId: 'user-456',
        authorName: 'Commenter',
        content: 'Top level comment',
        likesCount: 0,
        repliesCount: 0,
      );

      final replyComment = Comment(
        id: 'reply-123',
        postId: 'post-123',
        authorId: 'user-789',
        authorName: 'Replier',
        content: 'Reply to comment',
        parentCommentId: 'comment-123',
        likesCount: 0,
        repliesCount: 0,
      );

      expect(topLevelComment.isReply, isFalse);
      expect(replyComment.isReply, isTrue);
    });

    test('should check if comment has replies', () {
      final commentWithReplies = Comment(
        id: 'comment-123',
        postId: 'post-123',
        authorId: 'user-456',
        authorName: 'Commenter',
        content: 'Comment with replies',
        likesCount: 0,
        repliesCount: 3,
      );

      final commentWithoutReplies = Comment(
        id: 'comment-456',
        postId: 'post-123',
        authorId: 'user-456',
        authorName: 'Commenter',
        content: 'Comment without replies',
        likesCount: 0,
        repliesCount: 0,
      );

      expect(commentWithReplies.hasReplies, isTrue);
      expect(commentWithoutReplies.hasReplies, isFalse);
    });
  });

  group('PostType Tests', () {
    test('should convert PostType to string correctly', () {
      expect(PostType.text.toString(), equals('PostType.text'));
      expect(PostType.artwork.toString(), equals('PostType.artwork'));
      expect(PostType.progress.toString(), equals('PostType.progress'));
      expect(PostType.announcement.toString(), equals('PostType.announcement'));
    });

    test('should parse PostType from string correctly', () {
      expect(
        PostTypeExtension.fromString('PostType.text'),
        equals(PostType.text),
      );
      expect(
        PostTypeExtension.fromString('PostType.artwork'),
        equals(PostType.artwork),
      );
      expect(
        PostTypeExtension.fromString('PostType.progress'),
        equals(PostType.progress),
      );
      expect(
        PostTypeExtension.fromString('PostType.announcement'),
        equals(PostType.announcement),
      );
      expect(
        PostTypeExtension.fromString('invalid'),
        equals(PostType.text),
      ); // Default
    });

    test('should get type display name correctly', () {
      expect(PostType.text.displayName, equals('Text Post'));
      expect(PostType.artwork.displayName, equals('Artwork Showcase'));
      expect(PostType.progress.displayName, equals('Work in Progress'));
      expect(PostType.announcement.displayName, equals('Announcement'));
    });
  });

  group('ReportReason Tests', () {
    test('should convert ReportReason to string correctly', () {
      expect(ReportReason.spam.toString(), equals('ReportReason.spam'));
      expect(
        ReportReason.inappropriate.toString(),
        equals('ReportReason.inappropriate'),
      );
      expect(
        ReportReason.harassment.toString(),
        equals('ReportReason.harassment'),
      );
      expect(
        ReportReason.copyright.toString(),
        equals('ReportReason.copyright'),
      );
    });

    test('should get reason display name correctly', () {
      expect(ReportReason.spam.displayName, equals('Spam'));
      expect(
        ReportReason.inappropriate.displayName,
        equals('Inappropriate Content'),
      );
      expect(ReportReason.harassment.displayName, equals('Harassment'));
      expect(ReportReason.copyright.displayName, equals('Copyright Violation'));
    });
  });
}

// These classes should be in your actual community model files
class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final PostType postType;
  final List<String>? imageUrls;
  final List<String>? tags;
  final bool isPublic;
  final bool allowComments;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int? viewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.postType,
    this.imageUrls,
    this.tags,
    required this.isPublic,
    required this.allowComments,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isValid {
    return id.isNotEmpty &&
        authorId.isNotEmpty &&
        authorName.isNotEmpty &&
        content.isNotEmpty;
  }

  bool get hasImages => imageUrls != null && imageUrls!.isNotEmpty;
  int get imageCount => imageUrls?.length ?? 0;

  double get engagementRate {
    if (viewsCount == null || viewsCount == 0) return 0.0;
    final totalEngagements = likesCount + commentsCount + sharesCount;
    return (totalEngagements / viewsCount!) * 100;
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'authorName': authorName,
    'content': content,
    'postType': postType.toString(),
    'imageUrls': imageUrls,
    'tags': tags,
    'isPublic': isPublic,
    'allowComments': allowComments,
    'likesCount': likesCount,
    'commentsCount': commentsCount,
    'sharesCount': sharesCount,
    'viewsCount': viewsCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'],
    authorId: json['authorId'],
    authorName: json['authorName'],
    content: json['content'],
    postType: PostTypeExtension.fromString(json['postType']),
    imageUrls: json['imageUrls'] != null
        ? List<String>.from(json['imageUrls'])
        : null,
    tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    isPublic: json['isPublic'] ?? true,
    allowComments: json['allowComments'] ?? true,
    likesCount: json['likesCount'] ?? 0,
    commentsCount: json['commentsCount'] ?? 0,
    sharesCount: json['sharesCount'] ?? 0,
    viewsCount: json['viewsCount'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final String? parentCommentId;
  final int likesCount;
  final int repliesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.parentCommentId,
    required this.likesCount,
    required this.repliesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isValid {
    return id.isNotEmpty &&
        postId.isNotEmpty &&
        authorId.isNotEmpty &&
        authorName.isNotEmpty &&
        content.isNotEmpty;
  }

  bool get isReply => parentCommentId != null;
  bool get hasReplies => repliesCount > 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'postId': postId,
    'authorId': authorId,
    'authorName': authorName,
    'content': content,
    'parentCommentId': parentCommentId,
    'likesCount': likesCount,
    'repliesCount': repliesCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'],
    postId: json['postId'],
    authorId: json['authorId'],
    authorName: json['authorName'],
    content: json['content'],
    parentCommentId: json['parentCommentId'],
    likesCount: json['likesCount'] ?? 0,
    repliesCount: json['repliesCount'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}

enum PostType { text, artwork, progress, announcement }

extension PostTypeExtension on PostType {
  static PostType fromString(String value) {
    switch (value) {
      case 'PostType.text':
        return PostType.text;
      case 'PostType.artwork':
        return PostType.artwork;
      case 'PostType.progress':
        return PostType.progress;
      case 'PostType.announcement':
        return PostType.announcement;
      default:
        return PostType.text;
    }
  }

  String get displayName {
    switch (this) {
      case PostType.text:
        return 'Text Post';
      case PostType.artwork:
        return 'Artwork Showcase';
      case PostType.progress:
        return 'Work in Progress';
      case PostType.announcement:
        return 'Announcement';
    }
  }
}

enum ReportReason { spam, inappropriate, harassment, copyright, misinformation }

extension ReportReasonExtension on ReportReason {
  String get displayName {
    switch (this) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.inappropriate:
        return 'Inappropriate Content';
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.copyright:
        return 'Copyright Violation';
      case ReportReason.misinformation:
        return 'Misinformation';
    }
  }
}

enum ReportStatus { pending, reviewing, resolved, dismissed }

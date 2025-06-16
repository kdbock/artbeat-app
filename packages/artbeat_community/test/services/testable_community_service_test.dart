import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_community/services/testable_community_service.dart';
import 'package:artbeat_community/models/post_model.dart';
import 'package:artbeat_community/models/comment_model.dart';

// Generate mocks for the IImagePickerService
@GenerateNiceMocks([MockSpec<IImagePickerService>()])
import 'testable_community_service_test.mocks.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late TestableCommunityService communityService;
  late MockIImagePickerService mockImagePickerService;

  const testUserId = 'test-user-id';
  const testUserName = 'Test User';
  const testUserPhotoUrl = 'https://example.com/photo.jpg';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockImagePickerService = MockIImagePickerService();

    communityService = TestableCommunityService(
      firestore: fakeFirestore,
      imagePickerService: mockImagePickerService,
    );
  });

  group('TestableCommunityService Tests', () {
    test('pickPostImages returns result from image picker service', () async {
      // Arrange
      final mockFiles = [File('test_file_path')];
      when(mockImagePickerService.pickImages())
          .thenAnswer((_) async => mockFiles);

      // Act
      final result = await communityService.pickPostImages();

      // Assert
      expect(result, equals(mockFiles));
      verify(mockImagePickerService.pickImages()).called(1);
    });

    test('getPosts returns empty list when no posts exist', () async {
      // Act
      final posts = await communityService.getPosts();

      // Assert
      expect(posts, isEmpty);
    });

    test('createPost adds post to Firestore and returns ID', () async {
      // Act
      final postId = await communityService.createPost(
        userId: testUserId,
        userName: testUserName,
        userPhotoUrl: testUserPhotoUrl,
        content: 'Test post content',
        imageUrls: ['https://example.com/image.jpg'],
        tags: ['test', 'art'],
      );

      // Assert
      expect(postId, isNotNull);

      // Verify post was added to Firestore
      final postDoc = await fakeFirestore.collection('posts').doc(postId).get();
      expect(postDoc.exists, isTrue);
      expect(postDoc.data()!['userId'], equals(testUserId));
      expect(postDoc.data()!['content'], equals('Test post content'));
      expect((postDoc.data()!['imageUrls'] as List).first,
          equals('https://example.com/image.jpg'));
      expect((postDoc.data()!['tags'] as List), contains('test'));
    });

    test('getPostsByUserId returns posts for specific user', () async {
      // Arrange
      // Add a post for test user
      final postId = await communityService.createPost(
        userId: testUserId,
        userName: testUserName,
        userPhotoUrl: testUserPhotoUrl,
        content: 'Test user post',
        imageUrls: [],
      );

      // Add a post for another user
      await communityService.createPost(
        userId: 'other-user-id',
        userName: 'Other User',
        userPhotoUrl: 'https://example.com/other.jpg',
        content: 'Other user post',
        imageUrls: [],
      );

      // Act
      final posts = await communityService.getPostsByUserId(testUserId);

      // Assert
      expect(posts.length, equals(1));
      expect(posts.first.id, equals(postId));
      expect(posts.first.userId, equals(testUserId));
      expect(posts.first.content, equals('Test user post'));
    });

    test('deletePost removes post from Firestore', () async {
      // Arrange
      final postId = await communityService.createPost(
        userId: testUserId,
        userName: testUserName,
        userPhotoUrl: testUserPhotoUrl,
        content: 'To be deleted',
        imageUrls: [],
      );

      // Verify post exists
      var postDoc = await fakeFirestore.collection('posts').doc(postId).get();
      expect(postDoc.exists, isTrue);

      // Act
      final result = await communityService.deletePost(postId!);

      // Assert
      expect(result, isTrue);

      // Verify post was deleted
      postDoc = await fakeFirestore.collection('posts').doc(postId).get();
      expect(postDoc.exists, isFalse);
    });

    test('addComment adds comment to post and updates comment count', () async {
      // Arrange
      final postId = await communityService.createPost(
        userId: testUserId,
        userName: testUserName,
        userPhotoUrl: testUserPhotoUrl,
        content: 'Post for comment',
        imageUrls: [],
      );

      // Act
      final commentId = await communityService.addComment(
        postId: postId!,
        userId: testUserId,
        content: 'Test comment',
        userName: testUserName,
        userAvatarUrl: testUserPhotoUrl,
        type: 'Appreciation',
      );

      // Assert
      expect(commentId, isNotNull);

      // Verify comment was added
      final commentDoc = await fakeFirestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .get();

      expect(commentDoc.exists, isTrue);
      expect(commentDoc.data()!['content'], equals('Test comment'));

      // Verify comment count was updated
      final updatedPostDoc =
          await fakeFirestore.collection('posts').doc(postId).get();
      expect(updatedPostDoc.data()!['commentCount'], equals(1));
    });

    test('getComments returns comments for a post', () async {
      // Arrange
      final postId = await communityService.createPost(
        userId: testUserId,
        userName: testUserName,
        userPhotoUrl: testUserPhotoUrl,
        content: 'Post with comments',
        imageUrls: [],
      );

      // Add comments
      await communityService.addComment(
        postId: postId!,
        userId: testUserId,
        content: 'First comment',
        userName: testUserName,
        userAvatarUrl: testUserPhotoUrl,
      );

      await communityService.addComment(
        postId: postId,
        userId: 'other-user-id',
        content: 'Second comment',
        userName: 'Other User',
        userAvatarUrl: 'https://example.com/other.jpg',
      );

      // Act
      final comments = await communityService.getComments(postId);

      // Assert
      expect(comments.length, equals(2));

      // Comments should be ordered by createdAt descending, but since we're using
      // FieldValue.serverTimestamp() in a fake environment, we can't rely on the order
      // so we'll just check that both comments are there
      expect(comments.map((c) => c.content).toList()..sort(),
          equals(['First comment', 'Second comment']..sort()));
    });

    test('addApplauseToPost adds applause and updates count', () async {
      // Arrange
      final postId = await communityService.createPost(
        userId: testUserId,
        userName: testUserName,
        userPhotoUrl: testUserPhotoUrl,
        content: 'Post for applause',
        imageUrls: [],
      );

      // Act
      final result = await communityService.addApplauseToPost(
        postId: postId!,
        userId: testUserId,
      );

      // Assert
      expect(result, isTrue);

      // Verify applause was added
      final applauseDoc = await fakeFirestore
          .collection('posts')
          .doc(postId)
          .collection('applause')
          .doc(testUserId)
          .get();

      expect(applauseDoc.exists, isTrue);
      expect(applauseDoc.data()!['count'], equals(1));

      // Verify applause count was updated
      final updatedPostDoc =
          await fakeFirestore.collection('posts').doc(postId).get();
      expect(updatedPostDoc.data()!['applauseCount'], equals(1));
    });

    test('addApplauseToPost respects maximum applause limit', () async {
      // Arrange
      final postId = await communityService.createPost(
        userId: testUserId,
        userName: testUserName,
        userPhotoUrl: testUserPhotoUrl,
        content: 'Post for max applause test',
        imageUrls: [],
      );

      // Set user's applause to max
      await fakeFirestore
          .collection('posts')
          .doc(postId)
          .collection('applause')
          .doc(testUserId)
          .set({
        'count': PostModel.maxApplausePerUser,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Act
      final result = await communityService.addApplauseToPost(
        postId: postId!,
        userId: testUserId,
      );

      // Assert
      expect(result, isFalse); // Should return false when limit reached

      // Verify applause count was not updated
      final updatedPostDoc =
          await fakeFirestore.collection('posts').doc(postId).get();
      expect(updatedPostDoc.data()!['applauseCount'],
          equals(0)); // Still 0 as set initially
    });

    test('getTrendingPosts returns posts ordered by applause and comments',
        () async {
      // Arrange
      // Create posts with different engagement levels
      final lowEngagementPostId = await communityService.createPost(
        userId: testUserId,
        userName: testUserName,
        userPhotoUrl: testUserPhotoUrl,
        content: 'Low engagement post',
        imageUrls: [],
      );

      final highEngagementPostId = await communityService.createPost(
        userId: testUserId,
        userName: testUserName,
        userPhotoUrl: testUserPhotoUrl,
        content: 'High engagement post',
        imageUrls: [],
      );

      // Update engagement metrics for high engagement post
      await fakeFirestore.collection('posts').doc(highEngagementPostId).update({
        'applauseCount': 10,
        'commentCount': 5,
      });

      // Act
      final trendingPosts = await communityService.getTrendingPosts();

      // Assert - this depends on the implementation of getTrendingPosts
      // If it correctly orders by applauseCount and then commentCount
      expect(trendingPosts.length, equals(2));
      expect(trendingPosts.first.id, equals(highEngagementPostId));
      expect(trendingPosts.last.id, equals(lowEngagementPostId));
    });
  });
}

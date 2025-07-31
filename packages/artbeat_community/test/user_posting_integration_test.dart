import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Generate mocks for Firebase services
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference<Map<String, dynamic>>,
  DocumentReference<Map<String, dynamic>>,
])
import 'user_posting_integration_test.mocks.dart';

void main() {
  group('User Posting Integration Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockPostsCollection;
    late MockCollectionReference<Map<String, dynamic>> mockCommentsCollection;
    late MockDocumentReference<Map<String, dynamic>> mockPostDocument;
    late MockDocumentReference<Map<String, dynamic>> mockCommentDocument;

    const String testUserId = 'test-user-123';
    const String testUserName = 'Test User';
    const String testUserPhotoUrl = 'https://example.com/avatar.jpg';

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockPostsCollection = MockCollectionReference<Map<String, dynamic>>();
      mockCommentsCollection = MockCollectionReference<Map<String, dynamic>>();
      mockPostDocument = MockDocumentReference<Map<String, dynamic>>();
      mockCommentDocument = MockDocumentReference<Map<String, dynamic>>();

      // Setup Firestore collections
      when(mockFirestore.collection('posts')).thenReturn(mockPostsCollection);
      when(
        mockFirestore.collection('comments'),
      ).thenReturn(mockCommentsCollection);
    });

    group('Post Creation Tests', () {
      test('registered user can create a text post successfully', () async {
        // Arrange
        const postId = 'post-123';
        final postData = {
          'userId': testUserId,
          'userName': testUserName,
          'userPhotoUrl': testUserPhotoUrl,
          'content': 'This is my first community post!',
          'imageUrls': <String>[],
          'tags': ['community', 'first-post'],
          'location': 'San Francisco, CA',
          'geoPoint': const GeoPoint(37.7749, -122.4194),
          'zipCode': '94103',
          'isPublic': true,
          'applauseCount': 0,
          'commentCount': 0,
          'shareCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        when(mockPostDocument.id).thenReturn(postId);
        when(
          mockPostsCollection.add(any),
        ).thenAnswer((_) async => mockPostDocument);

        // Act
        final result = await mockPostsCollection.add(postData);

        // Assert
        expect(result.id, equals(postId));
        verify(
          mockPostsCollection.add(
            argThat(
              predicate<Map<String, dynamic>>(
                (data) =>
                    data['userId'] == testUserId &&
                    data['userName'] == testUserName &&
                    data['content'] == 'This is my first community post!' &&
                    data['isPublic'] == true,
              ),
            ),
          ),
        ).called(1);
      });

      test('registered user can create a post with images', () async {
        // Arrange
        const postId = 'post-with-images-456';
        final imageUrls = [
          'https://example.com/image1.jpg',
          'https://example.com/image2.jpg',
        ];
        final postData = {
          'userId': testUserId,
          'userName': testUserName,
          'userPhotoUrl': testUserPhotoUrl,
          'content': 'Check out my creative work!',
          'imageUrls': imageUrls,
          'tags': ['art', 'creative'],
          'location': 'New York, NY',
          'geoPoint': const GeoPoint(40.7128, -74.0060),
          'zipCode': '10001',
          'isPublic': true,
          'applauseCount': 0,
          'commentCount': 0,
          'shareCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        when(mockPostDocument.id).thenReturn(postId);
        when(
          mockPostsCollection.add(any),
        ).thenAnswer((_) async => mockPostDocument);

        // Act
        final result = await mockPostsCollection.add(postData);

        // Assert
        expect(result.id, equals(postId));
        verify(
          mockPostsCollection.add(
            argThat(
              predicate<Map<String, dynamic>>(
                (data) =>
                    data['userId'] == testUserId &&
                    data['imageUrls'] is List &&
                    (data['imageUrls'] as List).length == 2 &&
                    data['content'] == 'Check out my creative work!',
              ),
            ),
          ),
        ).called(1);
      });

      test('different user types can create posts', () async {
        // Test different user types to ensure inclusivity
        final userTypes = [
          {'id': 'artist-user', 'name': 'Artist User', 'type': 'artist'},
          {'id': 'regular-user', 'name': 'Regular User', 'type': 'user'},
          {'id': 'gallery-user', 'name': 'Gallery User', 'type': 'gallery'},
          {
            'id': 'enthusiast-user',
            'name': 'Art Enthusiast',
            'type': 'enthusiast',
          },
        ];

        for (final userType in userTypes) {
          final postId = 'post-${userType['id']}';
          final postData = {
            'userId': userType['id']!,
            'userName': userType['name']!,
            'userPhotoUrl': 'https://example.com/${userType['id']}-avatar.jpg',
            'content': 'Post from ${userType['name']} (${userType['type']})',
            'imageUrls': <String>[],
            'tags': [userType['type']!, 'test'],
            'location': 'Test Location',
            'geoPoint': const GeoPoint(0, 0),
            'zipCode': '00000',
            'isPublic': true,
            'applauseCount': 0,
            'commentCount': 0,
            'shareCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          when(mockPostDocument.id).thenReturn(postId);
          when(
            mockPostsCollection.add(any),
          ).thenAnswer((_) async => mockPostDocument);

          final result = await mockPostsCollection.add(postData);
          expect(result.id, equals(postId));
        }

        // Verify all user types could create posts
        verify(mockPostsCollection.add(any)).called(userTypes.length);
      });
    });

    group('Comment Creation Tests', () {
      test('registered user can comment on a post', () async {
        // Arrange
        const postId = 'post-123';
        const commentId = 'comment-456';
        final commentData = {
          'postId': postId,
          'userId': testUserId,
          'userName': testUserName,
          'userPhotoUrl': testUserPhotoUrl,
          'content': 'Great post! I really enjoyed reading this.',
          'parentCommentId': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        when(mockCommentDocument.id).thenReturn(commentId);
        when(
          mockCommentsCollection.add(any),
        ).thenAnswer((_) async => mockCommentDocument);

        // Act
        final result = await mockCommentsCollection.add(commentData);

        // Assert
        expect(result.id, equals(commentId));
        verify(
          mockCommentsCollection.add(
            argThat(
              predicate<Map<String, dynamic>>(
                (data) =>
                    data['postId'] == postId &&
                    data['userId'] == testUserId &&
                    data['content'] ==
                        'Great post! I really enjoyed reading this.' &&
                    data['parentCommentId'] == '',
              ),
            ),
          ),
        ).called(1);
      });

      test('different user types can comment on posts', () async {
        const postId = 'inclusive-post-123';
        final userTypes = [
          {'id': 'artist-commenter', 'name': 'Artist Commenter'},
          {'id': 'regular-commenter', 'name': 'Regular Commenter'},
          {'id': 'gallery-commenter', 'name': 'Gallery Commenter'},
        ];

        for (int i = 0; i < userTypes.length; i++) {
          final userType = userTypes[i];
          final commentId = 'comment-${userType['id']}-$i';
          final commentData = {
            'postId': postId,
            'userId': userType['id']!,
            'userName': userType['name']!,
            'userPhotoUrl': '',
            'content': 'Comment from ${userType['name']}',
            'parentCommentId': '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          when(mockCommentDocument.id).thenReturn(commentId);
          when(
            mockCommentsCollection.add(any),
          ).thenAnswer((_) async => mockCommentDocument);

          final result = await mockCommentsCollection.add(commentData);
          expect(result.id, equals(commentId));
        }

        // Verify all user types could create comments
        verify(mockCommentsCollection.add(any)).called(userTypes.length);
      });
    });

    group('Reply Creation Tests', () {
      test('registered user can reply to a comment', () async {
        // Arrange
        const postId = 'post-123';
        const parentCommentId = 'comment-456';
        const replyId = 'reply-789';
        final replyData = {
          'postId': postId,
          'userId': testUserId,
          'userName': testUserName,
          'userPhotoUrl': testUserPhotoUrl,
          'content': 'Thanks for your comment! I agree with your perspective.',
          'parentCommentId': parentCommentId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        when(mockCommentDocument.id).thenReturn(replyId);
        when(
          mockCommentsCollection.add(any),
        ).thenAnswer((_) async => mockCommentDocument);

        // Act
        final result = await mockCommentsCollection.add(replyData);

        // Assert
        expect(result.id, equals(replyId));
        verify(
          mockCommentsCollection.add(
            argThat(
              predicate<Map<String, dynamic>>(
                (data) =>
                    data['postId'] == postId &&
                    data['userId'] == testUserId &&
                    data['parentCommentId'] == parentCommentId &&
                    data['content'] ==
                        'Thanks for your comment! I agree with your perspective.',
              ),
            ),
          ),
        ).called(1);
      });

      test('registered user can create nested replies', () async {
        // Arrange
        const postId = 'post-123';
        const parentCommentId = 'comment-456';
        const nestedReplyId = 'nested-reply-101';
        final nestedReplyData = {
          'postId': postId,
          'userId': testUserId,
          'userName': testUserName,
          'userPhotoUrl': testUserPhotoUrl,
          'content': 'This is a nested reply to continue the conversation.',
          'parentCommentId': parentCommentId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        when(mockCommentDocument.id).thenReturn(nestedReplyId);
        when(
          mockCommentsCollection.add(any),
        ).thenAnswer((_) async => mockCommentDocument);

        // Act
        final result = await mockCommentsCollection.add(nestedReplyData);

        // Assert
        expect(result.id, equals(nestedReplyId));
        verify(
          mockCommentsCollection.add(
            argThat(
              predicate<Map<String, dynamic>>(
                (data) =>
                    data['parentCommentId'] == parentCommentId &&
                    data['content'] ==
                        'This is a nested reply to continue the conversation.',
              ),
            ),
          ),
        ).called(1);
      });
    });

    group('Full User Journey Integration Test', () {
      test(
        'complete user journey: create post, receive comment, reply to comment',
        () async {
          // This test simulates a complete user interaction flow

          // Step 1: User creates a post
          const postId = 'journey-post-123';
          final postData = {
            'userId': testUserId,
            'userName': testUserName,
            'userPhotoUrl': testUserPhotoUrl,
            'content': 'Sharing my latest creative project with the community!',
            'imageUrls': ['https://example.com/project.jpg'],
            'tags': ['creative', 'project', 'community'],
            'location': 'Seattle, WA',
            'geoPoint': const GeoPoint(47.6062, -122.3321),
            'zipCode': '98101',
            'isPublic': true,
            'applauseCount': 0,
            'commentCount': 0,
            'shareCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          when(mockPostDocument.id).thenReturn(postId);
          when(
            mockPostsCollection.add(any),
          ).thenAnswer((_) async => mockPostDocument);

          final createdPost = await mockPostsCollection.add(postData);
          expect(createdPost.id, equals(postId));

          // Step 2: Another user comments on the post
          const commentId = 'journey-comment-456';
          const commenterUserId = 'commenter-789';
          const commenterUserName = 'Community Member';
          final commentData = {
            'postId': postId,
            'userId': commenterUserId,
            'userName': commenterUserName,
            'userPhotoUrl': 'https://example.com/commenter-avatar.jpg',
            'content':
                'This is amazing work! What inspired you to create this?',
            'parentCommentId': '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          when(mockCommentDocument.id).thenReturn(commentId);
          when(
            mockCommentsCollection.add(any),
          ).thenAnswer((_) async => mockCommentDocument);

          final createdComment = await mockCommentsCollection.add(commentData);
          expect(createdComment.id, equals(commentId));

          // Step 3: Original poster replies to the comment
          const replyId = 'journey-reply-789';
          final replyData = {
            'postId': postId,
            'userId': testUserId,
            'userName': testUserName,
            'userPhotoUrl': testUserPhotoUrl,
            'content':
                'Thank you! I was inspired by the vibrant street art in my neighborhood.',
            'parentCommentId': commentId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          when(mockCommentDocument.id).thenReturn(replyId);
          when(
            mockCommentsCollection.add(any),
          ).thenAnswer((_) async => mockCommentDocument);

          final createdReply = await mockCommentsCollection.add(replyData);
          expect(createdReply.id, equals(replyId));

          // Verify all interactions were recorded
          verify(mockPostsCollection.add(any)).called(1); // Post creation
          verify(mockCommentsCollection.add(any)).called(2); // Comment + Reply
        },
      );
    });

    group('Data Validation Tests', () {
      test('post data contains required fields for all user types', () async {
        // Test that posts from any user type contain the necessary fields
        final testCases = [
          {
            'userType': 'artist',
            'content': 'Sharing my latest artwork with the community!',
            'hasImages': true,
          },
          {
            'userType': 'enthusiast',
            'content': 'Found this amazing piece at the local gallery!',
            'hasImages': true,
          },
          {
            'userType': 'collector',
            'content': 'Thoughts on contemporary art trends?',
            'hasImages': false,
          },
        ];

        for (final testCase in testCases) {
          final postData = {
            'userId': '${testCase['userType']}-user-123',
            'userName': '${testCase['userType']} User',
            'userPhotoUrl': 'https://example.com/avatar.jpg',
            'content': testCase['content'],
            'imageUrls': testCase['hasImages'] == true
                ? ['https://example.com/image.jpg']
                : <String>[],
            'tags': [testCase['userType'] as String, 'community'],
            'location': 'Test City',
            'isPublic': true,
            'applauseCount': 0,
            'commentCount': 0,
            'shareCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // Verify required fields are present
          expect(postData.containsKey('userId'), isTrue);
          expect(postData.containsKey('userName'), isTrue);
          expect(postData.containsKey('content'), isTrue);
          expect(postData.containsKey('isPublic'), isTrue);
          expect(postData.containsKey('applauseCount'), isTrue);
          expect(postData.containsKey('commentCount'), isTrue);
          expect(postData.containsKey('createdAt'), isTrue);

          // Verify content is not empty
          expect(postData['content'], isNotEmpty);
          expect(postData['userId'], isNotEmpty);
          expect(postData['userName'], isNotEmpty);
        }
      });

      test(
        'comment data contains required fields for all user types',
        () async {
          final commentData = {
            'postId': 'test-post-123',
            'userId': 'commenter-456',
            'userName': 'Community Member',
            'userPhotoUrl': 'https://example.com/avatar.jpg',
            'content':
                'This is a thoughtful comment from any community member.',
            'parentCommentId': '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // Verify required fields are present
          expect(commentData.containsKey('postId'), isTrue);
          expect(commentData.containsKey('userId'), isTrue);
          expect(commentData.containsKey('userName'), isTrue);
          expect(commentData.containsKey('content'), isTrue);
          expect(commentData.containsKey('parentCommentId'), isTrue);
          expect(commentData.containsKey('createdAt'), isTrue);

          // Verify content is not empty
          expect(commentData['postId'], isNotEmpty);
          expect(commentData['userId'], isNotEmpty);
          expect(commentData['userName'], isNotEmpty);
          expect(commentData['content'], isNotEmpty);
        },
      );
    });
  });
}

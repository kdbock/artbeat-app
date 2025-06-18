import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

/// Interface for image picker functionality to enable testing
abstract class IImagePickerService {
  Future<List<File>> pickImages();
}

/// Default implementation of IImagePickerService
class DefaultImagePickerService implements IImagePickerService {
  @override
  Future<List<File>> pickImages() async {
    // In a real implementation, this would use image_picker package
    return [];
  }
}

/// Testable version of CommunityService with dependency injection
class TestableCommunityService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final IImagePickerService _imagePickerService;

  TestableCommunityService({
    required FirebaseFirestore firestore,
    IImagePickerService? imagePickerService,
  }) : _firestore = firestore,
       _imagePickerService = imagePickerService ?? DefaultImagePickerService();

  // Method to pick images for a post
  Future<List<File>> pickPostImages() async {
    try {
      return await _imagePickerService.pickImages();
    } catch (e) {
      debugPrint('Error picking images: $e');
      return [];
    }
  }

  // Get all posts
  Future<List<PostModel>> getPosts({int limit = 10, String? lastPostId}) async {
    try {
      Query query = _firestore
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastPostId != null) {
        // Get the last document for pagination
        DocumentSnapshot lastDocSnapshot = await _firestore
            .collection('posts')
            .doc(lastPostId)
            .get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting posts: $e');
      return [];
    }
  }

  // Get posts by user ID
  Future<List<PostModel>> getPostsByUserId(
    String userId, {
    int limit = 10,
    String? lastPostId,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastPostId != null) {
        DocumentSnapshot lastDocSnapshot = await _firestore
            .collection('posts')
            .doc(lastPostId)
            .get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting posts by userId: $e');
      return [];
    }
  }

  // Create a new post
  Future<String?> createPost({
    required String userId,
    required String userName,
    required String userPhotoUrl,
    required String content,
    required List<String> imageUrls,
    List<String>? tags,
    String? location,
    GeoPoint? geoPoint,
    String? zipCode,
    bool isPublic = true,
    List<String>? mentionedUsers,
    Map<String, dynamic>? metadata,
    bool isUserVerified = false,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('posts').add({
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'content': content,
        'imageUrls': imageUrls,
        'tags': tags ?? [],
        'location': location ?? '',
        'geoPoint': geoPoint,
        'zipCode': zipCode,
        'createdAt': FieldValue.serverTimestamp(),
        'applauseCount': 0,
        'commentCount': 0,
        'shareCount': 0,
        'isPublic': isPublic,
        'mentionedUsers': mentionedUsers ?? [],
        'metadata': metadata ?? {},
        'isUserVerified': isUserVerified,
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating post: $e');
      return null;
    }
  }

  // Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return false;
    }
  }

  // Add a comment to a post
  Future<String?> addComment({
    required String postId,
    required String userId,
    required String content,
    required String userName,
    required String userAvatarUrl,
    String parentCommentId = '',
    String type = 'Appreciation',
  }) async {
    try {
      // Add the comment to Firestore
      DocumentReference commentRef = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
            'postId': postId,
            'userId': userId,
            'content': content,
            'parentCommentId': parentCommentId,
            'type': type,
            'createdAt': FieldValue.serverTimestamp(),
            'userName': userName,
            'userAvatarUrl': userAvatarUrl,
          });

      // Update the comment count on the post
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      return commentRef.id;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }

  // Get comments for a post
  Future<List<CommentModel>> getComments(
    String postId, {
    int limit = 20,
    String? lastCommentId,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastCommentId != null) {
        DocumentSnapshot lastDocSnapshot = await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(lastCommentId)
            .get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting comments: $e');
      return [];
    }
  }

  // Add applause to a post (with maximum applause limit per user)
  Future<bool> addApplauseToPost({
    required String postId,
    required String userId,
  }) async {
    try {
      // Check if the user has already given max applause
      DocumentSnapshot userApplauseDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('applause')
          .doc(userId)
          .get();

      int currentApplause = 0;
      if (userApplauseDoc.exists) {
        currentApplause =
            ((userApplauseDoc.data() as Map<String, dynamic>)['count']
                as int?) ??
            0;
      }

      // If user has not reached max applause, add one more
      if (currentApplause < PostModel.maxApplausePerUser) {
        // Use a transaction to ensure consistency
        await _firestore.runTransaction((transaction) async {
          transaction.set(
            _firestore
                .collection('posts')
                .doc(postId)
                .collection('applause')
                .doc(userId),
            {
              'count': currentApplause + 1,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          transaction.update(_firestore.collection('posts').doc(postId), {
            'applauseCount': FieldValue.increment(1),
          });
        });
        return true;
      } else {
        // User has reached max applause
        return false;
      }
    } catch (e) {
      debugPrint('Error adding applause: $e');
      return false;
    }
  }

  // Get trending posts based on applause and comment count
  Future<List<PostModel>> getTrendingPosts({int limit = 10}) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .orderBy('applauseCount', descending: true)
          .orderBy('commentCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting trending posts: $e');
      return [];
    }
  }
}

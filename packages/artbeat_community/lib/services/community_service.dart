import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class CommunityService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to pick images for a post
  Future<List<File>> pickPostImages() async {
    // This is a placeholder.
    // Actual implementation would use image_picker or a similar package
    // to allow the user to select images from their gallery or camera.
    debugPrint('pickPostImages called - placeholder implementation');
    return []; // Return an empty list for now
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
        DocumentSnapshot lastDocSnapshot =
            await _firestore.collection('posts').doc(lastPostId).get();
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
  Future<List<PostModel>> getPostsByUserId(String userId,
      {int limit = 10, String? lastPostId}) async {
    try {
      Query query = _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastPostId != null) {
        DocumentSnapshot lastDocSnapshot =
            await _firestore.collection('posts').doc(lastPostId).get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting posts by user ID: $e');
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
    required List<String> tags,
    required String location,
    GeoPoint? geoPoint,
    String? zipCode,
    bool isPublic = true,
    List<String>? mentionedUsers,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('posts').add({
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'content': content,
        'imageUrls': imageUrls,
        'tags': tags,
        'location': location,
        'geoPoint': geoPoint,
        'zipCode': zipCode,
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
        'commentCount': 0,
        'shareCount': 0,
        'isPublic': isPublic,
        'mentionedUsers': mentionedUsers,
        'metadata': metadata,
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
    required String userName,
    required String userPhotoUrl,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      // Add the comment to Firestore
      DocumentReference commentRef = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'parentCommentId': parentCommentId,
        'likeCount': 0,
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
  Future<List<CommentModel>> getComments(String postId,
      {int limit = 50, String? lastCommentId}) async {
    try {
      Query query = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .where('parentCommentId', isNull: true) // Get only top-level comments
          .orderBy('createdAt', descending: false) // Oldest first
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

  // Get replies to a comment
  Future<List<CommentModel>> getReplies(String postId, String commentId,
      {int limit = 50, String? lastReplyId}) async {
    try {
      Query query = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .where('parentCommentId', isEqualTo: commentId)
          .orderBy('createdAt', descending: false) // Oldest first
          .limit(limit);

      if (lastReplyId != null) {
        DocumentSnapshot lastDocSnapshot = await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(lastReplyId)
            .get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting replies: $e');
      return [];
    }
  }
}

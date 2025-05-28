import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat/models/post_model.dart';
import 'package:artbeat/models/comment_model.dart';
import 'package:artbeat/services/user_service.dart';

/// Service for handling community posts and feeds
class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Collection references
  final CollectionReference _postsCollection =
      FirebaseFirestore.instance.collection('posts');

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Create a new post
  Future<String> createPost({
    required String content,
    List<File>? images,
    List<String>? tags,
    String? location,
    GeoPoint? geoPoint,
    String? zipCode,
    bool isPublic = true,
    List<String>? mentionedUsers,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get current user data using UserService to ensure profile exists
    final userModel = await _userService.getCurrentUserModel();

    if (userModel == null) {
      throw Exception('User profile not found or could not be created');
    }

    final userName = userModel.fullName; // Use fullName from UserModel
    final userPhotoUrl = userModel.profileImageUrl;

    // Upload images if provided
    List<String> imageUrls = [];
    if (images != null && images.isNotEmpty) {
      imageUrls = await _uploadPostImages(images);
    }

    // Create post document
    final postData = {
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
      'likeCount': 0,
      'commentCount': 0,
      'shareCount': 0,
      'isPublic': isPublic,
      'mentionedUsers': mentionedUsers,
      'metadata': metadata,
    };

    // Add post to Firestore
    final docRef = await _postsCollection.add(postData);

    // Update user's post count
    await _firestore.collection('users').doc(userId).update({
      'postCount': FieldValue.increment(1),
    });

    // Notify mentioned users if any
    if (mentionedUsers != null && mentionedUsers.isNotEmpty) {
      _notifyMentionedUsers(mentionedUsers, docRef.id, content);
    }

    return docRef.id;
  }

  /// Upload post images to Firebase Storage
  Future<List<String>> _uploadPostImages(List<File> images) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    List<String> imageUrls = [];

    for (var i = 0; i < images.length; i++) {
      final file = images[i];
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${i}_$userId';
      final ref = _storage.ref().child('post_images/$fileName');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;

      final url = await snapshot.ref.getDownloadURL();
      imageUrls.add(url);
    }

    return imageUrls;
  }

  /// Notify users who were mentioned in a post
  Future<void> _notifyMentionedUsers(
    List<String> userIds,
    String postId,
    String content,
  ) async {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) return;

    // Get user data for notification using UserService
    final currentUserModel = await _userService.getCurrentUserModel();
    if (currentUserModel == null) {
      // Decide how to handle if current user model is not found for notification
      // For now, let's log and return, or use default values
      print('Current user profile not found for notification');
      return;
    }
    final userName = currentUserModel.fullName;
    final userPhoto = currentUserModel.profileImageUrl;

    for (final userId in userIds) {
      if (userId != currentUserId) {
        await _firestore.collection('notifications').add({
          'userId': userId,
          'type': 'mention',
          'sourceUserId': currentUserId,
          'sourceUserName': userName,
          'sourceUserPhoto': userPhoto,
          'content': 'mentioned you in a post',
          'postId': postId,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Check if user owns the post
    final postDoc = await _postsCollection.doc(postId).get();

    if (!postDoc.exists) {
      throw Exception('Post not found');
    }

    final postData = postDoc.data() as Map<String, dynamic>;
    if (postData['userId'] != userId) {
      throw Exception('You can only delete your own posts');
    }

    // Delete post images from storage
    final List<String> imageUrls = List<String>.from(
      postData['imageUrls'] ?? [],
    );
    for (final url in imageUrls) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (e) {
        // Log error but continue with post deletion
        debugPrint('Error deleting image: $e');
      }
    }

    // Delete all comments for this post
    final commentsSnapshot =
        await _postsCollection.doc(postId).collection('comments').get();

    final batch = _firestore.batch();

    for (final doc in commentsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the post
    batch.delete(_postsCollection.doc(postId));

    // Update user's post count
    batch.update(_firestore.collection('users').doc(userId), {
      'postCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  /// Like or unlike a post
  Future<void> toggleLikePost(String postId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Use a batched write to ensure consistency
    final batch = _firestore.batch();

    final postRef = _postsCollection.doc(postId);
    final likeRef = _firestore
        .collection('postLikes')
        .doc(postId)
        .collection('userLikes')
        .doc(userId);

    try {
      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // User has already liked, so unlike
        batch.delete(likeRef);
        batch.update(postRef, {
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        // User hasn't liked, so add like
        batch.set(likeRef, {
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        batch.update(postRef, {
          'likeCount': FieldValue.increment(1),
        });
      }

      // Commit the batch
      await batch.commit();

      // Notify post owner if it's not the current user
      final postDoc = await _postsCollection.doc(postId).get();
      final postData = postDoc.data() as Map<String, dynamic>;

      if (postData['userId'] != userId) {
        // Get user data for notification using UserService
        final currentUserModel = await _userService.getCurrentUserModel();
        if (currentUserModel == null) {
          print('Current user profile not found for like notification');
          return; // Or handle with default values
        }
        final userName = currentUserModel.fullName;
        final userPhoto = currentUserModel.profileImageUrl;

        await _firestore.collection('notifications').add({
          'userId': postData['userId'],
          'type': 'like',
          'sourceUserId': userId,
          'sourceUserName': userName,
          'sourceUserPhoto': userPhoto,
          'content': 'liked your post',
          'postId': postId,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      throw Exception('Failed to update like status: $e');
    }
  }

  /// Check if current user has liked a post
  Future<bool> hasUserLikedPost(String postId) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;

    try {
      final doc = await _firestore
          .collection('postLikes')
          .doc(postId)
          .collection('userLikes')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking like status: $e');
      return false; // Default to not liked in case of error
    }
  }

  /// Add a comment to a post
  Future<String> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
    List<String>? mentionedUsers,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get current user data using UserService
    final userModel = await _userService.getCurrentUserModel();
    if (userModel == null) {
      throw Exception('User profile not found or could not be created');
    }

    final userName = userModel.fullName;
    final userPhotoUrl = userModel.profileImageUrl;

    // Create comment
    final commentData = {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': 0,
      'parentCommentId': parentCommentId,
      'isEdited': false,
      'mentionedUsers': mentionedUsers,
      'timestamp':
          DateTime.now().millisecondsSinceEpoch, // For sorting consistency
    };

    // Add comment to Firestore as a subcollection of the post
    final docRef = await _postsCollection
        .doc(postId)
        .collection('comments')
        .add(commentData);

    // Update post's comment count
    await _postsCollection.doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });

    // If this is a reply to another comment, update the parent comment's reply count
    if (parentCommentId != null) {
      try {
        await _postsCollection
            .doc(postId)
            .collection('comments')
            .doc(parentCommentId)
            .update({
          'replyCount': FieldValue.increment(1),
        });
      } catch (e) {
        // Parent comment might not exist or other error
        print('Error updating reply count: $e');
      }
    }

    // Notify post owner if it's not the current user
    final postDoc = await _postsCollection.doc(postId).get();
    final postData = postDoc.data() as Map<String, dynamic>;
    if (postData['userId'] != userId) {
      await _firestore.collection('notifications').add({
        'userId': postData['userId'],
        'type': 'comment',
        'sourceUserId': userId,
        'sourceUserName': userName,
        'sourceUserPhoto': userPhotoUrl,
        'content': 'commented on your post',
        'postId': postId,
        'commentId': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }

    // Notify mentioned users
    if (mentionedUsers != null && mentionedUsers.isNotEmpty) {
      for (final mentionedId in mentionedUsers) {
        if (mentionedId != userId && mentionedId != postData['userId']) {
          await _firestore.collection('notifications').add({
            'userId': mentionedId,
            'type': 'mention',
            'sourceUserId': userId,
            'sourceUserName': userName,
            'sourceUserPhoto': userPhotoUrl,
            'content': 'mentioned you in a comment',
            'postId': postId,
            'commentId': docRef.id,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
    }

    // If this is a reply, notify the parent comment author
    if (parentCommentId != null) {
      final parentComment = await _postsCollection
          .doc(postId)
          .collection('comments')
          .doc(parentCommentId)
          .get();
      final parentData = parentComment.data() as Map<String, dynamic>;
      if (parentData['userId'] != userId &&
          parentData['userId'] != postData['userId']) {
        await _firestore.collection('notifications').add({
          'userId': parentData['userId'],
          'type': 'reply',
          'sourceUserId': userId,
          'sourceUserName': userName,
          'sourceUserPhoto': userPhotoUrl,
          'content': 'replied to your comment',
          'postId': postId,
          'commentId': docRef.id,
          'parentCommentId': parentCommentId,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    }

    return docRef.id;
  }

  /// Get comments for a post with pagination support
  Future<List<CommentModel>> getCommentsForPost(
    String postId, {
    int limit = 10,
    String? startAfter,
    bool? topLevelOnly = true,
    String? onlyWithId,
  }) async {
    Query query = _postsCollection.doc(postId).collection('comments');

    // Filter by specific comment ID if needed
    if (onlyWithId != null) {
      final doc = await _postsCollection
          .doc(postId)
          .collection('comments')
          .doc(onlyWithId)
          .get();

      if (doc.exists) {
        return [CommentModel.fromFirestore(doc, postId: postId)];
      }
      return [];
    }

    // Filter for top level comments only if requested
    if (topLevelOnly == true) {
      query = query.where('parentCommentId', isNull: true);
    }

    // Sort chronologically, older comments first
    query = query.orderBy('createdAt', descending: false);

    // Apply pagination if specified
    if (startAfter != null) {
      final startDoc = await _postsCollection
          .doc(postId)
          .collection('comments')
          .doc(startAfter)
          .get();

      if (startDoc.exists) {
        query = query.startAfterDocument(startDoc);
      }
    }

    // Apply limit
    query = query.limit(limit);

    // Execute query
    final snapshot = await query.get();

    // Map to comment models
    return snapshot.docs
        .map((doc) => CommentModel.fromFirestore(doc, postId: postId))
        .toList();
  }

  /// Get comment replies (for nested comments)
  Future<List<CommentModel>> getCommentReplies(
    String postId,
    String parentCommentId,
  ) async {
    final snapshot = await _postsCollection
        .doc(postId)
        .collection('comments')
        .where('parentCommentId', isEqualTo: parentCommentId)
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => CommentModel.fromFirestore(doc, postId: postId))
        .toList();
  }

  /// Get replies for a comment
  Future<List<CommentModel>> getRepliesForComment(
      String postId, String commentId) async {
    final snapshot = await _postsCollection
        .doc(postId)
        .collection('comments')
        .where('parentCommentId', isEqualTo: commentId)
        .orderBy('createdAt', descending: false)
        .get();
    return snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();
  }

  /// Delete a comment
  Future<void> deleteComment(String postId, String commentId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    final commentDoc = await _postsCollection
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .get();
    if (!commentDoc.exists) {
      throw Exception('Comment not found');
    }
    final commentData = commentDoc.data() as Map<String, dynamic>;
    if (commentData['userId'] != userId) {
      throw Exception('You can only delete your own comments');
    }
    // Check for replies to this comment
    final repliesSnapshot = await _postsCollection
        .doc(postId)
        .collection('comments')
        .where('parentCommentId', isEqualTo: commentId)
        .get();
    if (repliesSnapshot.docs.isNotEmpty) {
      // If there are replies, just mark as deleted but keep the content structure
      await _postsCollection
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({
        'content': '[Deleted]',
        'isDeleted': true,
      });
    } else {
      // No replies, can delete completely
      await _postsCollection
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();
    }
    // Update post's comment count
    await _postsCollection.doc(postId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }

  /// Get posts for personal feed (from followed users and own posts)
  Future<List<PostModel>> getPersonalFeed({int limit = 20}) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get followed users
    final followingSnapshot = await _firestore
        .collection('userFollowing')
        .doc(userId)
        .collection('following')
        .get();

    // Get list of followed user IDs
    final List<String> followedUserIds =
        followingSnapshot.docs.map((doc) => doc.id).toList();

    // Add current user ID to get their posts too
    followedUserIds.add(userId);

    if (followedUserIds.isEmpty) {
      return [];
    }

    // Query posts from followed users
    List<PostModel> allPosts = [];

    if (followedUserIds.length <= 10) {
      // For small follow lists, we can use a simple where-in query
      final postsSnapshot = await _postsCollection
          .where('userId', whereIn: followedUserIds)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      allPosts = postsSnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } else {
      // For larger follow lists, we need to batch the queries
      // Firebase has a limit of 10 items in a whereIn clause
      List<PostModel> batchedPosts = [];

      for (int i = 0; i < followedUserIds.length; i += 10) {
        final endIndex =
            (i + 10 < followedUserIds.length) ? i + 10 : followedUserIds.length;

        final batch = followedUserIds.sublist(i, endIndex);

        final batchResult = await _postsCollection
            .where('userId', whereIn: batch)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();

        final posts = batchResult.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList();

        batchedPosts.addAll(posts);
      }

      // Sort all posts by creation time
      batchedPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Limit to requested number
      if (batchedPosts.length > limit) {
        batchedPosts = batchedPosts.sublist(0, limit);
      }

      allPosts = batchedPosts;
    }

    return allPosts;
  }

  /// Get community feed based on location/zip code
  Future<List<PostModel>> getCommunityFeed({
    String? zipCode,
    GeoPoint? location,
    double? radiusKm,
    int limit = 20,
  }) async {
    if (zipCode != null) {
      // Query by zip code
      final snapshot = await _postsCollection
          .where('zipCode', isEqualTo: zipCode)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    } else if (location != null && radiusKm != null) {
      // For production implementation, you'd need to use GeoFirestore or a similar solution
      // for radius-based queries, as Firestore doesn't support geoqueries natively.
      // For simplicity, we'll just return a generic community feed
      final snapshot = await _postsCollection
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    } else {
      // Default global community feed (if no location provided)
      final snapshot = await _postsCollection
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    }
  }

  /// Get trending posts based on engagement
  Future<List<PostModel>> getTrendingPosts({int limit = 20}) async {
    // In a real implementation, you'd use a more sophisticated algorithm
    // to determine trending posts based on recent engagement, time decay, etc.
    // For simplicity, we'll just sort by engagement score (likes + comments + shares)

    final snapshot = await _postsCollection
        .where('isPublic', isEqualTo: true)
        .orderBy('likeCount', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  /// Get posts with a specific tag
  Future<List<PostModel>> getPostsByTag(String tag, {int limit = 20}) async {
    final snapshot = await _postsCollection
        .where('tags', arrayContains: tag)
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  /// Get a specific post by ID
  Future<PostModel?> getPostById(String postId) async {
    final doc = await _postsCollection.doc(postId).get();

    if (!doc.exists) {
      return null;
    }

    return PostModel.fromFirestore(doc);
  }

  /// Get posts from a specific user
  Future<List<PostModel>> getPostsByUser(
    String userId, {
    int limit = 20,
  }) async {
    final snapshot = await _postsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  /// Share post (create a new post that references the original)
  Future<String> sharePost(String originalPostId, {String? comment}) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get the original post
    final originalPost = await getPostById(originalPostId);
    if (originalPost == null) {
      throw Exception('Original post not found');
    }

    // Get current user data using UserService
    final userModel = await _userService.getCurrentUserModel();

    if (userModel == null) {
      throw Exception('User profile not found or could not be created');
    }

    final userName = userModel.fullName;
    final userPhotoUrl = userModel.profileImageUrl;

    // Create share post
    final shareData = {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': comment ?? '',
      'sharedPostId': originalPostId,
      'sharedPostUserId': originalPost.userId,
      'sharedPostUserName': originalPost.userName,
      'sharedPostContent': originalPost.content,
      'imageUrls': [],
      'tags': originalPost.tags,
      'location': userModel.location, // Use location from UserModel
      'zipCode':
          null, // UserModel doesn't have zipCode directly, adjust as needed or fetch separately if critical
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': 0,
      'commentCount': 0,
      'shareCount': 0,
      'isPublic': true,
      'isShare': true,
    };

    // Add share to Firestore
    final docRef = await _postsCollection.add(shareData);

    // Update original post's share count
    await _postsCollection.doc(originalPostId).update({
      'shareCount': FieldValue.increment(1),
    });

    // Notify the original post owner
    if (originalPost.userId != userId) {
      await _firestore.collection('notifications').add({
        'userId': originalPost.userId,
        'type': 'share',
        'sourceUserId': userId,
        'sourceUserName': userName,
        'sourceUserPhoto': userPhotoUrl,
        'content': 'shared your post',
        'postId': originalPostId,
        'sharedPostId': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }

    return docRef.id;
  }

  /// Pick images for a post
  Future<List<File>> pickPostImages({int maxImages = 5}) async {
    final picker = ImagePicker();
    final List<File> pickedFiles = [];

    final result = await picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (result.isNotEmpty) {
      for (var i = 0; i < result.length && i < maxImages; i++) {
        pickedFiles.add(File(result[i].path));
      }
    }

    return pickedFiles;
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/art_models.dart';
import '../models/post_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Unified service for art community operations
/// Simplified and focused on core art-sharing functionality
class ArtCommunityService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream controllers for real-time updates
  final StreamController<List<ArtPost>> _feedController =
      StreamController.broadcast();
  final StreamController<List<ArtistProfile>> _artistsController =
      StreamController.broadcast();

  Stream<List<ArtPost>> get feedStream => _feedController.stream;
  Stream<List<ArtistProfile>> get artistsStream => _artistsController.stream;

  /// Get current cached artists
  List<ArtistProfile> getArtists({int limit = 20}) {
    return _artistsCache.take(limit).toList();
  }

  // Cache for performance
  List<ArtPost> _feedCache = [];
  List<ArtistProfile> _artistsCache = [];

  ArtCommunityService() {
    _initializeStreams();
  }

  void _initializeStreams() {
    // Set up real-time listeners for feed
    _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
          _feedCache = snapshot.docs
              .map((doc) => ArtPost.fromFirestore(doc))
              .toList();
          _feedController.add(_feedCache);
        });

    // Set up real-time listeners for artists
    _firestore
        .collection('artistProfiles')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
          _artistsCache = snapshot.docs
              .map((doc) => ArtistProfile.fromFirestore(doc))
              .toList();
          _artistsController.add(_artistsCache);
        });
  }

  /// Get paginated feed posts
  Future<List<PostModel>> getFeed({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      // Load posts and add like status for current user
      final posts = <PostModel>[];
      for (final doc in snapshot.docs) {
        final post = PostModel.fromFirestore(doc);
        final isLiked = await hasUserLikedPost(post.id);
        final postWithLikeStatus = post.copyWith(isLikedByCurrentUser: isLiked);
        posts.add(postWithLikeStatus);
      }

      // Debug: Log the retrieved posts
      if (kDebugMode) {
        print('📱 DEBUG: Retrieved ${posts.length} posts from Firestore');
        for (int i = 0; i < posts.length; i++) {
          final post = posts[i];
          print(
            '📱 Post $i: "${post.content}" with ${post.imageUrls.length} images',
          );
          if (post.imageUrls.isNotEmpty) {
            print('📱   First image URL: ${post.imageUrls.first}');
          }
        }
      }

      return posts;
    } catch (e) {
      AppLogger.error('Error getting feed: $e');
      return [];
    }
  }

  /// Get posts by specific artist
  Future<List<ArtPost>> getArtistPosts(
    String artistId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: artistId)
          .where('isArtistPost', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Error getting artist posts: $e');
      return [];
    }
  }

  /// Get posts by topic/tag
  Future<List<ArtPost>> getPostsByTopic(String topic, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('tags', arrayContains: topic)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Error getting posts by topic: $e');
      return [];
    }
  }

  /// Create a new art post
  Future<String?> createPost({
    required String content,
    required List<String> imageUrls,
    List<String> tags = const [],
    bool isArtistPost = false,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Get user profile data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final post = ArtPost(
        id: '', // Will be set by Firestore
        userId: user.uid,
        userName:
            userData['displayName'] as String? ??
            userData['name'] as String? ??
            'Anonymous',
        userAvatarUrl: userData['profileImageUrl'] as String? ?? '',
        content: content,
        imageUrls: imageUrls,
        tags: tags,
        createdAt: DateTime.now(),
        isArtistPost: isArtistPost,
        isUserVerified: userData['isVerified'] as bool? ?? false,
      );

      // Debug: Log the post data being saved
      if (kDebugMode) {
        print('🔥 DEBUG: Saving post to Firestore:');
        print('🔥 Content: $content');
        print('🔥 Image URLs (${imageUrls.length}): $imageUrls');
        print('🔥 Tags: $tags');
        final firestoreData = post.toFirestore();
        print('🔥 Firestore data: $firestoreData');
      }

      final docRef = await _firestore
          .collection('posts')
          .add(post.toFirestore());
      AppLogger.info('Created post: ${docRef.id}');

      // Debug: Verify the post was saved correctly
      if (kDebugMode) {
        final savedDoc = await docRef.get();
        final savedData = savedDoc.data();
        print('🔥 DEBUG: Verified saved post data: $savedData');
      }

      return docRef.id;
    } catch (e) {
      AppLogger.error('Error creating post: $e');
      return null;
    }
  }

  /// Create an enhanced post with multimedia support
  Future<String?> createEnhancedPost({
    required String content,
    List<String> imageUrls = const [],
    String? videoUrl,
    String? audioUrl,
    List<String> tags = const [],
    bool isArtistPost = false,
    PostModerationStatus moderationStatus = PostModerationStatus.approved,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Get user profile data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final post = PostModel(
        id: '', // Will be set by Firestore
        userId: user.uid,
        userName:
            userData['displayName'] as String? ??
            userData['name'] as String? ??
            userData['fullName'] as String? ??
            user.displayName ??
            'Anonymous',
        userPhotoUrl: userData['profileImageUrl'] as String? ?? '',
        content: content,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        tags: tags,
        location: userData['location'] as String? ?? '',
        createdAt: DateTime.now(),
        engagementStats: EngagementStats(lastUpdated: DateTime.now()),
        isPublic: true,
        isUserVerified: userData['isVerified'] as bool? ?? false,
        moderationStatus: moderationStatus,
        flagged: moderationStatus != PostModerationStatus.approved,
      );

      // Debug: Log the enhanced post data being saved
      if (kDebugMode) {
        print('🔥 DEBUG: Saving enhanced post to Firestore:');
        print('🔥 Content: $content');
        print('🔥 Image URLs (${imageUrls.length}): $imageUrls');
        print('🔥 Video URL: $videoUrl');
        print('🔥 Audio URL: $audioUrl');
        print('🔥 Tags: $tags');
        print('🔥 Moderation Status: ${moderationStatus.value}');
      }

      // Save to posts collection
      final docRef = await _firestore
          .collection('posts')
          .add(post.toFirestore());

      // Also save to user_posts collection for easy user post retrieval
      await _firestore
          .collection('user_posts')
          .doc(user.uid)
          .collection('posts')
          .doc(docRef.id)
          .set({
            'postId': docRef.id,
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'moderationStatus': moderationStatus.value,
            'isArtistPost': isArtistPost,
            'hasImages': imageUrls.isNotEmpty,
            'hasVideo': videoUrl != null,
            'hasAudio': audioUrl != null,
            'tagCount': tags.length,
          });

      AppLogger.info('Created enhanced post: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      AppLogger.error('Error creating enhanced post: $e');
      return null;
    }
  }

  /// Like/unlike a post
  Future<bool> toggleLike(String postId) async {
    try {
      AppLogger.info(
        '🤍 ArtCommunityService.toggleLike called for postId: $postId',
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.error('🤍 No authenticated user found');
        return false;
      }

      AppLogger.info('🤍 Authenticated user: ${user.uid}');

      final likeRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(user.uid);

      AppLogger.info('🤍 Checking if like document exists...');
      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Unlike
        AppLogger.info('🤍 User has already liked this post, unliking...');
        await likeRef.delete();
        await _updateLikeCount(postId, -1);
        AppLogger.info('🤍 Unlike completed successfully');
        return false;
      } else {
        // Like
        AppLogger.info('🤍 User hasn\'t liked this post, liking...');
        await likeRef.set({'userId': user.uid, 'createdAt': Timestamp.now()});
        await _updateLikeCount(postId, 1);
        AppLogger.info('🤍 Like completed successfully');
        return true;
      }
    } catch (e) {
      AppLogger.error('Error toggling like: $e');
      return false;
    }
  }

  Future<void> _updateLikeCount(String postId, int change) async {
    try {
      AppLogger.info('🤍 Updating like count for post $postId by $change');

      final postRef = _firestore.collection('posts').doc(postId);
      await postRef.update({
        'engagementStats.likeCount': FieldValue.increment(change),
        'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
      });

      AppLogger.info('🤍 Like count update completed successfully');
    } catch (e) {
      AppLogger.error('🤍 Error updating like count: $e');
    }
  }

  /// Check if current user has liked a post
  Future<bool> hasUserLikedPost(String postId) async {
    try {
      AppLogger.info('🤍 Checking if user has liked post: $postId');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.info('🤍 No authenticated user, returning false');
        return false;
      }

      final likeDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(user.uid)
          .get();

      final hasLiked = likeDoc.exists;
      AppLogger.info(
        '🤍 User ${user.uid} has ${hasLiked ? 'liked' : 'not liked'} post $postId',
      );
      return hasLiked;
    } catch (e) {
      AppLogger.error('Error checking if user liked post $postId: $e');
      return false;
    }
  }

  /// Get comments for a post
  Future<List<ArtComment>> getComments(String postId, {int limit = 10}) async {
    try {
      AppLogger.info('💬 Getting comments for post: $postId');

      // First, let's try a simple query without orderBy to see if that's the issue
      AppLogger.info('💬 Trying simple query without orderBy...');
      final simpleSnapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();

      AppLogger.info(
        '💬 Simple query returned ${simpleSnapshot.docs.length} documents',
      );

      // Debug: Log simple query results
      if (simpleSnapshot.docs.isNotEmpty) {
        for (int i = 0; i < simpleSnapshot.docs.length && i < 3; i++) {
          final doc = simpleSnapshot.docs[i];
          final data = doc.data();
          AppLogger.info(
            '💬 Simple query result ${i}: postId="${data['postId']}", content="${data['content']}"',
          );
        }
      }

      // Try top-level comments collection first
      final snapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      AppLogger.info(
        '💬 Top-level comments query returned ${snapshot.docs.length} documents',
      );

      // Debug: Log the query details
      AppLogger.info('💬 Query details: postId="$postId", limit=$limit');

      final List<ArtComment> comments = [];

      // Debug: If no comments found, let's see what post IDs exist in the comments collection
      if (snapshot.docs.isEmpty) {
        AppLogger.info(
          '💬 No comments found for postId: "$postId", checking what post IDs exist...',
        );
        final allCommentsSnapshot = await _firestore
            .collection('comments')
            .limit(10)
            .get();
        AppLogger.info(
          '💬 Found ${allCommentsSnapshot.docs.length} total comments in collection',
        );
        for (final doc in allCommentsSnapshot.docs) {
          final data = doc.data();
          AppLogger.info(
            '💬 Comment ${doc.id} has postId: "${data['postId']}"',
          );
        }
      }

      if (snapshot.docs.isNotEmpty) {
        // Debug: Log the first few documents
        for (int i = 0; i < snapshot.docs.length && i < 3; i++) {
          final doc = snapshot.docs[i];
          AppLogger.info('💬 Comment doc ${i}: ${doc.id} - ${doc.data()}');
        }

        // Parse comments with error handling
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            AppLogger.info('💬 Raw comment data: $data');
            final comment = ArtComment.fromFirestore(doc);
            AppLogger.info('💬 Parsed comment userName: "${comment.userName}"');
            comments.add(comment);
            AppLogger.info(
              '💬 Successfully parsed comment: ${comment.id} - "${comment.content}" by ${comment.userName}',
            );
          } catch (e) {
            AppLogger.error('💬 Failed to parse comment ${doc.id}: $e');
          }
        }
      } else {
        // Try subcollection structure as fallback
        AppLogger.info(
          '💬 No comments in top-level collection, trying subcollection...',
        );
        final subcollectionSnapshot = await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();

        AppLogger.info(
          '💬 Subcollection query returned ${subcollectionSnapshot.docs.length} documents',
        );

        if (subcollectionSnapshot.docs.isNotEmpty) {
          // Debug: Log the first few documents
          for (int i = 0; i < subcollectionSnapshot.docs.length && i < 3; i++) {
            final doc = subcollectionSnapshot.docs[i];
            AppLogger.info(
              '💬 Subcollection comment doc ${i}: ${doc.id} - ${doc.data()}',
            );
          }

          // Parse subcollection comments with error handling
          for (final doc in subcollectionSnapshot.docs) {
            try {
              final comment = ArtComment.fromFirestore(doc);
              comments.add(comment);
              AppLogger.info(
                '💬 Successfully parsed subcollection comment: ${comment.id} - "${comment.content}"',
              );
            } catch (e) {
              AppLogger.error(
                '💬 Failed to parse subcollection comment ${doc.id}: $e',
              );
            }
          }
        }
      }

      AppLogger.info(
        '💬 Retrieved ${comments.length} comments for post $postId',
      );

      return comments;
    } catch (e) {
      AppLogger.error('Error getting comments: $e');
      return [];
    }
  }

  /// Add comment to a post
  Future<String?> addComment(String postId, String content) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      AppLogger.info('💬 User data for comment: $userData');
      AppLogger.info(
        '💬 fullName: "${userData['fullName']}", displayName: "${userData['displayName']}", name: "${userData['name']}"',
      );

      final comment = ArtComment(
        id: '',
        postId: postId,
        userId: user.uid,
        userName:
            userData['fullName'] as String? ??
            userData['displayName'] as String? ??
            userData['name'] as String? ??
            'Anonymous',
        userAvatarUrl: userData['profileImageUrl'] as String? ?? '',
        content: content,
        createdAt: DateTime.now(),
      );

      AppLogger.info('💬 Comment userName will be: "${comment.userName}"');

      final docRef = await _firestore
          .collection('comments')
          .add(comment.toFirestore());

      // Update comment count
      await _firestore.collection('posts').doc(postId).update({
        'engagementStats.commentCount': FieldValue.increment(1),
        'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      AppLogger.error('Error adding comment: $e');
      return null;
    }
  }

  /// Get artist profile
  Future<ArtistProfile?> getArtistProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('artistProfiles')
          .doc(userId)
          .get();
      if (doc.exists) {
        return ArtistProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting artist profile: $e');
      return null;
    }
  }

  /// Create or update artist profile
  Future<bool> updateArtistProfile(ArtistProfile profile) async {
    try {
      await _firestore
          .collection('artistProfiles')
          .doc(profile.userId)
          .set(profile.toFirestore());
      return true;
    } catch (e) {
      AppLogger.error('Error updating artist profile: $e');
      return false;
    }
  }

  /// Get popular topics/tags
  Future<List<String>> getPopularTopics({int limit = 10}) async {
    try {
      // This would typically use aggregation, but for simplicity we'll get recent posts
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final allTags = <String>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tags = List<String>.from(data['tags'] as Iterable? ?? []);
        allTags.addAll(tags);
      }

      // Count frequency and return most popular
      final tagCounts = <String, int>{};
      for (final tag in allTags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }

      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedTags.take(limit).map((e) => e.key).toList();
    } catch (e) {
      AppLogger.error('Error getting popular topics: $e');
      return ['Paintings', 'Digital Art', 'Photography', 'Sculpture'];
    }
  }

  /// Search posts by query
  Future<List<ArtPost>> searchPosts(String query, {int limit = 20}) async {
    try {
      // Simple search implementation - in production you'd want full-text search
      final snapshot = await _firestore
          .collection('posts')
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => ArtPost.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Error searching posts: $e');
      return [];
    }
  }

  /// Fix existing posts that show "Anonymous" by updating their userName field
  Future<void> fixAnonymousPosts() async {
    try {
      AppLogger.debug('Starting anonymous posts fix');

      // Query posts where userName is "Anonymous"
      final anonymousPostsQuery = await _firestore
          .collection('posts')
          .where('userName', isEqualTo: 'Anonymous')
          .get();

      AppLogger.debug(
        'Found ${anonymousPostsQuery.docs.length} posts with "Anonymous" userName',
      );

      int updatedCount = 0;
      int errorCount = 0;

      for (final doc in anonymousPostsQuery.docs) {
        try {
          final postData = doc.data();
          final userId = postData['userId'] as String?;

          if (userId == null) {
            AppLogger.warning('Post ${doc.id} has no userId, skipping');
            continue;
          }

          // Get user profile data
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();

          if (!userDoc.exists) {
            AppLogger.warning(
              'User profile not found for userId: $userId, skipping post ${doc.id}',
            );
            continue;
          }

          final userData = userDoc.data() ?? {};

          // Determine the correct user name with multiple fallbacks
          final correctUserName =
              userData['displayName'] as String? ??
              userData['name'] as String? ??
              userData['fullName'] as String? ??
              'Anonymous'; // Keep as Anonymous if still not found

          if (correctUserName == 'Anonymous') {
            AppLogger.info(
              'Could not find display name for user $userId, keeping as Anonymous',
            );
            continue;
          }

          // Update the post with the correct user name
          await doc.reference.update({'userName': correctUserName});

          updatedCount++;
          AppLogger.debug('Updated post ${doc.id}: "$correctUserName"');
        } catch (e) {
          errorCount++;
          AppLogger.error('Error updating post ${doc.id}: $e', error: e);
        }
      }

      AppLogger.info(
        'Anonymous posts fix complete. Updated: $updatedCount, Errors: $errorCount',
      );
    } catch (e) {
      AppLogger.error('Fatal error in fixAnonymousPosts: $e', error: e);
      rethrow;
    }
  }

  /// Increment share count for a post
  Future<void> incrementShareCount(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'engagementStats.shareCount': FieldValue.increment(1),
        'engagementStats.lastUpdated': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Share count incremented for post: $postId');
    } catch (e) {
      AppLogger.error('Error incrementing share count for post $postId: $e');
    }
  }

  @override
  void dispose() {
    _feedController.close();
    _artistsController.close();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:share_plus/share_plus.dart';
// Using ArtistProfileModel from artbeat_core to avoid conflicts
import '../../models/group_models.dart';
import '../../widgets/group_post_card.dart';
import '../../widgets/post_detail_modal.dart';
import 'create_group_post_screen.dart';

/// Screen showing an individual artist's community feed

class ArtistCommunityFeedScreen extends StatefulWidget {
  final ArtistProfileModel artist;
  const ArtistCommunityFeedScreen({Key? key, required this.artist})
    : super(key: key);

  @override
  _ArtistCommunityFeedScreenState createState() =>
      _ArtistCommunityFeedScreenState();
}

class _ArtistCommunityFeedScreenState extends State<ArtistCommunityFeedScreen> {
  // State variables
  final List<ArtistGroupPost> _posts = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  final int _postsPerPage = 10;
  late ScrollController _scrollController;
  bool _isCurrentUserArtist = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _checkIfCurrentUserArtist();
    _loadArtistPosts();

    // Mark community as visited when this screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CommunityProvider>().markCommunityAsVisited();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_isLoading) {
      _loadMorePosts();
    }
  }

  void _checkIfCurrentUserArtist() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid == widget.artist.userId) {
      _isCurrentUserArtist = true;
    }
  }

  Future<void> _loadArtistPosts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _posts.clear();
      _lastDocument = null;
    });
    try {
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('groupType', isEqualTo: 'artist')
          .where('userId', isEqualTo: widget.artist.userId)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_postsPerPage)
          .get();

      if (!mounted) return;

      if (postsSnapshot.docs.isNotEmpty) {
        _lastDocument = postsSnapshot.docs.last;
        final loadedPosts = <ArtistGroupPost>[];
        for (final doc in postsSnapshot.docs) {
          try {
            final post = ArtistGroupPost.fromFirestore(doc);
            loadedPosts.add(post);
          } catch (e) {
            // debugPrint('Error parsing post ${doc.id}: $e');
          }
        }
        // Posts loaded successfully
        setState(() {
          _posts.addAll(loadedPosts);
          _isLoading = false;
        });
      } else {
        // debugPrint('No posts found for ${widget.artist.displayName}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // debugPrint('Error loading artist posts: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load posts: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || _lastDocument == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('groupType', isEqualTo: 'artist')
          .where('userId', isEqualTo: widget.artist.userId)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_postsPerPage)
          .get();

      if (!mounted) return;

      if (postsSnapshot.docs.isNotEmpty) {
        _lastDocument = postsSnapshot.docs.last;

        final morePosts = <ArtistGroupPost>[];
        for (final doc in postsSnapshot.docs) {
          try {
            final post = ArtistGroupPost.fromFirestore(doc);
            morePosts.add(post);
          } catch (e) {
            // debugPrint('Error parsing post ${doc.id}: $e');
          }
        }

        if (mounted) {
          setState(() {
            _posts.addAll(morePosts);
          });
        }
      }
    } catch (e) {
      // debugPrint('Error loading more posts: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading more posts: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _handleAppreciate(ArtistGroupPost post) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) return;

        final currentCount = postDoc.data()?['applauseCount'] ?? 0;
        transaction.update(postRef, {'applauseCount': currentCount + 1});

        // Track user appreciation to prevent duplicate appreciations
        final userAppreciationRef = FirebaseFirestore.instance
            .collection('user_appreciations')
            .doc('${user.uid}_${post.id}');

        transaction.set(userAppreciationRef, {
          'userId': user.uid,
          'postId': post.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('❤️ Appreciated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to appreciate: $e')));
      }
    }
  }

  void _handleComment(BaseGroupPost post) {
    // Show post detail modal instead of full screen
    PostDetailModal.show(context, post);
  }

  void _handleFeature(BaseGroupPost post) async {
    try {
      // Mark post as featured in Firestore
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id);

      // First check if the document exists
      final postDoc = await postRef.get();
      if (!postDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Post not found')));
        }
        return;
      }

      // Update the post to mark it as featured
      await postRef.update({'isFeatured': true});

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post featured!')));
      }
    } catch (e) {
      // debugPrint('Error featuring post: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to feature post: $e')));
      }
    }
  }

  void _handleGift(BaseGroupPost post) {
    // Show dialog to select and send a virtual gift
    showDialog<void>(
      context: context,
      builder: (context) {
        String? selectedGift;
        return AlertDialog(
          title: const Text('Send a Gift'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButton<String>(
                    value: selectedGift,
                    hint: const Text(
                      'Select a gift',
                      style: TextStyle(color: ArtbeatColors.textPrimary),
                    ),
                    style: const TextStyle(color: ArtbeatColors.textPrimary),
                    dropdownColor: ArtbeatColors.surface,
                    items: const [
                      DropdownMenuItem(
                        value: '🌟',
                        child: Text(
                          'Star',
                          style: TextStyle(color: ArtbeatColors.textPrimary),
                        ),
                      ),
                      DropdownMenuItem(
                        value: '🎨',
                        child: Text(
                          'Palette',
                          style: TextStyle(color: ArtbeatColors.textPrimary),
                        ),
                      ),
                      DropdownMenuItem(
                        value: '💐',
                        child: Text(
                          'Bouquet',
                          style: TextStyle(color: ArtbeatColors.textPrimary),
                        ),
                      ),
                      DropdownMenuItem(
                        value: '👏',
                        child: Text(
                          'Applause',
                          style: TextStyle(color: ArtbeatColors.textPrimary),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => selectedGift = value),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedGift == null) return;
                // Save gift to Firestore (as a subcollection 'gifts')
                final postRef = FirebaseFirestore.instance
                    .collection('posts')
                    .doc(post.id);
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await postRef.collection('gifts').add({
                    'gift': selectedGift,
                    'fromUserId': user.uid,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Gift sent!')));
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  void _handleShare(BaseGroupPost post) async {
    try {
      final shareText =
          '${post.content}\n\nShared from ARTbeat by ${post.userName}';
      await SharePlus.instance.share(ShareParams(text: shareText));

      // Update share count in Firestore
      await _updateShareCount(post.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    }
  }

  /// Update share count in Firestore
  Future<void> _updateShareCount(String postId) async {
    try {
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) return;

        final currentCount = postDoc.data()?['shareCount'] ?? 0;
        transaction.update(postRef, {'shareCount': currentCount + 1});
      });
    } catch (e) {
      // debugPrint('Failed to update share count: $e');
    }
  }

  void _openDeveloperTools(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer Tools'),
        content: const Text(
          'Developer tools will be available in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Artist Avatar
              CircleAvatar(
                radius: 40,
                backgroundImage:
                    widget.artist.profileImageUrl?.isNotEmpty == true
                    ? NetworkImage(widget.artist.profileImageUrl!)
                    : null,
                child: widget.artist.profileImageUrl?.isNotEmpty != true
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),

              // Artist Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show verification badge if verified
                    if (widget.artist.isVerified) ...[
                      const Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 20,
                            color: ArtbeatColors.primaryPurple,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Verified Artist',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ArtbeatColors.primaryPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (widget.artist.location?.isNotEmpty == true) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: ArtbeatColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.artist.location ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: ArtbeatColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (widget.artist.bio?.isNotEmpty == true) ...[
                      Text(
                        widget.artist.bio!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ArtbeatColors.textSecondary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Mediums and Styles
          if (widget.artist.mediums.isNotEmpty ||
              widget.artist.styles.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...widget.artist.mediums.map(
                  (medium) => _buildTag(medium, ArtbeatColors.primaryPurple),
                ),
                ...widget.artist.styles.map(
                  (style) => _buildTag(style, ArtbeatColors.primaryGreen),
                ),
              ],
            ),
          ],

          // Create Post Button (only for the artist viewing their own feed)
          if (_isCurrentUserArtist) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showCreatePostOptions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArtbeatColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Create New Post',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              ArtbeatColors.primaryPurple,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading artist posts...',
            style: TextStyle(fontSize: 16, color: ArtbeatColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: ArtbeatColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: const TextStyle(
              fontSize: 16,
              color: ArtbeatColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadArtistPosts,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.palette,
            size: 64,
            color: ArtbeatColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.artist.displayName} hasn\'t posted yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ArtbeatColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isCurrentUserArtist
                ? 'Tap the + button to share your first artwork!'
                : 'Check back later for new artwork!',
            style: const TextStyle(
              fontSize: 14,
              color: ArtbeatColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePostOptions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ArtbeatColors.primaryPurple.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.palette,
                        color: ArtbeatColors.primaryPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Artist Post',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Share your artwork with the community',
                            style: TextStyle(
                              fontSize: 14,
                              color: ArtbeatColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Create options
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildCreateOption(
                      icon: Icons.photo_camera,
                      title: 'Share Artwork',
                      subtitle: 'Post photos of your latest creation',
                      color: ArtbeatColors.primaryPurple,
                      postType: 'artwork',
                    ),
                    _buildCreateOption(
                      icon: Icons.video_camera_back,
                      title: 'Process Video',
                      subtitle: 'Share your creative process',
                      color: ArtbeatColors.primaryGreen,
                      postType: 'process',
                    ),
                    _buildCreateOption(
                      icon: Icons.text_fields,
                      title: 'Artist Update',
                      subtitle: 'Share thoughts or updates',
                      color: ArtbeatColors.secondaryTeal,
                      postType: 'update',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String postType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute<bool>(
                builder: (context) => CreateGroupPostScreen(
                  groupType: GroupType.artist,
                  postType: postType,
                ),
              ),
            );
            // Refresh the feed if a post was created
            if (result == true) {
              _loadArtistPosts();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.artist.displayName}\'s Feed'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF9C27B0), // Purple
                Color(0xFF4CAF50), // Green
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          IconButton(
            icon: const Icon(Icons.message, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/messaging'),
          ),
          IconButton(
            icon: const Icon(Icons.developer_mode, color: Colors.white),
            onPressed: () => _openDeveloperTools(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
              ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Artist header
            _buildArtistHeader(),

            // Posts list
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _hasError
                  ? _buildErrorState()
                  : _posts.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadArtistPosts,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _posts.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final post = _posts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GroupPostCard(
                              post: post,
                              groupType: GroupType.artist,
                              onAppreciate: () => _handleAppreciate(post),
                              onComment: () => _handleComment(post),
                              onFeature: () => _handleFeature(post),
                              onGift: () => _handleGift(post),
                              onShare: () => _handleShare(post),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

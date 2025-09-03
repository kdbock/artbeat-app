import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/group_models.dart';
import '../../widgets/group_post_card.dart';
import '../../widgets/post_detail_modal.dart';
import '../../theme/community_colors.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
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
    // Navigate to enhanced gift purchasing flow for the artist
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => EnhancedGiftPurchaseScreen(
          recipientId: post.userId,
          recipientName: post.userName,
        ),
      ),
    );
  }

  void _handleSponsor(BaseGroupPost post) {
    // Navigate to sponsorship screen for the artist
    Navigator.pushNamed(
      context,
      '/sponsorship/create',
      arguments: {'artistId': post.userId, 'artistName': post.userName},
    );
  }

  void _handleCommission(BaseGroupPost post) {
    // Navigate to commission request screen for the artist
    Navigator.pushNamed(
      context,
      '/commission/request',
      arguments: {'artistId': post.userId, 'artistName': post.userName},
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

  void _handleDirectMessage() {
    // Navigate to direct messaging with this artist
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid != widget.artist.userId) {
      // Create or navigate to chat with this artist
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'recipientId': widget.artist.userId,
          'recipientName': widget.artist.displayName,
          'recipientAvatar': widget.artist.profileImageUrl,
        },
      );
    }
  }

  void _handleArtistLike() {
    // Handle liking the artist profile
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❤️ Liked ${widget.artist.displayName}!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleArtistFollow() {
    // Handle following the artist
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('👤 Following ${widget.artist.displayName}!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleArtistGift() {
    // Show gift options dialog
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.card_giftcard, color: ArtbeatColors.accentGold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Send Gift to ${widget.artist.displayName}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Show your appreciation with a virtual gift!',
              style: TextStyle(color: ArtbeatColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildGiftOption('🌟', 'Star'),
                _buildGiftOption('🎨', 'Palette'),
                _buildGiftOption('💐', 'Bouquet'),
                _buildGiftOption('👏', 'Applause'),
                _buildGiftOption('🎁', 'Gift Box'),
                _buildGiftOption('💝', 'Heart'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _handleArtistSponsor() {
    // Handle sponsoring the artist
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.volunteer_activism,
              color: ArtbeatColors.primaryGreen,
            ),
            const SizedBox(width: 8),
            Text('Sponsor ${widget.artist.displayName}'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support this artist\'s creative journey!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'Choose a sponsorship tier:',
              style: TextStyle(color: ArtbeatColors.textSecondary),
            ),
            SizedBox(height: 16),
            // Add sponsorship tier options here
            Text('🥉 Bronze Supporter - \$5/month'),
            SizedBox(height: 8),
            Text('🥈 Silver Patron - \$15/month'),
            SizedBox(height: 8),
            Text('🥇 Gold Benefactor - \$50/month'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '🎉 Thank you for sponsoring ${widget.artist.displayName}!',
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ArtbeatColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sponsor'),
          ),
        ],
      ),
    );
  }

  void _handleCommissionRequest() {
    // Show commission request dialog or navigate to commission form
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.palette, color: ArtbeatColors.accentGold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Commission ${widget.artist.displayName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ArtbeatColors.accentGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ArtbeatColors.accentGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: ArtbeatColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.artist.displayName} is available for commissions!',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Project Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Describe your commission project, style preferences, size, timeline, and budget...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: ArtbeatColors.surface,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reference Images (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: ArtbeatColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.image,
                      color: ArtbeatColors.textSecondary,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upload reference images',
                        style: TextStyle(
                          color: ArtbeatColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.add_photo_alternate,
                      color: ArtbeatColors.primaryPurple,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement commission request submission with form data
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '🎨 Commission request sent to ${widget.artist.displayName}! '
                    'They\'ll respond within 24-48 hours.',
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ArtbeatColors.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    ? const Icon(
                        Icons.person,
                        size: 40,
                        color: ArtbeatColors.textSecondary,
                      )
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ArtbeatColors.success.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(12),
                          ),
                          border: Border.all(
                            color: ArtbeatColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: ArtbeatColors.success,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Verified Artist',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ArtbeatColors.success,
                              ),
                            ),
                          ],
                        ),
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
                          color: ArtbeatColors.textPrimary,
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
                  (style) => _buildTag(style, ArtbeatColors.accentGold),
                ),
              ],
            ),
          ],

          // Enhanced Artist Engagement Bar
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: ArtbeatColors.backgroundSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ArtbeatColors.textSecondary.withValues(alpha: 0.1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 16),
                  // Like/Follow Artist
                  _buildModernEngagementButton(
                    icon: Icons.favorite,
                    label: 'Like',
                    color: Colors.red,
                    onPressed: () => _handleArtistLike(),
                  ),
                  const SizedBox(width: 12),

                  // Follow Artist
                  if (!_isCurrentUserArtist) ...[
                    _buildModernEngagementButton(
                      icon: Icons.person_add,
                      label: 'Follow',
                      color: ArtbeatColors.primaryPurple,
                      onPressed: () => _handleArtistFollow(),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Gift to Artist
                  _buildModernEngagementButton(
                    icon: Icons.card_giftcard,
                    label: 'Gift',
                    color: ArtbeatColors.accentGold,
                    onPressed: () => _handleArtistGift(),
                  ),
                  const SizedBox(width: 12),

                  // Sponsor Artist
                  _buildModernEngagementButton(
                    icon: Icons.volunteer_activism,
                    label: 'Sponsor',
                    color: ArtbeatColors.primaryGreen,
                    onPressed: () => _handleArtistSponsor(),
                  ),
                  const SizedBox(width: 12),

                  // Message Artist
                  if (!_isCurrentUserArtist) ...[
                    _buildModernEngagementButton(
                      icon: Icons.message,
                      label: 'Message',
                      color: ArtbeatColors.secondaryTeal,
                      onPressed: _handleDirectMessage,
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Commission Request
                  _buildModernEngagementButton(
                    icon: Icons.palette,
                    label: 'Commission',
                    color: ArtbeatColors.accentOrange,
                    onPressed: _handleCommissionRequest,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),

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
        borderRadius: const BorderRadius.all(Radius.circular(12)),
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

  Widget _buildModernEngagementButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70, // Fixed width to prevent overflow
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftOption(String emoji, String name) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎁 Sent $emoji $name to ${widget.artist.displayName}!',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: ArtbeatColors.textSecondary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                color: ArtbeatColors.textSecondary,
              ),
            ),
          ],
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
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: CommunityColors.communityGradient,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Header row with back button, title, and actions
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.artist.displayName}\'s Feed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {
                        // TODO: Implement search
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.message, color: Colors.white),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/messaging'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        toolbarHeight: 64, // Height for header
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: CommunityColors.communityBackgroundGradient,
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
                            child: Column(
                              children: [
                                GroupPostCard(
                                  post: post,
                                  groupType: GroupType.artist,
                                  onAppreciate: () => _handleAppreciate(post),
                                  onComment: () => _handleComment(post),
                                  onFeature: () => _handleFeature(post),
                                  onGift: () => _handleGift(post),
                                  onShare: () => _handleShare(post),
                                ),
                                // Additional engagement buttons for artist posts
                                if (!_isCurrentUserArtist ||
                                    post.userId !=
                                        FirebaseAuth.instance.currentUser?.uid)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(
                                        alpha: 0.05,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildEngagementButton(
                                          icon: Icons.attach_money,
                                          label: 'Sponsor',
                                          color: Colors.green,
                                          onTap: () => _handleSponsor(post),
                                        ),
                                        _buildEngagementButton(
                                          icon: Icons.work_outline,
                                          label: 'Commission',
                                          color: Colors.purple,
                                          onTap: () => _handleCommission(post),
                                        ),
                                        _buildEngagementButton(
                                          icon: Icons.message_outlined,
                                          label: 'Message',
                                          color: Colors.blue,
                                          onTap: () => _handleDirectMessage(),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
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

  Widget _buildEngagementButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

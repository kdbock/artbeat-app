import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_core/artbeat_core.dart' hide ArtworkModel;
import 'package:share_plus/share_plus.dart';

/// Screen for viewing artwork details
class ArtworkDetailScreen extends StatefulWidget {
  final String artworkId;

  const ArtworkDetailScreen({
    super.key,
    required this.artworkId,
  });

  @override
  State<ArtworkDetailScreen> createState() => _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends State<ArtworkDetailScreen> {
  final ArtworkService _artworkService = ArtworkService();
  final artist.SubscriptionService _subscriptionService =
      artist.SubscriptionService();
  final artist.AnalyticsService _analyticsService = artist.AnalyticsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  ArtworkModel? _artwork;
  ArtistProfileModel? _artist;
  String? _fallbackArtistName;
  String? _fallbackArtistImageUrl;
  bool _isOwner = false;
  List<Map<String, dynamic>> _ratings = [];
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  bool _ratingsLoading = false;
  List<CommentModel> _comments = [];
  bool _commentsLoading = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadArtworkData();
  }

  Future<void> _loadArtworkData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get artwork details
      var artwork = await _artworkService.getArtworkById(widget.artworkId);

      // Track artwork view for analytics if artwork exists
      if (artwork != null) {
        _analyticsService.trackArtworkView(
          artworkId: widget.artworkId,
          artistId: artwork.userId,
        );
      }

      if (artwork == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Artwork not found')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Get artist profile
      final artistProfile = await _subscriptionService
          .getArtistProfileById(artwork.artistProfileId);

      // If artist profile not found, try to get user information as fallback
      String? fallbackArtistName;
      String? fallbackArtistImageUrl;
      if (artistProfile == null) {
        try {
          final userService = UserService();
          final userData = await userService.getUserProfile(artwork.userId);
          fallbackArtistName = (userData?['fullName'] as String?) ??
              (userData?['displayName'] as String?) ??
              'Unknown Artist';
          fallbackArtistImageUrl = userData?['profileImageUrl'] as String?;
        } catch (e) {
          AppLogger.error('Error getting user profile for artist: $e');
          fallbackArtistName = 'Unknown Artist';
          fallbackArtistImageUrl = null;
        }
      }

      // Check if user is the owner of this artwork

      // Check if current user is the owner of this artwork
      final currentUser = _auth.currentUser;
      final isOwner = currentUser != null && currentUser.uid == artwork.userId;

      // Increment view count
      await _artworkService.incrementViewCount(widget.artworkId);

      // Refresh artwork to get updated view count
      final updatedArtwork =
          await _artworkService.getArtworkById(widget.artworkId);
      if (updatedArtwork != null) {
        artwork = updatedArtwork;
      }

      if (mounted) {
        setState(() {
          _artwork = artwork;
          _artist = artistProfile;
          _fallbackArtistName = fallbackArtistName;
          _fallbackArtistImageUrl = fallbackArtistImageUrl;
          _isOwner = isOwner;
          _isLoading = false;
        });

        // Load ratings and reviews after main data is loaded
        _loadRatingsAndReviews();
        _loadComments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading artwork: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRatingsAndReviews() async {
    if (_artwork == null) return;

    AppLogger.info('Loading ratings and reviews for artwork: ${_artwork!.id}');
    setState(() {
      _ratingsLoading = true;
    });

    try {
      final engagementService = ContentEngagementService();

      final ratings = await engagementService.getRatings(
        contentId: _artwork!.id,
        contentType: 'artwork',
      );

      AppLogger.info('Fetched ${ratings.length} ratings');

      final reviews = await engagementService.getReviews(
        contentId: _artwork!.id,
        contentType: 'artwork',
      );

      AppLogger.info('Fetched ${reviews.length} reviews');

      final averageRating = await engagementService.getAverageRating(
        contentId: _artwork!.id,
        contentType: 'artwork',
      );

      AppLogger.info('Average rating: $averageRating');

      if (mounted) {
        setState(() {
          _ratings = ratings;
          _reviews = reviews;
          _averageRating = averageRating;
          _ratingsLoading = false;
        });
        AppLogger.info('UI updated with ratings and reviews');
      }
    } catch (e) {
      AppLogger.error('Error loading ratings and reviews: $e');
      if (mounted) {
        setState(() {
          _ratingsLoading = false;
        });
      }
    }
  }

  void _shareArtwork() {
    if (_artwork == null) return;

    _showShareDialog();
  }

  Future<void> _showShareDialog() async {
    if (_artwork == null) return;

    final String artistName =
        _artist?.displayName ?? _fallbackArtistName ?? 'Artist';
    final String title = _artwork!.title;
    final String artworkUrl = 'https://artbeat.app/artwork/${_artwork!.id}';
    final String shareText =
        'Check out "$title" by $artistName on ARTbeat! 🎨\n\n$artworkUrl';

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share Artwork',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"$title" by $artistName',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    icon: Icons.message,
                    label: 'Messages',
                    onTap: () async {
                      Navigator.pop(context);
                      await SharePlus.instance.share(ShareParams(
                        text: shareText,
                        subject: 'Amazing artwork on ARTbeat',
                      ));
                      await _trackShare('messages');
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.copy,
                    label: 'Copy Link',
                    onTap: () async {
                      Navigator.pop(context);
                      // In a real app, you'd copy the dynamic link to clipboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Link copied to clipboard')),
                      );
                      await _trackShare('copy_link');
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.share,
                    label: 'More',
                    onTap: () async {
                      Navigator.pop(context);
                      await SharePlus.instance.share(ShareParams(
                        text: shareText,
                        subject: 'Amazing artwork on ARTbeat',
                      ));
                      await _trackShare('system_share');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Social media options (placeholders for now)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    icon: Icons.camera_alt,
                    label: 'Stories',
                    color: Colors.purple,
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Stories sharing coming soon!')),
                      );
                      await _trackShare('stories');
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    color: Colors.blue,
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Facebook sharing coming soon!')),
                      );
                      await _trackShare('facebook');
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.photo_camera,
                    label: 'Instagram',
                    color: Colors.pink,
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Instagram sharing coming soon!')),
                      );
                      await _trackShare('instagram');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (color ?? Theme.of(context).primaryColor)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color ?? Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _trackShare(String platform) async {
    try {
      final engagementService = ContentEngagementService();
      await engagementService.toggleEngagement(
        contentId: _artwork!.id,
        contentType: 'artwork',
        engagementType: EngagementType.share,
        metadata: {
          'platform': platform,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.error('Error tracking share: $e');
    }
  }

  void _editArtwork() {
    if (_artwork == null) return;

    Navigator.pushNamed(
      context,
      '/artwork/edit',
      arguments: {
        'artworkId': _artwork!.id,
        'artwork': _artwork,
      },
    ).then((_) {
      // Refresh artwork data when returning from edit
      _loadArtworkData();
    });
  }

  Future<void> _showDeleteConfirmation() async {
    if (_artwork == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Artwork'),
        content: Text(
          'Are you sure you want to delete "${_artwork!.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteArtwork();
    }
  }

  Future<void> _deleteArtwork() async {
    if (_artwork == null) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Deleting artwork...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      await _artworkService.deleteArtwork(_artwork!.id);

      if (mounted) {
        // Hide loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_artwork!.title}" has been deleted successfully'),
            backgroundColor: ArtbeatColors.primaryGreen,
          ),
        );

        // Navigate back to the previous screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        // Hide loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete artwork: $e'),
            backgroundColor: ArtbeatColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadComments() async {
    if (_artwork == null) return;

    setState(() => _commentsLoading = true);
    try {
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('artwork')
          .doc(_artwork!.id)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .get();

      final comments = commentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return CommentModel(
          id: doc.id,
          postId: _artwork!.id,
          userId: data['userId'] as String? ?? '',
          userName: data['userName'] as String? ?? '',
          userAvatarUrl: data['userAvatarUrl'] as String? ?? '',
          content: data['content'] as String? ?? '',
          createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
          parentCommentId: data['parentCommentId'] as String? ?? '',
          type: data['type'] as String? ?? 'Appreciation',
        );
      }).toList();

      setState(() => _comments = comments);
    } catch (e) {
      AppLogger.error('Error loading comments: $e');
    } finally {
      setState(() => _commentsLoading = false);
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || _artwork == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get user profile for name and photo
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      final userName =
          userData?['fullName'] ?? userData?['displayName'] ?? 'Anonymous';
      final userPhotoUrl = userData?['profileImageUrl'] ?? '';

      await FirebaseFirestore.instance
          .collection('artwork')
          .doc(_artwork!.id)
          .collection('comments')
          .add({
        'userId': user.uid,
        'userName': userName,
        'userAvatarUrl': userPhotoUrl,
        'content': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'parentCommentId': '',
        'type': 'Appreciation',
      });

      _commentController.clear();
      await _loadComments(); // Refresh comments
    } catch (e) {
      AppLogger.error('Error posting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post comment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MainLayout(
        currentIndex: -1, // No navigation highlight for detail screens
        child: Scaffold(
          appBar: EnhancedUniversalHeader(
            title: 'Artwork',
            showLogo: false,
          ),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final artwork = _artwork!;
    final artistProfile = _artist;

    return MainLayout(
      currentIndex: -1, // No navigation highlight for detail screens
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Artwork'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareArtwork,
            ),
            if (_isOwner) ...[
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editArtwork();
                  } else if (value == 'delete') {
                    _showDeleteConfirmation();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full-size artwork image
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SecureNetworkImage(
                  imageUrl: artwork.imageUrl,
                  fit: BoxFit.contain, // Show full image without cropping
                  enableThumbnailFallback: true, // Enable fallback for artwork
                  errorWidget: Container(
                    height: 300,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

              // Artwork details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with artist name and price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title only
                              Text(
                                artwork.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Moderation Status Chip
                              ArtworkModerationStatusChip(
                                status: artwork.moderationStatus,
                                showIcon: true,
                              ),
                              const SizedBox(height: 4),
                              if (artwork.yearCreated != null)
                                Text(
                                  '${artwork.yearCreated}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (artwork.isForSale)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '\$${artwork.price?.toStringAsFixed(2) ?? 'For Sale'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Artist info (clickable profile section)
                    if (artistProfile != null)
                      InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/artist/public-profile',
                            arguments: {'artistId': artistProfile.id},
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              UserAvatar(
                                imageUrl: artistProfile.profileImageUrl,
                                displayName: artistProfile.displayName,
                                radius: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      artistProfile.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (artistProfile.location != null &&
                                        artistProfile.location!.isNotEmpty)
                                      Text(
                                        artistProfile.location!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 16),
                            ],
                          ),
                        ),
                      )
                    else if (_fallbackArtistName != null)
                      // Show basic artist info when profile is not available
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            UserAvatar(
                              imageUrl: _fallbackArtistImageUrl,
                              displayName: _fallbackArtistName!,
                              radius: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _fallbackArtistName!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Divider
                    const Divider(height: 32),

                    // Details section
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    // Artwork properties
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: _buildPropertyRow('Medium', artwork.medium),
                    ),
                    if (artwork.dimensions != null)
                      _buildPropertyRow('Dimensions', artwork.dimensions!),
                    _buildPropertyRow('Style', artwork.styles.join(', ')),

                    // Divider
                    const Divider(height: 32),

                    // Description section
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        artwork.description,
                        style: const TextStyle(height: 1.5),
                      ),
                    ),

                    // Tags
                    if (artwork.tags?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: artwork.tags!
                            .map((tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor: Theme.of(context)
                                      .chipTheme
                                      .backgroundColor,
                                ))
                            .toList(),
                      ),
                    ],

                    // Content engagement bar
                    const SizedBox(height: 24),
                    ContentEngagementBar(
                      contentId: artwork.id,
                      contentType: 'artwork',
                      initialStats: artwork.engagementStats,
                      showSecondaryActions: true,
                      onEngagementChanged: () {
                        // Refresh ratings and reviews when user submits new ones
                        _loadRatingsAndReviews();
                      },
                    ),

                    // View count and rating count
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Rating count
                        const Icon(Icons.star,
                            size: 16, color: ArtbeatColors.darkGray),
                        const SizedBox(width: 4),
                        Text(
                          '${_ratings.length} ratings',
                          style: const TextStyle(
                            color: ArtbeatColors.darkGray,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // View count
                        const Icon(Icons.visibility,
                            size: 16, color: ArtbeatColors.darkGray),
                        const SizedBox(width: 4),
                        Text(
                          '${artwork.viewCount} views',
                          style: const TextStyle(
                            color: ArtbeatColors.darkGray,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    // Ratings and Reviews Section - always show after ratings/reviews are loaded
                    const SizedBox(height: 32),
                    const Divider(height: 32),

                    // Ratings Section
                    Row(
                      children: [
                        const Text(
                          'Ratings & Reviews',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        if (_ratingsLoading) ...[
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ] else if (_averageRating > 0) ...[
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < _averageRating.floor()
                                      ? Icons.star
                                      : (index < _averageRating
                                          ? Icons.star_half
                                          : Icons.star_border),
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                '${_averageRating.toStringAsFixed(1)} (${_ratings.length})',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Individual Ratings
                    if (_ratings.isNotEmpty) ...[
                      const Text(
                        'Recent Ratings:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_ratings
                          .take(3)
                          .map((rating) => _buildRatingItem(rating))
                          .toList()),
                      if (_ratings.length > 3) ...[
                        TextButton(
                          onPressed: () => _showAllRatings(),
                          child: Text('View all ${_ratings.length} ratings'),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ] else if (!_ratingsLoading) ...[
                      const Text(
                        'No ratings yet. Be the first to rate this artwork!',
                        style: TextStyle(
                          color: ArtbeatColors.darkGray,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Reviews Section
                    if (_reviews.isNotEmpty) ...[
                      const Text(
                        'Recent Reviews:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Individual Reviews
                      ...(_reviews
                          .take(2)
                          .map((review) => _buildReviewItem(review))
                          .toList()),

                      if (_reviews.length > 2) ...[
                        TextButton(
                          onPressed: () => _showAllReviews(),
                          child: Text('View all ${_reviews.length} reviews'),
                        ),
                      ],
                    ] else if (!_ratingsLoading) ...[
                      const Text(
                        'No reviews yet. Be the first to review this artwork!',
                        style: TextStyle(
                          color: ArtbeatColors.darkGray,
                          fontSize: 14,
                        ),
                      ),
                    ],

                    // Comments Section
                    const SizedBox(height: 32),
                    const Divider(height: 32),
                    Row(
                      children: [
                        const Text(
                          'Comments',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        if (_commentsLoading) ...[
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ] else ...[
                          Text(
                            '${_comments.length} comments',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Comment Input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Write a comment...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: 3,
                            minLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _postComment,
                          child: const Text('Post'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Comments List
                    if (_comments.isNotEmpty) ...[
                      ..._comments.map((comment) => _buildCommentItem(comment)),
                    ] else if (!_commentsLoading) ...[
                      const Text(
                        'No comments yet. Be the first to comment!',
                        style: TextStyle(
                          color: ArtbeatColors.darkGray,
                          fontSize: 14,
                        ),
                      ),
                    ],

                    // Social Engagement Widget
                    const SizedBox(height: 32),
                    const Divider(height: 32),
                    ArtworkSocialWidget(
                      artworkId: artwork.id,
                      artworkTitle: artwork.title,
                      showComments: true,
                      showRatings: true,
                      onEngagementChanged: () {
                        // Refresh data when engagement changes
                        _loadRatingsAndReviews();
                        _loadComments();
                      },
                    ),

                    // Action buttons
                    const SizedBox(height: 32),
                    if (artwork.isForSale)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // In a real app, this would navigate to purchase or inquiry page
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Purchase feature coming soon')),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Purchase'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
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

  Widget _buildRatingItem(Map<String, dynamic> rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            imageUrl: rating['userProfileImage'] as String?,
            displayName: rating['userName'] as String,
            radius: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rating['userName'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < (rating['rating'] as int)
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(rating['createdAt'] as DateTime),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            imageUrl: review['userProfileImage'] as String?,
            displayName: review['userName'] as String,
            radius: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review['userName'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  review['review'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(review['createdAt'] as DateTime),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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

  void _showAllRatings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Ratings (${_ratings.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _ratings.length,
                      itemBuilder: (context, index) {
                        return _buildRatingItem(_ratings[index]);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAllReviews() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Reviews (${_reviews.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        return _buildReviewItem(_reviews[index]);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            imageUrl: comment.userAvatarUrl,
            displayName: comment.userName,
            radius: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(comment.createdAt.toDate()),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

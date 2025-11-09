import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_core/artbeat_core.dart' hide ArtworkModel;
import 'package:share_plus/share_plus.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

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
            SnackBar(content: Text('artwork_detail_not_found'.tr())),
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('artwork_error_loading'.tr(namedArgs: {'error': e.toString()}))),
        );
        setState(() {
          _isLoading = false;
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
              Text(
                'artwork_share_title'.tr(),
                style: const TextStyle(
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
                    label: 'artwork_share_messages'.tr(),
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
                    label: 'artwork_share_copy_link'.tr(),
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('artwork_share_link_copied'.tr())),
                      );
                      await _trackShare('copy_link');
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.share,
                    label: 'artwork_share_more'.tr(),
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
                    label: 'artwork_share_stories'.tr(),
                    color: Colors.purple,
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('artwork_share_stories_coming'.tr())),
                      );
                      await _trackShare('stories');
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.facebook,
                    label: 'artwork_share_facebook'.tr(),
                    color: Colors.blue,
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('artwork_share_facebook_coming'.tr())),
                      );
                      await _trackShare('facebook');
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.photo_camera,
                    label: 'artwork_share_instagram'.tr(),
                    color: Colors.pink,
                    onTap: () async {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('artwork_share_instagram_coming'.tr())),
                      );
                      await _trackShare('instagram');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('common_cancel'.tr()),
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

      // Track share for challenge progress
      try {
        final challengeService = ChallengeService();
        await challengeService.recordSocialShare();
      } catch (e) {
        AppLogger.error('Error recording share to challenge: $e');
      }
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
        title: Text('artwork_delete_title'.tr()),
        content: Text(
          'artwork_delete_confirm'.tr(namedArgs: {'title': _artwork!.title}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('common_delete'.tr()),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Text('artwork_deleting'.tr()),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );

      await _artworkService.deleteArtwork(_artwork!.id);

      if (mounted) {
        // Hide loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('artwork_deleted_success'.tr(namedArgs: {'title': _artwork!.title})),
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('artwork_delete_failed'.tr(namedArgs: {'error': e.toString()})),
            backgroundColor: ArtbeatColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MainLayout(
        currentIndex: -1, // No navigation highlight for detail screens
        child: Scaffold(
          appBar: EnhancedUniversalHeader(
            title: 'artwork_detail_title'.tr(),
            showLogo: false,
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final artwork = _artwork!;
    final artistProfile = _artist;

    return MainLayout(
      currentIndex: -1, // No navigation highlight for detail screens
      child: Scaffold(
        appBar: AppBar(
          title: Text('artwork_detail_title'.tr()),
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
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 18),
                        const SizedBox(width: 8),
                        Text('common_edit'.tr()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('common_delete'.tr(), style: const TextStyle(color: Colors.red)),
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

                    // Content engagement bar (rate/comment handled by ArtworkSocialWidget below)
                    const SizedBox(height: 24),
                    ContentEngagementBar(
                      contentId: artwork.id,
                      contentType: 'artwork',
                      initialStats: artwork.engagementStats,
                      showSecondaryActions: true,
                      artistId: artwork.userId,
                      artistName: _artist?.displayName ??
                          _fallbackArtistName ??
                          'Unknown Artist',
                    ),

                    // View count
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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

                    // Social Engagement Widget
                    const SizedBox(height: 32),
                    const Divider(height: 32),
                    ArtworkSocialWidget(
                      artworkId: artwork.id,
                      artworkTitle: artwork.title,
                      showComments: true,
                      showRatings: true,
                    ),

                    // Action buttons
                    const SizedBox(height: 32),
                    if (artwork.isForSale)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to purchase screen
                            Navigator.pushNamed(
                              context,
                              '/artwork/purchase',
                              arguments: {'artworkId': artwork.id},
                            );
                          },
                          icon: const Icon(Icons.shopping_cart),
                          label: Text('artwork_purchase_button'.tr()),
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

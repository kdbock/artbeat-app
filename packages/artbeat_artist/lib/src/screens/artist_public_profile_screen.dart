import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:url_launcher/url_launcher.dart';
import '../services/subscription_service.dart';
import '../services/analytics_service.dart';
import '../models/artist_profile_model.dart';

/// Screen for viewing an artist's public profile
class ArtistPublicProfileScreen extends StatefulWidget {
  final String artistProfileId;

  const ArtistPublicProfileScreen({
    super.key,
    required this.artistProfileId,
  });

  @override
  State<ArtistPublicProfileScreen> createState() =>
      _ArtistPublicProfileScreenState();
}

class _ArtistPublicProfileScreenState extends State<ArtistPublicProfileScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final artwork.ArtworkService _artworkService = artwork.ArtworkService();
  final AnalyticsService _analyticsService = AnalyticsService();

  bool _isLoading = true;
  ArtistProfileModel? _artistProfile;
  List<artwork.ArtworkModel> _artwork = [];
  String? _currentUserId;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadArtistProfile();
  }

  Future<void> _loadArtistProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      _currentUserId = _subscriptionService.getCurrentUserId();

      // Get artist profile
      final artistProfile = await _subscriptionService
          .getArtistProfileById(widget.artistProfileId);

      // Track profile view for analytics if profile exists
      if (artistProfile != null) {
        _analyticsService.trackArtistProfileView(
          artistProfileId: widget.artistProfileId,
          artistId: artistProfile.userId,
        );
      }

      if (artistProfile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Artist profile not found')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Get artist's artwork
      final artwork = await _artworkService
          .getArtworkByArtistProfileId(widget.artistProfileId);

      // Check if current user is following this artist
      bool isFollowing = false;
      if (_currentUserId != null) {
        isFollowing = await _subscriptionService.isFollowingArtist(
          artistProfileId: widget.artistProfileId,
        );
      }

      if (mounted) {
        setState(() {
          _artistProfile = artistProfile as ArtistProfileModel?;
          _artwork = artwork;
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading artist profile: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUserId == null) {
      // Prompt user to log in
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to follow artists')),
        );
      }
      return;
    }

    try {
      final result = await _subscriptionService.toggleFollowArtist(
        artistProfileId: widget.artistProfileId,
      );

      if (mounted) {
        setState(() {
          _isFollowing = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Artist Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final artist = _artistProfile!;
    final bool isPremium =
        artist.subscriptionTier != core.SubscriptionTier.basic;
    final socialLinks = artist.socialLinks;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with cover image
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: artist.coverImageUrl != null &&
                      artist.coverImageUrl!.isNotEmpty
                  ? Image.network(
                      artist.coverImageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/default_profile.png',
                      fit: BoxFit.cover,
                    ),
            ),
          ),

          // Artist info
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile image and follow button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: artist.profileImageUrl != null &&
                                artist.profileImageUrl!.isNotEmpty
                            ? NetworkImage(artist.profileImageUrl!)
                                as ImageProvider
                            : const AssetImage('assets/default_profile.png'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  artist.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (artist.isVerified)
                                  const Icon(Icons.verified,
                                      color: Colors.blue, size: 20),
                              ],
                            ),
                            if (artist.location != null &&
                                artist.location!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      artist.location!,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing
                                    ? Colors.grey[200]
                                    : Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    _isFollowing ? Colors.black : Colors.white,
                                minimumSize: const Size(double.infinity, 36),
                              ),
                              child: Text(
                                _isFollowing ? 'Following' : 'Follow',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Subscription badge
                  if (isPremium)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: artist.subscriptionTier ==
                                  core.SubscriptionTier.premium
                              ? Colors.amber[100]
                              : Theme.of(context).colorScheme.primary.withAlpha(
                                  25), // Changed from withOpacity(0.1)
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: artist.subscriptionTier ==
                                      core.SubscriptionTier.premium
                                  ? Colors.amber[800]
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              artist.userType == UserType.gallery
                                  ? 'Gallery Business'
                                  : artist.subscriptionTier ==
                                          core.SubscriptionTier.premium
                                      ? 'Gallery Plan'
                                      : 'Pro Artist',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: artist.subscriptionTier ==
                                        core.SubscriptionTier.premium
                                    ? Colors.amber[800]
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Bio
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      artist.bio,
                      style: const TextStyle(height: 1.5),
                    ),
                  ),

                  // Specialties
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text(
                      'Specialties',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),

                  // Mediums and styles
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...artist.mediums.map((medium) => Chip(
                              label: Text(medium),
                              backgroundColor:
                                  Theme.of(context).chipTheme.backgroundColor,
                            )),
                        ...artist.styles.map((style) => Chip(
                              label: Text(style),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(
                                      25), // Changed from withOpacity(0.1)
                            )),
                      ],
                    ),
                  ),

                  // Social media and website links
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text(
                      'Connect',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (socialLinks['website'] != null &&
                            socialLinks['website']!.isNotEmpty)
                          IconButton(
                            onPressed: () => _launchUrl(socialLinks['website']),
                            icon: const Icon(Icons.language),
                            tooltip: 'Website',
                          ),
                        if (socialLinks['instagram'] != null &&
                            socialLinks['instagram']!.isNotEmpty)
                          IconButton(
                            onPressed: () => _launchUrl(
                                'https://instagram.com/${socialLinks['instagram']}'),
                            icon: const Icon(Icons.camera_alt),
                            tooltip: 'Instagram',
                          ),
                        if (socialLinks['facebook'] != null &&
                            socialLinks['facebook']!.isNotEmpty)
                          IconButton(
                            onPressed: () =>
                                _launchUrl(socialLinks['facebook']),
                            icon: const Icon(Icons.facebook),
                            tooltip: 'Facebook',
                          ),
                        if (socialLinks['twitter'] != null &&
                            socialLinks['twitter']!.isNotEmpty)
                          IconButton(
                            onPressed: () => _launchUrl(
                                'https://twitter.com/${socialLinks['twitter']}'),
                            icon: const Icon(Icons.email),
                            tooltip: 'Twitter',
                          ),
                        if (socialLinks['etsy'] != null &&
                            socialLinks['etsy']!.isNotEmpty)
                          IconButton(
                            onPressed: () => _launchUrl(socialLinks['etsy']),
                            icon: const Icon(Icons.shopping_bag),
                            tooltip: 'Etsy',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Artwork section title
          SliverPadding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Artwork',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '${_artwork.length} pieces',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Artwork grid
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: _artwork.isEmpty
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Text('No artwork available'),
                    ),
                  )
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final artwork = _artwork[index];
                        return _buildArtworkItem(artwork);
                      },
                      childCount: _artwork.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkItem(artwork.ArtworkModel artwork) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/artist/artwork-detail',
          arguments: {'artworkId': artwork.id},
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork image
            Expanded(
              child: Stack(
                children: [
                  // Image
                  SizedBox(
                    width: double.infinity,
                    child: Image.network(
                      artwork.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // For sale badge
                  if (artwork.isForSale)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '\$${artwork.price?.toStringAsFixed(2) ?? 'For Sale'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Artwork info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    artwork.medium,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:artbeat_community/artbeat_community.dart';
import 'package:share_plus/share_plus.dart';

class DashboardArtistsSection extends StatefulWidget {
  final DashboardViewModel viewModel;

  const DashboardArtistsSection({Key? key, required this.viewModel})
    : super(key: key);

  @override
  State<DashboardArtistsSection> createState() =>
      _DashboardArtistsSectionState();
}

class _DashboardArtistsSectionState extends State<DashboardArtistsSection> {
  // Track appreciate states for each artist
  final Map<String, bool> _appreciateStates = {};
  // Track loading states for each artist
  final Map<String, bool> _loadingStates = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context),
            const SizedBox(height: 16),
            _buildArtistsContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: ArtbeatColors.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.people, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Featured Artists',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              Text(
                'Discover talented artists in your community',
                style: TextStyle(
                  fontSize: 14,
                  color: ArtbeatColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [ArtbeatColors.primaryPurple, ArtbeatColors.primaryGreen],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/artist/browse'),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtistsContent(BuildContext context) {
    if (widget.viewModel.isLoadingArtists) {
      return _buildLoadingState();
    }

    if (widget.viewModel.artistsError != null) {
      return _buildErrorState();
    }

    final artists = widget.viewModel.artists;

    if (artists.isEmpty) {
      return _buildEmptyState(context);
    }

    return SizedBox(
      height: 140, // Updated to match new card height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 12,
              right: index == artists.length - 1 ? 0 : 0,
            ),
            child: _buildArtistCard(context, artist),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 140, // Updated to match new card height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 12),
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 140, // Updated to match new card height
      decoration: BoxDecoration(
        color: ArtbeatColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: ArtbeatColors.textSecondary,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Unable to load artists',
              style: TextStyle(color: ArtbeatColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 140, // Updated to match new card height
      decoration: BoxDecoration(
        color: ArtbeatColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              color: ArtbeatColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'No featured artists yet',
              style: TextStyle(
                color: ArtbeatColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back soon for featured artists!',
              style: TextStyle(color: ArtbeatColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/artists/search'),
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Find Artists'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistCard(BuildContext context, ArtistProfileModel artist) {
    return Container(
      width: 150,
      height: 140, // Increased to accommodate new layout
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: Appreciate icon, Avatar, Gift icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Appreciate icon (left of avatar)
                  _buildAppreciateButton(context, artist),

                  // Avatar (center)
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/artist/public-profile',
                      arguments: {'artistId': artist.id},
                    ),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            ArtbeatColors.primaryPurple,
                            ArtbeatColors.primaryGreen,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: ClipOval(
                          child:
                              (artist.profileImageUrl != null &&
                                  artist.profileImageUrl!.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: artist.profileImageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                        Icons.person,
                                        color: ArtbeatColors.textSecondary,
                                        size: 30,
                                      ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: ArtbeatColors.textSecondary,
                                  size: 30,
                                ),
                        ),
                      ),
                    ),
                  ),

                  // Gift icon (right of avatar)
                  _buildGiftButton(context, artist),
                ],
              ),

              // Artist name (links to profile)
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/artist/public-profile',
                    arguments: {'artistId': artist.id},
                  ),
                  child: Text(
                    artist.displayName.isNotEmpty
                        ? artist.displayName
                        : 'Unknown Artist',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ArtbeatColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Bottom row: Connect, Discuss, Amplify
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Connect (Follow)
                  _buildConnectButton(context, artist),

                  // Discuss (Community Feed)
                  _buildDiscussButton(context, artist),

                  // Amplify (Share)
                  _buildAmplifyButton(context, artist),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppreciateButton(
    BuildContext context,
    ArtistProfileModel artist,
  ) {
    final isAppreciated = _appreciateStates[artist.userId] ?? false;
    final isLoading = _loadingStates[artist.userId] ?? false;

    return GestureDetector(
      onTap: isLoading ? null : () => _handleAppreciateAction(context, artist),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isAppreciated
              ? ArtbeatColors.accentYellow.withValues(alpha: 0.2)
              : ArtbeatColors.accentYellow.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAppreciated
                ? ArtbeatColors.accentYellow
                : ArtbeatColors.accentYellow.withValues(alpha: 0.3),
            width: isAppreciated ? 1.5 : 1,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ArtbeatColors.accentYellow,
                  ),
                ),
              )
            : Icon(
                isAppreciated ? Icons.palette : Icons.palette_outlined,
                size: 16,
                color: ArtbeatColors.accentYellow,
              ),
      ),
    );
  }

  Widget _buildGiftButton(BuildContext context, ArtistProfileModel artist) {
    return GestureDetector(
      onTap: () => _handleGiftAction(context, artist),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: ArtbeatColors.accentGold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ArtbeatColors.accentGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.card_giftcard,
          size: 16,
          color: ArtbeatColors.accentGold,
        ),
      ),
    );
  }

  Widget _buildConnectButton(BuildContext context, ArtistProfileModel artist) {
    final isLoading = _loadingStates[artist.userId] ?? false;

    return GestureDetector(
      onTap: isLoading ? null : () => _handleConnectAction(context, artist),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: artist.isFollowing
              ? ArtbeatColors.primaryPurple.withValues(alpha: 0.2)
              : ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: artist.isFollowing
                ? ArtbeatColors.primaryPurple
                : ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
            width: artist.isFollowing ? 1.5 : 1,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ArtbeatColors.primaryPurple,
                  ),
                ),
              )
            : Icon(
                artist.isFollowing ? Icons.link : Icons.link_outlined,
                size: 14,
                color: ArtbeatColors.primaryPurple,
              ),
      ),
    );
  }

  Widget _buildDiscussButton(BuildContext context, ArtistProfileModel artist) {
    return GestureDetector(
      onTap: () => _handleDiscussAction(context, artist),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: ArtbeatColors.primaryGreen.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.chat_bubble_outline,
          size: 14,
          color: ArtbeatColors.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildAmplifyButton(BuildContext context, ArtistProfileModel artist) {
    return GestureDetector(
      onTap: () => _handleAmplifyAction(context, artist),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ArtbeatColors.accentOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: ArtbeatColors.accentOrange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.share_outlined,
          size: 14,
          color: ArtbeatColors.accentOrange,
        ),
      ),
    );
  }

  void _handleAppreciateAction(
    BuildContext context,
    ArtistProfileModel artist,
  ) async {
    if (_loadingStates[artist.userId] == true) return;

    setState(() {
      _loadingStates[artist.userId] = true;
    });

    try {
      // Toggle appreciate state using the universal engagement service
      final engagementService = UniversalEngagementService();
      final newState = await engagementService.toggleEngagement(
        contentId: artist.userId,
        contentType: 'profile',
        engagementType: EngagementType.appreciate,
      );

      // Update local state
      if (mounted) {
        setState(() {
          _appreciateStates[artist.userId] = newState;
        });
      }

      // Show feedback
      if (mounted) {
        final message = newState
            ? 'Appreciated ${artist.displayName}'
            : 'Removed appreciation for ${artist.displayName}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to appreciate: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingStates[artist.userId] = false;
        });
      }
    }
  }

  void _handleGiftAction(BuildContext context, ArtistProfileModel artist) {
    if (_loadingStates[artist.userId] == true) return;

    // Navigate to gift purchasing flow using direct navigation
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => GiftPurchaseScreen(
          recipientId: artist.userId,
          recipientName: artist.displayName,
        ),
      ),
    );
  }

  void _handleConnectAction(
    BuildContext context,
    ArtistProfileModel artist,
  ) async {
    if (_loadingStates[artist.userId] == true) return;

    setState(() {
      _loadingStates[artist.userId] = true;
    });

    try {
      // Toggle follow/connect status using the universal engagement service
      final engagementService = UniversalEngagementService();
      await engagementService.toggleEngagement(
        contentId: artist.userId,
        contentType: 'profile',
        engagementType: EngagementType.connect,
      );

      // Show feedback
      if (mounted) {
        final message = artist.isFollowing
            ? 'Disconnected from ${artist.displayName}'
            : 'Connected with ${artist.displayName}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingStates[artist.userId] = false;
        });
      }
    }
  }

  void _handleDiscussAction(BuildContext context, ArtistProfileModel artist) {
    // Navigate to the artist's specific community feed
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ArtistCommunityFeedScreen(artist: artist),
      ),
    );
  }

  void _handleAmplifyAction(
    BuildContext context,
    ArtistProfileModel artist,
  ) async {
    try {
      // Handle sharing functionality using engagement service
      final engagementService = UniversalEngagementService();
      await engagementService.toggleEngagement(
        contentId: artist.userId,
        contentType: 'profile',
        engagementType: EngagementType.amplify,
      );

      // Create share content
      final shareText =
          '🎨 Check out ${artist.displayName} on ARTbeat! '
          '${artist.bio?.isNotEmpty == true ? '\n\n"${artist.bio}"' : ''}'
          '\n\nDownload ARTbeat to discover amazing local artists!';

      // Share using share_plus package
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Discover ${artist.displayName} on ARTbeat',
        ),
      );

      // Show sharing success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shared ${artist.displayName}\'s profile'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

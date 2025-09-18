import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart'
    show CapturesListScreen, CaptureModel;

class DashboardCapturesSection extends StatelessWidget {
  final DashboardViewModel viewModel;

  const DashboardCapturesSection({Key? key, required this.viewModel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
            ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context),
            const SizedBox(height: 16),
            _buildCapturesContent(context),
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
            gradient: const LinearGradient(
              colors: [ArtbeatColors.primaryGreen, ArtbeatColors.primaryPurple],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Local Captures',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Discover amazing street art, murals, and sculptures found by our community',
                style: TextStyle(
                  fontSize: 14,
                  color: ArtbeatColors.textSecondary,
                  height: 1.3,
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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const CapturesListScreen(),
                ),
              ),
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
                      'Explore All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
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

  Widget _buildCapturesContent(BuildContext context) {
    if (viewModel.isLoadingLocalCaptures) {
      return _buildLoadingState();
    }

    if (viewModel.localCapturesError != null) {
      return _buildErrorState();
    }

    final captures = viewModel.localCaptures;

    if (captures.isEmpty) {
      return _buildEmptyState(context);
    }

    return SizedBox(
      height: 280, // Increased height for better showcase
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: captures.length,
        itemBuilder: (context, index) {
          final capture = captures[index];
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 16, // Increased spacing
              right: index == captures.length - 1 ? 0 : 0,
            ),
            child: _buildEnhancedCaptureCard(context, capture, index),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 16),
            child: _buildEnhancedSkeletonCard(),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 280,
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
              'Unable to load captures',
              style: TextStyle(color: ArtbeatColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: ArtbeatColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_camera_outlined,
              color: ArtbeatColors.textSecondary,
              size: 44,
            ),
            const SizedBox(height: 12),
            const Text(
              'No captures yet',
              style: TextStyle(
                color: ArtbeatColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Be the first to discover and share amazing local art!',
              style: TextStyle(
                color: ArtbeatColors.textSecondary,
                fontSize: 14,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    ArtbeatColors.primaryPurple,
                    ArtbeatColors.primaryGreen,
                  ],
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
                  onTap: () => Navigator.pushNamed(context, '/capture/create'),
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Add Capture',
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
        ),
      ),
    );
  }

  /// Enhanced capture card with modern design and better engagement
  Widget _buildEnhancedCaptureCard(
    BuildContext context,
    CaptureModel capture,
    int index,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return TweenAnimationBuilder<double>(
          duration: Duration(
            milliseconds: 300 + (index * 100),
          ), // Staggered animation
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: SizedBox(
                  width: 200, // Wider cards for better showcase
                  child: Hero(
                    tag: 'capture_${capture.id}',
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(20),
                      shadowColor: ArtbeatColors.primaryPurple.withValues(
                        alpha: 0.3,
                      ),
                      child: InkWell(
                        onTap: () => _showCaptureDetails(context, capture),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.white, Colors.grey.shade50],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Enhanced image section with overlay
                              Expanded(
                                flex: 7, // More space for the image
                                child: Stack(
                                  children: [
                                    // Main image
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color:
                                              ArtbeatColors.backgroundSecondary,
                                          image:
                                              ImageUrlValidator.isValidImageUrl(
                                                capture.imageUrl,
                                              )
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                    capture.imageUrl,
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child:
                                            !ImageUrlValidator.isValidImageUrl(
                                              capture.imageUrl,
                                            )
                                            ? const Icon(
                                                Icons.palette,
                                                color:
                                                    ArtbeatColors.primaryPurple,
                                                size: 48,
                                              )
                                            : null,
                                      ),
                                    ),

                                    // Gradient overlay for better text readability
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(
                                                alpha: 0.7,
                                              ),
                                            ],
                                            stops: const [0.6, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Floating engagement actions
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Column(
                                        children: [
                                          _buildLikeButton(context, capture),
                                          const SizedBox(height: 8),
                                          _buildFloatingActionButton(
                                            icon: Icons.share_outlined,
                                            color: ArtbeatColors.primaryGreen,
                                            onTap: () =>
                                                _handleShare(context, capture),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Location badge
                                    if (capture.locationName?.isNotEmpty ==
                                        true)
                                      Positioned(
                                        bottom: 12,
                                        left: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.6,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  capture.locationName ??
                                                      'Unknown Location',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Content section
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title with better typography
                                      Text(
                                        capture.title?.isNotEmpty == true
                                            ? capture.title!
                                            : 'Untitled Artwork',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: ArtbeatColors.textPrimary,
                                          height: 1.1,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      const SizedBox(height: 4),

                                      // Call to action
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              ArtbeatColors.primaryPurple,
                                              ArtbeatColors.primaryGreen,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.explore,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Discover',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Enhanced skeleton card for loading state
  Widget _buildEnhancedSkeletonCard() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image skeleton
          Expanded(
            flex: 7,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: ArtbeatColors.backgroundSecondary.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ArtbeatColors.primaryGreen,
                  ),
                ),
              ),
            ),
          ),

          // Content skeleton
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title skeleton
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: ArtbeatColors.backgroundSecondary.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: ArtbeatColors.backgroundSecondary.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  const Spacer(),

                  // Button skeleton
                  Container(
                    width: double.infinity,
                    height: 32,
                    decoration: BoxDecoration(
                      color: ArtbeatColors.backgroundSecondary.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Floating action button for engagement actions
  Widget _buildFloatingActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  /// Like button that shows filled/unfilled heart based on like status
  Widget _buildLikeButton(BuildContext context, CaptureModel capture) {
    return _LikeButtonWidget(
      viewModel: viewModel,
      capture: capture,
      onLike: () => _handleLike(context, capture),
    );
  }

  /// Handle like action with haptic feedback and proper state management
  Future<void> _handleLike(BuildContext context, CaptureModel capture) async {
    try {
      // Provide immediate haptic feedback
      await HapticFeedback.lightImpact();

      // Toggle the like using the viewModel
      final isLiked = await viewModel.toggleCaptureLike(capture.id);

      // Show appropriate feedback message
      final message = isLiked
          ? 'Added "${capture.title ?? 'artwork'}" to your liked captures!'
          : 'Removed "${capture.title ?? 'artwork'}" from your liked captures';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isLiked
              ? ArtbeatColors.primaryPurple
              : ArtbeatColors.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // The UI will automatically update because the viewModel notifies listeners
      // and the capture cards will rebuild with the new like state
    } catch (e) {
      // Handle errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update like: ${e.toString()}'),
          backgroundColor: ArtbeatColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  /// Handle share action
  void _handleShare(BuildContext context, CaptureModel capture) {
    // TODO: Implement actual share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "${capture.title ?? 'artwork'}"...'),
        backgroundColor: ArtbeatColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showCaptureDetails(BuildContext context, CaptureModel capture) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
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

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      if (ImageUrlValidator.isValidImageUrl(capture.imageUrl))
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            capture.imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: ArtbeatColors.backgroundSecondary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.broken_image,
                                  color: ArtbeatColors.textSecondary,
                                  size: 48,
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        capture.title ?? 'Untitled Capture',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Location
                      if (capture.locationName?.isNotEmpty == true)
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
                                capture.locationName ?? 'Unknown Location',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: ArtbeatColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Description
                      if (capture.description?.isNotEmpty == true)
                        Text(
                          capture.description ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: ArtbeatColors.textPrimary,
                            height: 1.5,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              '/art-walk/create',
                              arguments: {'captureId': capture.id},
                            );
                          },
                          icon: const Icon(Icons.directions_walk),
                          label: const Text('Create Art Walk'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ArtbeatColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stateful widget for the like button that properly handles state changes
class _LikeButtonWidget extends StatefulWidget {
  final DashboardViewModel viewModel;
  final CaptureModel capture;
  final VoidCallback onLike;

  const _LikeButtonWidget({
    required this.viewModel,
    required this.capture,
    required this.onLike,
  });

  @override
  State<_LikeButtonWidget> createState() => _LikeButtonWidgetState();
}

class _LikeButtonWidgetState extends State<_LikeButtonWidget> {
  bool? _isLiked;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLikeStatus();
  }

  @override
  void didUpdateWidget(_LikeButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload like status if the capture changed
    if (oldWidget.capture.id != widget.capture.id) {
      _loadLikeStatus();
    }
  }

  Future<void> _loadLikeStatus() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final isLiked = await widget.viewModel.hasUserLikedCapture(
        widget.capture.id,
      );
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = _isLiked ?? false;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading
              ? null
              : () async {
                  widget.onLike();
                  // Reload the like status after the action
                  await Future<void>.delayed(const Duration(milliseconds: 100));
                  _loadLikeStatus();
                },
          borderRadius: BorderRadius.circular(18),
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: _isLoading
                ? ArtbeatColors.textSecondary
                : ArtbeatColors.error,
          ),
        ),
      ),
    );
  }
}

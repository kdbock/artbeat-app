import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show OptimizedImage, MainLayout, ImageUrlValidator;

import '../widgets/art_walk_drawer.dart';
import '../theme/art_walk_design_system.dart';

/// Screen to display user's captured art
class MyCapturesScreen extends StatefulWidget {
  final CaptureModel? initialCapture;

  const MyCapturesScreen({super.key, this.initialCapture});

  @override
  State<MyCapturesScreen> createState() => _MyCapturesScreenState();
}

class _MyCapturesScreenState extends State<MyCapturesScreen>
    with AutomaticKeepAliveClientMixin {
  final CaptureService _captureService = CaptureService();
  List<CaptureModel> _captures = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCaptures();
  }

  Future<void> _loadCaptures() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.uid == null) {
        setState(() {
          _captures = [];
          _isLoading = false;
        });
        return;
      }

      final captures = await _captureService.getCapturesForUser(user!.uid);
      // debugPrint('📸 Loaded ${captures.length} captures for user in my_captures_screen');
      if (mounted) {
        setState(() {
          _captures = captures;
          _isLoading = false;
        });
      }
    } catch (e) {
      // debugPrint('Error loading captures: $e');
      if (mounted) {
        setState(() {
          _captures = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load captures. Please try again.'),
            backgroundColor: ArtWalkDesignSystem.accentOrange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadCaptures,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return MainLayout(
      currentIndex: 2, // Capture tab index
      drawer: const ArtWalkDrawer(),
      child: Scaffold(
        appBar: ArtWalkDesignSystem.buildAppBar(
          title: 'My Captures',
          showBackButton: true,
        ),
        body: ArtWalkDesignSystem.buildScreenContainer(
          child: _isLoading
              ? ArtWalkScreenTemplate.buildLoadingState(
                  message: 'Loading your captures...',
                )
              : _captures.isEmpty
              ? ArtWalkScreenTemplate.buildEmptyState(
                  title: 'No Captures Yet',
                  subtitle: 'Start capturing art to see your collection here.',
                  icon: Icons.camera_alt,
                  actionText: 'Capture Art',
                  onAction: () => Navigator.pushNamed(context, '/capture'),
                )
              : _buildCapturesGrid(),
        ),
        floatingActionButton: ArtWalkDesignSystem.buildFloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/capture'),
          icon: Icons.camera_alt,
          tooltip: 'Capture Art',
        ),
      ),
    );
  }

  Widget _buildCapturesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: ArtWalkDesignSystem.paddingM,
        mainAxisSpacing: ArtWalkDesignSystem.paddingM,
        childAspectRatio: 0.8,
      ),
      itemCount: _captures.length,
      itemBuilder: (context, index) {
        final capture = _captures[index];
        return CaptureCard(
          capture: capture,
          index: index,
          onTap: () => _showCaptureDetails(capture),
        );
      },
    );
  }

  void _showCaptureDetails(CaptureModel capture) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: ArtWalkDesignSystem.glassDecoration(),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(
                      bottom: ArtWalkDesignSystem.paddingL,
                    ),
                    decoration: BoxDecoration(
                      color: ArtWalkDesignSystem.textSecondary.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (ImageUrlValidator.isValidImageUrl(capture.imageUrl))
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.only(
                      bottom: ArtWalkDesignSystem.paddingM,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        ArtWalkDesignSystem.radiusL,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(capture.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Text(
                  capture.title ?? 'Untitled Capture',
                  style: ArtWalkDesignSystem.cardTitleStyle,
                ),
                const SizedBox(height: ArtWalkDesignSystem.paddingS),
                if (capture.artistName?.isNotEmpty == true) ...[
                  Text(
                    'Artist: ${capture.artistName}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: ArtWalkDesignSystem.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: ArtWalkDesignSystem.paddingS),
                ],
                if (capture.description?.isNotEmpty == true) ...[
                  Text(
                    capture.description!,
                    style: ArtWalkDesignSystem.cardSubtitleStyle,
                  ),
                  const SizedBox(height: ArtWalkDesignSystem.paddingM),
                ],
                if (capture.locationName?.isNotEmpty == true)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: ArtWalkDesignSystem.primaryTeal,
                        size: 20,
                      ),
                      const SizedBox(width: ArtWalkDesignSystem.paddingS),
                      Expanded(
                        child: Text(
                          capture.locationName!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: ArtWalkDesignSystem.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Optimized capture card widget with proper disposal management
class CaptureCard extends StatefulWidget {
  final CaptureModel capture;
  final int index;
  final VoidCallback onTap;

  const CaptureCard({
    super.key,
    required this.capture,
    required this.index,
    required this.onTap,
  });

  @override
  State<CaptureCard> createState() => _CaptureCardState();
}

class _CaptureCardState extends State<CaptureCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Container(
      decoration: ArtWalkDesignSystem.glassDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(ArtWalkDesignSystem.radiusXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: ArtWalkDesignSystem.cardBackground,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child:
                      ImageUrlValidator.isValidImageUrl(widget.capture.imageUrl)
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: RepaintBoundary(
                            child: OptimizedImage(
                              imageUrl:
                                  widget.capture.thumbnailUrl ??
                                  widget.capture.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              isThumbnail: true,
                              placeholder: Container(
                                color: ArtWalkDesignSystem.cardBackground,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        ArtWalkDesignSystem.primaryTeal,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: Container(
                                color: ArtWalkDesignSystem.cardBackground,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: ArtWalkDesignSystem.textSecondary,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            color: ArtWalkDesignSystem.cardBackground,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            color: ArtWalkDesignSystem.textSecondary,
                            size: 40,
                          ),
                        ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.capture.title ?? 'Untitled',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ArtWalkDesignSystem.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.capture.artistName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'by ${widget.capture.artistName}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ArtWalkDesignSystem.textSecondary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Flexible(
                        child: Row(
                          children: [
                            Icon(
                              widget.capture.isPublic
                                  ? Icons.public
                                  : Icons.lock,
                              size: 14,
                              color: widget.capture.isPublic
                                  ? ArtWalkDesignSystem.primaryTeal
                                  : ArtWalkDesignSystem.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.capture.isPublic ? 'Public' : 'Private',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: widget.capture.isPublic
                                        ? ArtWalkDesignSystem.primaryTeal
                                        : ArtWalkDesignSystem.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            if (!widget.capture.isProcessed) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.hourglass_empty,
                                size: 14,
                                color: ArtWalkDesignSystem.accentOrange,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  'Processing',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: ArtWalkDesignSystem.accentOrange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
    );
  }
}

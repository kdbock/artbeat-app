import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show ArtbeatColors, EnhancedUniversalHeader, OptimizedImage, MainLayout;
import 'package:artbeat_core/src/utils/color_extensions.dart';

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
      debugPrint(
        '📸 Loaded ${captures.length} captures for user in my_captures_screen',
      );
      if (mounted) {
        setState(() {
          _captures = captures;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading captures: $e');
      if (mounted) {
        setState(() {
          _captures = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load captures. Please try again.'),
            backgroundColor: ArtbeatColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: ArtbeatColors.white,
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
      currentIndex: 2, // Set to 2 for Captures tab
      child: Builder(
        builder: (context) {
          return Column(
            children: [
              EnhancedUniversalHeader(
                title: 'My Captures',
                backgroundColor: Colors.transparent,
                elevation: 0,
                showLogo: false,
                showDeveloperTools: true,
                onMenuPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                      });
                      _loadCaptures();
                    },
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ArtbeatColors.primaryPurple.withAlphaValue(0.05),
                        ArtbeatColors.white,
                        ArtbeatColors.primaryGreen.withAlphaValue(0.05),
                      ],
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ArtbeatColors.primaryPurple,
                            ),
                          ),
                        )
                      : _captures.isEmpty
                          ? _buildEmptyState()
                          : _buildCapturesList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: ArtbeatColors.primaryPurple.withAlphaValue(0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'No Captures Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ArtbeatColors.primaryPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start capturing art around you to see them here!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ArtbeatColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/capture/camera').then((_) {
                  // Refresh captures when returning from camera
                  _loadCaptures();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.primaryPurple,
                foregroundColor: ArtbeatColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture Art'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturesList() {
    return RefreshIndicator(
      onRefresh: _loadCaptures,
      color: ArtbeatColors.primaryPurple,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: _captures.length,
        // Add cache extent control to prevent excessive preloading
        cacheExtent: 400, // Limit cache to reasonable size
        itemBuilder: (context, index) {
          final capture = _captures[index];
          return CaptureCard(
            key: ValueKey('capture_${capture.id}'),
            capture: capture,
            index: index,
            onTap: () => _showCaptureDetail(capture),
          );
        },
      ),
    );
  }

  void _showCaptureDetail(CaptureModel capture) {
    // Navigate to capture detail screen instead of modal
    Navigator.of(
      context,
    ).pushNamed('/capture/detail', arguments: capture.id).then((_) {
      // Refresh captures when returning from detail
      _loadCaptures();
    });
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

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: ArtbeatColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: widget.capture.imageUrl.isNotEmpty
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
                              color: ArtbeatColors.background,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      ArtbeatColors.primaryPurple,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: Container(
                              color: ArtbeatColors.background,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: ArtbeatColors.textSecondary,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          color: ArtbeatColors.background,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          color: ArtbeatColors.textSecondary,
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
                        color: ArtbeatColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.capture.artistName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'by ${widget.capture.artistName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ArtbeatColors.textSecondary,
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
                            widget.capture.isPublic ? Icons.public : Icons.lock,
                            size: 14,
                            color: widget.capture.isPublic
                                ? ArtbeatColors.primaryGreen
                                : ArtbeatColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.capture.isPublic ? 'Public' : 'Private',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: widget.capture.isPublic
                                      ? ArtbeatColors.primaryGreen
                                      : ArtbeatColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          if (!widget.capture.isProcessed) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.hourglass_empty,
                              size: 14,
                              color: ArtbeatColors.warning,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                'Processing',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: ArtbeatColors.warning,
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
    );
  }
}

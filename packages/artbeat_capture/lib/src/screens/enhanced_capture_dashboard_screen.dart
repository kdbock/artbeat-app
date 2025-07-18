import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';

/// Enhanced Capture Dashboard Screen
///
/// This new capture dashboard combines the best elements from:
/// - Original Capture Dashboard (safety focus)
/// - Fluid Dashboard (smooth UX)
/// - Art Walk Dashboard (personalization & data integration)
///
/// Features:
/// - Personalized welcome message
/// - Recent captures showcase
/// - Capture stats and achievements
/// - Safety guidelines integration
/// - Community contribution highlights
/// - Quick action buttons
/// - Smooth scrolling experience
class EnhancedCaptureDashboardScreen extends StatefulWidget {
  const EnhancedCaptureDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedCaptureDashboardScreen> createState() =>
      _EnhancedCaptureDashboardScreenState();
}

class _EnhancedCaptureDashboardScreenState
    extends State<EnhancedCaptureDashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;

  // Data
  List<CaptureModel> _recentCaptures = [];
  List<CaptureModel> _communityCaptures = [];
  UserModel? _currentUser;
  int _totalUserCaptures = 0;
  int _totalCommunityViews = 0;

  // Services
  final CaptureService _captureService = CaptureService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load user data
      final user = await _userService.getCurrentUserModel();

      // Load recent captures
      List<CaptureModel> recentCaptures = [];
      List<CaptureModel> communityCaptures = [];
      int totalUserCaptures = 0;
      int totalCommunityViews = 0;

      if (user != null) {
        // Get user's recent captures
        recentCaptures = await _captureService.getUserCaptures(
          userId: user.id,
          limit: 6,
        );

        // Get user's total capture count
        totalUserCaptures = await _captureService.getUserCaptureCount(user.id);

        // Get total community views of user's captures
        totalCommunityViews = await _captureService.getUserCaptureViews(
          user.id,
        );
      }

      // Get some community captures for inspiration
      communityCaptures = await _captureService.getAllCaptures(limit: 8);

      if (mounted) {
        setState(() {
          _currentUser = user;
          _recentCaptures = recentCaptures;
          _communityCaptures = communityCaptures;
          _totalUserCaptures = totalUserCaptures;
          _totalCommunityViews = totalCommunityViews;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading capture dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _openTermsAndConditionsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const TermsAndConditionsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
              Colors.white,
              ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Header Section
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome message
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      ArtbeatColors.primaryGreen.withValues(
                                        alpha: 0.1,
                                      ),
                                      ArtbeatColors.primaryPurple.withValues(
                                        alpha: 0.1,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: ArtbeatColors.primaryGreen
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.camera_alt,
                                      size: 48,
                                      color: ArtbeatColors.primaryGreen,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Ready to Capture Art?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: ArtbeatColors.textPrimary,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Discover and document public art to help build our community map',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: ArtbeatColors.textSecondary,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Main action button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _openTermsAndConditionsScreen,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ArtbeatColors.primaryGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(
                                    Icons.assignment_turned_in,
                                    size: 24,
                                  ),
                                  label: const Text(
                                    'Start Capture',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Stats section
                              if (_currentUser != null) ...[
                                Text(
                                  'Your Impact',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: ArtbeatColors.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        title: 'Captures',
                                        value: _totalUserCaptures.toString(),
                                        icon: Icons.camera_alt,
                                        color: ArtbeatColors.primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildStatCard(
                                        title: 'Community Views',
                                        value: _totalCommunityViews.toString(),
                                        icon: Icons.visibility,
                                        color: ArtbeatColors.primaryPurple,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                              ],

                              // Recent captures section
                              if (_recentCaptures.isNotEmpty) ...[
                                Text(
                                  'Your Recent Captures',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: ArtbeatColors.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Recent captures grid
                      if (_recentCaptures.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final capture = _recentCaptures[index];
                              return _buildCaptureCard(capture);
                            }, childCount: _recentCaptures.length),
                          ),
                        ),

                      // Community inspiration section
                      if (_communityCaptures.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                Text(
                                  'Community Inspiration',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: ArtbeatColors.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'See what others are discovering in your area',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: ArtbeatColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              itemCount: _communityCaptures.length,
                              itemBuilder: (context, index) {
                                final capture = _communityCaptures[index];
                                return Container(
                                  width: 160,
                                  margin: const EdgeInsets.only(right: 16),
                                  child: _buildCommunityCard(capture),
                                );
                              },
                            ),
                          ),
                        ),
                      ],

                      // Bottom padding
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureCard(CaptureModel capture) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.network(
              capture.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),

            // Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (capture.title?.isNotEmpty == true)
                    Text(
                      capture.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(capture.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      capture.status.value.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildCommunityCard(CaptureModel capture) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.network(
              capture.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),

            // Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                capture.title ?? 'Community Capture',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(CaptureStatus status) {
    switch (status) {
      case CaptureStatus.approved:
        return ArtbeatColors.primaryGreen;
      case CaptureStatus.pending:
        return ArtbeatColors.accentYellow;
      case CaptureStatus.rejected:
        return Colors.red;
    }
  }
}

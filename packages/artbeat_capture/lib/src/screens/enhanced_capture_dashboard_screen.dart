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
  bool _hasAcceptedDisclaimer = false;
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

  void _showDisclaimerDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Safety & Legal Notice'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Before you capture art, please read and agree to the following:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Safety Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.security,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Safety Guidelines',
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Always be aware of your surroundings\n'
                        '• Do not trespass on private property\n'
                        '• Stay on public sidewalks and paths\n'
                        '• Be respectful of other people and property\n'
                        '• Use caution when crossing streets or navigating traffic',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Legal Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.gavel,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Legal Guidelines',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Only capture art in public spaces\n'
                        '• No nudity or inappropriate content\n'
                        '• No derogatory or offensive images\n'
                        '• Respect artist copyrights and permissions\n'
                        '• All captures are subject to moderation',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Art Walk Integration
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ArtbeatColors.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.map,
                            color: ArtbeatColors.primaryGreen,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Art Walk Process',
                            style: TextStyle(
                              color: ArtbeatColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'When you capture art, you\'re contributing to the ARTbeat community! '
                        'Your captures help build Art Walks - curated routes that guide other users to discover '
                        'public art in their area. Each capture is geotagged and can become part of a walking tour '
                        'for other art enthusiasts.',
                        style: TextStyle(
                          color: ArtbeatColors.primaryGreen,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasAcceptedDisclaimer = true;
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('I Agree & Understand'),
            ),
          ],
        );
      },
    );
  }

  void _openCaptureScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const CaptureScreen()),
    );
  }

  void _openDrawer(BuildContext context) {
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.hasDrawer) {
      scaffoldState.openDrawer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigation drawer not available'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
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
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: ArtbeatColors.primaryPurple,
                      size: 24,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search & Discover',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Find artists, artwork, and inspiration',
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

              // Menu items
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildSearchTile(
                      icon: Icons.person_search,
                      title: 'Find Artists',
                      subtitle: 'Discover local and featured artists',
                      color: ArtbeatColors.primaryPurple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artist/search');
                      },
                    ),
                    _buildSearchTile(
                      icon: Icons.camera_alt,
                      title: 'Search Captures',
                      subtitle: 'Browse community art captures',
                      color: ArtbeatColors.primaryGreen,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/captures/search');
                      },
                    ),
                    _buildSearchTile(
                      icon: Icons.palette,
                      title: 'Browse Artwork',
                      subtitle: 'Explore art collections',
                      color: ArtbeatColors.secondaryTeal,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artwork/browse');
                      },
                    ),
                    _buildSearchTile(
                      icon: Icons.location_on,
                      title: 'Local Art',
                      subtitle: 'Find art near you',
                      color: ArtbeatColors.accentYellow,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/local');
                      },
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

  void _showProfileMenu(BuildContext context) {
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
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_circle,
                      color: ArtbeatColors.primaryPurple,
                      size: 24,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile & Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Manage your profile and preferences',
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

              // Menu items
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildProfileTile(
                      icon: Icons.person,
                      title: 'My Profile',
                      subtitle: 'View and edit your profile',
                      color: ArtbeatColors.primaryPurple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                    _buildProfileTile(
                      icon: Icons.collections,
                      title: 'My Captures',
                      subtitle: 'View your art captures',
                      color: ArtbeatColors.primaryGreen,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/captures');
                      },
                    ),
                    _buildProfileTile(
                      icon: Icons.settings,
                      title: 'Settings',
                      subtitle: 'App preferences and settings',
                      color: ArtbeatColors.secondaryTeal,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                    _buildProfileTile(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'Get help with the app',
                      color: ArtbeatColors.accentYellow,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/help');
                      },
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

  Widget _buildSearchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 2, // Capture is index 2
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 4),
          child: ArtbeatGradientBackground(
            addShadow: true,
            child: EnhancedUniversalHeader(
              title: 'Capture Art',
              showLogo: false,
              showSearch: true,
              showDeveloperTools: true,
              onSearchPressed: () => _showSearchModal(context),
              onProfilePressed: () => _showProfileMenu(context),
              onMenuPressed: () => _openDrawer(context),
              backgroundColor: Colors.transparent,
              foregroundColor: ArtbeatColors.textPrimary,
              elevation: 0,
            ),
          ),
        ),
        drawer: const ArtbeatDrawer(),
        body: Container(
          decoration: _buildArtisticBackground(),
          child: SafeArea(
            child: _isLoading ? _buildLoadingState() : _buildContent(),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildArtisticBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ArtbeatColors.primaryPurple.withValues(alpha: 0.03),
          Colors.white,
          ArtbeatColors.primaryGreen.withValues(alpha: 0.03),
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(ArtbeatColors.primaryPurple),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: ArtbeatColors.primaryPurple,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Welcome Section
          SliverToBoxAdapter(child: _buildWelcomeSection()),

          // Stats Section
          SliverToBoxAdapter(child: _buildStatsSection()),

          // Main Action Section
          SliverToBoxAdapter(child: _buildMainActionSection()),

          // Recent Captures Section
          if (_recentCaptures.isNotEmpty)
            SliverToBoxAdapter(child: _buildRecentCapturesSection()),

          // Community Inspiration Section
          SliverToBoxAdapter(child: _buildCommunityInspirationSection()),

          // How It Works Section
          SliverToBoxAdapter(child: _buildHowItWorksSection()),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final userName = _currentUser?.fullName.isNotEmpty == true
        ? _currentUser!.fullName.split(' ').first
        : _currentUser?.username ?? 'Artist';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ArtbeatColors.primaryPurple,
                      ArtbeatColors.primaryGreen,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: ArtbeatColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: ArtbeatColors.primaryPurple,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Ready to discover and share amazing art?',
            style: TextStyle(
              fontSize: 16,
              color: ArtbeatColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.camera_alt,
              title: 'Your Captures',
              value: _totalUserCaptures.toString(),
              color: ArtbeatColors.primaryPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.visibility,
              title: 'Community Views',
              value: _totalCommunityViews.toString(),
              color: ArtbeatColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
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
            style: const TextStyle(
              fontSize: 12,
              color: ArtbeatColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_hasAcceptedDisclaimer) ...[
            // Disclaimer Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Colors.orange.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Safety & Legal Agreement',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ArtbeatColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Before you can capture art, please read and agree to our safety and legal guidelines. This helps ensure everyone\'s safety and legal compliance.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ArtbeatColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _showDisclaimerDialog,
                      icon: const Icon(Icons.assignment_turned_in),
                      label: const Text('Read & Agree to Guidelines'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Capture Action Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ArtbeatColors.primaryPurple,
                          ArtbeatColors.primaryGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Ready to Capture!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ArtbeatColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You\'ve agreed to our guidelines. Now you can capture public art and contribute to the ARTbeat community.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ArtbeatColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _openCaptureScreen,
                      icon: const Icon(Icons.camera_alt, size: 24),
                      label: const Text(
                        'Start Capturing',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArtbeatColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Secondary Actions
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryActionCard(
                    icon: Icons.collections,
                    title: 'My Captures',
                    subtitle: 'View your gallery',
                    color: ArtbeatColors.primaryPurple,
                    onTap: () => Navigator.pushNamed(context, '/captures'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSecondaryActionCard(
                    icon: Icons.explore,
                    title: 'Art Walk',
                    subtitle: 'Find nearby art',
                    color: ArtbeatColors.primaryGreen,
                    onTap: () =>
                        Navigator.pushNamed(context, '/art-walk/dashboard'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecondaryActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCapturesSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                color: ArtbeatColors.primaryPurple,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Recent Captures',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/captures'),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: ArtbeatColors.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recentCaptures.length,
              itemBuilder: (context, index) {
                final capture = _recentCaptures[index];
                return Container(
                  width: 100,
                  margin: EdgeInsets.only(
                    right: index < _recentCaptures.length - 1 ? 12 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: capture.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(capture.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: capture.imageUrl.isEmpty
                        ? ArtbeatColors.primaryPurple.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: capture.imageUrl.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.camera_alt,
                            color: ArtbeatColors.primaryPurple,
                            size: 24,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityInspirationSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people,
                color: ArtbeatColors.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Community Inspiration',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/community/feed'),
                child: const Text(
                  'See More',
                  style: TextStyle(
                    color: ArtbeatColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _communityCaptures.length,
              itemBuilder: (context, index) {
                final capture = _communityCaptures[index];
                return Container(
                  width: 100,
                  margin: EdgeInsets.only(
                    right: index < _communityCaptures.length - 1 ? 12 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: capture.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(capture.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: capture.imageUrl.isEmpty
                        ? ArtbeatColors.primaryGreen.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: capture.imageUrl.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.camera_alt,
                            color: ArtbeatColors.primaryGreen,
                            size: 24,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ArtbeatColors.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: ArtbeatColors.primaryGreen,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'How It Works',
                style: TextStyle(
                  color: ArtbeatColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '1. Review and agree to safety & legal guidelines\n'
            '2. Use your camera to capture public art\n'
            '3. Add details about the artwork and artist\n'
            '4. Share with the ARTbeat community\n'
            '5. Your captures help build Art Walks for others!',
            style: TextStyle(
              color: ArtbeatColors.primaryGreen,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

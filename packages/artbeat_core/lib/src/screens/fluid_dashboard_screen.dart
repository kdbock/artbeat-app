import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/artbeat_colors.dart';
import 'package:artbeat_ads/artbeat_ads.dart';
import '../widgets/user_experience_card.dart';
import '../widgets/artbeat_drawer.dart';
import '../widgets/enhanced_universal_header.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../widgets/main_layout.dart';
import '../widgets/dashboard/dashboard_hero_section.dart';

/// Fluid Dashboard Screen - Clean and Simple
///
/// This is the main dashboard for the ARTbeat app
class FluidDashboardScreen extends StatefulWidget {
  const FluidDashboardScreen({Key? key}) : super(key: key);

  @override
  State<FluidDashboardScreen> createState() => _FluidDashboardScreenState();
}

class _FluidDashboardScreenState extends State<FluidDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Initialize the dashboard view model after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final viewModel = Provider.of<DashboardViewModel>(
          context,
          listen: false,
        );
        await viewModel.initialize();
      } catch (e, stack) {
        debugPrint('❌ Error initializing dashboard: $e');
        debugPrint('❌ Stack trace: $stack');
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DashboardViewModel>(context);
    return Scaffold(
      key: _scaffoldKey,
      drawer: const ArtbeatDrawer(),
      appBar: EnhancedUniversalHeader(
        showLogo: true,
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        backgroundColor: Colors.white,
        foregroundColor: ArtbeatColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: MainLayout(
          currentIndex: 0,
          child: _buildFluidContent(viewModel),
        ),
      ),
    );
  }

  Widget _buildFluidContent(DashboardViewModel viewModel) {
    // Show loading indicator while initializing
    if (viewModel.isInitializing) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            ArtbeatColors.primaryPurple,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.refresh(),
      color: ArtbeatColors.primaryPurple,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Hero Map Section
          SliverToBoxAdapter(
            child: DashboardHeroSection(
              viewModel: viewModel,
              onProfileMenuTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              onFindArtTap: () => _navigateToArtWalk(context),
            ),
          ),

          // User experience card (for logged in users)
          if (viewModel.isAuthenticated && viewModel.currentUser != null)
            SliverToBoxAdapter(child: _buildUserExperienceSection(viewModel)),

          // App explanation section (for new/anonymous users)
          if (!viewModel.isAuthenticated)
            SliverToBoxAdapter(child: _buildAppExplanationSection()),

          // Ad placement
          if (viewModel.isAuthenticated)
            const SliverToBoxAdapter(
              child: BannerAdWidget(location: AdLocation.dashboard),
            ),

          // Navigation sections
          SliverToBoxAdapter(child: _buildNavigationSection()),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildUserExperienceSection(DashboardViewModel viewModel) {
    final user = viewModel.currentUser!;
    return Container(
      margin: const EdgeInsets.all(16),
      child: UserExperienceCard(user: user),
    );
  }

  Widget _buildAppExplanationSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.palette, color: ArtbeatColors.primaryPurple, size: 28),
              SizedBox(width: 12),
              Text(
                'Welcome to ARTbeat',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Discover public art, connect with local artists, and explore your creative community. Join thousands of art enthusiasts already using ARTbeat.',
            style: TextStyle(
              fontSize: 16,
              color: ArtbeatColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/auth/register'),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Join Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArtbeatColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/auth/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ArtbeatColors.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildNavigationCard(
                icon: Icons.camera_alt,
                title: 'Art Captures',
                subtitle: 'Discover public art',
                color: ArtbeatColors.primaryGreen,
                onTap: () => Navigator.pushNamed(context, '/captures'),
              ),
              _buildNavigationCard(
                icon: Icons.people,
                title: 'Artists',
                subtitle: 'Connect with creators',
                color: ArtbeatColors.primaryPurple,
                onTap: () => Navigator.pushNamed(context, '/artists'),
              ),
              _buildNavigationCard(
                icon: Icons.palette,
                title: 'Artwork',
                subtitle: 'Browse collections',
                color: ArtbeatColors.warning,
                onTap: () => Navigator.pushNamed(context, '/artwork'),
              ),
              _buildNavigationCard(
                icon: Icons.forum,
                title: 'Community',
                subtitle: 'Join discussions',
                color: ArtbeatColors.info,
                onTap: () => Navigator.pushNamed(context, '/community'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ArtbeatColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: ArtbeatColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToArtWalk(BuildContext context) {
    // Navigate to art walk dashboard
    Navigator.pushNamed(context, '/art-walk/dashboard');
  }
}

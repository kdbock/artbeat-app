import 'package:flutter/material.dart';
import 'package:artbeat_artist/artbeat_artist.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

/// Artist Dashboard Screen - Main screen for artist features
class ArtistDashboardScreen extends StatefulWidget {
  const ArtistDashboardScreen({super.key});

  @override
  State<ArtistDashboardScreen> createState() => _ArtistDashboardScreenState();
}

class _ArtistDashboardScreenState extends State<ArtistDashboardScreen>
    with SingleTickerProviderStateMixin {
  final SubscriptionService _subscriptionService = SubscriptionService();

  // State variables
  bool _isLoading = true;
  core.ArtistProfileModel? _artistProfile;
  SubscriptionModel? _subscription;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadArtistData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadArtistData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load artist profile
      final core.ArtistProfileModel? artistProfile =
          await _subscriptionService.getCurrentArtistProfile();

      // Load subscription
      final subscription = await _subscriptionService.getUserSubscription();

      if (mounted) {
        setState(() {
          _artistProfile = artistProfile;
          _subscription = subscription;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading artist data: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Navigate to create artist profile if none exists
  void _navigateToCreateProfile() {
    Navigator.pushNamed(context, '/artist/create-profile')
        .then((_) => _loadArtistData());
  }

  // Get subscription tier display name
  String get _tierName {
    if (_subscription == null) return 'Free Plan';

    switch (_subscription!.tier) {
      case core.SubscriptionTier.basic:
        return 'Artist Basic Plan (Free)';
      case core.SubscriptionTier.standard:
        return 'Artist Pro Plan (\$9.99/month)';
      case core.SubscriptionTier.premium:
        return 'Gallery Plan (\$49.99/month)';
      case core.SubscriptionTier.none:
        return 'Free Plan';
    }
  }

  // Check if this is a gallery account
  bool get _isGallery =>
      _artistProfile != null && _artistProfile!.userType == UserType.gallery;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Artist Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If profile doesn't exist yet, show setup screen
    if (_artistProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Artist Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.palette, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text(
                'Set up your artist profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Share your artwork with the WordNerd community by creating an artist profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create Artist Profile'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                ),
                onPressed: _navigateToCreateProfile,
              ),
            ],
          ),
        ),
      );
    }

    // Artist dashboard with profile
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/artist/settings')
                  .then((_) => _loadArtistData());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: _isGallery ? 'Gallery Overview' : 'Overview'),
            const Tab(text: 'Artwork'),
            const Tab(text: 'Analytics'),
            const Tab(text: 'Events'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Subscription banner
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context)
                .colorScheme
                .primary
                .withAlpha(25), // Changed from withOpacity(0.1)
            child: Row(
              children: [
                Icon(
                  _subscription?.tier == core.SubscriptionTier.basic
                      ? Icons.star_border
                      : Icons.star,
                  color: _subscription?.tier == core.SubscriptionTier.premium
                      ? Colors.amber
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _tierName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/artist/subscription')
                        .then((_) => _loadArtistData());
                  },
                  child: Text(
                    _subscription?.tier == core.SubscriptionTier.basic
                        ? 'Upgrade'
                        : 'Manage',
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildArtworkTab(),
                _buildAnalyticsTab(),
                _buildEventsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/artist/upload-artwork')
              .then((_) => _loadArtistData());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Dashboard overview tab
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artist profile summary
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image
              CircleAvatar(
                radius: 40,
                backgroundImage: _artistProfile?.profileImageUrl != null
                    ? NetworkImage(_artistProfile!.profileImageUrl!)
                        as ImageProvider
                    : const AssetImage('assets/default_profile.png'),
              ),

              const SizedBox(width: 16),

              // Artist info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _artistProfile?.displayName ?? 'Artist',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _artistProfile?.location ?? 'Location not specified',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ...(_artistProfile!.mediums).map((medium) => Chip(
                              label: Text(medium),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Profile completion tracker
          _buildProfileCompletionTracker(),

          const SizedBox(height: 24),

          // Quick stats
          _buildQuickStats(),

          const SizedBox(height: 24),

          // Recent activity
          _buildRecentActivity(),

          const SizedBox(height: 24),

          // Upgrade promotion if on free plan
          if (_subscription?.tier == core.SubscriptionTier.basic)
            _buildUpgradePromotion(),
        ],
      ),
    );
  }

  // Profile completion tracker
  Widget _buildProfileCompletionTracker() {
    // Calculate completion percentage
    final profile = _artistProfile!;
    int completed = 0;
    int total = 6; // Basic fields plus 5 optional ones

    // Check for completed fields
    if (profile.displayName.isNotEmpty) completed++;
    if (profile.bio != null && profile.bio!.isNotEmpty) completed++;
    if (profile.mediums.isNotEmpty) completed++;
    if (profile.styles.isNotEmpty) completed++;
    if (profile.location != null && profile.location!.isNotEmpty) completed++;

    // Access social links from the socialLinks map
    final socialLinks = profile.socialLinks;
    if (socialLinks['website']?.isNotEmpty ?? false) {
      completed++;
    }
    if (profile.profileImageUrl != null &&
        profile.profileImageUrl!.isNotEmpty) {
      completed++;
    }
    if (profile.coverImageUrl != null && profile.coverImageUrl!.isNotEmpty) {
      completed++;
    }

    // Social links
    int totalSocial = 0;
    if (socialLinks['instagram']?.isNotEmpty ?? false) {
      totalSocial++;
    }
    if (socialLinks['facebook']?.isNotEmpty ?? false) totalSocial++;
    if (socialLinks['twitter']?.isNotEmpty ?? false) totalSocial++;
    if (socialLinks['etsy']?.isNotEmpty ?? false) totalSocial++;

    // Add 0-2 points based on social links
    if (totalSocial >= 2) {
      completed += 2;
    } else if (totalSocial == 1) {
      completed += 1;
    }

    final double completionPercentage = (completed / total) * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile Completion',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('${completionPercentage.round()}%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: Colors.grey[300],
              minHeight: 8,
            ),
            if (completionPercentage < 100)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Complete Profile'),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/artist/edit-profile',
                      arguments: {'artistProfileId': profile.id},
                    ).then((_) => _loadArtistData());
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Quick stats
  Widget _buildQuickStats() {
    // These would be populated with real data from a separate analytics service
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Stats',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              icon: Icons.visibility,
              value: '0',
              label: 'Profile Views',
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.image,
              value: '0',
              label: 'Artworks',
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.favorite,
              value: '0',
              label: 'Favorites',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Recent activity
  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // In a real app, this would be a ListView.builder with real data
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent activity',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Add premium feature buttons
        if (_subscription != null &&
            (_subscription!.tier == core.SubscriptionTier.standard ||
                _subscription!.tier == core.SubscriptionTier.premium))
          _buildPremiumFeatures(),

        // Add gallery management button for gallery accounts
        if (_isGallery &&
            _subscription != null &&
            _subscription!.tier == core.SubscriptionTier.premium)
          _buildGalleryFeatures(),
      ],
    );
  }

  // Premium features for Pro and Gallery plans
  Widget _buildPremiumFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Premium Features',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.analytics,
                title: 'Analytics',
                description: 'View detailed analytics',
                onTap: () => Navigator.pushNamed(context, '/artist/analytics'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.bar_chart,
                title: 'Subscription',
                description: 'Track subscription stats',
                onTap: () => Navigator.pushNamed(
                    context, '/artist/subscription-analytics'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.event,
                title: 'Events',
                description: 'Create & manage events',
                onTap: () =>
                    Navigator.pushNamed(context, '/artist/create-event'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.star,
                title: 'Featured',
                description: 'Promote your artwork',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon!')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Gallery-specific features
  Widget _buildGalleryFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Gallery Management',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: InkWell(
            onTap: () =>
                Navigator.pushNamed(context, '/artist/gallery-management'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.people,
                      color: Colors.deepPurple.shade800,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage Artists',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add, edit and manage artists in your gallery',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build feature cards
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Upgrade promotion
  Widget _buildUpgradePromotion() {
    return Card(
      color: Theme.of(context)
          .colorScheme
          .primary
          .withAlpha(25), // Changed from withOpacity(0.1)
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upgrade to Artist Pro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unlock unlimited artwork listings, get featured in discover section, and access advanced analytics.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.star),
                  label: const Text('Learn More'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/artist/subscription');
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upgrade),
                  label: const Text('Upgrade Now'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/artist/subscription');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Artwork tab
  Widget _buildArtworkTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No artwork yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Upload Artwork'),
            onPressed: () {
              Navigator.pushNamed(context, '/artist/upload-artwork')
                  .then((_) => _loadArtistData());
            },
          ),
        ],
      ),
    );
  }

  // Analytics tab
  Widget _buildAnalyticsTab() {
    final bool isPremium = _subscription != null &&
        (_subscription!.tier == core.SubscriptionTier.standard ||
            _subscription!.tier == core.SubscriptionTier.premium);

    if (!isPremium) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Analytics are available with Artist Pro',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/artist/subscription');
              },
              child: const Text('Upgrade to Pro'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bar_chart,
            size: 64,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 16),
          const Text(
            'View detailed analytics for your artist profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/artist/analytics');
            },
            icon: const Icon(Icons.analytics),
            label: const Text('Open Analytics Dashboard'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Track engagement, views, and follower growth',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Events tab
  Widget _buildEventsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No events yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create Event'),
            onPressed: () {
              Navigator.pushNamed(context, '/artist/create-event')
                  .then((_) => _loadArtistData());
            },
          ),
        ],
      ),
    );
  }
}

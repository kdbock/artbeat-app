import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../../widgets/enhanced_artwork_card.dart';

/// Enhanced community feed screen showcasing the new social engagement system
class EnhancedCommunityFeedScreen extends StatefulWidget {
  const EnhancedCommunityFeedScreen({super.key});

  @override
  State<EnhancedCommunityFeedScreen> createState() =>
      _EnhancedCommunityFeedScreenState();
}

class _EnhancedCommunityFeedScreenState
    extends State<EnhancedCommunityFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Feed'),
        backgroundColor: ArtbeatColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Captures'),
            Tab(text: 'Artworks'),
            Tab(text: 'Artists'),
            Tab(text: 'Events'),
            Tab(text: 'Posts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllFeed(),
          _buildCapturesFeed(),
          _buildArtworksFeed(),
          _buildArtistsFeed(),
          _buildEventsFeed(),
          _buildPostsFeed(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOptions(context),
        backgroundColor: ArtbeatColors.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAllFeed() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Demo Artwork
        EnhancedArtworkCard(
          artwork: _createDemoArtwork(),
          onTap: () => _showArtworkDetails(context),
        ),

        // Demo Capture
        _buildCaptureCard(),

        // Demo Artist Profile
        _buildArtistCard(),

        // Demo Event
        _buildEventCard(),

        // Demo Post
        _buildPostCard(),

        // Demo Comment Thread
        _buildCommentCard(),
      ],
    );
  }

  Widget _buildCapturesFeed() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildContentTypeHeader(
          'Street Art Captures',
          'Discover amazing street art and public installations',
          Icons.camera_alt,
          ArtbeatColors.primaryPurple,
        ),
        const SizedBox(height: 16),
        _buildCaptureCard(),
        const SizedBox(height: 16),
        _buildCaptureCard(title: 'Graffiti Mural Downtown'),
        const SizedBox(height: 16),
        _buildCaptureCard(title: 'Sculpture in Central Park'),
      ],
    );
  }

  Widget _buildArtworksFeed() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        EnhancedArtworkCard(artwork: _createDemoArtwork()),
        EnhancedArtworkCard(
          artwork: _createDemoArtwork(
            title: 'Digital Dreams',
            description:
                'A vibrant digital artwork exploring the intersection of technology and creativity.',
            medium: 'Digital Art',
            price: 299.99,
          ),
        ),
        EnhancedArtworkCard(
          artwork: _createDemoArtwork(
            title: 'Ocean Waves',
            description:
                'Acrylic painting capturing the power and beauty of ocean waves.',
            medium: 'Acrylic Paint',
            price: 850.00,
          ),
        ),
      ],
    );
  }

  Widget _buildArtistsFeed() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildContentTypeHeader(
          'Featured Artists',
          'Connect with talented artists in your community',
          Icons.person,
          ArtbeatColors.primaryGreen,
        ),
        const SizedBox(height: 16),
        _buildArtistCard(),
        const SizedBox(height: 16),
        _buildArtistCard(name: 'Sarah Chen', specialty: 'Digital Artist'),
        const SizedBox(height: 16),
        _buildArtistCard(name: 'Marcus Rodriguez', specialty: 'Sculptor'),
      ],
    );
  }

  Widget _buildEventsFeed() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildContentTypeHeader(
          'Art Events',
          'Discover exhibitions, workshops, and art community events',
          Icons.event,
          ArtbeatColors.secondaryTeal,
        ),
        const SizedBox(height: 16),
        _buildEventCard(),
        const SizedBox(height: 16),
        _buildEventCard(
          title: 'Digital Art Workshop',
          description:
              'Learn digital painting techniques with professional artists.',
        ),
        const SizedBox(height: 16),
        _buildEventCard(
          title: 'Gallery Opening Night',
          description:
              'Join us for the opening of our contemporary art exhibition.',
        ),
      ],
    );
  }

  Widget _buildPostsFeed() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildContentTypeHeader(
          'Community Posts',
          'Join the conversation with fellow art enthusiasts',
          Icons.article,
          ArtbeatColors.accentOrange,
        ),
        const SizedBox(height: 16),
        _buildPostCard(),
        const SizedBox(height: 16),
        _buildPostCard(
          content:
              'Just finished my latest painting! What do you think about using bold colors in abstract art?',
        ),
        const SizedBox(height: 16),
        _buildCommentCard(),
      ],
    );
  }

  Widget _buildContentTypeHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
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
    );
  }

  Widget _buildCaptureCard({String title = 'Amazing Street Art'}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: ArtbeatColors.primaryPurple,
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
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
                        ),
                      ),
                      const Text(
                        'Captured 2 hours ago',
                        style: TextStyle(
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

          // Image placeholder
          Container(
            width: double.infinity,
            height: 200,
            color: ArtbeatColors.backgroundSecondary,
            child: const Center(
              child: Icon(
                Icons.image,
                size: 64,
                color: ArtbeatColors.textSecondary,
              ),
            ),
          ),

          // Description
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Found this incredible mural while exploring the arts district. The colors and detail are absolutely stunning!',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
          ),

          // Engagement Bar for Captures
          ContentEngagementBar(
            contentId: 'demo_capture_1',
            contentType: 'capture',
            initialStats: _getDemoStats(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCard({
    String name = 'Alex Johnson',
    String specialty = 'Mixed Media Artist',
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Artist Profile
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: ArtbeatColors.primaryGreen,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        specialty,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Creating unique pieces that blend traditional and digital techniques.',
                        style: TextStyle(fontSize: 13, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Artist Engagement Bar
            ContentEngagementBar(
              contentId: 'demo_artist_1',
              contentType: 'artist',
              initialStats: _getDemoStats(),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard({
    String title = 'Contemporary Art Exhibition',
    String description =
        'Explore the latest works from emerging local artists in this exciting exhibition.',
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ArtbeatColors.secondaryTeal.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ArtbeatColors.secondaryTeal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: ArtbeatColors.secondaryTeal,
                    size: 20,
                  ),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'March 15-30, 2024 • Downtown Gallery',
                        style: TextStyle(
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

          // Event Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              description,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),

          // Event Engagement Bar
          ContentEngagementBar(
            contentId: 'demo_event_1',
            contentType: 'event',
            initialStats: _getDemoStats(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard({
    String content =
        'What\'s everyone working on this week? I\'d love to see your latest projects and get some inspiration!',
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: ArtbeatColors.accentOrange,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community Member',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '1 hour ago',
                        style: TextStyle(
                          fontSize: 12,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  color: ArtbeatColors.textSecondary,
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Post Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),

          const SizedBox(height: 16),

          // Post Engagement Bar
          ContentEngagementBar(
            contentId: 'demo_post_1',
            contentType: 'post',
            initialStats: _getDemoStats(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comment Header
            const Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: ArtbeatColors.primaryPurple,
                  child: Icon(Icons.person, color: Colors.white, size: 16),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Art Enthusiast',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '30 minutes ago',
                        style: TextStyle(
                          fontSize: 11,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Comment Content
            const Text(
              'This is such an inspiring piece! I love how you\'ve used color to convey emotion. The technique reminds me of some of the great impressionist masters.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),

            const SizedBox(height: 12),

            // Comment Engagement Bar
            ContentEngagementBar(
              contentId: 'demo_comment_1',
              contentType: 'comment',
              initialStats: _getDemoStats(),
              isCompact: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ],
        ),
      ),
    );
  }

  ArtworkModel _createDemoArtwork({
    String title = 'Sunset Dreams',
    String description =
        'A vibrant abstract painting inspired by the colors of a summer sunset.',
    String medium = 'Oil Paint',
    double price = 450.00,
  }) {
    return ArtworkModel(
      id: 'demo_artwork_1',
      title: title,
      description: description,
      artistId: 'demo_artist_1',
      imageUrl: '', // Empty for demo
      price: price,
      medium: medium,
      tags: ['Abstract', 'Contemporary', 'Colorful'],
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      isSold: false,
      applauseCount: 42,
      viewsCount: 156,
      artistName: 'Demo Artist',
    );
  }

  EngagementStats _getDemoStats() {
    return EngagementStats(
      likeCount: 42,
      commentCount: 15,
      replyCount: 8,
      shareCount: 23,
      seenCount: 156,
      rateCount: 12,
      reviewCount: 5,
      followCount: 89,
      giftCount: 7,
      sponsorCount: 3,
      messageCount: 11,
      commissionCount: 2,
      totalGiftValue: 125.50,
      totalSponsorValue: 450.00,
      lastUpdated: DateTime.now(),
    );
  }

  void _showArtworkDetails(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening artwork details...')));
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create New Content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildCreateOption(Icons.camera_alt, 'Capture Street Art', () {}),
            _buildCreateOption(Icons.palette, 'Share Artwork', () {}),
            _buildCreateOption(Icons.article, 'Create Post', () {}),
            _buildCreateOption(Icons.event, 'Create Event', () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: ArtbeatColors.primaryPurple),
      title: Text(title),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

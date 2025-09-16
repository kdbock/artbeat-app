import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'simple_ad_create_screen.dart';

/// Educational dashboard explaining how to create ads and their costs
class AdEducationDashboard extends StatefulWidget {
  const AdEducationDashboard({super.key});

  @override
  State<AdEducationDashboard> createState() => _AdEducationDashboardState();
}

class _AdEducationDashboardState extends State<AdEducationDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advertise on ARTbeat'),
        backgroundColor: ArtbeatColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _navigateToCreateAd,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Create Ad',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'How It Works'),
                Tab(text: 'Pricing'),
                Tab(text: 'Examples'),
              ],
              labelColor: ArtbeatColors.primaryGreen,
              unselectedLabelColor: Colors.grey,
              indicatorColor: ArtbeatColors.primaryGreen,
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHowItWorksTab(),
                _buildPricingTab(),
                _buildExamplesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                    ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.campaign,
                    size: 64,
                    color: ArtbeatColors.primaryGreen,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Reach Art Lovers Worldwide',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Promote your art, gallery, or business to our engaged community of art enthusiasts, collectors, and professionals.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Step by step guide
          const Text(
            'How to Create Your Ad',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          _buildStepCard(
            step: 1,
            title: 'Choose Your Ad Type',
            description:
                'Select from banner ads, feed ads, or sponsored posts based on your goals.',
            icon: Icons.view_carousel,
          ),

          _buildStepCard(
            step: 2,
            title: 'Select Size & Location',
            description:
                'Choose where your ad appears: dashboard, artist profiles, or art walk maps.',
            icon: Icons.location_on,
          ),

          _buildStepCard(
            step: 3,
            title: 'Set Duration & Budget',
            description:
                'Pick how long you want your ad to run and review the total cost.',
            icon: Icons.schedule,
          ),

          _buildStepCard(
            step: 4,
            title: 'Upload Creative',
            description:
                'Add your images, compelling copy, and call-to-action.',
            icon: Icons.image,
          ),

          _buildStepCard(
            step: 5,
            title: 'Launch & Monitor',
            description: 'Submit for approval and track performance once live.',
            icon: Icons.rocket_launch,
          ),

          const SizedBox(height: 32),

          // Benefits section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Why Advertise on ARTbeat?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    'Targeted Audience',
                    'Reach art lovers, collectors, and industry professionals',
                    Icons.people,
                  ),
                  _buildBenefitItem(
                    'High Engagement',
                    'Our users actively engage with art content and discoveries',
                    Icons.thumb_up,
                  ),
                  _buildBenefitItem(
                    'Quality Traffic',
                    'Drive meaningful traffic to your website or gallery',
                    Icons.trending_up,
                  ),
                  _buildBenefitItem(
                    'Flexible Options',
                    'Choose from various ad formats and budget levels',
                    Icons.tune,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToCreateAd,
              icon: const Icon(Icons.add),
              label: const Text('Start Creating Your Ad'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: ArtbeatColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ad Pricing',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          const Text(
            'Transparent pricing with no hidden fees. Pay only for what you need.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),

          const SizedBox(height: 24),

          // Size pricing
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ad Sizes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPricingItem(
                    'Small',
                    '\$2.50/day',
                    'Perfect for subtle promotion',
                  ),
                  _buildPricingItem(
                    'Medium',
                    '\$5.00/day',
                    'Balanced visibility and cost',
                  ),
                  _buildPricingItem(
                    'Large',
                    '\$8.50/day',
                    'Maximum impact and reach',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Location pricing
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Premium Locations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPricingItem(
                    'Dashboard',
                    '+50% visibility',
                    'Prime real estate on main screen',
                  ),
                  _buildPricingItem(
                    'Artist Profiles',
                    '+25% visibility',
                    'Appear on relevant artist pages',
                  ),
                  _buildPricingItem(
                    'Art Walk Maps',
                    '+30% visibility',
                    'Show on location-based art discovery',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Duration options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Duration Options',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPricingItem(
                    '7 Days',
                    'Base rate',
                    'Perfect for testing campaigns',
                  ),
                  _buildPricingItem(
                    '30 Days',
                    '20% discount',
                    'Most popular choice',
                  ),
                  _buildPricingItem(
                    '90 Days',
                    '35% discount',
                    'Maximum value for long-term promotion',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Cost calculator
          const Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cost Calculator',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Example: Medium ad on Dashboard for 30 days',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '\$5.00 × 1.5 × 30 = \$225.00',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ArtbeatColors.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '(Base rate × Premium location × Days)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToCreateAd,
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate Your Cost'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: ArtbeatColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamplesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ad Examples',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          const Text(
            'See how other artists and galleries are successfully promoting their work.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),

          const SizedBox(height: 24),

          // Example 1
          _buildExampleCard(
            'Gallery Exhibition Promotion',
            'A local gallery promoting their upcoming contemporary art exhibition.',
            'assets/default_artwork.png',
            '2,500 impressions • 45 clicks • 12% CTR',
            '\$180 for 30 days',
          ),

          const SizedBox(height: 16),

          // Example 2
          _buildExampleCard(
            'Artist Portfolio Showcase',
            'An emerging artist showcasing their latest collection to potential collectors.',
            'assets/default_profile.png',
            '1,800 impressions • 67 clicks • 18% CTR',
            '\$135 for 30 days',
          ),

          const SizedBox(height: 16),

          // Example 3
          _buildExampleCard(
            'Art Workshop Registration',
            'A community art center promoting their weekend painting workshops.',
            'assets/default_artwork.png',
            '3,200 impressions • 89 clicks • 14% CTR',
            '\$240 for 30 days',
          ),

          const SizedBox(height: 24),

          // Success tips
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tips for Success',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildTipItem(
                    'High-quality images that showcase your work beautifully',
                  ),
                  _buildTipItem('Compelling headlines that grab attention'),
                  _buildTipItem(
                    'Clear call-to-action that tells viewers what to do next',
                  ),
                  _buildTipItem(
                    'Target the right audience with appropriate ad placement',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToCreateAd,
              icon: const Icon(Icons.lightbulb),
              label: const Text('Get Inspired & Create'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: ArtbeatColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  step.toString(),
                  style: const TextStyle(
                    color: ArtbeatColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(icon, color: ArtbeatColors.primaryGreen, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: ArtbeatColors.primaryGreen, size: 20),
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
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingItem(String title, String price, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
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
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    String title,
    String description,
    String image,
    String metrics,
    String cost,
  ) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mock image placeholder
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 48, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.analytics, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      metrics,
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.attach_money,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      cost,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: ArtbeatColors.primaryGreen, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  void _navigateToCreateAd() {
    Navigator.push<SimpleAdCreateScreen>(
      context,
      MaterialPageRoute<SimpleAdCreateScreen>(
        builder: (context) => const SimpleAdCreateScreen(),
      ),
    );
  }
}

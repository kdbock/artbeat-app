import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Screen that explains the ARTbeat achievement and experience system
class AchievementInfoScreen extends StatelessWidget {
  const AchievementInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EnhancedUniversalHeader(
        title: 'Achievement System',
        showLogo: false,
        showSearch: false,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                    ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: ArtbeatColors.primaryPurple,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome to ARTbeat Achievements!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Discover art, earn experience, and unlock achievements as you explore the world of public art.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Experience Points Section
            _buildSection(
              title: '🌟 Experience Points (XP)',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Earn XP by participating in ARTbeat activities:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  _buildXPItem('Complete an Art Walk', '100 XP'),
                  _buildXPItem('Create a New Art Walk', '75 XP'),
                  _buildXPItem('Get Art Capture Approved', '50 XP'),
                  _buildXPItem('Submit a Review (50+ words)', '30 XP'),
                  _buildXPItem('Walk Used by 5+ Users', '75 XP'),
                  _buildXPItem('Visit Individual Artwork', '10 XP'),
                  _buildXPItem('Receive Helpful Vote', '10 XP'),
                  _buildXPItem('Edit/Update Walk', '20 XP'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Level System Section
            _buildSection(
              title: '🎨 Level System',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progress through 10 levels inspired by famous artists:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  _buildLevelItem(
                    1,
                    'Sketcher (Frida Kahlo)',
                    '0-199 XP',
                    Colors.brown,
                  ),
                  _buildLevelItem(
                    2,
                    'Color Blender (Jacob Lawrence)',
                    '200-499 XP',
                    Colors.orange,
                  ),
                  _buildLevelItem(
                    3,
                    'Brush Trailblazer (Yayoi Kusama)',
                    '500-999 XP',
                    Colors.pink,
                  ),
                  _buildLevelItem(
                    4,
                    'Street Master (Jean-Michel Basquiat)',
                    '1000-1499 XP',
                    Colors.red,
                  ),
                  _buildLevelItem(
                    5,
                    'Mural Maven (Faith Ringgold)',
                    '1500-2499 XP',
                    Colors.purple,
                  ),
                  _buildLevelItem(
                    6,
                    'Avant-Garde Explorer (Zarina Hashmi)',
                    '2500-3999 XP',
                    Colors.indigo,
                  ),
                  _buildLevelItem(
                    7,
                    'Visionary Creator (El Anatsui)',
                    '4000-5999 XP',
                    Colors.blue,
                  ),
                  _buildLevelItem(
                    8,
                    'Art Legend (Leonardo da Vinci)',
                    '6000-7999 XP',
                    Colors.teal,
                  ),
                  _buildLevelItem(
                    9,
                    'Cultural Curator (Shirin Neshat)',
                    '8000-9999 XP',
                    Colors.green,
                  ),
                  _buildLevelItem(
                    10,
                    'Art Walk Influencer',
                    '10000+ XP',
                    ArtbeatColors.primaryPurple,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Achievement Categories Section
            _buildSection(
              title: '🏆 Achievement Categories',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAchievementCategory(
                    'Art Walks',
                    'Complete art walks and explore new routes',
                    Icons.directions_walk,
                    ArtbeatColors.primaryPurple,
                    [
                      'First Steps - Complete your first art walk',
                      'Walk Explorer - Complete 5 different art walks',
                      'Walk Master - Complete 20 different art walks',
                      'Marathon Walker - Complete a walk of at least 5km',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildAchievementCategory(
                    'Art Discovery',
                    'Discover and appreciate public art',
                    Icons.palette,
                    ArtbeatColors.primaryGreen,
                    [
                      'Art Collector - View 10 different art pieces',
                      'Art Expert - View 50 different art pieces',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildAchievementCategory(
                    'Contributions',
                    'Add content and help grow the community',
                    Icons.volunteer_activism,
                    Colors.orange,
                    [
                      'Urban Photographer - Add 5 new public art pieces',
                      'Major Contributor - Add 20 new public art pieces',
                      'Art Curator - Create 3 art walks',
                      'Master Curator - Create 10 art walks',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildAchievementCategory(
                    'Social',
                    'Engage with the ARTbeat community',
                    Icons.people,
                    Colors.pink,
                    [
                      'Art Commentator - Leave 10 comments on art walks',
                      'Social Butterfly - Share 5 art walks',
                      'Early Adopter - Join during the first month',
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Badge Tiers Section
            _buildSection(
              title: '🥇 Badge Tiers',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Achievements are awarded in three tiers:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  _buildTierItem(
                    'Bronze',
                    'First-time achievements and early milestones',
                    const Color(0xFFCD7F32),
                  ),
                  _buildTierItem(
                    'Silver',
                    'Mid-level achievements showing dedication',
                    const Color(0xFFC0C0C0),
                  ),
                  _buildTierItem(
                    'Gold',
                    'Advanced achievements for true art enthusiasts',
                    const Color(0xFFFFD700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Level Perks Section
            _buildSection(
              title: '🎁 Level Perks',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unlock special privileges as you level up:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  _buildPerkItem(3, 'Suggest edits to any public artwork'),
                  _buildPerkItem(
                    5,
                    'Moderate reviews (report abuse, vote quality)',
                  ),
                  _buildPerkItem(7, 'Early access to beta features'),
                  _buildPerkItem(
                    10,
                    'Become an Art Walk Influencer with featured profile',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Call to Action
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Ready to Start Your Journey?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Begin exploring art walks to earn your first achievements and start climbing the levels!',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/art-walks');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtbeatColors.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Explore Art Walks'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildXPItem(String activity, String xp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ArtbeatColors.primaryPurple,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(activity, style: const TextStyle(fontSize: 14))),
          Text(
            xp,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.primaryPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelItem(int level, String title, String xpRange, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                level.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  xpRange,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCategory(
    String title,
    String description,
    IconData icon,
    Color color,
    List<String> achievements,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
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
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...achievements.map(
            (achievement) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      achievement,
                      style: const TextStyle(fontSize: 13),
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

  Widget _buildTierItem(String tier, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier,
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

  Widget _buildPerkItem(int level, String perk) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ArtbeatColors.primaryPurple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Lv.$level',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(perk, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

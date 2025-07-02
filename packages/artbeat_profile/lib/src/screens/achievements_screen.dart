import 'package:flutter/material.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  final AchievementService _achievementService = AchievementService();
  bool _isLoading = true;
  List<AchievementModel> _achievements = [];
  Map<String, List<AchievementModel>> _categorizedAchievements = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAchievements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);

    try {
      final achievements = await _achievementService.getUserAchievements();

      // Mark any new achievements as viewed
      for (final achievement in achievements.where((a) => a.isNew)) {
        await _achievementService.markAchievementAsViewed(achievement.id);
      }

      // Categorize achievements
      final Map<String, List<AchievementModel>> categorized = {
        'Art Walks': [],
        'Art Discovery': [],
        'Contributions': [],
        'Social': [],
      };

      for (final achievement in achievements) {
        switch (achievement.type) {
          case AchievementType.firstWalk:
          case AchievementType.walkExplorer:
          case AchievementType.walkMaster:
          case AchievementType.marathonWalker:
            categorized['Art Walks']!.add(achievement);
            break;
          case AchievementType.artCollector:
          case AchievementType.artExpert:
            categorized['Art Discovery']!.add(achievement);
            break;
          case AchievementType.photographer:
          case AchievementType.contributor:
          case AchievementType.curator:
          case AchievementType.masterCurator:
            categorized['Contributions']!.add(achievement);
            break;
          case AchievementType.commentator:
          case AchievementType.socialButterfly:
          case AchievementType.earlyAdopter:
            categorized['Social']!.add(achievement);
            break;
        }
      }

      setState(() {
        _achievements = achievements;
        _categorizedAchievements = categorized;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading achievements: $e')),
        );
      }
    }
  }

  void _showAchievementDetails(AchievementModel achievement) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _getAchievementColors(achievement),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _getAchievementIcon(achievement),
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                achievement.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                achievement.description,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Earned on ${_formatDate(achievement.earnedAt)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  IconData _getAchievementIcon(AchievementModel achievement) {
    final String iconName = achievement.iconName;

    // Map the string icon name to actual IconData
    switch (iconName) {
      case 'directions_walk':
        return Icons.directions_walk;
      case 'explore':
        return Icons.explore;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'collections':
        return Icons.collections;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'add_a_photo':
        return Icons.add_a_photo;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'comment':
        return Icons.comment;
      case 'share':
        return Icons.share;
      case 'palette':
        return Icons.palette;
      case 'star':
        return Icons.star;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'access_time':
        return Icons.access_time;
      default:
        return Icons.emoji_events;
    }
  }

  List<Color> _getAchievementColors(AchievementModel achievement) {
    switch (achievement.type) {
      // "First" achievements - bronze
      case AchievementType.firstWalk:
      case AchievementType.artCollector:
      case AchievementType.photographer:
      case AchievementType.commentator:
      case AchievementType.socialButterfly:
      case AchievementType.curator:
      case AchievementType.earlyAdopter:
        return [const Color(0xFFCD7F32), const Color(0xFFA05B20)];
      // Mid-level achievements - silver
      case AchievementType.walkExplorer:
      case AchievementType.artExpert:
      case AchievementType.marathonWalker:
        return [const Color(0xFFC0C0C0), const Color(0xFF8a8a8a)];
      // Advanced achievements - gold
      case AchievementType.walkMaster:
      case AchievementType.contributor:
      case AchievementType.masterCurator:
        return [const Color(0xFFFFD700), const Color(0xFFB7950B)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // No specific index for this screen
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Achievements'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: ArtbeatColors.primaryPurple,
            unselectedLabelColor: ArtbeatColors.textSecondary,
            indicatorColor: ArtbeatColors.primaryPurple,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Art Walks'),
              Tab(text: 'Art Discovery'),
              Tab(text: 'Social'),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ArtbeatColors.primaryPurple.withAlpha(13), // 0.05 opacity
                Colors.white,
                ArtbeatColors.primaryGreen.withAlpha(13), // 0.05 opacity
              ],
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ArtbeatColors.primaryPurple,
                    ),
                  )
                : RefreshIndicator(
                    color: ArtbeatColors.primaryPurple,
                    onRefresh: _loadAchievements,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // All achievements
                        _buildAchievementsTab(_achievements),

                        // Art Walks tab
                        _buildAchievementsTab(
                          _categorizedAchievements['Art Walks'] ?? [],
                        ),

                        // Art Discovery tab
                        _buildAchievementsTab(
                          _categorizedAchievements['Art Discovery'] ?? [],
                        ),

                        // Social tab
                        _buildAchievementsTab([
                          ...(_categorizedAchievements['Social'] ?? []),
                          ...(_categorizedAchievements['Contributions'] ?? []),
                        ]),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsTab(List<AchievementModel> achievements) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Achievement Progress',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You have earned ${achievements.length} out of 13 possible achievements',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: achievements.length / 13,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAchievementStatItem(
                        'Bronze',
                        _countAchievementsByTier(achievements, 'bronze'),
                        const Color(0xFFCD7F32),
                      ),
                      _buildAchievementStatItem(
                        'Silver',
                        _countAchievementsByTier(achievements, 'silver'),
                        const Color(0xFFC0C0C0),
                      ),
                      _buildAchievementStatItem(
                        'Gold',
                        _countAchievementsByTier(achievements, 'gold'),
                        const Color(0xFFFFD700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Achievements Grid
          AchievementsGrid(
            achievements: achievements,
            showDetails: true,
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            badgeSize: 80,
            onAchievementTap: _showAchievementDetails,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementStatItem(String name, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(128),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  int _countAchievementsByTier(
    List<AchievementModel> achievements,
    String tier,
  ) {
    Set<AchievementType> tierAchievements;

    switch (tier) {
      case 'bronze':
        tierAchievements = {
          AchievementType.firstWalk,
          AchievementType.artCollector,
          AchievementType.photographer,
          AchievementType.commentator,
          AchievementType.socialButterfly,
          AchievementType.curator,
          AchievementType.earlyAdopter,
        };
        break;
      case 'silver':
        tierAchievements = {
          AchievementType.walkExplorer,
          AchievementType.artExpert,
          AchievementType.marathonWalker,
        };
        break;
      case 'gold':
        tierAchievements = {
          AchievementType.walkMaster,
          AchievementType.contributor,
          AchievementType.masterCurator,
        };
        break;
      default:
        return 0;
    }

    return achievements.where((a) => tierAchievements.contains(a.type)).length;
  }
}

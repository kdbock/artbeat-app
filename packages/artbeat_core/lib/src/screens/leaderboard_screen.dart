import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import '../services/leaderboard_service.dart';
import '../utils/logger.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LeaderboardService _leaderboardService = LeaderboardService();
  final RewardsService _rewardsService = RewardsService();

  Map<LeaderboardCategory, List<LeaderboardEntry>> _leaderboards = {};
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  final List<LeaderboardCategory> _categories = [
    LeaderboardCategory.totalXP,
    LeaderboardCategory.capturesCreated,
    LeaderboardCategory.artWalksCompleted,
    LeaderboardCategory.artWalksCreated,
    LeaderboardCategory.level,
    LeaderboardCategory.highestRatedCapture,
    LeaderboardCategory.highestRatedArtWalk,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadLeaderboards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboards() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final leaderboards = await _leaderboardService.getMultipleLeaderboards(
        categories: _categories,
        limit: 50,
      );
      final stats = await _leaderboardService.getLeaderboardStats();

      if (!mounted) return;
      setState(() {
        _leaderboards = leaderboards;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading leaderboards: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Leaderboards',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: _stats != null ? _buildStatsOverlay() : null,
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Theme.of(context).primaryColor,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                tabs: _categories
                    .map(
                      (category) => Tab(
                        icon: Text(
                          category.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                        text: category.displayName,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          // Tab View Content
          SliverFillRemaining(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: _categories
                        .map((category) => _buildLeaderboardTab(category))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverlay() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40), // Space for title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCard(
                title: 'Total Users',
                value: '${_stats!['totalUsers']}',
                icon: Icons.people,
              ),
              _StatCard(
                title: 'Total XP',
                value: _formatNumber(_stats!['totalXP'] as int),
                icon: Icons.flash_on,
              ),
              _StatCard(
                title: 'Avg Level',
                value: '${(_stats!['averageXP'] / 100).round()}',
                icon: Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(LeaderboardCategory category) {
    final entries = _leaderboards[category] ?? [];

    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Be the first to earn points in this category!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboards,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length + 2, // +2 for header and your rank
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCategoryHeader(category);
          }

          if (index == 1) {
            return _buildCurrentUserRank(category);
          }

          final entry = entries[index - 2];
          return _buildLeaderboardCard(entry, category);
        },
      ),
    );
  }

  Widget _buildCategoryHeader(LeaderboardCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(category.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.displayName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _getCategoryDescription(category),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserRank(LeaderboardCategory category) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _leaderboardService.getCurrentUserLeaderboardInfo(category),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final currentUserEntry =
            snapshot.data!['currentUser'] as LeaderboardEntry;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildLeaderboardCard(
            currentUserEntry,
            category,
            isCurrentUser: true,
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardCard(
    LeaderboardEntry entry,
    LeaderboardCategory category, {
    bool isCurrentUser = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: Theme.of(context).primaryColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getRankColor(entry.rank),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#${entry.rank}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Profile Image
            CircleAvatar(
              radius: 24,
              backgroundImage: entry.profileImageUrl != null
                  ? CachedNetworkImageProvider(entry.profileImageUrl!)
                  : null,
              child: entry.profileImageUrl == null
                  ? const Icon(Icons.person, size: 24)
                  : null,
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? Theme.of(context).primaryColor : null,
                ),
              ),
            ),
            if (isCurrentUser)
              Icon(
                Icons.person,
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Level ${entry.level} • ${_rewardsService.getLevelTitle(entry.level)}',
            ),
            if (category != LeaderboardCategory.totalXP &&
                category != LeaderboardCategory.level)
              Text('${entry.experiencePoints} total XP'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatValue(entry.value, category),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Text(
              _getValueLabel(category),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[600]!; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.brown[400]!; // Bronze
      default:
        return Theme.of(context).primaryColor;
    }
  }

  String _getCategoryDescription(LeaderboardCategory category) {
    switch (category) {
      case LeaderboardCategory.totalXP:
        return 'Total experience points earned across all activities';
      case LeaderboardCategory.capturesCreated:
        return 'Number of art captures created by users';
      case LeaderboardCategory.artWalksCompleted:
        return 'Number of art walks completed by users';
      case LeaderboardCategory.artWalksCreated:
        return 'Number of public art walks created';
      case LeaderboardCategory.level:
        return 'Highest level achieved based on experience';
      case LeaderboardCategory.highestRatedCapture:
        return 'Highest rated art capture (5-star rating system)';
      case LeaderboardCategory.highestRatedArtWalk:
        return 'Highest rated art walk (5-star rating system)';
    }
  }

  String _formatValue(int value, LeaderboardCategory category) {
    if (category == LeaderboardCategory.totalXP) {
      return _formatNumber(value);
    } else if (category == LeaderboardCategory.highestRatedCapture ||
        category == LeaderboardCategory.highestRatedArtWalk) {
      // Convert back from scaled integer to rating (if we were storing ratings * 100)
      // For now, just show the value as stars if it's between 1-5
      if (value >= 1 && value <= 5) {
        return '$value⭐';
      } else if (value == 0) {
        return 'No rating';
      }
      return value.toString();
    }
    return value.toString();
  }

  String _getValueLabel(LeaderboardCategory category) {
    switch (category) {
      case LeaderboardCategory.totalXP:
        return 'XP';
      case LeaderboardCategory.capturesCreated:
        return 'captures';
      case LeaderboardCategory.artWalksCompleted:
        return 'completed';
      case LeaderboardCategory.artWalksCreated:
        return 'created';
      case LeaderboardCategory.level:
        return 'level';
      case LeaderboardCategory.highestRatedCapture:
        return 'stars';
      case LeaderboardCategory.highestRatedArtWalk:
        return 'stars';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

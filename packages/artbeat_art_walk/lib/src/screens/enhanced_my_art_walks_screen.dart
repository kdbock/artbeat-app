import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import '../constants/routes.dart';

/// Enhanced screen for managing user's art walks with progress tracking
class EnhancedMyArtWalksScreen extends StatefulWidget {
  const EnhancedMyArtWalksScreen({super.key});

  @override
  State<EnhancedMyArtWalksScreen> createState() =>
      _EnhancedMyArtWalksScreenState();
}

class _EnhancedMyArtWalksScreenState extends State<EnhancedMyArtWalksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final ArtWalkService _artWalkService = ArtWalkService();
  final ArtWalkProgressService _progressService = ArtWalkProgressService();

  String? _userId;
  bool _isLoading = true;

  // Data for each tab
  List<ArtWalkProgress> _inProgressWalks = [];
  List<ArtWalkProgress> _completedWalks = [];
  List<ArtWalkModel> _createdWalks = [];
  List<ArtWalkModel> _savedWalks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _userId = _artWalkService.getCurrentUserId();
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Load data for all tabs concurrently
      final results = await Future.wait([
        _progressService.getIncompleteWalks(_userId!),
        _progressService.getCompletedWalks(_userId!),
        _artWalkService.getUserCreatedWalks(_userId!),
        _artWalkService.getUserSavedWalks(_userId!),
      ]);

      if (mounted) {
        setState(() {
          _inProgressWalks = results[0] as List<ArtWalkProgress>;
          _completedWalks = results[1] as List<ArtWalkProgress>;
          _createdWalks = results[2] as List<ArtWalkModel>;
          _savedWalks = results[3] as List<ArtWalkModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return _buildNotLoggedInView();
    }

    return MainLayout(
      currentIndex: 1, // Assuming this is the second tab in main navigation
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Art Walks'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.play_circle_outline),
                text: 'In Progress',
                child: _buildTabWithBadge(
                  icon: Icons.play_circle_outline,
                  text: 'In Progress',
                  count: _inProgressWalks.length,
                ),
              ),
              Tab(
                icon: const Icon(Icons.check_circle_outline),
                text: 'Completed',
                child: _buildTabWithBadge(
                  icon: Icons.check_circle_outline,
                  text: 'Completed',
                  count: _completedWalks.length,
                ),
              ),
              Tab(
                icon: const Icon(Icons.create_outlined),
                text: 'Created',
                child: _buildTabWithBadge(
                  icon: Icons.create_outlined,
                  text: 'Created',
                  count: _createdWalks.length,
                ),
              ),
              Tab(
                icon: const Icon(Icons.bookmark_outline),
                text: 'Saved',
                child: _buildTabWithBadge(
                  icon: Icons.bookmark_outline,
                  text: 'Saved',
                  count: _savedWalks.length,
                ),
              ),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildInProgressTab(),
                  _buildCompletedTab(),
                  _buildCreatedTab(),
                  _buildSavedTab(),
                ],
              ),
        floatingActionButton:
            _tabController.index ==
                2 // Created tab
            ? FloatingActionButton.extended(
                onPressed: () =>
                    Navigator.pushNamed(context, '/create-art-walk'),
                icon: const Icon(Icons.add),
                label: const Text('Create Walk'),
              )
            : null,
      ),
    );
  }

  Widget _buildTabWithBadge({
    required IconData icon,
    required String text,
    required int count,
  }) {
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(fontSize: 12)),
          ],
        ),
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotLoggedInView() {
    return MainLayout(
      currentIndex: 1,
      child: Scaffold(
        appBar: AppBar(title: const Text('My Art Walks')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle,
                size: 80,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Please log in to view your art walks',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInProgressTab() {
    if (_inProgressWalks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.explore,
        title: 'No walks in progress',
        subtitle: 'Start exploring art walks to see your progress here',
        actionText: 'Explore Walks',
        onAction: () => Navigator.pushNamed(context, '/art-walks'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _inProgressWalks.length,
        itemBuilder: (context, index) {
          final progress = _inProgressWalks[index];
          return InProgressWalkCard(
            progress: progress,
            onResume: () => _resumeWalk(progress),
            onPause: () => _pauseWalk(progress),
            onAbandon: () => _abandonWalk(progress),
            onTap: () => _viewWalkDetails(progress.artWalkId),
          );
        },
      ),
    );
  }

  Widget _buildCompletedTab() {
    if (_completedWalks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle,
        title: 'No completed walks yet',
        subtitle: 'Complete your first art walk to see it here',
        actionText: 'Start Walking',
        onAction: () => Navigator.pushNamed(context, '/art-walks'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedWalks.length,
        itemBuilder: (context, index) {
          final progress = _completedWalks[index];
          return CompletedWalkCard(
            progress: progress,
            onTap: () => _viewWalkDetails(progress.artWalkId),
            onShare: () => _shareWalkCompletion(progress),
            onReview: () => _reviewWalk(progress),
          );
        },
      ),
    );
  }

  Widget _buildCreatedTab() {
    if (_createdWalks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.create,
        title: 'No walks created yet',
        subtitle: 'Share your favorite art spots by creating a walk',
        actionText: 'Create Walk',
        onAction: () => Navigator.pushNamed(context, '/create-art-walk'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _createdWalks.length,
        itemBuilder: (context, index) {
          final walk = _createdWalks[index];
          return CreatedWalkCard(
            walk: walk,
            onTap: () => _viewWalkDetails(walk.id),
            onEdit: () => _editWalk(walk),
            onDelete: () => _deleteWalk(walk),
            onShare: () => _shareWalk(walk),
          );
        },
      ),
    );
  }

  Widget _buildSavedTab() {
    if (_savedWalks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark,
        title: 'No saved walks yet',
        subtitle: 'Save interesting walks to find them easily later',
        actionText: 'Browse Walks',
        onAction: () => Navigator.pushNamed(context, '/art-walks'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _savedWalks.length,
        itemBuilder: (context, index) {
          final walk = _savedWalks[index];
          return SavedWalkCard(
            walk: walk,
            onTap: () => _viewWalkDetails(walk.id),
            onUnsave: () => _unsaveWalk(walk),
            onStart: () => _startWalk(walk),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onAction, child: Text(actionText)),
          ],
        ),
      ),
    );
  }

  // Action methods
  Future<void> _resumeWalk(ArtWalkProgress progress) async {
    try {
      await _progressService.resumeWalk(progress.id);
      Navigator.pushNamed(
        context,
        '/art-walk-experience',
        arguments: {'artWalkId': progress.artWalkId},
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error resuming walk: $e')));
    }
  }

  Future<void> _pauseWalk(ArtWalkProgress progress) async {
    try {
      await _progressService.pauseWalk();
      _loadAllData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error pausing walk: $e')));
    }
  }

  Future<void> _abandonWalk(ArtWalkProgress progress) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon Walk?'),
        content: const Text(
          'Are you sure you want to abandon this walk? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abandon'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _progressService.abandonWalk();
        _loadAllData();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error abandoning walk: $e')));
      }
    }
  }

  void _viewWalkDetails(String walkId) {
    Navigator.pushNamed(
      context,
      '/art-walk-detail',
      arguments: {'walkId': walkId},
    );
  }

  void _shareWalkCompletion(ArtWalkProgress progress) {
    // Implement sharing logic
  }

  void _reviewWalk(ArtWalkProgress progress) {
    // Navigate to review screen
  }

  void _editWalk(ArtWalkModel walk) {
    Navigator.pushNamed(
      context,
      '/edit-art-walk',
      arguments: {'walkId': walk.id},
    );
  }

  Future<void> _deleteWalk(ArtWalkModel walk) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Walk?'),
        content: Text(
          'Are you sure you want to delete "${walk.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _artWalkService.deleteArtWalk(walk.id);
        _loadAllData();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting walk: $e')));
      }
    }
  }

  void _shareWalk(ArtWalkModel walk) {
    // Implement sharing logic
  }

  Future<void> _unsaveWalk(ArtWalkModel walk) async {
    try {
      await _artWalkService.unsaveArtWalk(walk.id);
      _loadAllData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error unsaving walk: $e')));
    }
  }

  void _startWalk(ArtWalkModel walk) {
    Navigator.pushNamed(
      context,
      ArtWalkRoutes.enhancedExperience,
      arguments: {'artWalkId': walk.id, 'artWalk': walk},
    );
  }
}

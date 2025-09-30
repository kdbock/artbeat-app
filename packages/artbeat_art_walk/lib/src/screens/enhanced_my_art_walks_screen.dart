import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import '../constants/routes.dart';

/// Helper class for empty state configuration
class _EmptyStateConfig {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onAction;

  _EmptyStateConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
  });
}

/// Enhanced screen for managing user's art walks with progress tracking
class EnhancedMyArtWalksScreen extends StatefulWidget {
  const EnhancedMyArtWalksScreen({super.key});

  @override
  State<EnhancedMyArtWalksScreen> createState() =>
      _EnhancedMyArtWalksScreenState();
}

class _EnhancedMyArtWalksScreenState extends State<EnhancedMyArtWalksScreen> {
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
    _userId = _artWalkService.getCurrentUserId();
    _loadAllData();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Art Walks'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSingleScrollView(),
    );
  }

  Widget _buildSingleScrollView() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadAllData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // In Progress Section
                _buildSection(
                  title: 'In Progress',
                  icon: Icons.play_circle_outline,
                  count: _inProgressWalks.length,
                  isEmpty: _inProgressWalks.isEmpty,
                  emptyStateConfig: _EmptyStateConfig(
                    icon: Icons.explore,
                    title: 'No walks in progress',
                    subtitle:
                        'Start exploring art walks to see your progress here',
                    actionText: 'Explore Walks',
                    onAction: () =>
                        Navigator.pushNamed(context, ArtWalkRoutes.dashboard),
                  ),
                  builder: () => Column(
                    children: _inProgressWalks
                        .map(
                          (progress) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InProgressWalkCard(
                              progress: progress,
                              onResume: () => _resumeWalk(progress),
                              onPause: () => _pauseWalk(progress),
                              onAbandon: () => _abandonWalk(progress),
                              onTap: () => _viewWalkDetails(progress.artWalkId),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Completed Section
                _buildSection(
                  title: 'Completed',
                  icon: Icons.check_circle_outline,
                  count: _completedWalks.length,
                  isEmpty: _completedWalks.isEmpty,
                  emptyStateConfig: _EmptyStateConfig(
                    icon: Icons.check_circle,
                    title: 'No completed walks yet',
                    subtitle: 'Complete your first art walk to see it here',
                    actionText: 'Start Walking',
                    onAction: () =>
                        Navigator.pushNamed(context, ArtWalkRoutes.dashboard),
                  ),
                  builder: () => Column(
                    children: _completedWalks
                        .map(
                          (progress) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: CompletedWalkCard(
                              progress: progress,
                              onTap: () => _viewWalkDetails(progress.artWalkId),
                              onShare: () => _shareWalkCompletion(progress),
                              onReview: () => _reviewWalk(progress),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Created Section
                _buildSection(
                  title: 'Created',
                  icon: Icons.create_outlined,
                  count: _createdWalks.length,
                  isEmpty: _createdWalks.isEmpty,
                  emptyStateConfig: _EmptyStateConfig(
                    icon: Icons.create,
                    title: 'No walks created yet',
                    subtitle:
                        'Share your favorite art spots by creating a walk',
                    actionText: 'Create Walk',
                    onAction: () => Navigator.pushNamed(
                      context,
                      ArtWalkRoutes.enhancedCreate,
                    ),
                  ),
                  builder: () => Column(
                    children: _createdWalks
                        .map(
                          (walk) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: CreatedWalkCard(
                              walk: walk,
                              onTap: () => _viewWalkDetails(walk.id),
                              onEdit: () => _editWalk(walk),
                              onDelete: () => _deleteWalk(walk),
                              onShare: () => _shareWalk(walk),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Saved Section
                _buildSection(
                  title: 'Saved',
                  icon: Icons.bookmark_outline,
                  count: _savedWalks.length,
                  isEmpty: _savedWalks.isEmpty,
                  emptyStateConfig: _EmptyStateConfig(
                    icon: Icons.bookmark,
                    title: 'No saved walks yet',
                    subtitle:
                        'Save interesting walks to find them easily later',
                    actionText: 'Browse Walks',
                    onAction: () =>
                        Navigator.pushNamed(context, ArtWalkRoutes.dashboard),
                  ),
                  builder: () => Column(
                    children: _savedWalks
                        .map(
                          (walk) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SavedWalkCard(
                              walk: walk,
                              onTap: () => _viewWalkDetails(walk.id),
                              onUnsave: () => _unsaveWalk(walk),
                              onStart: () => _startWalk(walk),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ),
        // Floating Action Button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () =>
                Navigator.pushNamed(context, ArtWalkRoutes.enhancedCreate),
            icon: const Icon(Icons.add),
            label: const Text('Create Walk'),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required int count,
    required bool isEmpty,
    required _EmptyStateConfig emptyStateConfig,
    required Widget Function() builder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Content or Empty State
        isEmpty ? _buildCompactEmptyState(emptyStateConfig) : builder(),
      ],
    );
  }

  Widget _buildCompactEmptyState(_EmptyStateConfig config) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            config.icon,
            size: 32,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  config.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: config.onAction,
            child: Text(config.actionText),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Scaffold(
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
      ArtWalkRoutes.experience,
      arguments: {'artWalkId': walk.id, 'artWalk': walk},
    );
  }
}

import 'package:flutter/material.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart';

class ArtWalkListScreen extends StatefulWidget {
  const ArtWalkListScreen({super.key});

  @override
  State<ArtWalkListScreen> createState() => _ArtWalkListScreenState();
}

class _ArtWalkListScreenState extends State<ArtWalkListScreen> {
  final ArtWalkService _artWalkService = ArtWalkService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<ArtWalkModel> _artWalks = [];
  List<ArtWalkModel> _filteredWalks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filterOptions = ['All', 'My Walks', 'Popular', 'Nearby'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await _loadArtWalks();
    } catch (e) {
      // debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadArtWalks() async {
    try {
      final walks = await _artWalkService.getPopularArtWalks(limit: 50);
      if (mounted) {
        setState(() {
          _artWalks = walks;
          _applyFilters();
        });
      }
    } catch (e) {
      // debugPrint('Error loading art walks: $e');
    }
  }

  void _applyFilters() {
    List<ArtWalkModel> filtered = _artWalks;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (walk) =>
                walk.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                walk.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Apply category filter
    switch (_selectedFilter) {
      case 'My Walks':
        final userId = _artWalkService.getCurrentUserId();
        if (userId != null) {
          filtered = filtered.where((walk) => walk.userId == userId).toList();
        }
        break;
      case 'Popular':
        filtered.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case 'Nearby':
        // For now, just show all - could be enhanced with location filtering
        break;
    }

    setState(() => _filteredWalks = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 1,
      drawer: const ArtWalkDrawer(),
      scaffoldKey: _scaffoldKey,
      child: Scaffold(
        appBar: ArtWalkDesignSystem.buildAppBar(
          title: 'Art Walks',
          showBackButton: true,
          scaffoldKey: _scaffoldKey,
        ),
        body: ArtWalkDesignSystem.buildScreenContainer(
          child: _isLoading
              ? Center(
                  child: ArtWalkDesignSystem.buildGlassCard(
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ArtWalkDesignSystem.primaryTeal,
                          ),
                        ),
                        SizedBox(height: ArtWalkDesignSystem.paddingM),
                        Text(
                          'Loading art walks...',
                          style: ArtWalkDesignSystem.cardTitleStyle,
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
        ),
        floatingActionButton: ArtWalkDesignSystem.buildFloatingActionButton(
          onPressed: _navigateToCreateWalk,
          icon: Icons.add_location,
          tooltip: 'Create Art Walk',
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildSearchAndFilterBar(),
        Expanded(
          child: _filteredWalks.isEmpty
              ? _buildEmptyState()
              : _buildWalksList(),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    return ArtWalkDesignSystem.buildGlassCard(
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: ArtWalkDesignSystem.cardDecoration(),
            child: TextField(
              style: ArtWalkDesignSystem.cardTitleStyle,
              decoration: const InputDecoration(
                hintText: 'Search art walks...',
                hintStyle: ArtWalkDesignSystem.cardSubtitleStyle,
                prefixIcon: Icon(
                  Icons.search,
                  color: ArtWalkDesignSystem.primaryTeal,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(ArtWalkDesignSystem.paddingM),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilters();
              },
            ),
          ),
          const SizedBox(height: ArtWalkDesignSystem.paddingM),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                      _applyFilters();
                    },
                    backgroundColor: Colors.white,
                    selectedColor: ArtWalkColors.primaryTeal.withValues(
                      alpha: 0.1,
                    ),
                    checkmarkColor: ArtWalkColors.primaryTeal,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? ArtWalkColors.primaryTeal
                          : ArtWalkColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalksList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredWalks.length,
      itemBuilder: (context, index) {
        final walk = _filteredWalks[index];
        return _buildWalkCard(walk);
      },
    );
  }

  Widget _buildWalkCard(ArtWalkModel walk) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToWalkDetail(walk.id),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image with overlay
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  // Cover image
                  () {
                    // Debug logging
                    debugPrint(
                      'ArtWalk ${walk.title}: coverImageUrl=${walk.coverImageUrl}, imageUrls=${walk.imageUrls.length}',
                    );

                    if (walk.coverImageUrl != null &&
                        walk.coverImageUrl!.isNotEmpty) {
                      AppLogger.info(
                        'Using coverImageUrl: ${walk.coverImageUrl}',
                      );
                      return SecureNetworkImage(
                        imageUrl: walk.coverImageUrl!,
                        fit: BoxFit.cover,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        placeholder: Container(
                          decoration: BoxDecoration(
                            color: ArtWalkColors.primaryTeal.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              color: ArtWalkColors.primaryTeal,
                              size: 48,
                            ),
                          ),
                        ),
                        errorWidget: Container(
                          decoration: BoxDecoration(
                            color: ArtWalkColors.primaryTeal.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: ArtWalkColors.textSecondary,
                              size: 48,
                            ),
                          ),
                        ),
                      );
                    } else if (walk.imageUrls.isNotEmpty) {
                      AppLogger.info(
                        'Using imageUrls[0]: ${walk.imageUrls.first}',
                      );
                      return SecureNetworkImage(
                        imageUrl: walk.imageUrls.first,
                        fit: BoxFit.cover,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        placeholder: Container(
                          decoration: BoxDecoration(
                            color: ArtWalkColors.primaryTeal.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              color: ArtWalkColors.primaryTeal,
                              size: 48,
                            ),
                          ),
                        ),
                        errorWidget: Container(
                          decoration: BoxDecoration(
                            color: ArtWalkColors.primaryTeal.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: ArtWalkColors.textSecondary,
                              size: 48,
                            ),
                          ),
                        ),
                      );
                    } else {
                      AppLogger.info('No image available for ${walk.title}');
                      return Container(
                        decoration: BoxDecoration(
                          color: ArtWalkColors.primaryTeal.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.map,
                            color: ArtWalkColors.primaryTeal,
                            size: 48,
                          ),
                        ),
                      );
                    }
                  }(),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  // Title and stats overlay
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          walk.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                walk.zipCode ?? 'Location not specified',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    walk.description,
                    style: const TextStyle(
                      color: ArtWalkColors.textSecondary,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Stats and actions
                  Row(
                    children: [
                      // Art pieces count
                      _buildStatItem(
                        icon: Icons.image,
                        label: '${walk.artworkIds.length} pieces',
                      ),
                      const SizedBox(width: 16),
                      // Views count
                      _buildStatItem(
                        icon: Icons.visibility,
                        label: '${walk.viewCount} views',
                      ),
                      const Spacer(),
                      // Action button
                      ElevatedButton.icon(
                        onPressed: () => _navigateToWalkDetail(walk.id),
                        icon: const Icon(Icons.explore, size: 16),
                        label: const Text('Explore'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ArtWalkColors.primaryTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ArtWalkColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: ArtWalkColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: ArtWalkColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No art walks found for "$_searchQuery"'
                : 'No art walks available',
            style: const TextStyle(
              color: ArtWalkColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Create your first art walk to get started',
            style: TextStyle(
              color: ArtWalkColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateWalk,
              icon: const Icon(Icons.add),
              label: const Text('Create Art Walk'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtWalkColors.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToWalkDetail(String walkId) {
    Navigator.pushNamed(
      context,
      '/art-walk/detail',
      arguments: {'walkId': walkId},
    );
  }

  void _navigateToCreateWalk() {
    Navigator.pushNamed(context, '/art-walk/create');
  }
}

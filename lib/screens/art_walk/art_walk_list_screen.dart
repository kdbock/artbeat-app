import 'package:flutter/material.dart';
import 'package:artbeat/models/art_walk_model.dart';
import 'package:artbeat/services/art_walk_service.dart';
import 'package:artbeat/screens/art_walk/art_walk_detail_screen.dart';
import 'package:artbeat/screens/art_walk/create_art_walk_screen.dart';
import 'package:artbeat/widgets/nc_region_art_walk_filter.dart';
import 'package:artbeat/utils/nc_location_helper.dart';
import 'package:share_plus/share_plus.dart';

class ArtWalkListScreen extends StatefulWidget {
  const ArtWalkListScreen({super.key});

  @override
  State<ArtWalkListScreen> createState() => _ArtWalkListScreenState();
}

class _ArtWalkListScreenState extends State<ArtWalkListScreen>
    with SingleTickerProviderStateMixin {
  final ArtWalkService _artWalkService = ArtWalkService();
  final NCLocationHelper _locationHelper = NCLocationHelper();
  bool _isLoading = true;

  List<ArtWalkModel> _myWalks = [];
  List<ArtWalkModel> _popularWalks = [];
  List<ArtWalkModel> _regionFilteredWalks = [];
  String? _selectedRegion;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadArtWalks();
    _determineUserRegion();
  }

  Future<void> _determineUserRegion() async {
    try {
      final userRegion = await _locationHelper.getUserRegion();
      if (mounted && userRegion != null) {
        setState(() {
          _selectedRegion = userRegion;
        });
      }
    } catch (e) {
      debugPrint('Error determining user region: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadArtWalks() async {
    setState(() => _isLoading = true);

    try {
      final userId = _artWalkService.getCurrentUserId();
      if (userId != null) {
        _myWalks = await _artWalkService.getUserArtWalks(userId);
      }

      _popularWalks = await _artWalkService.getPopularArtWalks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading art walks: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _shareArtWalk(ArtWalkModel walk) async {
    try {
      await SharePlus.instance.share(ShareParams(
        text: 'Check out this Art Walk: "${walk.title}" on ARTbeat!',
        subject: 'ARTbeat Art Walk: ${walk.title}',
      ));

      // Record the share
      await _artWalkService.recordArtWalkShare(walk.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteArtWalk(ArtWalkModel walk) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Art Walk'),
        content: Text('Are you sure you want to delete "${walk.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _artWalkService.deleteArtWalk(walk.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Art walk deleted')),
      );
      _loadArtWalks(); // Refresh the list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting art walk: ${e.toString()}')),
      );
    }
  }

  // Handle art walks filtered by region
  void _handleRegionFilteredArtWalks(List<ArtWalkModel> artWalks) {
    if (mounted) {
      setState(() {
        _regionFilteredWalks = artWalks;
      });
    }
  }

  // Build tab for browsing by NC regions
  Widget _buildNCRegionsTab() {
    return Column(
      children: [
        // Region filter widget at the top
        NCRegionArtWalkFilter(
          onArtWalksLoaded: _handleRegionFilteredArtWalks,
          initialRegion: _selectedRegion,
          showLoadingIndicator: false,
        ),

        // Art walks filtered by region
        Expanded(
          child: _regionFilteredWalks.isEmpty
              ? _buildEmptyState(
                  'No art walks found in this region',
                  'Try selecting a different region, or create a new art walk',
                )
              : _buildWalksList(_regionFilteredWalks, isMyWalks: false),
        ),
      ],
    );
  }

  // Build a banner to promote NC region-based exploration
  Widget _buildNCRegionsBanner() {
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(2); // Switch to NC Regions tab
      },
      child: Card(
        margin: const EdgeInsets.all(16.0),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [Colors.green.shade100, Colors.green.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(
                Icons.map_outlined,
                size: 40,
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Explore NC by Region',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Discover art walks in different regions of North Carolina',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Art Walks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Walks'),
            Tab(text: 'Popular'),
            Tab(text: 'NC Regions'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadArtWalks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // My Walks Tab
                Column(
                  children: [
                    if (_myWalks.isEmpty)
                      _buildEmptyState(
                        'You haven\'t created any art walks yet',
                        'Create a walk to organize and share your favorite public art',
                      )
                    else
                      Expanded(
                        child: _buildWalksList(_myWalks, isMyWalks: true),
                      ),

                    // NC Regions promo banner
                    _buildNCRegionsBanner(),
                  ],
                ),

                // Popular Walks Tab
                Column(
                  children: [
                    if (_popularWalks.isEmpty)
                      _buildEmptyState(
                        'No popular walks found',
                        'Be the first to create and share an art walk',
                      )
                    else
                      Expanded(
                        child: _buildWalksList(_popularWalks, isMyWalks: false),
                      ),

                    // NC Regions promo banner
                    _buildNCRegionsBanner(),
                  ],
                ),

                // NC Regions Tab
                _buildNCRegionsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateArtWalkScreen()),
          );

          if (result == true && mounted) {
            _loadArtWalks();
          }
        },
        child: const Icon(Icons.add),
      ),
      // Add the NC Regions banner below the app bar
      bottomSheet: _tabController.index == 2 // Only show on NC Regions tab
          ? _buildNCRegionsBanner()
          : null,
    );
  }

  Widget _buildEmptyState(String title, String description) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _tabController.index == 0 // Only show on My Walks tab
                ? ElevatedButton.icon(
                    onPressed: () async {
                      // Added async
                      await Navigator.push(
                        // Added await
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateArtWalkScreen()),
                      );
                      // Potentially refresh if needed, though FAB already does
                      if (mounted) {
                        // Added mounted check
                        _loadArtWalks();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Art Walk'),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildWalksList(List<ArtWalkModel> walks, {required bool isMyWalks}) {
    return RefreshIndicator(
      onRefresh: _loadArtWalks,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: walks.length,
        itemBuilder: (context, index) {
          final walk = walks[index];
          return _buildWalkCard(walk, isMyWalks);
        },
      ),
    );
  }

  Widget _buildWalkCard(ArtWalkModel walk, bool isMyWalk) {
    final String? imageUrl =
        walk.imageUrls.isNotEmpty ? walk.imageUrls.first : null;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          imageUrl != null
              ? Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                )
              : Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.map,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  walk.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  walk.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                // Stats row
                Row(
                  children: [
                    Icon(
                      Icons.photo_library_outlined, // Changed for clarity
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text('${walk.publicArtIds.length} artworks'),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _shareArtWalk(walk),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
              ),
              TextButton.icon(
                onPressed: () async {
                  // Added async
                  await Navigator.push(
                    // Added await
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtWalkDetailScreen(walkId: walk.id),
                    ),
                  );
                  if (mounted) {
                    // Added mounted check
                    _loadArtWalks(); // Refresh after viewing details, in case of changes
                  }
                },
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View'),
              ),
              if (isMyWalk)
                TextButton.icon(
                  onPressed: () => _deleteArtWalk(walk),
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 18),
                  label:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

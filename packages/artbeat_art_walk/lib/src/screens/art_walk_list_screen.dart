import 'package:flutter/material.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:share_plus/share_plus.dart' as share_plus;

class ArtWalkListScreen extends StatefulWidget {
  const ArtWalkListScreen({super.key});

  @override
  State<ArtWalkListScreen> createState() => _ArtWalkListScreenState();
}

class _ArtWalkListScreenState extends State<ArtWalkListScreen>
    with SingleTickerProviderStateMixin {
  final ArtWalkService _artWalkService = ArtWalkService();
  bool _isLoading = true;

  List<ArtWalkModel> _myWalks = [];
  List<ArtWalkModel> _popularWalks = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadArtWalks();
  }

  @override
  void didUpdateWidget(covariant ArtWalkListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recreate TabController if length changed during hot reload
    if (_tabController.length != 2) {
      _tabController.dispose();
      _tabController = TabController(length: 2, vsync: this);
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
      await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          text: 'Check out this Art Walk: "${walk.title}" on ARTbeat!',
        ),
      );

      // Record the share
      await _artWalkService.recordArtWalkShare(walk.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing: ${e.toString()}')));
    }
  }

  Future<void> _editArtWalk(ArtWalkModel walk) async {
    final result = await Navigator.pushNamed(
      context,
      '/art-walk/edit',
      arguments: {'walkId': walk.id, 'artWalk': walk},
    );

    if (result == true && mounted) {
      _loadArtWalks(); // Refresh the list after editing
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Art walk deleted')));
      _loadArtWalks(); // Refresh the list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting art walk: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: EnhancedUniversalHeader(
          title: 'Art Walks',
          showLogo: false,
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFF4FB3BE), // Light Teal
              Color(0xFFFF9E80), // Light Orange/Peach
            ],
          ),
          titleGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFF4FB3BE), // Light Teal
              Color(0xFFFF9E80), // Light Orange/Peach
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadArtWalks,
            ),
          ],
        ),
        body: Column(
          children: [
            // Tab Bar
            Container(
              color: const Color(
                0xFF00838F,
              ), // Art Walk header color - matches Welcome Travel user box teal
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white, // Text/Icon color
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'My Walks'),
                  Tab(text: 'Popular'),
                ],
              ),
            ),
            // Tab Bar View
            Expanded(
              child: _isLoading
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
                                child: _buildWalksList(
                                  _myWalks,
                                  isMyWalks: true,
                                ),
                              ),
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
                                child: _buildWalksList(
                                  _popularWalks,
                                  isMyWalks: false,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
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
      ),
    );
  }

  Widget _buildEmptyState(String title, String description) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _tabController.index ==
                    0 // Only show on My Walks tab
                ? ElevatedButton.icon(
                    onPressed: () async {
                      // Added async
                      await Navigator.push(
                        // Added await
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const CreateArtWalkScreen(),
                        ),
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
    final String? imageUrl = walk.imageUrls.isNotEmpty
        ? walk.imageUrls.first
        : null;
    final bool hasValidImage =
        imageUrl != null &&
        imageUrl.isNotEmpty &&
        Uri.tryParse(imageUrl)?.hasScheme == true;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          hasValidImage
              ? Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(imageUrl) as ImageProvider,
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
                    child: Icon(Icons.map, size: 40, color: Colors.grey),
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
                  style: const TextStyle(fontSize: 14),
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
                    Text('${walk.artworkIds.length} artworks'),
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
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ArtWalkDetailScreen(walkId: walk.id),
                    ),
                  );
                  if (mounted) {
                    _loadArtWalks(); // Refresh after viewing details, in case of changes
                  }
                },
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View'),
              ),
              if (isMyWalk) ...[
                TextButton.icon(
                  onPressed: () => _editArtWalk(walk),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.blue,
                    size: 18,
                  ),
                  label: const Text(
                    'Edit',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _deleteArtWalk(walk),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 18,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

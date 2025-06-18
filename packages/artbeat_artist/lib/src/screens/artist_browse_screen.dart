import 'package:flutter/material.dart';
import 'package:artbeat_artist/artbeat_artist.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

/// Screen for browsing artists
class ArtistBrowseScreen extends StatefulWidget {
  const ArtistBrowseScreen({super.key});

  @override
  State<ArtistBrowseScreen> createState() => _ArtistBrowseScreenState();
}

class _ArtistBrowseScreenState extends State<ArtistBrowseScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isLoading = true;
  List<core.ArtistProfileModel> _artists = [];
  String _selectedMedium = 'All';
  String _selectedStyle = 'All';
  final TextEditingController _searchController = TextEditingController();

  // Filter options
  final List<String> _mediums = [
    'All',
    'Oil Paint',
    'Acrylic',
    'Watercolor',
    'Digital',
    'Mixed Media',
    'Photography'
  ];
  final List<String> _styles = [
    'All',
    'Abstract',
    'Realism',
    'Impressionism',
    'Pop Art',
    'Surrealism',
    'Contemporary'
  ];

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArtists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all artists with current filters
      final artists = await _subscriptionService.getAllArtists(
        searchQuery: _searchController.text,
        medium: _selectedMedium != 'All' ? _selectedMedium : null,
        style: _selectedStyle != 'All' ? _selectedStyle : null,
      );

      if (mounted) {
        setState(() {
          _artists = artists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading artists: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    _loadArtists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Artists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filter',
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search artists...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadArtists();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                if (value.isEmpty || value.length > 2) {
                  _loadArtists();
                }
              },
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                FilterChip(
                  label: Text('Medium: $_selectedMedium'),
                  selected: _selectedMedium != 'All',
                  onSelected: (_) => _showFilterDialog(),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Style: $_selectedStyle'),
                  selected: _selectedStyle != 'All',
                  onSelected: (_) => _showFilterDialog(),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _artists.isEmpty
                    ? const Center(child: Text('No artists found'))
                    : ListView.builder(
                        itemCount: _artists.length,
                        itemBuilder: (context, index) {
                          final artist = _artists[index];
                          return _buildArtistCard(artist);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCard(core.ArtistProfileModel artist) {
    final bool isPremium =
        artist.subscriptionTier != core.SubscriptionTier.free &&
            artist.subscriptionTier != core.SubscriptionTier.artistBasic;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isPremium ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPremium
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/artist/public-profile',
            arguments: {'artistProfileId': artist.id},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image and profile picture
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover image
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    image: DecorationImage(
                      image: artist.coverImageUrl != null &&
                              artist.coverImageUrl!.isNotEmpty
                          ? NetworkImage(artist.coverImageUrl!) as ImageProvider
                          : const AssetImage('assets/default_profile.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Profile picture
                Positioned(
                  bottom: -40,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: artist.profileImageUrl != null &&
                              artist.profileImageUrl!.isNotEmpty
                          ? NetworkImage(artist.profileImageUrl!)
                              as ImageProvider
                          : const AssetImage('assets/default_profile.png'),
                    ),
                  ),
                ),

                // Premium badge
                if (artist.subscriptionTier != core.SubscriptionTier.free &&
                    artist.subscriptionTier !=
                        core.SubscriptionTier.artistBasic)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: artist.subscriptionTier ==
                                core.SubscriptionTier.gallery
                            ? Colors.amber
                            : Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            artist.subscriptionTier ==
                                    core.SubscriptionTier.gallery
                                ? 'Gallery'
                                : 'Pro',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Verified badge
                if (artist.isVerified)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 45), // Space for profile pic

            // Artist info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          artist.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (artist.userType.name == core.UserType.gallery.name)
                        Chip(
                          label: const Text('Gallery'),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withAlpha(51),
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    artist.bio ?? 'No bio provided',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...artist.mediums.take(2).map((medium) => Chip(
                            label: Text(medium),
                            backgroundColor:
                                Theme.of(context).chipTheme.backgroundColor,
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          )),
                      if (artist.mediums.length > 2)
                        Chip(
                          label: Text('+${artist.mediums.length - 2}'),
                          backgroundColor:
                              Theme.of(context).chipTheme.backgroundColor,
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
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

  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        String tempMedium = _selectedMedium;
        String tempStyle = _selectedStyle;

        return AlertDialog(
          title: const Text('Filter Artists'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Medium',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _mediums.map((medium) {
                    return ChoiceChip(
                      label: Text(medium),
                      selected: tempMedium == medium,
                      onSelected: (selected) {
                        setState(() {
                          tempMedium = selected ? medium : 'All';
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Style',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _styles.map((style) {
                    return ChoiceChip(
                      label: Text(style),
                      selected: tempStyle == style,
                      onSelected: (selected) {
                        setState(() {
                          tempStyle = selected ? style : 'All';
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedMedium = tempMedium;
                  _selectedStyle = tempStyle;
                });
                Navigator.pop(context);
                _applyFilters();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}

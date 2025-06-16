import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_community/artbeat_community.dart' as community;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;

/// Screen for discovering users and artists on the platform
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final core.UserService _userService = core.UserService();
  final artist.SubscriptionService _artistSubscriptionService =
      artist.SubscriptionService();
  final core.SubscriptionService _subscriptionService =
      core.SubscriptionService();

  late TabController _tabController;

  List<core.UserModel> _searchResults = [];
  List<core.UserModel> _suggestedUsers = [];
  List<artist.ArtistProfileModel> _featuredArtists = []; // restored
  bool _isLoading = false;
  bool _isSearching = false;

  // Placeholder lists for nearby content
  final List<community.PostModel> _feedItems = [];
  final List<core.UserModel> _nearbyUsers = [];
  final List<artist.ArtistProfileModel> _nearbyArtists = [];
  final List<artwork.ArtworkModel> _nearbyArtworks = [];
  final List<core.EventModel> _nearbyEvents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSuggestedUsers();
    _loadFeaturedArtists();
    // TODO: Load nearby content lists (_feedItems, _nearbyUsers, etc.)
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestedUsers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _userService.getSuggestedUsers();
      if (!mounted) return;

      setState(() {
        _suggestedUsers = users;
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('Error loading suggested users: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load suggested users. You may be offline.'),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFeaturedArtists() async {
    try {
      final coreArtists = await _subscriptionService.getFeaturedArtists();
      if (!mounted) return;

      final artists = await Future.wait(coreArtists.map((a) async {
        final artistProfile =
            await _artistSubscriptionService.getArtistProfileById(a.id);
        if (artistProfile == null) {
          // Create a minimal artist profile from core model
          return artist.ArtistProfileModel(
            id: a.id,
            userId: a.userId,
            displayName: a.displayName,
            bio: a.bio ?? '',
            userType: core.UserType.artist,
            mediums: const [],
            styles: const [],
            subscriptionTier: a.subscriptionTier,
            createdAt: a.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return artistProfile;
      }));

      setState(() {
        _featuredArtists = artists.cast<artist.ArtistProfileModel>();
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('Error loading featured artists: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load featured artists. You may be offline.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _isSearching = true;
      });
    }

    try {
      final users = await _userService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = users;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar at the top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),

          // Tab bar for Users and Artists
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'People'),
              Tab(text: 'Artists'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
          ),

          // Art Walk Banner
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/art-walk/map'),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade300,
                    Colors.deepPurple.shade700
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.2).round()),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Art Walk',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Discover public art in your area or create your own custom art walks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.map_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                ],
              ),
            ),
          ),

          // Content area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // People tab
                _buildPeopleTab(),

                // Artists tab
                _buildArtistsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Display horizontal sliders for various nearby content
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Community feed slider placeholder
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Community Feed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: _feedItems.isEmpty
                ? const Center(child: Text('No feed items available'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _feedItems.length,
                    itemBuilder: (context, index) {
                      final item = _feedItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 200,
                          child: Center(child: Text(item.content)),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),
          // Users nearby slider placeholder
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Users Nearby',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: _nearbyUsers.isEmpty
                ? const Center(child: Text('No users nearby'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _nearbyUsers.length,
                    itemBuilder: (context, index) {
                      final user = _nearbyUsers[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            const CircleAvatar(radius: 30),
                            const SizedBox(height: 8),
                            Text(user.fullName),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),
          // Artists nearby slider placeholder
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Artists Nearby',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: _nearbyArtists.isEmpty
                ? const Center(child: Text('No artists nearby'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _nearbyArtists.length,
                    itemBuilder: (context, index) {
                      final artistProfile = _nearbyArtists[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            const CircleAvatar(radius: 30),
                            const SizedBox(height: 8),
                            Text(artistProfile.displayName),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),
          // Artwork nearby slider placeholder
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Artwork Nearby',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: _nearbyArtworks.isEmpty
                ? const Center(child: Text('No artwork nearby'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _nearbyArtworks.length,
                    itemBuilder: (context, index) {
                      final art = _nearbyArtworks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 140,
                          child: Center(child: Text(art.title)),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),
          // Events nearby slider placeholder
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Events Nearby',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: _nearbyEvents.isEmpty
                ? const Center(child: Text('No events nearby'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _nearbyEvents.length,
                    itemBuilder: (context, index) {
                      final event = _nearbyEvents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 180,
                          child: Center(child: Text(event.title)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Browse artists button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/artist/browse');
            },
            icon: const Icon(Icons.search),
            label: const Text('Browse All Artists'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),

        // Artist subscription card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Card(
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/artist/subscription');
              },
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Are you an artist?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Icon(
                          Icons.palette,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your artist profile and showcase your work to art enthusiasts worldwide.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/artist/subscription');
                      },
                      child: const Text('Learn More'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Featured artists section
        const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Text(
            'Featured Artists',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Featured artists list
        Expanded(
          child: _featuredArtists.isEmpty
              ? const Center(child: Text('No featured artists available'))
              : ListView.builder(
                  itemCount: _featuredArtists.length,
                  itemBuilder: (context, index) {
                    final artist = _featuredArtists[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (artist.profileImageUrl?.isNotEmpty ??
                                false)
                            ? NetworkImage(artist.profileImageUrl!)
                                as ImageProvider
                            : const AssetImage('assets/default_profile.png'),
                      ),
                      title: Text(artist.displayName),
                      subtitle: Text(artist.styles.isNotEmpty
                          ? artist.styles.first
                          : artist.mediums.isNotEmpty
                              ? artist.mediums.first
                              : 'Artist'),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/artist/public-profile',
                          arguments: {'artistProfileId': artist.id},
                        );
                      },
                      trailing: ElevatedButton(
                        onPressed: () async {
                          try {
                            // Replace with your actual logic to check if following
                            final isCurrentlyFollowing =
                                await _artistSubscriptionService
                                    .isFollowingArtist(
                                        artistProfileId: artist.id);

                            if (isCurrentlyFollowing) {
                              await _artistSubscriptionService.unfollowArtist(
                                  artistProfileId: artist.id);
                            } else {
                              await _artistSubscriptionService.followArtist(
                                  artistProfileId: artist.id);
                            }

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isCurrentlyFollowing
                                      ? 'You have unfollowed ${artist.displayName}'
                                      : 'You are now following ${artist.displayName}',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        child: const Text('Follow'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

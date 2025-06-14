import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_artist/artbeat_artist.dart' as artist;

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
  List<artist.ArtistProfileModel> _featuredArtists = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSuggestedUsers();
    _loadFeaturedArtists();
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

          // NC Regions Banner
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/explore/nc-regions'),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade300, Colors.green.shade700],
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
                          'NC Art Regions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Explore art and artists from different North Carolina regions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.explore_outlined,
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

    if (_isSearching && _searchResults.isEmpty) {
      return const Center(child: Text('No users found'));
    }

    final usersToDisplay = _isSearching ? _searchResults : _suggestedUsers;

    if (usersToDisplay.isEmpty) {
      return const Center(child: Text('No suggested users available'));
    }

    return ListView.builder(
      itemCount: usersToDisplay.length,
      itemBuilder: (context, index) {
        final user = usersToDisplay[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: (user.profileImageUrl?.isNotEmpty ?? false)
                ? NetworkImage(user.profileImageUrl!) as ImageProvider
                : const AssetImage('assets/default_profile.png'),
          ),
          title: Text(
              user.fullName.isNotEmpty ? user.fullName : (user.username ?? '')),
          subtitle: Text(user.username ?? ''),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/profile/view',
              arguments: {'userId': user.id, 'isCurrentUser': false},
            );
          },
          trailing: IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              // Implement follow functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Follow ${user.username} functionality coming soon!')),
              );
            },
          ),
        );
      },
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

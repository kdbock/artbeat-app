import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_community/artbeat_community.dart' as community;
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Screen for discovering users and artists on the platform
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  final artist.SubscriptionService _artistSubscriptionService =
      artist.SubscriptionService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  late TabController _tabController;

  // Search and loading state
  final List<UserModel> _searchResults = <UserModel>[];
  List<ArtistProfileModel> _featuredArtists = <ArtistProfileModel>[];
  bool _isLoading = false;

  // Nearby content state
  final List<community.PostModel> _feedItems = <community.PostModel>[];
  final List<UserModel> _nearbyUsers = <UserModel>[];
  final List<ArtistProfileModel> _nearbyArtists = <ArtistProfileModel>[];
  final List<artwork.ArtworkModel> _nearbyArtworks = <artwork.ArtworkModel>[];
  final List<EventModel> _nearbyEvents = <EventModel>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialContent();
  }

  Future<void> _loadInitialContent() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadSuggestedUsers(),
        _loadFeaturedArtists(),
        _loadNearbyContent(),
      ]);
    } catch (e) {
      debugPrint('Error loading initial content: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNearbyContent() async {
    try {
      // Save current location for caching
      final position = await Geolocator.getCurrentPosition();
      final point = GeoPoint(position.latitude, position.longitude);

      // Load nearby content in parallel
      await Future.wait([
        _loadNearbyUsers(point),
        _loadNearbyArtists(point),
        _loadNearbyArtworks(point),
        _loadNearbyEvents(point),
        _loadNearbyPosts(point),
      ]);
    } catch (e) {
      debugPrint('Error loading nearby content: $e');
    }
  }

  Future<List<UserModel>> _loadNearbyUsers(GeoPoint location) async {
    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      final snapshot = await usersRef.orderBy('location').limit(50).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          id: doc.id,
          email: data['email'] as String? ?? '',
          username: data['username'] as String? ?? '',
          fullName: data['fullName'] as String? ?? '',
          bio: data['bio'] as String? ?? '',
          profileImageUrl: data['profileImageUrl'] as String? ?? '',
          location: data['location'] as String? ?? '',
          posts: List<String>.from(
            (data['posts'] ?? <dynamic>[]) as List<dynamic>,
          ),
          followers: List<String>.from(
            (data['followers'] ?? <dynamic>[]) as List<dynamic>,
          ),
          following: List<String>.from(
            (data['following'] ?? <dynamic>[]) as List<dynamic>,
          ),
          captures: (data['captures'] as List<dynamic>? ?? [])
              .map((capture) => CaptureModel.fromJson(capture as Map<String, dynamic>))
              .toList(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          lastActive: data['lastActive'] != null
              ? (data['lastActive'] as Timestamp).toDate()
              : null,
          userType: data['userType'] as String?,
          preferences: data['preferences'] as Map<String, dynamic>?,
          experiencePoints: data['experiencePoints'] as int? ?? 0,
          level: data['level'] as int? ?? 1,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading nearby users: $e');
      return [];
    }
  }

  Future<List<ArtistProfileModel>> _loadNearbyArtists(GeoPoint location) async {
    try {
      final artistsRef = FirebaseFirestore.instance.collection(
        'artistProfiles',
      );
      final snapshot = await artistsRef.orderBy('location').limit(50).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ArtistProfileModel(
          id: doc.id,
          userId: data['userId'] as String,
          displayName: data['displayName'] as String,
          bio: data['bio'] as String,
          userType: UserType.artist,
          location: data['location'] as String?,
          mediums: List<String>.from(
            (data['mediums'] ?? <dynamic>[]) as List<dynamic>,
          ),
          styles: List<String>.from(
            (data['styles'] ?? <dynamic>[]) as List<dynamic>,
          ),
          profileImageUrl: data['profileImageUrl'] as String?,
          coverImageUrl: data['coverImageUrl'] as String?,
          socialLinks: Map<String, String>.from(
            (data['socialLinks'] ?? <dynamic, dynamic>{})
                as Map<dynamic, dynamic>,
          ),
          isVerified: data['isVerified'] as bool? ?? false,
          isFeatured: data['isFeatured'] as bool? ?? false,
          subscriptionTier: _getTierFromString(
            data['subscriptionTier'] as String? ?? 'artistBasic',
          ),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading nearby artists: $e');
      return [];
    }
  }

  SubscriptionTier _getTierFromString(String tierString) {
    return SubscriptionTier.values.firstWhere(
      (t) => t.name == tierString,
      orElse: () => SubscriptionTier.artistBasic,
    );
  }

  Future<List<artwork.ArtworkModel>> _loadNearbyArtworks(
    GeoPoint location,
  ) async {
    try {
      final artworksRef = FirebaseFirestore.instance.collection('artworks');
      final snapshot = await artworksRef
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final locationData = data['location'] as GeoPoint?;
        return artwork.ArtworkModel(
          id: doc.id,
          userId: data['userId'] as String,
          artistProfileId: data['artistProfileId'] as String,
          title: data['title'] as String,
          description: data['description'] as String,
          imageUrl: data['imageUrl'] as String,
          medium: data['medium'] as String,
          styles: List<String>.from(
            (data['styles'] ?? <dynamic>[]) as List<dynamic>,
          ),
          location: locationData != null
              ? '${locationData.latitude}, ${locationData.longitude}'
              : null,
          isForSale: data['isForSale'] as bool? ?? false,
          isSold: data['isSold'] as bool? ?? false,
          price: (data['price'] as num?)?.toDouble(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading nearby artworks: $e');
      return [];
    }
  }

  Future<List<EventModel>> _loadNearbyEvents(GeoPoint point) async {
    try {
      final eventsRef = FirebaseFirestore.instance.collection('events');
      final snapshot = await eventsRef
          .where('location', isNull: false)
          .where('endDate', isGreaterThan: DateTime.now())
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EventModel(
          id: doc.id,
          title: data['title'] as String,
          description: data['description'] as String,
          startDate: (data['startDate'] as Timestamp).toDate(),
          endDate: data['endDate'] != null
              ? (data['endDate'] as Timestamp).toDate()
              : null,
          location: data['location'] as String,
          imageUrl: data['imageUrl'] as String?,
          artistId: data['artistId'] as String,
          isPublic: data['isPublic'] as bool? ?? true,
          attendeeIds: List<String>.from(
            (data['attendeeIds'] ?? <dynamic>[]) as List<dynamic>,
          ),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading nearby events: $e');
      return [];
    }
  }

  Future<List<community.PostModel>> _loadNearbyPosts(GeoPoint location) async {
    try {
      final postsRef = FirebaseFirestore.instance.collection('posts');
      final snapshot = await postsRef
          .where('location', isNull: false)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final posts = snapshot.docs.map((doc) {
        final data = doc.data();
        return community.PostModel(
          id: doc.id,
          userId: data['userId'] as String,
          userName: data['userName'] as String,
          userPhotoUrl: data['userPhotoUrl'] as String? ?? '',
          content: data['content'] as String,
          imageUrls: List<String>.from(
            (data['imageUrls'] ?? <dynamic>[]) as List<dynamic>,
          ),
          tags: List<String>.from(
            (data['tags'] ?? <dynamic>[]) as List<dynamic>,
          ),
          location: data['location'] as String,
          geoPoint: data['geoPoint'] as GeoPoint?,
          zipCode: data['zipCode'] as String?,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          applauseCount: (data['applauseCount'] as num?)?.toInt() ?? 0,
          commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
          shareCount: (data['shareCount'] as num?)?.toInt() ?? 0,
          isPublic: data['isPublic'] as bool? ?? true,
          mentionedUsers: data['mentionedUsers'] != null
              ? List<String>.from(
                  (data['mentionedUsers'] ?? <dynamic>[]) as List<dynamic>,
                )
              : null,
          metadata: data['metadata'] as Map<String, dynamic>?,
          isUserVerified: data['isUserVerified'] as bool? ?? false,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _feedItems.clear();
          _feedItems.addAll(posts);
        });
      }

      return posts;
    } catch (e) {
      debugPrint('Error loading nearby posts: $e');
      return [];
    }
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
        _searchResults.clear();
        _searchResults.addAll(users);
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

      final artists = await Future.wait(
        coreArtists.map((a) async {
          final artistProfile = await _artistSubscriptionService
              .getArtistProfileById(a.id);
          if (artistProfile == null) {
            // Create a minimal artist profile from core model
            return ArtistProfileModel(
              id: a.id,
              userId: a.userId,
              displayName: a.displayName,
              bio: a.bio ?? '',
              userType: UserType.artist,
              mediums: const <String>[],
              styles: const <String>[],
              subscriptionTier: a.subscriptionTier,
              createdAt: a.createdAt,
              updatedAt: DateTime.now(),
            );
          }
          return artistProfile;
        }),
      );

      setState(() {
        _featuredArtists = artists.cast<ArtistProfileModel>();
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
        _searchResults.clear();
        _isLoading = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final users = await _userService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _searchResults.addAll(users);
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
                    Colors.deepPurple.shade700,
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
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.map_outlined, color: Colors.white, size: 40),
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
            child: Text(
              'Community Feed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
            child: Text(
              'Users Nearby',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
            child: Text(
              'Artists Nearby',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
            child: Text(
              'Artwork Nearby',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
            child: Text(
              'Events Nearby',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      leading: UserAvatar(
                        imageUrl: artist.profileImageUrl,
                        displayName: artist.displayName,
                        radius: 20,
                      ),
                      title: Text(artist.displayName),
                      subtitle: Text(
                        artist.styles.isNotEmpty
                            ? artist.styles.first
                            : artist.mediums.isNotEmpty
                            ? artist.mediums.first
                            : 'Artist',
                      ),
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
                                      artistProfileId: artist.id,
                                    );

                            if (isCurrentlyFollowing) {
                              await _artistSubscriptionService.unfollowArtist(
                                artistProfileId: artist.id,
                              );
                            } else {
                              await _artistSubscriptionService.followArtist(
                                artistProfileId: artist.id,
                              );
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

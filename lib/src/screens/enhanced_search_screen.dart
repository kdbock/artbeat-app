import 'dart:async';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/navigation_service.dart';
import '../services/route_analytics_service.dart';

/// Enhanced search screen with multiple search categories
class EnhancedSearchScreen extends StatefulWidget {
  const EnhancedSearchScreen({super.key});

  @override
  State<EnhancedSearchScreen> createState() => _EnhancedSearchScreenState();
}

class _EnhancedSearchScreenState extends State<EnhancedSearchScreen>
    with RouteAnalyticsMixin {
  final TextEditingController _searchController = TextEditingController();
  SearchCategory _selectedCategory = SearchCategory.all;
  final List<String> _recentSearches = [];
  bool _isLoading = false;

  // Search results
  List<SearchResult> _searchResults = [];
  String _currentQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    trackRouteVisit('/search', source: 'fluid_dashboard');

    // Handle initial query from route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final initialQuery = args?['query'] as String?;
      if (initialQuery != null && initialQuery.isNotEmpty) {
        _searchController.text = initialQuery;
        _performSearch(initialQuery);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _debouncedSearch(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) => core.MainLayout(
    currentIndex: 1, // Search tab index
    appBar: core.EnhancedUniversalHeader(
      title: 'Search',
      showLogo: false,
      showSearch: false, // Don't show search button in search screen
      showBackButton: false,
      backgroundColor: Colors.white,
      foregroundColor: core.ArtbeatColors.textPrimary,
      elevation: 1,
    ),
    child: Column(
      children: [
        _buildSearchHeader(),
        _buildSearchCategories(),
        Expanded(
          child: _searchController.text.isEmpty
              ? _buildSearchSuggestions()
              : _buildSearchResults(),
        ),
      ],
    ),
  );

  Widget _buildSearchHeader() => Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        // Search bar
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search ${_selectedCategory.displayName}...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {});
              _debouncedSearch(value);
            },
          ),
        ),
        if (_isLoading) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
        ],
      ],
    ),
  );

  Widget _buildSearchCategories() => Container(
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: SearchCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
            trackNavigationSource('/search', 'category_${category.name}');

            // Re-run search with new category if there's a current query
            if (_currentQuery.isNotEmpty) {
              _performSearch(_currentQuery);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? core.ArtbeatColors.primaryPurple
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                category.displayName,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );

  Widget _buildSearchSuggestions() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick actions
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildQuickActionGrid(),

        const SizedBox(height: 32),

        // Recent searches
        if (_recentSearches.isNotEmpty) ...[
          const Text(
            'Recent Searches',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._recentSearches.map(_buildRecentSearchItem),
        ],

        // Popular searches
        const Text(
          'Popular Searches',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildPopularSearches(),
      ],
    ),
  );

  Widget _buildQuickActionGrid() {
    final quickActions = [
      QuickAction(
        icon: Icons.palette,
        title: 'Browse Art',
        subtitle: 'Discover artwork',
        onTap: () => context.safeNavigate('/artwork/featured'),
      ),
      QuickAction(
        icon: Icons.people,
        title: 'Find Artists',
        subtitle: 'Connect with artists',
        onTap: () => context.safeNavigate('/artist/search'),
      ),
      QuickAction(
        icon: Icons.map,
        title: 'Art Walks',
        subtitle: 'Explore locations',
        onTap: () => context.safeNavigate('/art-walk/map'),
      ),
      QuickAction(
        icon: Icons.event,
        title: 'Events',
        subtitle: 'Find events',
        onTap: () => context.safeNavigate('/events'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: quickActions.length,
      itemBuilder: (context, index) {
        final action = quickActions[index];
        return GestureDetector(
          onTap: action.onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  action.icon,
                  size: 32,
                  color: core.ArtbeatColors.primaryPurple,
                ),
                const SizedBox(height: 8),
                Text(
                  action.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action.subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentSearchItem(String search) => ListTile(
    leading: const Icon(Icons.history),
    title: Text(search),
    trailing: IconButton(
      icon: const Icon(Icons.close),
      onPressed: () {
        setState(() {
          _recentSearches.remove(search);
        });
      },
    ),
    onTap: () {
      _searchController.text = search;
      _performSearch(search);
    },
  );

  Widget _buildPopularSearches() {
    final popularSearches = [
      'abstract art',
      'local artists',
      'sculptures',
      'street art',
      'digital art',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: popularSearches
          .map(
            (search) => GestureDetector(
              onTap: () {
                _searchController.text = search;
                _performSearch(search);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(search),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching...'),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _currentQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Results Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No results found for "$_currentQuery"',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildSearchResultItem(result);
      },
    );
  }

  Widget _buildSearchResultItem(SearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildResultIcon(result),
        title: Text(
          result.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: result.subtitle.isNotEmpty ? Text(result.subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _handleResultTap(result),
      ),
    );
  }

  Widget _buildResultIcon(SearchResult result) {
    if (result.imageUrl != null && result.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          result.imageUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _getDefaultIcon(result.type),
        ),
      );
    }
    return _getDefaultIcon(result.type);
  }

  Widget _getDefaultIcon(SearchResultType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case SearchResultType.artist:
        iconData = Icons.person;
        color = Colors.blue;
        break;
      case SearchResultType.artwork:
        iconData = Icons.palette;
        color = Colors.purple;
        break;
      case SearchResultType.event:
        iconData = Icons.event;
        color = Colors.orange;
        break;
      case SearchResultType.artWalk:
        iconData = Icons.directions_walk;
        color = Colors.green;
        break;
      case SearchResultType.location:
        iconData = Icons.location_on;
        color = Colors.red;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(iconData, color: color),
    );
  }

  void _handleResultTap(SearchResult result) {
    switch (result.type) {
      case SearchResultType.artist:
        // Navigate to artist profile
        Navigator.pushNamed(
          context,
          '/profile',
          arguments: {'userId': result.id},
        );
        break;
      case SearchResultType.artwork:
        // Navigate to artwork detail
        Navigator.pushNamed(
          context,
          '/artwork/detail',
          arguments: {'artworkId': result.id},
        );
        break;
      case SearchResultType.event:
        // Navigate to event detail
        Navigator.pushNamed(
          context,
          '/events/detail',
          arguments: {'eventId': result.id},
        );
        break;
      case SearchResultType.artWalk:
        // Navigate to art walk detail
        Navigator.pushNamed(
          context,
          '/art-walk/detail',
          arguments: {'artWalkId': result.id},
        );
        break;
      case SearchResultType.location:
        // Handle location tap
        break;
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _currentQuery = query;
    });

    // Add to recent searches
    if (!_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    }

    // Track search
    trackNavigationSource('/search', 'search_query');

    try {
      final results = await _searchDatabase(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    }
  }

  Future<List<SearchResult>> _searchDatabase(String query) async {
    final List<SearchResult> results = [];
    final lowerQuery = query.toLowerCase();

    try {
      // Search users/artists
      if (_selectedCategory == SearchCategory.all ||
          _selectedCategory == SearchCategory.artists) {
        // Get all users and filter client-side for better search results
        final usersQuery = await FirebaseFirestore.instance
            .collection('users')
            .limit(100) // Get more users to search through
            .get();

        for (final doc in usersQuery.docs) {
          final data = doc.data();
          final fullName = data['fullName'] as String? ?? '';
          final username = data['username'] as String? ?? '';
          final profileImageUrl = data['profileImageUrl'] as String?;

          // Check if query matches any part of the full name or username
          final fullNameLower = fullName.toLowerCase();
          final usernameLower = username.toLowerCase();

          bool matches = false;

          // Check for exact word matches (like "Kelly" in "Kristy Kelly")
          if (fullNameLower.contains(lowerQuery) ||
              usernameLower.contains(lowerQuery)) {
            matches = true;
          }

          // Check for word boundary matches
          final queryWords = lowerQuery.split(' ');
          final nameWords = fullNameLower.split(' ');

          for (final queryWord in queryWords) {
            if (queryWord.isNotEmpty) {
              for (final nameWord in nameWords) {
                if (nameWord.startsWith(queryWord) ||
                    nameWord.contains(queryWord)) {
                  matches = true;
                  break;
                }
              }
              if (matches) break;
            }
          }

          if (matches) {
            results.add(
              SearchResult(
                id: doc.id,
                title: fullName.isNotEmpty ? fullName : username,
                subtitle: username.isNotEmpty ? '@$username' : '',
                imageUrl: profileImageUrl,
                type: SearchResultType.artist,
                data: data,
              ),
            );
          }
        }
      }

      // Search artwork/captures
      if (_selectedCategory == SearchCategory.all ||
          _selectedCategory == SearchCategory.artwork) {
        final capturesQuery = await FirebaseFirestore.instance
            .collection('captures')
            .where('title', isGreaterThanOrEqualTo: query)
            .where('title', isLessThanOrEqualTo: '$query\uf8ff')
            .limit(10)
            .get();

        for (final doc in capturesQuery.docs) {
          final data = doc.data();
          results.add(
            SearchResult(
              id: doc.id,
              title: data['title'] as String? ?? 'Untitled',
              subtitle: data['artistName'] as String? ?? 'Unknown Artist',
              imageUrl: data['imageUrl'] as String?,
              type: SearchResultType.artwork,
              data: data,
            ),
          );
        }
      }

      // Search events
      if (_selectedCategory == SearchCategory.all ||
          _selectedCategory == SearchCategory.events) {
        final eventsQuery = await FirebaseFirestore.instance
            .collection('events')
            .where('title', isGreaterThanOrEqualTo: query)
            .where('title', isLessThanOrEqualTo: '$query\uf8ff')
            .limit(10)
            .get();

        for (final doc in eventsQuery.docs) {
          final data = doc.data();
          results.add(
            SearchResult(
              id: doc.id,
              title: data['title'] as String? ?? 'Untitled Event',
              subtitle: data['description'] as String? ?? '',
              imageUrl: data['imageUrl'] as String?,
              type: SearchResultType.event,
              data: data,
            ),
          );
        }
      }
    } catch (e) {
      print('Search error: $e');
    }

    return results;
  }
}

enum SearchCategory {
  all,
  artists,
  artwork,
  events,
  artWalks,
  locations;

  String get displayName {
    switch (this) {
      case SearchCategory.all:
        return 'All';
      case SearchCategory.artists:
        return 'Artists';
      case SearchCategory.artwork:
        return 'Artwork';
      case SearchCategory.events:
        return 'Events';
      case SearchCategory.artWalks:
        return 'Art Walks';
      case SearchCategory.locations:
        return 'Locations';
    }
  }
}

/// Search result model
class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final SearchResultType type;
  final Map<String, dynamic> data;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.type,
    required this.data,
  });
}

/// Search result types
enum SearchResultType { artist, artwork, event, artWalk, location }

class QuickAction {
  QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
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

  @override
  void initState() {
    super.initState();
    trackRouteVisit('/search', source: 'fluid_dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchHeader(),
        _buildSearchCategories(),
        Expanded(
          child: _searchController.text.isEmpty
              ? _buildSearchSuggestions()
              : _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          Container(
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
                _performSearch(value);
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
  }

  Widget _buildSearchCategories() {
    return Container(
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
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
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
            ..._recentSearches.map((search) => _buildRecentSearchItem(search)),
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
  }

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

  Widget _buildRecentSearchItem(String search) {
    return ListTile(
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
  }

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
      children: popularSearches.map((search) {
        return GestureDetector(
          onTap: () {
            _searchController.text = search;
            _performSearch(search);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(search),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchResults() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Search Results',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Search functionality will be implemented here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
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

    // Simulate search delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
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

class QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

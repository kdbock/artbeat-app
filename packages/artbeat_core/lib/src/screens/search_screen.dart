import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Universal Search Screen for ARTbeat
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0, // Home index for bottom nav
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 4),
          child: ArtbeatGradientBackground(
            addShadow: true,
            child: EnhancedUniversalHeader(
              title: 'Search',
              showLogo: false,
              showSearch: false,
              showDeveloperTools: false,
              onSearchPressed: null,
              onProfilePressed: () => Navigator.pushNamed(context, '/profile'),
              onMenuPressed: () => Navigator.pushNamed(context, '/menu'),
              backgroundColor: Colors.transparent,
              foregroundColor: ArtbeatColors.textPrimary,
              elevation: 0,
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE3F2FD),
                Color(0xFFF8FBFF),
                Color(0xFFE1F5FE),
                Color(0xFFBBDEFB),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search artists, artwork, events...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _query = value.trim();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _query.isEmpty
                      ? _buildEmptyState()
                      : _buildSearchResults(_query),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 48, color: ArtbeatColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'Start typing to search',
            style: TextStyle(fontSize: 16, color: ArtbeatColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(String query) {
    // Placeholder for search results
    // Replace with actual search logic and result widgets
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(
              Icons.person,
              color: ArtbeatColors.primaryPurple,
            ),
            title: Text('Result ${index + 1} for "$query"'),
            subtitle: const Text('Type: Artist/Artwork/Event'),
            onTap: () {},
          ),
        );
      },
    );
  }
}

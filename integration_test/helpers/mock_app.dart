import 'package:flutter/material.dart';
import 'package:artbeat_core/src/widgets/filter/search_bar_with_filter.dart';
import 'package:artbeat_core/src/models/filter_types.dart';
import 'package:artbeat_core/src/services/search/search_cache.dart';
import 'package:artbeat_core/src/services/search/search_history.dart';

class MockSearchApp extends StatefulWidget {
  const MockSearchApp({super.key});

  @override
  State<MockSearchApp> createState() => _MockSearchAppState();
}

class _MockSearchAppState extends State<MockSearchApp> {
  final SearchCache _cache = SearchCache();
  final SearchHistory _history = SearchHistory();

  void _handleSearch(String query) async {
    // Generate mock results
    final results = List.generate(
      5,
      (index) => {
        'id': 'test_$index',
        'title': 'Test Result $index',
        'type': index % 2 == 0 ? 'Artist' : 'Artwork',
      },
    );

    // Cache the results
    final key = _cache.generateCacheKey(query, {});
    _cache.cacheResults(key: key, results: results);

    // Add to history
    await _history.addSearch(query: query, filters: {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ARTbeat Search'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
          ],
        ),
        body: SearchBarWithFilter(
          searchHint: 'Search...',
          initialFilters: const FilterParameters(),
          onSearchChanged: _handleSearch,
          onFiltersChanged: (filters) {
            // Handle filter changes
          },
          showArtistTypes: true,
          showArtMediums: true,
        ),
      ),
    );
  }
}

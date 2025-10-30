import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/known_entity_model.dart';
import '../repositories/known_entity_repository.dart';
import '../services/search/search_history.dart';

/// Search state enum
enum SearchStatus { idle, loading, error }

/// Search sort options
enum SearchSortOption { relevant, recent, popular }

/// Unified search controller using Provider pattern
class SearchController extends ChangeNotifier {
  final KnownEntityRepository _repository;
  Timer? _debounceTimer;

  // State fields
  String _query = '';
  SearchStatus _status = SearchStatus.idle;
  List<KnownEntity> _results = [];
  String _errorMessage = '';

  // Filter fields
  final Set<KnownEntityType> _selectedFilters = {};
  SearchSortOption _sortOption = SearchSortOption.relevant;

  // Getters
  String get query => _query;
  SearchStatus get status => _status;
  List<KnownEntity> get results => _getFilteredAndSortedResults();
  String get errorMessage => _errorMessage;
  bool get isLoading => _status == SearchStatus.loading;
  bool get hasError => _status == SearchStatus.error;
  bool get hasResults => _results.isNotEmpty;
  bool get isEmpty => _results.isEmpty && _status != SearchStatus.loading;

  // Filter and sort getters
  Set<KnownEntityType> get selectedFilters => _selectedFilters;
  SearchSortOption get sortOption => _sortOption;
  bool get hasActiveFilters => _selectedFilters.isNotEmpty;

  SearchController({KnownEntityRepository? repository})
    : _repository = repository ?? KnownEntityRepository();

  /// Update search query with debounce
  void updateQuery(String newQuery) {
    final trimmedQuery = newQuery.trim();

    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Update query immediately for UI responsiveness
    _query = trimmedQuery;
    notifyListeners();

    // Clear results if query is empty
    if (trimmedQuery.isEmpty) {
      _clearResults();
      return;
    }

    // Debounce search execution by 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(trimmedQuery);
    });
  }

  /// Perform search immediately without debounce
  Future<void> search(String query) async {
    _debounceTimer?.cancel();
    _query = query.trim();

    if (_query.isEmpty) {
      _clearResults();
      return;
    }

    await _performSearch(_query);
  }

  /// Execute the actual search
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    try {
      _status = SearchStatus.loading;
      _errorMessage = '';
      notifyListeners();

      debugPrint('🔍 SearchController: Searching for "$query"');

      final results = await _repository.search(query);

      _status = SearchStatus.idle;
      _results = results;

      // Save search to history
      await SearchHistory().addSearch(query: query, filters: {});

      debugPrint('🎯 SearchController: Found ${results.length} results');
    } catch (error, stackTrace) {
      _status = SearchStatus.error;
      _errorMessage = error.toString();
      _results = [];

      debugPrint('❌ SearchController: Search error: $error');
      if (kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
    }

    notifyListeners();
  }

  /// Clear search results and query
  void clear() {
    _debounceTimer?.cancel();
    _query = '';
    _clearResults();
  }

  /// Clear only results, keeping query
  void _clearResults() {
    _status = SearchStatus.idle;
    _results = [];
    _errorMessage = '';
    notifyListeners();
  }

  /// Retry last search
  Future<void> retry() async {
    if (_query.isNotEmpty) {
      await _performSearch(_query);
    }
  }

  /// Get results by type
  List<KnownEntity> getResultsByType(KnownEntityType type) {
    return _results.where((entity) => entity.type == type).toList();
  }

  /// Get results count by type
  Map<KnownEntityType, int> getResultsCountByType() {
    final counts = <KnownEntityType, int>{};

    for (final entity in _results) {
      counts[entity.type] = (counts[entity.type] ?? 0) + 1;
    }

    return counts;
  }

  /// Check if has results of specific type
  bool hasResultsOfType(KnownEntityType type) {
    return _results.any((entity) => entity.type == type);
  }

  /// Toggle filter for a specific entity type
  void toggleFilter(KnownEntityType type) {
    if (_selectedFilters.contains(type)) {
      _selectedFilters.remove(type);
    } else {
      _selectedFilters.add(type);
    }
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedFilters.clear();
    notifyListeners();
  }

  /// Update sort option
  void setSortOption(SearchSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  /// Get filtered and sorted results
  List<KnownEntity> _getFilteredAndSortedResults() {
    List<KnownEntity> filtered = _results;

    // Apply type filters if any are selected
    if (_selectedFilters.isNotEmpty) {
      filtered = filtered
          .where((entity) => _selectedFilters.contains(entity.type))
          .toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case SearchSortOption.recent:
        filtered.sort((a, b) {
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
      case SearchSortOption.popular:
        // In a real app, this would be based on likes/views/engagement
        // For now, we'll sort by type (content-based popularity)
        filtered.sort((a, b) => b.type.index.compareTo(a.type.index));
        break;
      case SearchSortOption.relevant:
        // Already sorted by relevance from repository
        break;
    }

    return filtered;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

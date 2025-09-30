import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/known_entity_model.dart';
import '../repositories/known_entity_repository.dart';

/// Search state enum
enum SearchStatus { idle, loading, error }

/// Unified search controller using Provider pattern
class SearchController extends ChangeNotifier {
  final KnownEntityRepository _repository;
  Timer? _debounceTimer;

  // State fields
  String _query = '';
  SearchStatus _status = SearchStatus.idle;
  List<KnownEntity> _results = [];
  String _errorMessage = '';

  // Getters
  String get query => _query;
  SearchStatus get status => _status;
  List<KnownEntity> get results => _results;
  String get errorMessage => _errorMessage;
  bool get isLoading => _status == SearchStatus.loading;
  bool get hasError => _status == SearchStatus.error;
  bool get hasResults => _results.isNotEmpty;
  bool get isEmpty => _results.isEmpty && _status != SearchStatus.loading;

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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

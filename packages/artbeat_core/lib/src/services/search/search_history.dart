import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchHistory {
  static final SearchHistory _instance = SearchHistory._internal();
  factory SearchHistory() => _instance;
  SearchHistory._internal();

  static const String _prefsKey = 'search_history';
  static const int _maxHistoryItems = 20;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<void> addSearch({
    required String query,
    required Map<String, dynamic> filters,
  }) async {
    final prefs = await _prefs;
    final history = await getSearchHistory();

    final searchEntry = {
      'query': query,
      'filters': filters,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Add to start of list and remove duplicates
    history.removeWhere((item) => item['query'] == query);
    history.insert(0, searchEntry);

    // Limit history size
    if (history.length > _maxHistoryItems) {
      history.removeLast();
    }

    await prefs.setString(_prefsKey, jsonEncode(history));
  }

  Future<List<Map<String, dynamic>>> getSearchHistory() async {
    final prefs = await _prefs;
    final String? historyJson = prefs.getString(_prefsKey);
    if (historyJson == null) return [];

    final List<dynamic> decoded = jsonDecode(historyJson);
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> clearHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_prefsKey);
  }

  Future<void> removeSearchItem(String query) async {
    final prefs = await _prefs;
    final history = await getSearchHistory();

    history.removeWhere((item) => item['query'] == query);
    await prefs.setString(_prefsKey, jsonEncode(history));
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_prefsKey);
  }
}

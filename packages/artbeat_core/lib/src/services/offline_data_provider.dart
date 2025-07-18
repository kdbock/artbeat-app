import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Utility class for managing offline data storage (simplified)
class OfflineDataProvider {
  static final OfflineDataProvider _instance = OfflineDataProvider._internal();
  factory OfflineDataProvider() => _instance;

  OfflineDataProvider._internal();

  // This would normally use SharedPreferences, but we'll use an in-memory solution for simplicity
  final Map<String, dynamic> _cache = {};

  /// Initialize the offline data provider
  Future<void> init() async {
    try {
      // This would normally initialize SharedPreferences
      debugPrint('✅ Offline data provider initialized');
    } catch (e) {
      debugPrint('❌ Error initializing offline data provider: $e');
    }
  }

  /// Save data to cache
  Future<bool> saveData(String key, dynamic value) async {
    try {
      if (value is String || value is bool || value is int || value is double) {
        _cache[key] = value;
      } else {
        _cache[key] = jsonEncode(value);
      }
      debugPrint('✅ Saved data to key: $key');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving data for key $key: $e');
      return false;
    }
  }

  /// Get data from cache
  T? getData<T>(String key, {T? defaultValue}) {
    try {
      if (!_cache.containsKey(key)) {
        return defaultValue;
      }

      final value = _cache[key];

      if (value is T) {
        return value;
      }

      if (T == List || T == Map) {
        return jsonDecode(value as String) as T?;
      }

      return defaultValue;
    } catch (e) {
      debugPrint('❌ Error getting data for key $key: $e');
      return defaultValue;
    }
  }

  /// Remove data from cache
  Future<bool> removeData(String key) async {
    try {
      _cache.remove(key);
      debugPrint('✅ Removed data for key: $key');
      return true;
    } catch (e) {
      debugPrint('❌ Error removing data for key $key: $e');
      return false;
    }
  }

  /// Clear all data from cache
  Future<bool> clearAll() async {
    try {
      _cache.clear();
      debugPrint('✅ Cleared all cache data');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing cache data: $e');
      return false;
    }
  }

  /// Check if key exists in cache
  bool containsKey(String key) {
    return _cache.containsKey(key);
  }

  /// Get all keys in cache
  Set<String> getKeys() {
    return _cache.keys.toSet();
  }
}

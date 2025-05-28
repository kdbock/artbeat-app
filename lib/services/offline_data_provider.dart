import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artbeat/utils/connectivity_utils.dart';

/// A service that helps manage data caching for offline use
class OfflineDataProvider {
  static final OfflineDataProvider _instance = OfflineDataProvider._internal();
  static OfflineDataProvider get instance => _instance;

  OfflineDataProvider._internal();

  // Cached data expiration in hours
  final int _defaultCacheExpiration = 24;

  /// Save data to local cache with an expiration time
  Future<void> saveData({
    required String key,
    required dynamic data,
    int expirationHours = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expirationHours':
            expirationHours > 0 ? expirationHours : _defaultCacheExpiration,
      };

      // Store the JSON string
      await prefs.setString(key, jsonEncode(cacheData));
      debugPrint('✅ Data saved to offline cache: $key');
    } catch (e) {
      debugPrint('❌ Error saving data to offline cache: $e');
    }
  }

  /// Retrieve data from local cache if it exists and hasn't expired
  Future<dynamic> getData(String key, {bool ignoreExpiration = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(key);

      if (cachedData == null) {
        return null;
      }

      final cacheMap = jsonDecode(cachedData) as Map<String, dynamic>;

      if (!ignoreExpiration) {
        final timestamp = cacheMap['timestamp'] as int;
        final expirationHours = cacheMap['expirationHours'] as int;

        final expirationTime = Duration(hours: expirationHours).inMilliseconds;
        final currentTime = DateTime.now().millisecondsSinceEpoch;

        // Check if data has expired
        if (currentTime - timestamp > expirationTime) {
          debugPrint('⚠️ Cached data expired: $key');
          await removeData(key);
          return null;
        }
      }

      return cacheMap['data'];
    } catch (e) {
      debugPrint('❌ Error retrieving data from offline cache: $e');
      return null;
    }
  }

  /// Remove specific data from cache
  Future<void> removeData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      debugPrint('✅ Data removed from offline cache: $key');
    } catch (e) {
      debugPrint('❌ Error removing data from offline cache: $e');
    }
  }

  /// Clear all cached data
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('✅ All data cleared from offline cache');
    } catch (e) {
      debugPrint('❌ Error clearing offline cache: $e');
    }
  }

  /// Helper method to retrieve data with connectivity awareness
  Future<dynamic> getDataWithConnectivityCheck(
      String key, Future<dynamic> Function() fetchOnline) async {
    final isOnline = await ConnectivityUtils.instance.checkConnectivity();

    if (isOnline) {
      try {
        // Try to fetch fresh data
        final onlineData = await fetchOnline();

        // Save the fresh data to cache
        await saveData(key: key, data: onlineData);

        return onlineData;
      } catch (e) {
        debugPrint(
            '⚠️ Error fetching online data, using cached data if available: $e');
        // On error, fall back to cached data
        return await getData(key);
      }
    } else {
      // Offline mode - use cached data
      debugPrint('⚠️ Device is offline, using cached data for $key');
      return await getData(key);
    }
  }
}

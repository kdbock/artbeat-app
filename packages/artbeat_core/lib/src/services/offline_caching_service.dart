import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../utils/logger.dart';

/// Advanced caching service for offline support with TTL
class OfflineCachingService {
  static final OfflineCachingService _instance =
      OfflineCachingService._internal();
  factory OfflineCachingService() => _instance;
  OfflineCachingService._internal();

  late SharedPreferences _prefs;
  static const String _cachePrefix = 'artbeat_cache_';
  static const String _cacheMetaPrefix = 'artbeat_meta_';
  static const Duration defaultTTL = Duration(hours: 1);

  /// Initialize the caching service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      AppLogger.info('✅ Offline caching service initialized');
    } catch (e) {
      AppLogger.error('❌ Error initializing caching service: $e');
      rethrow;
    }
  }

  /// Cache data with TTL
  Future<void> cacheData<T>(
    String key,
    T data, {
    Duration ttl = defaultTTL,
  }) async {
    try {
      final cacheKey = '$_cachePrefix$key';
      final metaKey = '$_cacheMetaPrefix$key';

      // Serialize data
      final jsonData = jsonEncode(data);

      // Store data
      await _prefs.setString(cacheKey, jsonData);

      // Store metadata (expiration time)
      final expiresAt = DateTime.now().add(ttl).millisecondsSinceEpoch;
      await _prefs.setInt(metaKey, expiresAt);

      AppLogger.info(
        '✅ Cached data with key: $key (TTL: ${ttl.inMinutes} min)',
      );
    } catch (e) {
      AppLogger.error('❌ Error caching data: $e');
    }
  }

  /// Retrieve cached data if not expired
  Future<T?> getCachedData<T>(
    String key, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final cacheKey = '$_cachePrefix$key';
      final metaKey = '$_cacheMetaPrefix$key';

      // Check if cache exists
      if (!_prefs.containsKey(cacheKey)) {
        return null;
      }

      // Check if cache expired
      final expiresAt = _prefs.getInt(metaKey);
      if (expiresAt != null &&
          DateTime.now().millisecondsSinceEpoch > expiresAt) {
        // Cache expired, remove it
        await _prefs.remove(cacheKey);
        await _prefs.remove(metaKey);
        AppLogger.info('🗑️ Cache expired for key: $key');
        return null;
      }

      // Retrieve and deserialize data
      final jsonData = _prefs.getString(cacheKey);
      if (jsonData == null) return null;

      if (fromJson != null) {
        final decodedData = jsonDecode(jsonData) as Map<String, dynamic>;
        return fromJson(decodedData);
      }

      AppLogger.info('✅ Retrieved cached data for key: $key');
      return jsonDecode(jsonData) as T?;
    } catch (e) {
      AppLogger.error('❌ Error retrieving cached data: $e');
      return null;
    }
  }

  /// Cache list of items (for pagination)
  Future<void> cacheList<T>(
    String key,
    List<T> items, {
    Duration ttl = defaultTTL,
  }) async {
    try {
      final cacheKey = '$_cachePrefix$key';
      final metaKey = '$_cacheMetaPrefix$key';

      // Serialize list
      final jsonData = jsonEncode(items);

      // Store data
      await _prefs.setString(cacheKey, jsonData);

      // Store metadata
      final expiresAt = DateTime.now().add(ttl).millisecondsSinceEpoch;
      await _prefs.setInt(metaKey, expiresAt);
      await _prefs.setInt('${metaKey}_count', items.length);

      AppLogger.info('✅ Cached ${items.length} items with key: $key');
    } catch (e) {
      AppLogger.error('❌ Error caching list: $e');
    }
  }

  /// Retrieve cached list
  Future<List<T>?> getCachedList<T>(
    String key, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final cacheKey = '$_cachePrefix$key';
      final metaKey = '$_cacheMetaPrefix$key';

      // Check if cache exists
      if (!_prefs.containsKey(cacheKey)) {
        return null;
      }

      // Check if cache expired
      final expiresAt = _prefs.getInt(metaKey);
      if (expiresAt != null &&
          DateTime.now().millisecondsSinceEpoch > expiresAt) {
        // Cache expired, remove it
        await clearCache(key);
        AppLogger.info('🗑️ Cache list expired for key: $key');
        return null;
      }

      // Retrieve and deserialize data
      final jsonData = _prefs.getString(cacheKey);
      if (jsonData == null) return null;

      final decodedList = jsonDecode(jsonData) as List;

      if (fromJson != null) {
        return decodedList
            .map((item) => fromJson(item as Map<String, dynamic>))
            .toList();
      }

      AppLogger.info(
        '✅ Retrieved ${decodedList.length} cached items for key: $key',
      );
      return decodedList.cast<T>();
    } catch (e) {
      AppLogger.error('❌ Error retrieving cached list: $e');
      return null;
    }
  }

  /// Append to cached list (for pagination)
  Future<void> appendToCache<T>(
    String key,
    List<T> newItems, {
    Duration ttl = defaultTTL,
  }) async {
    try {
      final existing = await getCachedList<T>(key);
      final combined = [...?existing, ...newItems];
      await cacheList(key, combined, ttl: ttl);
      AppLogger.info('✅ Appended ${newItems.length} items to cache: $key');
    } catch (e) {
      AppLogger.error('❌ Error appending to cache: $e');
    }
  }

  /// Clear specific cache
  Future<void> clearCache(String key) async {
    try {
      final cacheKey = '$_cachePrefix$key';
      final metaKey = '$_cacheMetaPrefix$key';

      await _prefs.remove(cacheKey);
      await _prefs.remove(metaKey);
      await _prefs.remove('${metaKey}_count');

      AppLogger.info('🗑️ Cleared cache for key: $key');
    } catch (e) {
      AppLogger.error('❌ Error clearing cache: $e');
    }
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    try {
      final keys = _prefs.getKeys();
      final cachesToClear = keys
          .where(
            (key) =>
                key.startsWith(_cachePrefix) ||
                key.startsWith(_cacheMetaPrefix),
          )
          .toList();

      for (final key in cachesToClear) {
        await _prefs.remove(key);
      }

      AppLogger.info('🗑️ Cleared ${cachesToClear.length} cache entries');
    } catch (e) {
      AppLogger.error('❌ Error clearing all caches: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final keys = _prefs.getKeys();
      final cacheKeys = keys
          .where((key) => key.startsWith(_cachePrefix))
          .toList();

      int totalSize = 0;
      int expiredCount = 0;

      for (final key in cacheKeys) {
        final data = _prefs.getString(key);
        if (data != null) {
          totalSize += data.length;
        }

        // Check if expired
        final metaKey = key.replaceFirst(_cachePrefix, _cacheMetaPrefix);
        final expiresAt = _prefs.getInt(metaKey);
        if (expiresAt != null &&
            DateTime.now().millisecondsSinceEpoch > expiresAt) {
          expiredCount++;
        }
      }

      return {
        'totalCacheEntries': cacheKeys.length,
        'approximateSizeKB': (totalSize / 1024).toStringAsFixed(2),
        'expiredCount': expiredCount,
      };
    } catch (e) {
      AppLogger.error('❌ Error getting cache stats: $e');
      return {};
    }
  }

  /// Auto-cleanup expired caches
  Future<void> autoCleanup() async {
    try {
      final keys = _prefs.getKeys();
      final metaKeys = keys
          .where((key) => key.startsWith(_cacheMetaPrefix))
          .toList();

      int cleanedCount = 0;

      for (final metaKey in metaKeys) {
        final expiresAt = _prefs.getInt(metaKey);
        if (expiresAt != null &&
            DateTime.now().millisecondsSinceEpoch > expiresAt) {
          final cacheKey = metaKey.replaceFirst(_cacheMetaPrefix, _cachePrefix);
          await _prefs.remove(cacheKey);
          await _prefs.remove(metaKey);
          cleanedCount++;
        }
      }

      if (cleanedCount > 0) {
        AppLogger.info(
          '🧹 Auto-cleanup removed $cleanedCount expired cache entries',
        );
      }
    } catch (e) {
      AppLogger.error('❌ Error in auto-cleanup: $e');
    }
  }

  /// Start periodic cleanup (call this in app initialization)
  void startPeriodicCleanup({Duration interval = const Duration(minutes: 15)}) {
    Timer.periodic(interval, (_) {
      autoCleanup();
    });
    AppLogger.info(
      '🔄 Started periodic cache cleanup every ${interval.inMinutes} minutes',
    );
  }
}

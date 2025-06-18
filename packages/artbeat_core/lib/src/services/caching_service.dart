import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:math' as math;

class CachingService {
  static final CachingService _instance = CachingService._internal();
  factory CachingService() => _instance;
  CachingService._internal();

  DefaultCacheManager get _cacheManager => DefaultCacheManager();

  /// Clear old cached images to free up memory
  Future<void> clearOldCache() async {
    try {
      await _cacheManager.emptyCache();
      debugPrint('🧹 Cleared old image cache');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Remove specific file from cache
  Future<void> removeFromCache(String url) async {
    try {
      await _cacheManager.removeFile(url);
      debugPrint('🗑️ Removed $url from cache');
    } catch (e) {
      debugPrint('❌ Error removing file from cache: $e');
    }
  }

  /// Get cache statistics
  Future<String> getCacheStats() async {
    try {
      // Get a cache entry to check if cache exists
      final file = await _cacheManager.getFileFromCache("");
      if (file == null) {
        return "Cache is empty";
      }

      final fileLength = await file.file.length();
      return 'Cache file size: ${_formatBytes(fileLength)}';
    } catch (e) {
      debugPrint('❌ Error getting cache stats: $e');
      return 'Cache stats unavailable';
    }
  }

  /// Format bytes into human readable string
  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }
}

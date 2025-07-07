import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:collection';

/// Comprehensive image management service to prevent buffer overflow
/// and optimize image loading across the app
class ImageManagementService {
  static final ImageManagementService _instance =
      ImageManagementService._internal();
  factory ImageManagementService() => _instance;
  ImageManagementService._internal();

  // Configuration constants
  static const int maxConcurrentLoads =
      2; // Reduced from 3 to prevent buffer overflow
  static const int maxCacheSize = 100; // MB
  static const int thumbnailSize = 300;
  static const int profileImageSize = 200;
  static const Duration cacheDuration = Duration(days: 7);

  // Active loading tracking
  int _activeLoads = 0;
  final Queue<VoidCallback> _loadQueue = Queue<VoidCallback>();
  final Set<String> _loadingUrls = <String>{};

  // Custom cache manager with optimized settings
  late final CacheManager _cacheManager;

  /// Initialize the image management service
  Future<void> initialize() async {
    _cacheManager = CacheManager(
      Config(
        'artbeat_optimized_cache',
        stalePeriod: cacheDuration,
        maxNrOfCacheObjects: 200,
        repo: JsonCacheInfoRepository(databaseName: 'artbeat_cache'),
        fileSystem: IOFileSystem('artbeat_cache'),
      ),
    );

    debugPrint('🖼️ ImageManagementService initialized');
    debugPrint('📊 Max concurrent loads: $maxConcurrentLoads');
    debugPrint('💾 Cache duration: ${cacheDuration.inDays} days');
  }

  /// Get an optimized image widget with proper buffer management
  Widget getOptimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    bool isProfile = false,
    bool isThumbnail = false,
    Widget? placeholder,
    Widget? errorWidget,
    bool enableMemoryCache = true,
    bool enableDiskCache = true,
  }) {
    // Determine optimal dimensions
    int? memCacheWidth;
    int? memCacheHeight;

    if (isProfile) {
      memCacheWidth = profileImageSize;
      memCacheHeight = profileImageSize;
    } else if (isThumbnail) {
      memCacheWidth = thumbnailSize;
      memCacheHeight = thumbnailSize;
    } else if (width != null && height != null) {
      // Guard against NaN, Infinity, or negative values
      if (width.isFinite && !width.isNaN && width > 0) {
        memCacheWidth = width.toInt();
      } else {
        memCacheWidth = thumbnailSize; // fallback
      }
      if (height.isFinite && !height.isNaN && height > 0) {
        memCacheHeight = height.toInt();
      } else {
        memCacheHeight = thumbnailSize; // fallback
      }
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      cacheManager: _cacheManager,
      placeholder: placeholder != null
          ? (context, url) => placeholder
          : (context, url) => _buildPlaceholder(width, height),
      errorWidget: errorWidget != null
          ? (context, url, error) => errorWidget
          : (context, url, error) => _buildErrorWidget(width, height),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      useOldImageOnUrlChange: true,
      cacheKey: _generateCacheKey(imageUrl, memCacheWidth, memCacheHeight),
      // Note: maxWidthDiskCache and maxHeightDiskCache removed as they require ImageCacheManager
    );
  }

  /// Load image with queue management to prevent buffer overflow
  Future<void> loadImageWithQueue(
    String imageUrl,
    VoidCallback onComplete,
  ) async {
    // Check if already loading
    if (_loadingUrls.contains(imageUrl)) {
      debugPrint('🔄 Image already loading: $imageUrl');
      return;
    }

    // Add to loading set
    _loadingUrls.add(imageUrl);

    if (_activeLoads < maxConcurrentLoads) {
      _executeLoad(imageUrl, onComplete);
    } else {
      // Add to queue
      _loadQueue.add(() => _executeLoad(imageUrl, onComplete));
      debugPrint('📥 Image queued for loading: $imageUrl');
    }
  }

  /// Execute image load with proper resource management
  void _executeLoad(String imageUrl, VoidCallback onComplete) {
    _activeLoads++;
    debugPrint(
      '🔄 Loading image ($_activeLoads/$maxConcurrentLoads): $imageUrl',
    );

    // Preload the image
    _cacheManager
        .getSingleFile(imageUrl)
        .then((file) {
          debugPrint('✅ Image loaded successfully: $imageUrl');
          _completeLoad(imageUrl, onComplete);
        })
        .catchError((dynamic error) {
          debugPrint('❌ Image load failed: $imageUrl - $error');
          _completeLoad(imageUrl, onComplete);
        });
  }

  /// Complete image load and process queue
  void _completeLoad(String imageUrl, VoidCallback onComplete) {
    _activeLoads--;
    _loadingUrls.remove(imageUrl);
    onComplete();

    // Process next in queue
    if (_loadQueue.isNotEmpty && _activeLoads < maxConcurrentLoads) {
      final nextLoad = _loadQueue.removeFirst();
      nextLoad();
    }
  }

  /// Generate cache key for image with dimensions
  String _generateCacheKey(String imageUrl, int? width, int? height) {
    if (width != null && height != null) {
      return '${imageUrl}_${width}x$height';
    }
    return imageUrl;
  }

  /// Build placeholder widget
  Widget _buildPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 24),
      ),
    );
  }

  /// Preload critical images
  Future<void> preloadCriticalImages(List<String> imageUrls) async {
    debugPrint('🔄 Preloading ${imageUrls.length} critical images');

    for (final url in imageUrls.take(maxConcurrentLoads)) {
      if (!_loadingUrls.contains(url)) {
        _cacheManager.getSingleFile(url).catchError((dynamic error) {
          debugPrint('❌ Preload failed for: $url');
          // No return needed
        });
      }
    }
  }

  /// Clear old cache entries
  Future<void> clearOldCache() async {
    try {
      await _cacheManager.emptyCache();
      debugPrint('🧹 Image cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      return {
        'fileCount': 0, // Directory access not available
        'totalSize': 0,
        'totalSizeMB': '0.00',
        'activeLoads': _activeLoads,
        'queuedLoads': _loadQueue.length,
      };
    } catch (e) {
      debugPrint('❌ Error getting cache stats: $e');
      return {
        'error': e.toString(),
        'activeLoads': _activeLoads,
        'queuedLoads': _loadQueue.length,
      };
    }
  }

  /// Dispose of resources
  void dispose() {
    _loadQueue.clear();
    _loadingUrls.clear();
    _activeLoads = 0;
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:collection';
import 'dart:async' show Zone;
import '../widgets/secure_network_image.dart';
import '../utils/logger.dart';

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
  CacheManager? _cacheManager;
  bool _isInitialized = false;

  /// Get the cache manager (public accessor)
  CacheManager? get cacheManager => _cacheManager;

  /// Check if we're in a test environment
  bool get _isTestEnvironment {
    // Only skip in actual test environments, not debug mode
    return const bool.fromEnvironment('FLUTTER_TEST') ||
        (Zone.current[#test] != null);
  }

  /// Initialize the image management service
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.info(
        '🖼️ ImageManagementService already initialized, skipping',
      );
      return;
    }

    AppLogger.info('🖼️ ImageManagementService initializing...');
    AppLogger.info('🖼️ Is test environment: $_isTestEnvironment');

    // Skip cache manager initialization in test environments
    if (_isTestEnvironment) {
      debugPrint(
        '🖼️ ImageManagementService skipping cache manager in test environment',
      );
      _isInitialized = true;
      return;
    }

    AppLogger.info('🖼️ ImageManagementService initializing cache manager...');
    _cacheManager = CacheManager(
      Config(
        'artbeat_optimized_cache',
        stalePeriod: cacheDuration,
        maxNrOfCacheObjects: 200,
        repo: JsonCacheInfoRepository(databaseName: 'artbeat_cache'),
        fileSystem: IOFileSystem('artbeat_cache'),
      ),
    );

    _isInitialized = true;
    AppLogger.info(
      '🖼️ ImageManagementService initialized with cache manager: ${_cacheManager != null}',
    );
    AppLogger.analytics('📊 Max concurrent loads: $maxConcurrentLoads');
    AppLogger.info('💾 Cache duration: ${cacheDuration.inDays} days');
  }

  /// Get an optimized image widget with proper buffer management and Firebase Storage auth
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
    bool useSecureLoading = true,
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

    // Guard against invalid URLs that crash CachedNetworkImage
    final uri = Uri.tryParse(imageUrl);
    final isValidNetworkUrl =
        uri != null && uri.hasScheme && uri.host.isNotEmpty;

    // Debug: Print URL validation info
    AppLogger.info('🖼️ ImageManagementService validating URL: $imageUrl');
    AppLogger.info('🖼️ URI parsed: $uri');
    AppLogger.info('🖼️ Has scheme: ${uri?.hasScheme}');
    AppLogger.info('🖼️ Host: ${uri?.host}');
    AppLogger.network('🖼️ Is valid network URL: $isValidNetworkUrl');

    // More permissive validation - allow any non-empty URL that looks like it might be a network URL
    final isLikelyValidUrl =
        imageUrl.isNotEmpty &&
        (isValidNetworkUrl ||
            imageUrl.startsWith('http') ||
            imageUrl.contains('firebasestorage'));

    if (!isLikelyValidUrl) {
      AppLogger.error('🖼️ URL failed validation, showing error widget');
      // Fallback placeholder/error container without network call
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: errorWidget ?? _buildErrorWidget(width, height),
      );
    }

    // Use secure loading for Firebase Storage URLs or when explicitly requested
    final isFirebaseStorageUrl = imageUrl.contains(
      'firebasestorage.googleapis.com',
    );
    if (useSecureLoading && isFirebaseStorageUrl) {
      return SecureNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder ?? _buildPlaceholder(width, height),
        errorWidget: errorWidget ?? _buildErrorWidget(width, height),
        enableThumbnailFallback:
            true, // Enable fallback to thumbnails and path corrections
      );
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
      AppLogger.info('🔄 Image already loading: $imageUrl');
      return;
    }

    // Add to loading set
    _loadingUrls.add(imageUrl);

    if (_activeLoads < maxConcurrentLoads) {
      _executeLoad(imageUrl, onComplete);
    } else {
      // Add to queue
      _loadQueue.add(() => _executeLoad(imageUrl, onComplete));
      AppLogger.info('📥 Image queued for loading: $imageUrl');
    }
  }

  /// Execute image load with proper resource management
  void _executeLoad(String imageUrl, VoidCallback onComplete) {
    _activeLoads++;
    debugPrint(
      '🔄 Loading image ($_activeLoads/$maxConcurrentLoads): $imageUrl',
    );

    // Preload the image
    if (_cacheManager != null) {
      _cacheManager!
          .getSingleFile(imageUrl)
          .then((file) {
            AppLogger.info('✅ Image loaded successfully: $imageUrl');
            _completeLoad(imageUrl, onComplete);
          })
          .catchError((dynamic error) {
            AppLogger.error('❌ Image load failed: $imageUrl - $error');
            _completeLoad(imageUrl, onComplete);
          });
    } else {
      // In test environments where cache manager is not available,
      // simulate successful load completion
      AppLogger.info('✅ Image loaded successfully (simulated): $imageUrl');
      _completeLoad(imageUrl, onComplete);
    }
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
    AppLogger.info('🔄 Preloading ${imageUrls.length} critical images');

    if (_cacheManager == null) {
      // In test environments, just return without doing anything
      AppLogger.info('🖼️ Skipping preload in test environment');
      return;
    }

    for (final url in imageUrls.take(maxConcurrentLoads)) {
      if (!_loadingUrls.contains(url)) {
        _cacheManager!.getSingleFile(url).catchError((dynamic error) {
          AppLogger.error('❌ Preload failed for: $url');
          throw error as Object;
        });
      }
    }
  }

  /// Clear old cache entries
  Future<void> clearOldCache() async {
    try {
      await _cacheManager?.emptyCache();
      AppLogger.info('🧹 Image cache cleared');
    } catch (e) {
      AppLogger.error('❌ Error clearing cache: $e');
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
      AppLogger.error('❌ Error getting cache stats: $e');
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

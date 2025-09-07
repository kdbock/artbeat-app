import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Advanced performance optimization service for ARTbeat platform
/// Provides caching, lazy loading, memory management, and performance monitoring
class PerformanceOptimizationService {
  static final PerformanceOptimizationService _instance =
      PerformanceOptimizationService._internal();
  factory PerformanceOptimizationService() => _instance;
  PerformanceOptimizationService._internal();

  // Cache management
  final Map<String, CacheEntry<dynamic>> _memoryCache = {};
  final Map<String, Timer> _cacheTimers = {};
  final int _maxCacheSize = 100;
  final Duration _defaultCacheExpiry = const Duration(minutes: 30);

  // Performance monitoring
  final Map<String, PerformanceMetric> _performanceMetrics = {};
  final List<PerformanceEvent> _performanceEvents = [];
  final int _maxEvents = 1000;

  // Lazy loading management
  final Map<String, LazyLoadController> _lazyLoadControllers = {};

  // Memory management
  int _currentMemoryUsage = 0;
  final int _maxMemoryUsage = 50 * 1024 * 1024; // 50MB

  /// Initialize performance optimization service
  Future<void> initialize() async {
    await _setupPerformanceMonitoring();
    _startMemoryCleanupTimer();
  }

  /// Setup performance monitoring
  Future<void> _setupPerformanceMonitoring() async {
    // Monitor frame rendering
    WidgetsBinding.instance.addTimingsCallback(_onFrameRendered);
  }

  /// Start memory cleanup timer
  void _startMemoryCleanupTimer() {
    Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupMemory();
    });
  }

  /// Handle frame rendering callback
  void _onFrameRendered(List<FrameTiming> timings) {
    for (final timing in timings) {
      final buildDuration = timing.buildDuration.inMicroseconds / 1000.0;
      final rasterDuration = timing.rasterDuration.inMicroseconds / 1000.0;

      _recordPerformanceEvent(
        PerformanceEvent(
          type: PerformanceEventType.frameRender,
          duration: buildDuration + rasterDuration,
          timestamp: DateTime.now(),
          metadata: {
            'buildDuration': buildDuration,
            'rasterDuration': rasterDuration,
          },
        ),
      );
    }
  }

  // ==========================================
  // CACHING SYSTEM
  // ==========================================

  /// Store data in cache
  void cacheData<T>(String key, T data, {Duration? expiry}) {
    final expiryDuration = expiry ?? _defaultCacheExpiry;

    // Remove old entry if exists
    if (_memoryCache.containsKey(key)) {
      _cacheTimers[key]?.cancel();
    }

    // Add new entry
    _memoryCache[key] = CacheEntry<T>(
      data: data,
      timestamp: DateTime.now(),
      expiry: expiryDuration,
    );

    // Set expiry timer
    _cacheTimers[key] = Timer(expiryDuration, () {
      _memoryCache.remove(key);
      _cacheTimers.remove(key);
    });

    // Cleanup if cache is too large
    if (_memoryCache.length > _maxCacheSize) {
      _cleanupOldestCacheEntries();
    }
  }

  /// Retrieve data from cache
  T? getCachedData<T>(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return null;

    // Check if expired
    if (DateTime.now().difference(entry.timestamp) > entry.expiry) {
      _memoryCache.remove(key);
      _cacheTimers[key]?.cancel();
      _cacheTimers.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  /// Clear cache
  void clearCache([String? key]) {
    if (key != null) {
      _memoryCache.remove(key);
      _cacheTimers[key]?.cancel();
      _cacheTimers.remove(key);
    } else {
      _memoryCache.clear();
      for (final timer in _cacheTimers.values) {
        timer.cancel();
      }
      _cacheTimers.clear();
    }
  }

  /// Cleanup oldest cache entries
  void _cleanupOldestCacheEntries() {
    final entries = _memoryCache.entries.toList();
    entries.sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

    final toRemove = entries
        .take(_maxCacheSize ~/ 4)
        .map((e) => e.key)
        .toList();
    for (final key in toRemove) {
      _memoryCache.remove(key);
      _cacheTimers[key]?.cancel();
      _cacheTimers.remove(key);
    }
  }

  // ==========================================
  // LAZY LOADING SYSTEM
  // ==========================================

  /// Create lazy load controller
  LazyLoadController createLazyLoadController(String id) {
    final controller = LazyLoadController(id);
    _lazyLoadControllers[id] = controller;
    return controller;
  }

  /// Get lazy load controller
  LazyLoadController? getLazyLoadController(String id) {
    return _lazyLoadControllers[id];
  }

  /// Create lazy loading widget
  Widget createLazyLoadWidget({
    required String id,
    required Future<Widget> Function() builder,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return LazyLoadWidget(
      id: id,
      builder: builder,
      placeholder: placeholder ?? const CircularProgressIndicator(),
      errorWidget: errorWidget ?? const Icon(Icons.error),
      controller: createLazyLoadController(id),
    );
  }

  // ==========================================
  // MEMORY MANAGEMENT
  // ==========================================

  /// Track memory usage
  void trackMemoryUsage(int bytes) {
    _currentMemoryUsage += bytes;
    if (_currentMemoryUsage > _maxMemoryUsage) {
      _cleanupMemory();
    }
  }

  /// Cleanup memory
  void _cleanupMemory() {
    // Clear old cache entries
    _cleanupOldestCacheEntries();

    // Clear old performance events
    if (_performanceEvents.length > _maxEvents) {
      _performanceEvents.removeRange(0, _performanceEvents.length - _maxEvents);
    }

    // Force garbage collection in debug mode
    if (kDebugMode) {
      SystemChannels.platform.invokeMethod('System.requestGC');
    }

    _currentMemoryUsage = 0;
  }

  /// Get memory usage info
  MemoryInfo getMemoryInfo() {
    return MemoryInfo(
      currentUsage: _currentMemoryUsage,
      maxUsage: _maxMemoryUsage,
      cacheSize: _memoryCache.length,
      utilizationPercentage: (_currentMemoryUsage / _maxMemoryUsage * 100)
          .clamp(0, 100),
    );
  }

  // ==========================================
  // PERFORMANCE MONITORING
  // ==========================================

  /// Record performance event
  void _recordPerformanceEvent(PerformanceEvent event) {
    _performanceEvents.add(event);

    // Update metrics
    final key = event.type.name;
    if (_performanceMetrics.containsKey(key)) {
      _performanceMetrics[key]!.addMeasurement(event.duration);
    } else {
      _performanceMetrics[key] = PerformanceMetric(event.type)
        ..addMeasurement(event.duration);
    }

    // Cleanup old events
    if (_performanceEvents.length > _maxEvents) {
      _performanceEvents.removeAt(0);
    }
  }

  /// Start performance measurement
  PerformanceMeasurement startMeasurement(String operation) {
    return PerformanceMeasurement(operation, this);
  }

  /// Record operation performance
  void recordOperation(
    String operation,
    double durationMs, [
    Map<String, dynamic>? metadata,
  ]) {
    _recordPerformanceEvent(
      PerformanceEvent(
        type: PerformanceEventType.operation,
        duration: durationMs,
        timestamp: DateTime.now(),
        operation: operation,
        metadata: metadata,
      ),
    );
  }

  /// Get performance metrics
  Map<String, PerformanceMetric> getPerformanceMetrics() {
    return Map.unmodifiable(_performanceMetrics);
  }

  /// Get performance summary
  PerformanceSummary getPerformanceSummary() {
    final frameMetric =
        _performanceMetrics[PerformanceEventType.frameRender.name];
    final operationMetrics = _performanceMetrics.values
        .where((m) => m.type == PerformanceEventType.operation)
        .toList();

    return PerformanceSummary(
      averageFrameTime: frameMetric?.averageDuration ?? 0,
      frameDrops: frameMetric?.measurements.where((m) => m > 16.67).length ?? 0,
      totalOperations: operationMetrics.fold(
        0,
        (sum, m) => sum + m.measurements.length,
      ),
      memoryInfo: getMemoryInfo(),
      cacheHitRate: _calculateCacheHitRate(),
    );
  }

  /// Calculate cache hit rate
  double _calculateCacheHitRate() {
    // This would be tracked with actual cache hits/misses
    // For now, return a placeholder
    return 0.85;
  }

  // ==========================================
  // IMAGE OPTIMIZATION
  // ==========================================

  /// Optimize image for display
  Future<Uint8List> optimizeImage(
    Uint8List imageBytes, {
    int? maxWidth,
    int? maxHeight,
    int quality = 85,
  }) async {
    final measurement = startMeasurement('image_optimization');

    try {
      // This would typically use image processing libraries
      // For now, return the original bytes as a placeholder
      await Future<void>.delayed(const Duration(milliseconds: 50));

      measurement.finish();
      return imageBytes;
    } catch (e) {
      measurement.finish();
      rethrow;
    }
  }

  /// Create optimized image widget
  Widget createOptimizedImage({
    required String url,
    double? width,
    double? height,
    BoxFit? fit,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return OptimizedImageWidget(
      url: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      service: this,
    );
  }

  /// Dispose service
  void dispose() {
    clearCache();
    _lazyLoadControllers.clear();
    _performanceEvents.clear();
    _performanceMetrics.clear();
  }
}

// ==========================================
// SUPPORTING CLASSES
// ==========================================

/// Cache entry
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration expiry;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiry,
  });
}

/// Performance event types
enum PerformanceEventType {
  frameRender,
  operation,
  networkRequest,
  databaseQuery,
  imageLoad,
}

/// Performance event
class PerformanceEvent {
  final PerformanceEventType type;
  final double duration;
  final DateTime timestamp;
  final String? operation;
  final Map<String, dynamic>? metadata;

  PerformanceEvent({
    required this.type,
    required this.duration,
    required this.timestamp,
    this.operation,
    this.metadata,
  });
}

/// Performance metric
class PerformanceMetric {
  final PerformanceEventType type;
  final List<double> measurements = [];

  PerformanceMetric(this.type);

  void addMeasurement(double duration) {
    measurements.add(duration);
    if (measurements.length > 100) {
      measurements.removeAt(0);
    }
  }

  double get averageDuration {
    if (measurements.isEmpty) return 0;
    return measurements.reduce((a, b) => a + b) / measurements.length;
  }

  double get maxDuration {
    if (measurements.isEmpty) return 0;
    return measurements.reduce((a, b) => a > b ? a : b);
  }

  double get minDuration {
    if (measurements.isEmpty) return 0;
    return measurements.reduce((a, b) => a < b ? a : b);
  }
}

/// Performance measurement helper
class PerformanceMeasurement {
  final String operation;
  final PerformanceOptimizationService service;
  final DateTime startTime;

  PerformanceMeasurement(this.operation, this.service)
    : startTime = DateTime.now();

  void finish([Map<String, dynamic>? metadata]) {
    final duration =
        DateTime.now().difference(startTime).inMicroseconds / 1000.0;
    service.recordOperation(operation, duration, metadata);
  }
}

/// Memory information
class MemoryInfo {
  final int currentUsage;
  final int maxUsage;
  final int cacheSize;
  final double utilizationPercentage;

  MemoryInfo({
    required this.currentUsage,
    required this.maxUsage,
    required this.cacheSize,
    required this.utilizationPercentage,
  });
}

/// Performance summary
class PerformanceSummary {
  final double averageFrameTime;
  final int frameDrops;
  final int totalOperations;
  final MemoryInfo memoryInfo;
  final double cacheHitRate;

  PerformanceSummary({
    required this.averageFrameTime,
    required this.frameDrops,
    required this.totalOperations,
    required this.memoryInfo,
    required this.cacheHitRate,
  });
}

/// Lazy load controller
class LazyLoadController extends ChangeNotifier {
  final String id;
  bool _isLoaded = false;
  bool _isLoading = false;
  Object? _error;

  LazyLoadController(this.id);

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setLoaded(bool loaded) {
    _isLoaded = loaded;
    _isLoading = false;
    notifyListeners();
  }

  void setError(Object error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }
}

/// Lazy load widget
class LazyLoadWidget extends StatefulWidget {
  final String id;
  final Future<Widget> Function() builder;
  final Widget placeholder;
  final Widget errorWidget;
  final LazyLoadController controller;

  const LazyLoadWidget({
    super.key,
    required this.id,
    required this.builder,
    required this.placeholder,
    required this.errorWidget,
    required this.controller,
  });

  @override
  State<LazyLoadWidget> createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends State<LazyLoadWidget> {
  Widget? _loadedWidget;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    if (!widget.controller.isLoaded && !widget.controller.isLoading) {
      _loadWidget();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadWidget() async {
    widget.controller.setLoading(true);

    try {
      final widget = await this.widget.builder();
      _loadedWidget = widget;
      this.widget.controller.setLoaded(true);
    } catch (e) {
      this.widget.controller.setError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.error != null) {
      return widget.errorWidget;
    }

    if (widget.controller.isLoaded && _loadedWidget != null) {
      return _loadedWidget!;
    }

    return widget.placeholder;
  }
}

/// Optimized image widget
class OptimizedImageWidget extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final PerformanceOptimizationService service;

  const OptimizedImageWidget({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    required this.service,
  });

  @override
  State<OptimizedImageWidget> createState() => _OptimizedImageWidgetState();
}

class _OptimizedImageWidgetState extends State<OptimizedImageWidget> {
  @override
  Widget build(BuildContext context) {
    // Check cache first
    final cachedImage = widget.service.getCachedData<Widget>(
      'image_${widget.url}',
    );
    if (cachedImage != null) {
      return cachedImage;
    }

    // Load and cache image
    return FutureBuilder<Widget>(
      future: _loadOptimizedImage(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return widget.errorWidget ?? const Icon(Icons.error);
        }

        if (snapshot.hasData) {
          // Cache the loaded image
          widget.service.cacheData('image_${widget.url}', snapshot.data!);
          return snapshot.data!;
        }

        return widget.placeholder ?? const CircularProgressIndicator();
      },
    );
  }

  Future<Widget> _loadOptimizedImage() async {
    final measurement = widget.service.startMeasurement('image_load');

    try {
      // This would typically load and optimize the image
      // For now, return a placeholder Image.network
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final image = Image.network(
        widget.url,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ?? const Icon(Icons.error);
        },
      );

      measurement.finish({'url': widget.url});
      return image;
    } catch (e) {
      measurement.finish({'url': widget.url, 'error': e.toString()});
      rethrow;
    }
  }
}

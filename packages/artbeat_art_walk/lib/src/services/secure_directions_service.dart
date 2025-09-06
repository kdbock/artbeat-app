import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:artbeat_core/artbeat_core.dart';
import 'package:logger/logger.dart';

/// Secure service for managing Google Directions API requests with proper API key protection
///
/// This service implements server-side proxy patterns to protect API keys and provides
/// additional security features like request validation, rate limiting, and audit logging.
class SecureDirectionsService {
  static SecureDirectionsService? _instance;
  static SecureDirectionsService get instance =>
      _instance ??= SecureDirectionsService._();

  final Logger _logger = Logger();
  final Map<String, DateTime> _requestLimiter = {};
  final Map<String, dynamic> _cachedRoutes = {};

  static const Duration _rateLimitWindow = Duration(seconds: 1);
  static const int _maxRequestsPerWindow = 10;
  static const Duration _cacheExpiry = Duration(hours: 24);
  static const Duration _requestTimeout = Duration(seconds: 15);

  SecureDirectionsService._();

  /// Initialize the secure directions service
  Future<void> initialize() async {
    try {
      // Verify that we have proper configuration
      final hasValidConfig = await _validateConfiguration();
      if (!hasValidConfig) {
        throw Exception('Invalid configuration for SecureDirectionsService');
      }

      _logger.i('SecureDirectionsService initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize SecureDirectionsService', error: e);
      rethrow;
    }
  }

  /// Get secure directions between two points with enhanced security
  Future<Map<String, dynamic>> getSecureDirections({
    required String origin,
    required String destination,
    List<String>? waypoints,
    String? language = 'en',
    String? region,
    bool optimize = true,
  }) async {
    try {
      // Validate input parameters
      _validateDirectionsInput(origin, destination);

      // Check rate limiting
      if (!_checkRateLimit()) {
        throw Exception('Rate limit exceeded. Please try again later.');
      }

      // Create cache key
      final cacheKey = _createCacheKey(origin, destination, waypoints);

      // Try to get cached result first
      final cachedResult = _getCachedRoute(cacheKey);
      if (cachedResult != null) {
        _logger.d('Returning cached directions for key: $cacheKey');
        return cachedResult;
      }

      // Make secure API request through proxy
      final result = await _makeSecureDirectionsRequest(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
        language: language,
        region: region,
        optimize: optimize,
      );

      // Cache the result
      _cacheRoute(cacheKey, result);

      // Log successful request (without sensitive data)
      _logger.i('Secure directions request completed successfully');

      return result;
    } catch (e) {
      _logger.e('Error in getSecureDirections', error: e);
      rethrow;
    }
  }

  /// Validate configuration and security settings
  Future<bool> _validateConfiguration() async {
    try {
      // Check if we have a valid server endpoint for the proxy
      final serverEndpoint = ConfigService.instance.get(
        'SECURE_DIRECTIONS_ENDPOINT',
      );
      final apiKey = ConfigService.instance.get('DIRECTIONS_API_KEY_HASH');

      if (serverEndpoint == null || apiKey == null) {
        _logger.w('Missing secure directions configuration');
        return false;
      }

      // In debug mode, we might use direct API calls with additional validation
      if (kDebugMode) {
        final directApiKey = ConfigService.instance.get('GOOGLE_MAPS_API_KEY');
        if (directApiKey == null ||
            directApiKey.isEmpty ||
            directApiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
          _logger.w('Invalid direct API key in debug mode');
          return false;
        }
      }

      return true;
    } catch (e) {
      _logger.e('Configuration validation failed', error: e);
      return false;
    }
  }

  /// Validate directions input parameters
  void _validateDirectionsInput(String origin, String destination) {
    if (origin.isEmpty || destination.isEmpty) {
      throw ArgumentError('Origin and destination cannot be empty');
    }

    // Basic sanitization
    if (origin.length > 200 || destination.length > 200) {
      throw ArgumentError(
        'Origin and destination must be under 200 characters',
      );
    }

    // Check for suspicious patterns
    final suspiciousPatterns = RegExp(r'[<>"\\]');
    if (suspiciousPatterns.hasMatch(origin) ||
        suspiciousPatterns.hasMatch(destination)) {
      throw ArgumentError('Invalid characters in origin or destination');
    }
  }

  /// Check rate limiting to prevent abuse
  bool _checkRateLimit() {
    final now = DateTime.now();
    final windowStart = now.subtract(_rateLimitWindow);

    // Clean old entries
    _requestLimiter.removeWhere(
      (key, timestamp) => timestamp.isBefore(windowStart),
    );

    // Check current requests in window
    final requestsInWindow = _requestLimiter.length;
    if (requestsInWindow >= _maxRequestsPerWindow) {
      _logger.w('Rate limit exceeded: $requestsInWindow requests in window');
      return false;
    }

    // Add current request
    _requestLimiter[now.millisecondsSinceEpoch.toString()] = now;
    return true;
  }

  /// Create cache key for directions request
  String _createCacheKey(
    String origin,
    String destination,
    List<String>? waypoints,
  ) {
    final waypointsStr = waypoints?.join('|') ?? '';
    final key = '$origin->$destination|$waypointsStr';
    return base64Encode(utf8.encode(key));
  }

  /// Get cached route if available and not expired
  Map<String, dynamic>? _getCachedRoute(String cacheKey) {
    final cached = _cachedRoutes[cacheKey];
    if (cached == null) return null;

    final cachedAt = DateTime.parse(cached['cached_at'] as String);
    if (DateTime.now().difference(cachedAt) > _cacheExpiry) {
      _cachedRoutes.remove(cacheKey);
      return null;
    }

    return cached['data'] as Map<String, dynamic>;
  }

  /// Cache route data with timestamp
  void _cacheRoute(String cacheKey, Map<String, dynamic> data) {
    _cachedRoutes[cacheKey] = {
      'data': data,
      'cached_at': DateTime.now().toIso8601String(),
    };

    // Limit cache size to prevent memory issues
    if (_cachedRoutes.length > 100) {
      final oldestKey = _cachedRoutes.keys.first;
      _cachedRoutes.remove(oldestKey);
    }
  }

  /// Make secure directions request through server proxy or direct API
  Future<Map<String, dynamic>> _makeSecureDirectionsRequest({
    required String origin,
    required String destination,
    List<String>? waypoints,
    String? language,
    String? region,
    bool optimize = true,
  }) async {
    try {
      if (kDebugMode) {
        // In development, use direct API with additional security
        return await _makeDirectApiRequest(
          origin: origin,
          destination: destination,
          waypoints: waypoints,
          language: language,
          region: region,
          optimize: optimize,
        );
      } else {
        // In production, use server proxy
        return await _makeProxyApiRequest(
          origin: origin,
          destination: destination,
          waypoints: waypoints,
          language: language,
          region: region,
          optimize: optimize,
        );
      }
    } catch (e) {
      _logger.e('Secure directions request failed', error: e);
      rethrow;
    }
  }

  /// Make direct API request (debug mode only)
  Future<Map<String, dynamic>> _makeDirectApiRequest({
    required String origin,
    required String destination,
    List<String>? waypoints,
    String? language,
    String? region,
    bool optimize = true,
  }) async {
    final apiKey = ConfigService.instance.get('GOOGLE_MAPS_API_KEY');
    if (apiKey == null) {
      throw Exception('Missing Google Maps API key for direct request');
    }

    final queryParams = {
      'origin': origin,
      'destination': destination,
      'mode': 'walking',
      'key': apiKey,
    };

    if (waypoints != null && waypoints.isNotEmpty) {
      queryParams['waypoints'] = optimize
          ? 'optimize:true|${waypoints.join('|')}'
          : waypoints.join('|');
    }

    if (language != null) queryParams['language'] = language;
    if (region != null) queryParams['region'] = region;

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/directions/json',
      queryParams,
    );

    final response = await http.get(uri).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Directions API request failed: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    if (data['status'] != 'OK') {
      throw Exception(
        'Directions API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}',
      );
    }

    return data;
  }

  /// Make API request through secure server proxy
  Future<Map<String, dynamic>> _makeProxyApiRequest({
    required String origin,
    required String destination,
    List<String>? waypoints,
    String? language,
    String? region,
    bool optimize = true,
  }) async {
    final serverEndpoint = ConfigService.instance.get(
      'SECURE_DIRECTIONS_ENDPOINT',
    );
    if (serverEndpoint == null) {
      throw Exception('Missing secure directions server endpoint');
    }

    final requestBody = {
      'origin': origin,
      'destination': destination,
      'mode': 'walking',
      'optimize': optimize,
    };

    if (waypoints != null && waypoints.isNotEmpty) {
      requestBody['waypoints'] = waypoints;
    }
    if (language != null) requestBody['language'] = language;
    if (region != null) requestBody['region'] = region;

    // Add authentication header
    final authKey = ConfigService.instance.get('DIRECTIONS_API_KEY_HASH');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authKey',
      'User-Agent': 'ARTbeat/1.0',
    };

    final response = await http
        .post(
          Uri.parse('$serverEndpoint/directions'),
          headers: headers,
          body: json.encode(requestBody),
        )
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Proxy directions request failed: ${response.statusCode}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    if (data['status'] != 'OK') {
      throw Exception('Proxy directions error: ${data['status']}');
    }

    return data;
  }

  /// Clear all cached routes
  void clearCache() {
    _cachedRoutes.clear();
    _logger.i('Directions cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_routes': _cachedRoutes.length,
      'memory_usage_mb': (_cachedRoutes.toString().length / 1024 / 1024)
          .toStringAsFixed(2),
    };
  }

  /// Dispose resources
  void dispose() {
    _cachedRoutes.clear();
    _requestLimiter.clear();
    _instance = null;
  }
}

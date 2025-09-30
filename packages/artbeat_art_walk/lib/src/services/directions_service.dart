import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Service for fetching walking directions between locations
class DirectionsService {
  final String? _apiKey;
  static const Duration _requestTimeout = Duration(seconds: 10);
  static const int _maxRetries = 2;
  static const String _cacheKey = 'artbeat_directions_cache';

  DirectionsService({String? apiKey}) : _apiKey = apiKey;

  /// Get directions between two points with caching and retry logic
  Future<Map<String, dynamic>> getDirections(
    String origin,
    String destination, {
    bool useCachedData = true,
    List<String>? waypoints,
  }) async {
    final apiKey = _apiKey ?? ConfigService.instance.googleMapsApiKey;

    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
      AppLogger.warning('⚠️ Invalid Google Maps API key');
      throw Exception('Invalid or missing API key for directions');
    }

    // Create cache key based on origin, destination, and waypoints
    final waypointsString = waypoints?.join('|') ?? '';
    final String cacheEntryKey =
        '${origin}_to_${destination}_${waypointsString}_directions';

    // Try to get cached directions first if requested
    if (useCachedData) {
      final cachedData = await _getCachedDirections(cacheEntryKey);
      if (cachedData != null) {
        AppLogger.info('🗺️ Using cached directions');
        return cachedData;
      }
    }

    // Parameters for request
    final queryParams = {
      'origin': origin,
      'destination': destination,
      'mode': 'walking', // Always use walking mode for art walks
      'key': apiKey,
    };

    // Add waypoints if provided
    if (waypoints != null && waypoints.isNotEmpty) {
      queryParams['waypoints'] = waypoints.join('|');
    }

    final url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/directions/json',
      queryParams,
    );

    int attempt = 0;
    Exception? lastError;

    while (attempt < _maxRetries) {
      try {
        debugPrint(
          '🗺️ Fetching directions (attempt ${attempt + 1}/$_maxRetries)',
        );

        final response = await http.get(url).timeout(_requestTimeout);

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;

          // Check if the API returned an error status
          if (data.containsKey('status') && data['status'] != 'OK') {
            throw Exception(
              'API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}',
            );
          }

          // Cache valid directions data
          _cacheDirections(cacheEntryKey, data);
          return data;
        } else {
          throw Exception(
            'HTTP error ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } on TimeoutException {
        lastError = Exception('Request timed out');
        AppLogger.info(
          '⌛ Directions request timed out (attempt ${attempt + 1})',
        );
      } on SocketException {
        lastError = Exception('Network error');
        debugPrint(
          '🌐 Network error while fetching directions (attempt ${attempt + 1})',
        );
      } on Exception catch (e) {
        lastError = e;
        AppLogger.error(
          '❌ Error fetching directions: $e (attempt ${attempt + 1})',
        );
      }

      attempt++;
      if (attempt < _maxRetries) {
        // Exponential backoff
        await Future<void>.delayed(Duration(seconds: 1 * attempt));
      }
    }

    // After all retries failed, try to return cached data even if not requested initially
    if (!useCachedData) {
      final fallbackCachedData = await _getCachedDirections(cacheEntryKey);
      if (fallbackCachedData != null) {
        AppLogger.info(
          '🔄 Falling back to cached directions after API failures',
        );
        return fallbackCachedData;
      }
    }

    throw lastError ??
        Exception('Failed to get directions after $_maxRetries attempts');
  }

  /// Cache directions data for offline use
  Future<void> _cacheDirections(String key, Map<String, dynamic> data) async {
    try {
      // Get the current cache data by leveraging the existing cache format
      final prefs = await SharedPreferences.getInstance();
      final String? jsonCache = prefs.getString(_cacheKey);
      Map<String, dynamic> cache = {};
      if (jsonCache != null) {
        cache = jsonDecode(jsonCache) as Map<String, dynamic>;
      }

      // Add new entry
      cache[key] = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Save back to preferences
      await prefs.setString(_cacheKey, jsonEncode(cache));
    } catch (e) {
      AppLogger.warning('⚠️ Failed to cache directions: $e');
    }
  }

  /// Get cached directions if available and not expired
  Future<Map<String, dynamic>?> _getCachedDirections(String key) async {
    try {
      // Get the cache data using shared preferences directly
      final prefs = await SharedPreferences.getInstance();
      final String? jsonCache = prefs.getString(_cacheKey);
      if (jsonCache == null || jsonCache.isEmpty) {
        return null;
      }

      final cache = jsonDecode(jsonCache) as Map<String, dynamic>;
      final entry = cache[key];

      if (entry != null) {
        final timestamp = entry['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        // Use cache if less than 1 day old
        if (now - timestamp < const Duration(days: 1).inMilliseconds) {
          return entry['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      AppLogger.error('⚠️ Error retrieving cached directions: $e');
    }
    return null;
  }

  /// Clear the directions cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      AppLogger.warning('⚠️ Failed to clear directions cache: $e');
    }
  }
}

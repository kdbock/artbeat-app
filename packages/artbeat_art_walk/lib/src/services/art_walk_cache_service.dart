import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

import 'package:artbeat_core/artbeat_core.dart';

/// Service for caching art walks locally for offline access
class ArtWalkCacheService {
  // Keys for shared preferences
  static const String _artWalkCacheKey = 'cached_art_walks';
  static const String _publicArtCacheKey = 'cached_public_art';
  static const String _lastCacheTimeKey = 'last_art_walk_cache_time';
  static const int _cacheExpiryHours = 24; // Cache expiry time in hours

  /// Check if the device is currently online
  Future<bool> isOnline() async {
    return ConnectivityUtils().hasInternetConnection;
  }

  /// Determine if we should use cached data based on connectivity
  /// Returns true if we should use cache (offline or force cache is true)
  Future<bool> shouldUseCache({bool forceCache = false}) async {
    if (forceCache) return true;
    return !(await isOnline());
  }

  /// Log cache operation with connectivity status
  void _logCacheOperation(String operation, {bool isOnline = true}) {
    debugPrint(
        '${isOnline ? '🌐' : '📱'} ArtWalkCache: $operation ${isOnline ? '(online)' : '(offline)'}');
  }

  /// Cache an art walk and its associated art pieces
  Future<bool> cacheArtWalk(
      ArtWalkModel artWalk, List<PublicArtModel> artPieces) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cache the art walk
      Map<String, dynamic> cachedWalks = _getCachedArtWalks(prefs);
      cachedWalks[artWalk.id] = _serializeArtWalkModel(artWalk);
      await prefs.setString(_artWalkCacheKey, jsonEncode(cachedWalks));

      // Cache the art pieces
      Map<String, dynamic> cachedArt = _getCachedPublicArt(prefs);
      for (final art in artPieces) {
        cachedArt[art.id] = _serializePublicArtModel(art);
      }
      await prefs.setString(_publicArtCacheKey, jsonEncode(cachedArt));

      // Update last cache time
      await prefs.setString(
          _lastCacheTimeKey, DateTime.now().toIso8601String());

      return true;
    } catch (e) {
      // Error caching art walk: $e
      return false;
    }
  }

  /// Get a cached art walk by ID
  Future<ArtWalkModel?> getCachedArtWalk(String walkId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedWalks = _getCachedArtWalks(prefs);

      if (!cachedWalks.containsKey(walkId)) {
        return null;
      }

      return _deserializeArtWalkModel(cachedWalks[walkId], walkId);
    } catch (e) {
      // Error getting cached art walk: $e
      return null;
    }
  }

  /// Get all cached art pieces for an art walk
  Future<List<PublicArtModel>> getCachedArtInWalk(ArtWalkModel artWalk) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedArt = _getCachedPublicArt(prefs);

      final List<PublicArtModel> artPieces = [];
      for (final artId in artWalk.publicArtIds) {
        // Changed from artWalk.artIds
        if (cachedArt.containsKey(artId)) {
          final art = _deserializePublicArtModel(cachedArt[artId], artId);
          if (art != null) {
            artPieces.add(art);
          }
        }
      }

      return artPieces;
    } catch (e) {
      // Error getting cached art in walk: $e
      return [];
    }
  }

  /// Check if there are any cached art walks
  Future<bool> hasCachedArtWalks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedWalks = _getCachedArtWalks(prefs);
      return cachedWalks.isNotEmpty;
    } catch (e) {
      // Error checking cached art walks: $e
      return false;
    }
  }

  /// Get all cached art walks
  Future<List<ArtWalkModel>> getAllCachedArtWalks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedWalks = _getCachedArtWalks(prefs);
      final isDeviceOnline = await isOnline();

      _logCacheOperation('Retrieving all cached art walks',
          isOnline: isDeviceOnline);

      return cachedWalks.entries
          .map((entry) {
            return _deserializeArtWalkModel(entry.value, entry.key);
          })
          .where((walk) => walk != null)
          .cast<ArtWalkModel>()
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting all cached art walks: $e');
      return [];
    }
  }

  /// Check if the cache is expired
  Future<bool> isCacheExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCacheTimeStr = prefs.getString(_lastCacheTimeKey);

      if (lastCacheTimeStr == null) {
        return true;
      }

      final lastCacheTime = DateTime.parse(lastCacheTimeStr);
      final now = DateTime.now();
      final difference = now.difference(lastCacheTime);

      return difference.inHours > _cacheExpiryHours;
    } catch (e) {
      // Error checking if cache is expired: $e
      return true;
    }
  }

  /// Clear expired cache
  Future<void> clearExpiredCache() async {
    if (await isCacheExpired()) {
      await clearCache();
    }
  }

  /// Clear all cached art walks
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_artWalkCacheKey);
      await prefs.remove(_publicArtCacheKey);
      await prefs.remove(_lastCacheTimeKey);
    } catch (e) {
      // Error clearing art walk cache: $e
    }
  }

  /// Helper method to get all cached art walks
  Map<String, dynamic> _getCachedArtWalks(SharedPreferences prefs) {
    final cachedWalksStr = prefs.getString(_artWalkCacheKey);
    if (cachedWalksStr == null) {
      return {};
    }
    return jsonDecode(cachedWalksStr);
  }

  /// Helper method to get all cached public art
  Map<String, dynamic> _getCachedPublicArt(SharedPreferences prefs) {
    final cachedArtStr = prefs.getString(_publicArtCacheKey);
    if (cachedArtStr == null) {
      return {};
    }
    return jsonDecode(cachedArtStr);
  }

  /// Serialize ArtWalkModel to Map
  Map<String, dynamic> _serializeArtWalkModel(ArtWalkModel walk) {
    return {
      'userId': walk.userId,
      'title': walk.title,
      'description': walk.description,
      'publicArtIds': walk.publicArtIds, // Changed from artIds
      'isPublic': walk.isPublic,
      'viewCount': walk.viewCount,
      'createdAt': walk.createdAt.millisecondsSinceEpoch,
      'imageUrls': walk.imageUrls, // Added from current model
      'zipCode': walk.zipCode, // Added from current model
      // Fields below are from an older model version and removed as they are not in the current ArtWalkModel
      // 'routePolyline': walk.routePolyline,
      // 'distanceKm': walk.distanceKm,
      // 'estimatedMinutes': walk.estimatedMinutes,
      // 'coverImageUrl': walk.coverImageUrl, // Note: ArtWalkModel now uses imageUrls (list)
      // 'likeCount': walk.likeCount,
      // 'shareCount': walk.shareCount,
      // 'averageRating': walk.averageRating,
      // 'ratingCount': walk.ratingCount,
      // 'updatedAt': walk.updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Deserialize Map to ArtWalkModel
  ArtWalkModel? _deserializeArtWalkModel(dynamic data, String id) {
    if (data == null) return null;

    try {
      return ArtWalkModel(
        id: id,
        userId: data['userId'],
        title: data['title'],
        description: data['description'],
        publicArtIds: List<String>.from(
            data['publicArtIds'] ?? []), // Changed from artIds
        isPublic: data['isPublic'] ?? true,
        viewCount: data['viewCount'] ?? 0,
        createdAt: createdAtFromMillis(data['createdAt']),
        imageUrls: List<String>.from(
            data['imageUrls'] ?? []), // Added from current model
        zipCode: data['zipCode'], // Added from current model
        // Fields below are from an older model version and removed as they are not in the current ArtWalkModel
        // routePolyline: data['routePolyline'],
        // distanceKm: data['distanceKm']?.toDouble(),
        // estimatedMinutes: data['estimatedMinutes'],
        // coverImageUrl: data['coverImageUrl'], // Note: ArtWalkModel now uses imageUrls (list)
        // likeCount: data['likeCount'] ?? 0,
        // shareCount: data['shareCount'] ?? 0,
        // averageRating: data['averageRating']?.toDouble(),
        // ratingCount: data['ratingCount'] ?? 0,
        // updatedAt: data['updatedAt'] != null
        //     ? updatedAtFromMillis(data['updatedAt'])
        //     : null,
      );
    } catch (e) {
      // Error deserializing art walk: $e
      return null;
    }
  }

  /// Serialize PublicArtModel to Map
  Map<String, dynamic> _serializePublicArtModel(PublicArtModel art) {
    return {
      'userId': art.userId,
      'title': art.title,
      'description': art.description,
      'imageUrl': art.imageUrl,
      'artistName': art.artistName,
      'latitude': art.location.latitude,
      'longitude': art.location.longitude,
      'address': art.address,
      'tags': art.tags,
      'artType': art.artType,
      'isVerified': art.isVerified,
      'viewCount': art.viewCount,
      'likeCount': art.likeCount,
      'usersFavorited': art.usersFavorited,
      'createdAt': art.createdAt.millisecondsSinceEpoch,
      'updatedAt': art.updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Deserialize Map to PublicArtModel
  PublicArtModel? _deserializePublicArtModel(dynamic data, String id) {
    if (data == null) return null;

    try {
      return PublicArtModel(
        id: id,
        userId: data['userId'],
        title: data['title'],
        description: data['description'],
        imageUrl: data['imageUrl'],
        artistName: data['artistName'],
        location: geoPointFromLatLng(data['latitude'], data['longitude']),
        address: data['address'],
        tags: List<String>.from(data['tags']),
        artType: data['artType'],
        isVerified: data['isVerified'] ?? false,
        viewCount: data['viewCount'] ?? 0,
        likeCount: data['likeCount'] ?? 0,
        usersFavorited: List<String>.from(data['usersFavorited']),
        createdAt: createdAtFromMillis(data['createdAt']),
        updatedAt: data['updatedAt'] != null
            ? updatedAtFromMillis(data['updatedAt'])
            : null,
      );
    } catch (e) {
      // Error deserializing public art: $e
      return null;
    }
  }

  /// Convert milliseconds to Timestamp
  dynamic createdAtFromMillis(int? millis) {
    if (millis == null) {
      return DateTime.now().millisecondsSinceEpoch;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Convert milliseconds to Timestamp for updatedAt
  dynamic updatedAtFromMillis(int? millis) {
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Convert lat/lng to GeoPoint
  dynamic geoPointFromLatLng(double latitude, double longitude) {
    // Since we can't directly create a Firestore GeoPoint, we'll create a compatible object
    return {'latitude': latitude, 'longitude': longitude};
  }
}

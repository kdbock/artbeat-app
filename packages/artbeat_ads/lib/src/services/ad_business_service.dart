import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ad_type.dart';
import '../models/ad_location.dart';
import '../models/ad_status.dart';
import '../models/ad_model.dart';
import '../models/ad_artist_model.dart';
import '../models/ad_gallery_model.dart';
import '../models/ad_user_model.dart';
import '../models/ad_artist_approved_model.dart';
import '../models/ad_duration.dart';
import '../utils/ad_constants.dart';
import '../services/ad_service.dart';
import '../services/ad_artist_service.dart';
import '../services/ad_gallery_service.dart';
import '../services/ad_user_service.dart';
import '../services/ad_artist_approved_service.dart';

/// Business logic service for ad operations
/// Handles pricing, validation, submission routing, and business rules
class AdBusinessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Service instances
  final AdService _adService = AdService();
  final AdArtistService _artistService = AdArtistService();
  final AdGalleryService _galleryService = AdGalleryService();
  final AdUserService _userService = AdUserService();
  final AdArtistApprovedService _artistApprovedService =
      AdArtistApprovedService();

  /// Get price per day for specific ad type
  double getPriceForAdType(AdType adType) {
    switch (adType) {
      case AdType.square:
      case AdType.rectangle:
        return AdConstants.userAdPricePerDay;
      case AdType.artistApproved:
        return AdConstants.artistAdPricePerDay * 2; // Premium pricing
    }
  }

  /// Get price per day based on user type
  double getPriceForUserType(String userType) {
    switch (userType) {
      case 'artist':
        return AdConstants.artistAdPricePerDay;
      case 'gallery':
        return AdConstants.galleryAdPricePerDay;
      case 'user':
        return AdConstants.userAdPricePerDay;
      case 'admin':
        return 0.0; // Admin ads are free
      default:
        return AdConstants.userAdPricePerDay;
    }
  }

  /// Check if user can create ads of this type
  Future<bool> canUserCreateAdType(
    String userId,
    AdType adType,
    String userType,
  ) async {
    try {
      // Admin can create any type
      if (userType == 'admin') return true;

      // Check user subscription/permissions based on type
      switch (adType) {
        case AdType.artistApproved:
          return await _checkArtistApprovedPermissions(userId);
        default:
          return true; // Basic ad types available to all
      }
    } catch (e) {
      debugPrint('❌ Error checking ad creation permissions: $e');
      return false;
    }
  }

  /// Check if location is available for ad placement
  Future<bool> isLocationAvailable(
    AdLocation location,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Check if there are conflicting ads in the same location and time period
      final query = await _firestore
          .collection('ads')
          .where('location', isEqualTo: location.index)
          .where('status', isEqualTo: AdStatus.running.index)
          .get();

      for (final doc in query.docs) {
        final data = doc.data();
        final existingStart = (data['startDate'] as Timestamp).toDate();
        final existingEnd = (data['endDate'] as Timestamp).toDate();

        // Check for overlap
        if (startDate.isBefore(existingEnd) && endDate.isAfter(existingStart)) {
          return false; // Overlap found
        }
      }

      return true; // No conflicts
    } catch (e) {
      debugPrint('❌ Error checking location availability: $e');
      return false;
    }
  }

  /// Calculate total cost for ad campaign
  double calculateTotalCost(
    double pricePerDay,
    int durationDays,
    String userType,
  ) {
    double basePrice = pricePerDay * durationDays;

    // Apply discounts for longer campaigns
    if (durationDays >= 30) {
      basePrice *= 0.85; // 15% discount for monthly campaigns
    } else if (durationDays >= 14) {
      basePrice *= 0.90; // 10% discount for bi-weekly campaigns
    } else if (durationDays >= 7) {
      basePrice *= 0.95; // 5% discount for weekly campaigns
    }

    return basePrice;
  }

  /// Submit ad to appropriate service based on user type and ad type
  Future<String> submitAd(Map<String, dynamic> adData, String userType) async {
    try {
      final adType = AdType.values[adData['type'] as int];

      switch (userType) {
        case 'admin':
          return await _adService.createAd(_createAdModel(adData));

        case 'artist':
          if (adType == AdType.artistApproved) {
            return await _artistApprovedService.createArtistApprovedAd(
              _createArtistApprovedModel(adData),
            );
          } else {
            return await _artistService.createArtistAd(
              _createArtistModel(adData),
            );
          }

        case 'gallery':
          return await _galleryService.createGalleryAd(
            _createGalleryModel(adData),
          );

        case 'user':
          return await _userService.createUserAd(_createUserModel(adData));

        default:
          throw Exception('Unknown user type: $userType');
      }
    } catch (e) {
      debugPrint('❌ Error submitting ad: $e');
      rethrow;
    }
  }

  /// Validate ad data before submission
  bool validateAdData(Map<String, dynamic> adData, String userType) {
    // Required fields validation
    final requiredFields = [
      'ownerId',
      'type',
      'title',
      'description',
      'location',
      'duration',
    ];
    for (final field in requiredFields) {
      if (!adData.containsKey(field) || adData[field] == null) {
        debugPrint('❌ Missing required field: $field');
        return false;
      }
    }

    // Image validation
    if (!adData.containsKey('imageUrl') ||
        (adData['imageUrl'] as String).isEmpty) {
      // For some ad types, check artworkUrls as well
      if (!adData.containsKey('artworkUrls') ||
          (adData['artworkUrls'] as String).isEmpty) {
        debugPrint('❌ Missing image URL');
        return false;
      }
    }

    // Type-specific validation
    final adType = AdType.values[adData['type'] as int];
    return _validateAdTypeSpecificData(adData, adType);
  }

  bool _validateAdTypeSpecificData(Map<String, dynamic> adData, AdType adType) {
    switch (adType) {
      case AdType.artistApproved:
        // Artist approved ads need avatar and artwork images
        if (!adData.containsKey('avatarUrl') ||
            (adData['avatarUrl'] as String).isEmpty) {
          debugPrint('❌ Missing avatar URL for artist approved ad');
          return false;
        }
        if (!adData.containsKey('artworkUrls') ||
            (adData['artworkUrls'] as String).isEmpty) {
          debugPrint('❌ Missing artwork URLs for artist approved ad');
          return false;
        }
        break;
      default:
        // Standard validation passed
        break;
    }
    return true;
  }

  Future<bool> _checkArtistApprovedPermissions(String userId) async {
    try {
      // Check if user has artist profile with proper subscription
      final artistDoc = await _firestore
          .collection('artistProfiles')
          .doc(userId)
          .get();

      if (!artistDoc.exists) return false;

      final data = artistDoc.data()!;
      final userType = data['userType'] as String?;

      return userType == 'artist' || userType == 'gallery';
    } catch (e) {
      debugPrint('❌ Error checking artist approved permissions: $e');
      return false;
    }
  }

  // Model creation methods with proper type casting
  AdModel _createAdModel(Map<String, dynamic> data) {
    return AdModel(
      id: '',
      ownerId: data['ownerId'] as String,
      type: AdType.values[data['type'] as int],
      imageUrl: data['imageUrl'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      location: AdLocation.values[data['location'] as int],
      duration: AdDuration(
        days: (data['duration'] as Map<String, dynamic>)['days'] as int,
      ),
      pricePerDay: (data['pricePerDay'] as num).toDouble(),
      startDate: data['startDate'] as DateTime,
      endDate: data['endDate'] as DateTime,
      status: AdStatus.values[data['status'] as int],
      targetId: data['targetId'] as String?,
      destinationUrl: data['destinationUrl'] as String?,
      ctaText: data['ctaText'] as String?,
    );
  }

  AdArtistModel _createArtistModel(Map<String, dynamic> data) {
    return AdArtistModel(
      id: '',
      ownerId: data['ownerId'] as String,
      type: AdType.values[data['type'] as int],
      imageUrl: data['imageUrl'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      location: AdLocation.values[data['location'] as int],
      duration: AdDuration(
        days: (data['duration'] as Map<String, dynamic>)['days'] as int,
      ),
      pricePerDay: (data['pricePerDay'] as num).toDouble(),
      startDate: data['startDate'] as DateTime,
      endDate: data['endDate'] as DateTime,
      status: AdStatus.values[data['status'] as int],
      artistId: data['ownerId'] as String, // Artist is both owner and subject
      eventId: data['eventId'] as String?,
      artworkId: data['artworkId'] as String?,
    );
  }

  AdGalleryModel _createGalleryModel(Map<String, dynamic> data) {
    return AdGalleryModel(
      id: '',
      ownerId: data['ownerId'] as String,
      type: AdType.values[data['type'] as int],
      imageUrl: data['imageUrl'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      location: AdLocation.values[data['location'] as int],
      duration: AdDuration(
        days: (data['duration'] as Map<String, dynamic>)['days'] as int,
      ),
      pricePerDay: (data['pricePerDay'] as num).toDouble(),
      startDate: data['startDate'] as DateTime,
      endDate: data['endDate'] as DateTime,
      status: AdStatus.values[data['status'] as int],
      galleryId: data['ownerId'] as String, // Gallery is both owner and subject
      businessName: data['businessName'] as String?,
    );
  }

  AdUserModel _createUserModel(Map<String, dynamic> data) {
    return AdUserModel(
      id: '',
      ownerId: data['ownerId'] as String,
      type: AdType.values[data['type'] as int],
      imageUrl: data['imageUrl'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      location: AdLocation.values[data['location'] as int],
      duration: AdDuration(
        days: (data['duration'] as Map<String, dynamic>)['days'] as int,
      ),
      pricePerDay: (data['pricePerDay'] as num).toDouble(),
      startDate: data['startDate'] as DateTime,
      endDate: data['endDate'] as DateTime,
      status: AdStatus.values[data['status'] as int],
      userId: data['ownerId'] as String, // User is both owner and subject
    );
  }

  AdArtistApprovedModel _createArtistApprovedModel(Map<String, dynamic> data) {
    final artworkUrls = (data['artworkUrls'] as String).split(',');
    final now = DateTime.now();

    return AdArtistApprovedModel(
      id: '',
      ownerId: data['ownerId'] as String,
      artistId: data['ownerId'] as String,
      type: AdType.values[data['type'] as int],
      avatarImageUrl: data['avatarUrl'] as String,
      artworkImageUrls: artworkUrls,
      tagline: (data['tagline'] as String?) ?? '', // Default to empty if null
      title: data['title'] as String,
      description: data['description'] as String,
      location: AdLocation.values[data['location'] as int],
      duration: AdDuration(
        days: (data['duration'] as Map<String, dynamic>)['days'] as int,
      ),
      pricePerDay: (data['pricePerDay'] as num).toDouble(),
      startDate: data['startDate'] as DateTime,
      endDate: data['endDate'] as DateTime,
      status: AdStatus.values[data['status'] as int],
      destinationUrl: data['destinationUrl'] as String?,
      ctaText: data['ctaText'] as String?,
      animationSpeed: data['animationSpeed'] as int,
      autoPlay: data['autoPlay'] as bool,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Get recommended duration based on ad type and budget
  int getRecommendedDuration(AdType adType, double budget, double pricePerDay) {
    if (pricePerDay <= 0) return 7; // Default to 1 week

    final maxDays = (budget / pricePerDay).floor();

    // Recommend optimal duration based on ad type
    switch (adType) {
      case AdType.artistApproved:
        return maxDays.clamp(14, 30); // 2-4 weeks for premium ads
      default:
        return maxDays.clamp(3, 14); // 3 days to 2 weeks for standard ads
    }
  }

  /// Get available locations for user type
  List<AdLocation> getAvailableLocations(String userType) {
    switch (userType) {
      case 'admin':
        return AdLocation.values; // Admin can place anywhere
      case 'gallery':
        return [
          AdLocation.dashboard,
          AdLocation.communityFeed,
          AdLocation.artWalkDashboard,
          AdLocation.eventsDashboard,
        ];
      case 'artist':
        return [
          AdLocation.dashboard,
          AdLocation.communityFeed,
          AdLocation.captureDashboard,
        ];
      default:
        return [AdLocation.dashboard, AdLocation.communityFeed];
    }
  }
}

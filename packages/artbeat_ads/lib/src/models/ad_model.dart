import 'package:cloud_firestore/cloud_firestore.dart';
import 'ad_type.dart';
import 'ad_status.dart';
import 'ad_location.dart';
import 'ad_duration.dart';
import 'ad_size.dart';
import 'image_fit.dart';

/// Simplified Ad model for the new ad system
class AdModel {
  final String id;
  final String ownerId;
  final AdType type;
  final AdSize size;
  final String imageUrl;
  final List<String>
  artworkUrls; // Multiple images for rotating display (1-4 images)
  final String title;
  final String description;
  final AdLocation location;
  final AdDuration duration;
  final DateTime startDate;
  final DateTime endDate;
  final AdStatus status;
  final String? approvalId;
  final String? destinationUrl; // External URL to drive traffic to
  final String? ctaText; // Call-to-action text (e.g., "Shop Now", "Learn More")
  final ImageFit imageFit; // How the image should be fitted in the ad space

  /// Price per day is determined by ad size
  double get pricePerDay => size.pricePerDay;

  AdModel({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.size,
    required this.imageUrl,
    this.artworkUrls = const [],
    required this.title,
    required this.description,
    required this.location,
    required this.duration,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.approvalId,
    this.destinationUrl,
    this.ctaText,
    this.imageFit =
        ImageFit.cover, // Default to cover for backward compatibility
  });

  factory AdModel.fromMap(Map<String, dynamic> map, String id) {
    final rawType = map['type'];
    final intType = rawType is int
        ? rawType
        : int.tryParse(rawType.toString()) ?? 0;

    final rawSize = map['size'];
    final intSize = rawSize is int
        ? rawSize
        : int.tryParse(rawSize.toString()) ?? 0;

    final rawLocation = map['location'];
    final intLocation = rawLocation is int
        ? rawLocation
        : int.tryParse(rawLocation.toString()) ?? 0;

    final rawStatus = map['status'];
    final intStatus = rawStatus is int
        ? rawStatus
        : int.tryParse(rawStatus.toString()) ?? 0;

    final rawDuration = map['duration'];
    final durationMap = rawDuration is Map<String, dynamic>
        ? rawDuration
        : <String, dynamic>{};

    // Parse artworkUrls from comma-separated string or list
    List<String> artworkUrls = [];
    final rawArtworkUrls = map['artworkUrls'];
    if (rawArtworkUrls != null) {
      if (rawArtworkUrls is String && rawArtworkUrls.isNotEmpty) {
        artworkUrls = rawArtworkUrls
            .split(',')
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList();
      } else if (rawArtworkUrls is List) {
        artworkUrls = rawArtworkUrls
            .map((url) => url.toString())
            .where((url) => url.isNotEmpty)
            .toList();
      }
    }

    // Safe enum parsing with additional validation
    AdType safeType;
    try {
      safeType = intType >= 0 && intType < AdType.values.length
          ? AdType.values[intType]
          : AdType.banner_ad;
    } catch (e) {
      safeType = AdType.banner_ad;
    }

    AdSize safeSize;
    try {
      safeSize = intSize >= 0 && intSize < AdSize.values.length
          ? AdSize.values[intSize]
          : AdSize.small;
    } catch (e) {
      safeSize = AdSize.small;
    }

    AdLocation safeLocation;
    try {
      safeLocation = intLocation >= 0 && intLocation < AdLocation.values.length
          ? AdLocation.values[intLocation]
          : AdLocation.dashboard;
    } catch (e) {
      safeLocation = AdLocation.dashboard;
    }

    AdStatus safeStatus;
    try {
      safeStatus = intStatus >= 0 && intStatus < AdStatus.values.length
          ? AdStatus.values[intStatus]
          : AdStatus.pending;
    } catch (e) {
      safeStatus = AdStatus.pending;
    }

    // Parse imageFit with safe fallback
    ImageFit safeImageFit;
    try {
      final rawImageFit = map['imageFit'];
      final intImageFit = rawImageFit is int
          ? rawImageFit
          : int.tryParse(rawImageFit.toString()) ?? 0;
      safeImageFit = intImageFit >= 0 && intImageFit < ImageFit.values.length
          ? ImageFit.values[intImageFit]
          : ImageFit.cover;
    } catch (e) {
      safeImageFit = ImageFit.cover;
    }

    return AdModel(
      id: id,
      ownerId: map['ownerId']?.toString() ?? '',
      type: safeType,
      size: safeSize,
      imageUrl: map['imageUrl']?.toString() ?? '',
      artworkUrls: artworkUrls,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      location: safeLocation,
      duration: AdDurationExtension.fromMap(durationMap),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      status: safeStatus,
      approvalId: map['approvalId']?.toString(),
      destinationUrl: map['destinationUrl']?.toString(),
      ctaText: map['ctaText']?.toString(),
      imageFit: safeImageFit,
    );
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'type': type.index,
    'size': size.index,
    'imageUrl': imageUrl,
    'artworkUrls': artworkUrls.join(','), // Store as comma-separated string
    'title': title,
    'description': description,
    'location': location.index,
    'duration': duration.toMap(),
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'status': status.index,
    'approvalId': approvalId,
    'destinationUrl': destinationUrl,
    'ctaText': ctaText,
    'imageFit': imageFit.index,
  };

  /// Create a copy of this ad with some properties replaced
  AdModel copyWith({
    String? id,
    String? ownerId,
    AdType? type,
    AdSize? size,
    String? imageUrl,
    List<String>? artworkUrls,
    String? title,
    String? description,
    AdLocation? location,
    AdDuration? duration,
    DateTime? startDate,
    DateTime? endDate,
    AdStatus? status,
    String? approvalId,
    String? destinationUrl,
    String? ctaText,
    String? linkUrl, // Handle linkUrl parameter
    String? contactInfo, // Handle contactInfo parameter
    ImageFit? imageFit,
    DateTime? updatedAt, // Handle updatedAt parameter
  }) {
    return AdModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      type: type ?? this.type,
      size: size ?? this.size,
      imageUrl: imageUrl ?? this.imageUrl,
      artworkUrls: artworkUrls ?? this.artworkUrls,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      duration: duration ?? this.duration,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      approvalId: approvalId ?? this.approvalId,
      destinationUrl: linkUrl ?? destinationUrl ?? this.destinationUrl,
      ctaText: ctaText ?? this.ctaText,
      imageFit: imageFit ?? this.imageFit,
    );
  }
}

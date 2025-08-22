import 'package:cloud_firestore/cloud_firestore.dart';
import 'ad_type.dart';
import 'ad_status.dart';
import 'ad_location.dart';
import 'ad_duration.dart';
import 'ad_size.dart';

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
      duration: AdDuration.fromMap(durationMap),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      status: safeStatus,
      approvalId: map['approvalId']?.toString(),
      destinationUrl: map['destinationUrl']?.toString(),
      ctaText: map['ctaText']?.toString(),
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
  };
}

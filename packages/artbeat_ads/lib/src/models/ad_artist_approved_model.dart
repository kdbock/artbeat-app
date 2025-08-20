import 'package:cloud_firestore/cloud_firestore.dart';
import 'ad_type.dart';
import 'ad_status.dart';
import 'ad_location.dart';
import 'ad_duration.dart';

/// Artist Approved Ad model with support for multiple artwork images and GIF animation
class AdArtistApprovedModel {
  final String id;
  final String ownerId;
  final String artistId;
  final AdType type;
  final String avatarImageUrl; // Artist headshot/avatar
  final List<String> artworkImageUrls; // 4 artwork images for GIF animation
  final String tagline; // Artist tagline
  final String title;
  final String description;
  final AdLocation location;
  final AdDuration duration;
  final double pricePerDay;
  final DateTime startDate;
  final DateTime endDate;
  final AdStatus status;
  final String? approvalId;
  final String? destinationUrl; // Artist profile or website URL
  final String? ctaText; // Call-to-action text
  final int animationSpeed; // Speed of GIF animation in milliseconds
  final bool autoPlay; // Whether to auto-play the GIF animation
  final DateTime createdAt;
  final DateTime updatedAt;

  AdArtistApprovedModel({
    required this.id,
    required this.ownerId,
    required this.artistId,
    required this.type,
    required this.avatarImageUrl,
    required this.artworkImageUrls,
    required this.tagline,
    required this.title,
    required this.description,
    required this.location,
    required this.duration,
    required this.pricePerDay,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.approvalId,
    this.destinationUrl,
    this.ctaText,
    this.animationSpeed = 1000, // Default 1 second per image
    this.autoPlay = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdArtistApprovedModel.fromMap(Map<String, dynamic> map, String id) {
    final rawType = map['type'];
    final intType = rawType is int
        ? rawType
        : int.tryParse(rawType.toString()) ?? 0;
    final rawLocation = map['location'];
    final intLocation = rawLocation is int
        ? rawLocation
        : int.tryParse(rawLocation.toString()) ?? 0;
    final rawStatus = map['status'];
    final intStatus = rawStatus is int
        ? rawStatus
        : int.tryParse(rawStatus.toString()) ?? 0;
    final rawPrice = map['pricePerDay'] ?? 1.0;
    final doublePrice = rawPrice is double
        ? rawPrice
        : double.tryParse(rawPrice.toString()) ?? 1.0;
    final rawDuration = map['duration'];
    final durationMap = rawDuration is Map<String, dynamic>
        ? rawDuration
        : <String, dynamic>{};

    // Handle artwork images list
    final rawArtworkImages = map['artworkImageUrls'];
    final List<String> artworkImages = [];
    if (rawArtworkImages is List) {
      artworkImages.addAll(rawArtworkImages.cast<String>());
    }

    return AdArtistApprovedModel(
      id: id,
      ownerId: map['ownerId']?.toString() ?? '',
      artistId: map['artistId']?.toString() ?? '',
      type: AdType.values[intType],
      avatarImageUrl: map['avatarImageUrl']?.toString() ?? '',
      artworkImageUrls: artworkImages,
      tagline: map['tagline']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      location: AdLocation.values[intLocation],
      duration: AdDuration.fromMap(durationMap),
      pricePerDay: doublePrice,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      status: AdStatus.values[intStatus],
      approvalId: map['approvalId']?.toString(),
      destinationUrl: map['destinationUrl']?.toString(),
      ctaText: map['ctaText']?.toString(),
      animationSpeed: map['animationSpeed'] as int? ?? 1000,
      autoPlay: map['autoPlay'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'artistId': artistId,
    'type': type.index,
    'avatarImageUrl': avatarImageUrl,
    'artworkImageUrls': artworkImageUrls,
    'tagline': tagline,
    'title': title,
    'description': description,
    'location': location.index,
    'duration': duration.toMap(),
    'pricePerDay': pricePerDay,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'status': status.index,
    'approvalId': approvalId,
    'destinationUrl': destinationUrl,
    'ctaText': ctaText,
    'animationSpeed': animationSpeed,
    'autoPlay': autoPlay,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  AdArtistApprovedModel copyWith({
    String? id,
    String? ownerId,
    String? artistId,
    AdType? type,
    String? avatarImageUrl,
    List<String>? artworkImageUrls,
    String? tagline,
    String? title,
    String? description,
    AdLocation? location,
    AdDuration? duration,
    double? pricePerDay,
    DateTime? startDate,
    DateTime? endDate,
    AdStatus? status,
    String? approvalId,
    String? destinationUrl,
    String? ctaText,
    int? animationSpeed,
    bool? autoPlay,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdArtistApprovedModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      artistId: artistId ?? this.artistId,
      type: type ?? this.type,
      avatarImageUrl: avatarImageUrl ?? this.avatarImageUrl,
      artworkImageUrls: artworkImageUrls ?? this.artworkImageUrls,
      tagline: tagline ?? this.tagline,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      duration: duration ?? this.duration,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      approvalId: approvalId ?? this.approvalId,
      destinationUrl: destinationUrl ?? this.destinationUrl,
      ctaText: ctaText ?? this.ctaText,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      autoPlay: autoPlay ?? this.autoPlay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validate that the ad has all required fields for artist approved ads
  bool get isValid {
    return avatarImageUrl.isNotEmpty &&
        artworkImageUrls.length == 4 &&
        artworkImageUrls.every((url) => url.isNotEmpty) &&
        tagline.isNotEmpty &&
        title.isNotEmpty &&
        description.isNotEmpty;
  }

  /// Get the total cost for this ad campaign
  double get totalCost => pricePerDay * duration.days;

  /// Check if the ad is currently active
  bool get isActive {
    final now = DateTime.now();
    return status == AdStatus.running &&
        now.isAfter(startDate) &&
        now.isBefore(endDate);
  }
}

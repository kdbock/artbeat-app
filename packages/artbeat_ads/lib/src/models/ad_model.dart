import 'package:cloud_firestore/cloud_firestore.dart';
import 'ad_type.dart';
import 'ad_status.dart';
import 'ad_location.dart';
import 'ad_duration.dart';

/// Base Ad model for all ad types (user, artist, gallery, admin)
class AdModel {
  final String id;
  final String ownerId;
  final AdType type;
  final String imageUrl;
  final String title;
  final String description;
  final AdLocation location;
  final AdDuration duration;
  final double pricePerDay;
  final DateTime startDate;
  final DateTime endDate;
  final AdStatus status;
  final String? approvalId;
  final String? targetId; // e.g. artistId, artworkId, eventId, galleryId
  final String? destinationUrl; // External URL to drive traffic to
  final String? ctaText; // Call-to-action text (e.g., "Shop Now", "Learn More")

  AdModel({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.location,
    required this.duration,
    required this.pricePerDay,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.approvalId,
    this.targetId,
    this.destinationUrl,
    this.ctaText,
  });

  factory AdModel.fromMap(Map<String, dynamic> map, String id) {
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
    return AdModel(
      id: id,
      ownerId: map['ownerId']?.toString() ?? '',
      type: AdType.values[intType],
      imageUrl: map['imageUrl']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      location: AdLocation.values[intLocation],
      duration: AdDuration.fromMap(durationMap),
      pricePerDay: doublePrice,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      status: AdStatus.values[intStatus],
      approvalId: map['approvalId']?.toString(),
      targetId: map['targetId']?.toString(),
      destinationUrl: map['destinationUrl']?.toString(),
      ctaText: map['ctaText']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'type': type.index,
    'imageUrl': imageUrl,
    'title': title,
    'description': description,
    'location': location.index,
    'duration': duration.toMap(),
    'pricePerDay': pricePerDay,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'status': status.index,
    'approvalId': approvalId,
    'targetId': targetId,
    'destinationUrl': destinationUrl,
    'ctaText': ctaText,
  };
}

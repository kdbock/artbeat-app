import 'package:cloud_firestore/cloud_firestore.dart';
import 'ad_model.dart';
import 'ad_type.dart';
import 'ad_status.dart';
import 'ad_location.dart';
import 'ad_duration.dart';

/// Model for artist-created ads
class AdArtistModel extends AdModel {
  final String artistId;
  final String? eventId;
  final String? artworkId;

  AdArtistModel({
    required super.id,
    required super.ownerId,
    required super.type,
    required super.imageUrl,
    required super.title,
    required super.description,
    required super.location,
    required super.duration,
    required super.pricePerDay,
    required super.startDate,
    required super.endDate,
    required super.status,
    super.approvalId,
    super.targetId,
    required this.artistId,
    this.eventId,
    this.artworkId,
  });

  factory AdArtistModel.fromMap(Map<String, dynamic> map, String id) {
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
    return AdArtistModel(
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
      artistId: map['artistId']?.toString() ?? '',
      eventId: map['eventId']?.toString(),
      artworkId: map['artworkId']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'artistId': artistId,
    'eventId': eventId,
    'artworkId': artworkId,
  };
}

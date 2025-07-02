import 'package:cloud_firestore/cloud_firestore.dart';
import 'ad_model.dart';
import 'ad_type.dart';
import 'ad_status.dart';
import 'ad_location.dart';
import 'ad_duration.dart';

/// Model for gallery/institution ads
class AdGalleryModel extends AdModel {
  final String galleryId;
  final String? businessName;

  AdGalleryModel({
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
    required this.galleryId,
    this.businessName,
  });

  factory AdGalleryModel.fromMap(Map<String, dynamic> map, String id) {
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
    final rawPrice = map['pricePerDay'] ?? 5.0;
    final doublePrice = rawPrice is double
        ? rawPrice
        : double.tryParse(rawPrice.toString()) ?? 5.0;
    final rawDuration = map['duration'];
    final durationMap = rawDuration is Map<String, dynamic>
        ? rawDuration
        : <String, dynamic>{};
    return AdGalleryModel(
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
      galleryId: map['galleryId']?.toString() ?? '',
      businessName: map['businessName']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'galleryId': galleryId,
    'businessName': businessName,
  };
}

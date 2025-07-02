import 'package:cloud_firestore/cloud_firestore.dart';

class CommissionModel {
  final String id;
  final String galleryId;
  final String artistId;
  final String artworkId;
  final double commissionRate;
  final String status; // pending, active, cancelled
  final Timestamp createdAt;
  final Timestamp updatedAt;

  CommissionModel({
    required this.id,
    required this.galleryId,
    required this.artistId,
    required this.artworkId,
    required this.commissionRate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommissionModel(
      id: doc.id,
      galleryId: (data['galleryId'] as String?) ?? '',
      artistId: (data['artistId'] as String?) ?? '',
      artworkId: (data['artworkId'] as String?) ?? '',
      commissionRate: ((data['commissionRate'] as num?) ?? 0.0).toDouble(),
      status: (data['status'] as String?) ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
      updatedAt: (data['updatedAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'galleryId': galleryId,
      'artistId': artistId,
      'artworkId': artworkId,
      'commissionRate': commissionRate,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  CommissionModel copyWith(Map<String, dynamic> updates) {
    return CommissionModel(
      id: (updates['id'] as String?) ?? id,
      galleryId: (updates['galleryId'] as String?) ?? galleryId,
      artistId: (updates['artistId'] as String?) ?? artistId,
      artworkId: (updates['artworkId'] as String?) ?? artworkId,
      commissionRate: ((updates['commissionRate'] as num?) ?? commissionRate)
          .toDouble(),
      status: (updates['status'] as String?) ?? status,
      createdAt: (updates['createdAt'] as Timestamp?) ?? createdAt,
      updatedAt: (updates['updatedAt'] as Timestamp?) ?? updatedAt,
    );
  }
}

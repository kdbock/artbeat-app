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
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommissionModel(
      id: doc.id,
      galleryId: data['galleryId'] ?? '',
      artistId: data['artistId'] ?? '',
      artworkId: data['artworkId'] ?? '',
      commissionRate: (data['commissionRate'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
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
      id: updates['id'] ?? id,
      galleryId: updates['galleryId'] ?? galleryId,
      artistId: updates['artistId'] ?? artistId,
      artworkId: updates['artworkId'] ?? artworkId,
      commissionRate: updates['commissionRate'] ?? commissionRate,
      status: updates['status'] ?? status,
      createdAt: updates['createdAt'] ?? createdAt,
      updatedAt: updates['updatedAt'] ?? updatedAt,
    );
  }
}

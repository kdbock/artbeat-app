import 'package:cloud_firestore/cloud_firestore.dart';

class CommissionModel {
  final String id;
  final String artistId;
  final String galleryId;
  final double commissionRate;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // pending, active, cancelled
  final int paymentTermDays;
  final List<String> appliedArtworkIds;

  CommissionModel({
    required this.id,
    required this.artistId,
    required this.galleryId,
    required this.commissionRate,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.paymentTermDays,
    required this.appliedArtworkIds,
  });

  factory CommissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommissionModel(
      id: doc.id,
      artistId: data['artistId'] as String? ?? '',
      galleryId: data['galleryId'] as String? ?? '',
      commissionRate: (data['commissionRate'] as num? ?? 0.0).toDouble(),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      status: data['status'] as String? ?? 'pending',
      paymentTermDays: data['paymentTermDays'] as int? ?? 30,
      appliedArtworkIds: List<String>.from(
        data['appliedArtworkIds'] as List<dynamic>? ?? [],
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'artistId': artistId,
      'galleryId': galleryId,
      'commissionRate': commissionRate,
      'startDate': Timestamp.fromDate(startDate),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      'status': status,
      'paymentTermDays': paymentTermDays,
      'appliedArtworkIds': appliedArtworkIds,
    };
  }

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';
}

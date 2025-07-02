import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/commission_model.dart';

class CommissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CommissionModel>> getCommissionsByUser(String userId) async {
    final querySnapshot = await _firestore
        .collection('commissions')
        .where('userId', isEqualTo: userId)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return CommissionModel(
        id: doc.id,
        galleryId: data['galleryId'] as String,
        artistId: data['artistId'] as String,
        artworkId: data['artworkId'] as String,
        commissionRate: (data['commissionRate'] as num).toDouble(),
        status: data['status'] as String,
        createdAt: data['createdAt'] as Timestamp,
        updatedAt: data['updatedAt'] as Timestamp,
      );
    }).toList();
  }

  Future<void> createCommission(CommissionModel commission) async {
    await _firestore.collection('commissions').doc(commission.id).set({
      'galleryId': commission.galleryId,
      'artistId': commission.artistId,
      'artworkId': commission.artworkId,
      'commissionRate': commission.commissionRate,
      'status': commission.status,
      'createdAt': commission.createdAt,
      'updatedAt': commission.updatedAt,
    });
  }

  Future<void> updateCommission(
    String commissionId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore
        .collection('commissions')
        .doc(commissionId)
        .update(updates);
  }

  Future<void> deleteCommission(String commissionId) async {
    await _firestore.collection('commissions').doc(commissionId).delete();
  }
}

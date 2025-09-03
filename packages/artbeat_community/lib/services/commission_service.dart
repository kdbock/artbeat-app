import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/commission_model.dart';

class CommissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CommissionModel>> getCommissionsByUser(String userId) async {
    // Query for commissions where user is either the gallery or the artist
    final galleryCommissionsQuery = await _firestore
        .collection('commissions')
        .where('galleryId', isEqualTo: userId)
        .get();

    final artistCommissionsQuery = await _firestore
        .collection('commissions')
        .where('artistId', isEqualTo: userId)
        .get();

    final allCommissions = [
      ...galleryCommissionsQuery.docs,
      ...artistCommissionsQuery.docs,
    ];

    // Remove duplicates in case a user is both gallery and artist for the same commission
    final uniqueCommissions = <String, DocumentSnapshot>{};
    for (final doc in allCommissions) {
      uniqueCommissions[doc.id] = doc;
    }

    return uniqueCommissions.values
        .map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            return CommissionModel(
              id: doc.id,
              galleryId: data['galleryId'] as String? ?? '',
              artistId: data['artistId'] as String? ?? '',
              artworkId: data['artworkId'] as String? ?? '',
              commissionRate: ((data['commissionRate'] as num?) ?? 0.0)
                  .toDouble(),
              status: (data['status'] as String?) ?? 'pending',
              createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
              updatedAt: (data['updatedAt'] as Timestamp?) ?? Timestamp.now(),
            );
          } catch (e) {
            // Log the error but don't fail the entire operation
            debugPrint('Error parsing commission ${doc.id}: $e');
            return null;
          }
        })
        .where((commission) => commission != null)
        .cast<CommissionModel>()
        .toList();
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

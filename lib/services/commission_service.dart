import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat/models/commission_model.dart';

/// Service for handling commissions between galleries and artists
class CommissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  final CollectionReference _commissionsCollection =
      FirebaseFirestore.instance.collection('commissions');

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get all commissions for a gallery (where galleryId matches current user's artistProfileId)
  Future<List<CommissionModel>> getGalleryCommissions() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Find the gallery profile ID for the current user
      final galleryProfileSnapshot = await _firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: userId)
          .where('userType', isEqualTo: 'gallery')
          .get();

      if (galleryProfileSnapshot.docs.isEmpty) {
        throw Exception('No gallery profile found for this user');
      }

      final galleryProfileId = galleryProfileSnapshot.docs.first.id;

      // Get commissions where this gallery is a party
      final commissionsSnapshot = await _commissionsCollection
          .where('galleryId', isEqualTo: galleryProfileId)
          .orderBy('createdAt', descending: true)
          .get();

      return commissionsSnapshot.docs
          .map((doc) => CommissionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting gallery commissions: $e');
    }
  }

  /// Get all commissions for an artist (where artistId matches current user's artistProfileId)
  Future<List<CommissionModel>> getArtistCommissions() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Find the artist profile ID for the current user
      final artistProfileSnapshot = await _firestore
          .collection('artistProfiles')
          .where('userId', isEqualTo: userId)
          .where('userType', isEqualTo: 'artist')
          .get();

      if (artistProfileSnapshot.docs.isEmpty) {
        throw Exception('No artist profile found for this user');
      }

      final artistProfileId = artistProfileSnapshot.docs.first.id;

      // Get commissions where this artist is a party
      final commissionsSnapshot = await _commissionsCollection
          .where('artistId', isEqualTo: artistProfileId)
          .orderBy('createdAt', descending: true)
          .get();

      return commissionsSnapshot.docs
          .map((doc) => CommissionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting artist commissions: $e');
    }
  }

  /// Create a new commission agreement
  Future<String> createCommission({
    required String galleryId,
    required String artistId,
    required double commissionRate,
    required Map<String, dynamic> terms,
    List<String>? artworkIds,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Create the commission document
      final commissionData = {
        'galleryId': galleryId,
        'artistId': artistId,
        'commissionRate': commissionRate,
        'status': CommissionStatus.pending.name,
        'terms': terms,
        'artworkIds': artworkIds ?? [],
        'transactions': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': userId,
      };

      final docRef = await _commissionsCollection.add(commissionData);
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating commission: $e');
    }
  }

  /// Update commission status
  Future<void> updateCommissionStatus({
    required String commissionId,
    required CommissionStatus status,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _commissionsCollection.doc(commissionId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': userId,
      });
    } catch (e) {
      throw Exception('Error updating commission status: $e');
    }
  }

  /// Add a transaction to a commission
  Future<void> addCommissionTransaction({
    required String commissionId,
    required String artworkId,
    required String artworkTitle,
    required double saleAmount,
    required double commissionAmount,
    required DateTime saleDate, // This will be used as transactionDate
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the commission document
      final commissionDoc =
          await _commissionsCollection.doc(commissionId).get();
      if (!commissionDoc.exists) {
        throw Exception('Commission not found');
      }

      // Create the transaction
      final transaction = CommissionTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        artworkId: artworkId,
        artworkTitle: artworkTitle,
        saleAmount: saleAmount,
        commissionAmount: commissionAmount,
        transactionDate: saleDate,
        status: 'pending',
        paymentMethod: null,
        receiptId: null,
      );

      // Add the transaction to the commission's transactions array
      await _commissionsCollection.doc(commissionId).update({
        'transactions': FieldValue.arrayUnion([transaction.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': userId,
      });

      // If commission is in 'active' status, add the artwork to the artworkIds array if not already there
      if (commissionDoc.get('status') == CommissionStatus.active.name) {
        final artworkIds =
            List<String>.from(commissionDoc.get('artworkIds') ?? []);
        if (!artworkIds.contains(artworkId)) {
          await _commissionsCollection.doc(commissionId).update({
            'artworkIds': FieldValue.arrayUnion([artworkId]),
          });
        }
      }
    } catch (e) {
      throw Exception('Error adding commission transaction: $e');
    }
  }

  /// Mark a transaction as paid
  Future<void> markTransactionAsPaid({
    required String commissionId,
    required String transactionId,
    required DateTime paymentDate,
    String? paymentMethod,
    String? referenceNumber,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the commission document
      final commissionDoc =
          await _commissionsCollection.doc(commissionId).get();
      if (!commissionDoc.exists) {
        throw Exception('Commission not found');
      }

      // Get the transactions array
      final transactions = List<Map<String, dynamic>>.from(
          commissionDoc.get('transactions') ?? []);

      // Find and update the specific transaction
      final updatedTransactions = transactions.map((transaction) {
        if (transaction['id'] == transactionId) {
          return {
            ...transaction,
            'isPaid': true,
            'paymentDate': Timestamp.fromDate(paymentDate),
            'paymentMethod': paymentMethod,
            'referenceNumber': referenceNumber,
          };
        }
        return transaction;
      }).toList();

      // Update the commission document with the updated transactions
      await _commissionsCollection.doc(commissionId).update({
        'transactions': updatedTransactions,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': userId,
      });
    } catch (e) {
      throw Exception('Error marking transaction as paid: $e');
    }
  }

  /// Get commission by ID
  Future<CommissionModel> getCommissionById(String commissionId) async {
    try {
      final commissionDoc =
          await _commissionsCollection.doc(commissionId).get();
      if (!commissionDoc.exists) {
        throw Exception('Commission not found');
      }

      return CommissionModel.fromFirestore(commissionDoc);
    } catch (e) {
      throw Exception('Error getting commission: $e');
    }
  }

  /// Update commission terms
  Future<void> updateCommissionTerms({
    required String commissionId,
    required Map<String, dynamic> terms,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _commissionsCollection.doc(commissionId).update({
        'terms': terms,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': userId,
      });
    } catch (e) {
      throw Exception('Error updating commission terms: $e');
    }
  }
}

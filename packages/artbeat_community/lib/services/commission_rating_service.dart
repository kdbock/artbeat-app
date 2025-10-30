import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/commission_rating_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

class CommissionRatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submit a rating for a completed commission
  Future<String> submitRating({
    required String commissionId,
    required String ratedUserId,
    required String ratedUserName,
    required double overallRating,
    required double qualityRating,
    required double communicationRating,
    required double timelinessRating,
    required String comment,
    required bool wouldRecommend,
    required List<String> tags,
    required bool isArtistRating,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User must be authenticated');

      final ratingId = _firestore.collection('commission_ratings').doc().id;

      final rating = CommissionRating(
        id: ratingId,
        commissionId: commissionId,
        ratedById: user.uid,
        ratedByName: user.displayName ?? 'Unknown',
        ratedUserId: ratedUserId,
        ratedUserName: ratedUserName,
        overallRating: overallRating,
        qualityRating: qualityRating,
        communicationRating: communicationRating,
        timelinessRating: timelinessRating,
        comment: comment,
        wouldRecommend: wouldRecommend,
        tags: tags,
        createdAt: DateTime.now(),
        isArtistRating: isArtistRating,
        metadata: {'submittedAt': DateTime.now().toIso8601String()},
      );

      await _firestore
          .collection('commission_ratings')
          .doc(ratingId)
          .set(rating.toFirestore());

      // Update artist reputation
      await _updateArtistReputation(ratedUserId);

      return ratingId;
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }

  /// Get ratings for a user
  Future<List<CommissionRating>> getRatingsForUser(
    String userId, {
    bool isArtistRating = true,
  }) async {
    try {
      final query = await _firestore
          .collection('commission_ratings')
          .where('ratedUserId', isEqualTo: userId)
          .where('isArtistRating', isEqualTo: isArtistRating)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => CommissionRating.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get ratings: $e');
    }
  }

  /// Get artist reputation
  Future<ArtistReputation?> getArtistReputation(String artistId) async {
    try {
      final doc = await _firestore
          .collection('artist_reputation')
          .doc(artistId)
          .get();

      if (!doc.exists) return null;
      return ArtistReputation.fromFirestore(doc);
    } catch (e) {
      AppLogger.error('Failed to get artist reputation: $e');
      return null;
    }
  }

  /// Update artist reputation based on ratings
  Future<void> _updateArtistReputation(String artistId) async {
    try {
      final ratings = await _firestore
          .collection('commission_ratings')
          .where('ratedUserId', isEqualTo: artistId)
          .where('isPublic', isEqualTo: true)
          .get();

      if (ratings.docs.isEmpty) return;

      double totalQuality = 0;
      double totalCommunication = 0;
      double totalTimeliness = 0;
      int recommendCount = 0;

      for (final doc in ratings.docs) {
        final rating = CommissionRating.fromFirestore(doc);
        totalQuality += rating.qualityRating;
        totalCommunication += rating.communicationRating;
        totalTimeliness += rating.timelinessRating;
        if (rating.wouldRecommend) recommendCount++;
      }

      final count = ratings.docs.length;
      final overallRating =
          (totalQuality + totalCommunication + totalTimeliness) / (count * 3);

      // Get artist name
      final artistDoc = await _firestore
          .collection('users')
          .doc(artistId)
          .get();
      final artistName = (artistDoc.data()?['displayName'] as String?) ?? '';

      // Create rating distribution
      final distribution = <String, int>{};
      for (final doc in ratings.docs) {
        final rating = CommissionRating.fromFirestore(doc);
        final ratingStr = rating.overallRating.toInt().toString();
        distribution[ratingStr] = (distribution[ratingStr] ?? 0) + 1;
      }

      final reputation = ArtistReputation(
        artistId: artistId,
        artistName: artistName,
        overallRating: overallRating,
        qualityRating: totalQuality / count,
        communicationRating: totalCommunication / count,
        timelinessRating: totalTimeliness / count,
        totalRatings: count,
        recommendCount: recommendCount,
        recentRatings: [],
        ratingDistribution: distribution,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('artist_reputation')
          .doc(artistId)
          .set(reputation.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('Failed to update artist reputation: $e');
    }
  }

  /// Mark rating as helpful
  Future<void> markHelpful(String ratingId) async {
    try {
      await _firestore.collection('commission_ratings').doc(ratingId).update({
        'helpfulCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to mark rating as helpful: $e');
    }
  }

  /// Get rating for specific commission
  Future<CommissionRating?> getRatingForCommission(String commissionId) async {
    try {
      final query = await _firestore
          .collection('commission_ratings')
          .where('commissionId', isEqualTo: commissionId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return CommissionRating.fromFirestore(query.docs.first);
    } catch (e) {
      AppLogger.error('Failed to get commission rating: $e');
      return null;
    }
  }
}

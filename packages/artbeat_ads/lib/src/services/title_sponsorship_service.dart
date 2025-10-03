import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../models/title_sponsorship_model.dart';

/// Service for managing title sponsorships
/// Handles the premium $5,000/month app-wide sponsorship
class TitleSponsorshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference for title sponsorships
  CollectionReference get _sponsorshipsCollection =>
      _firestore.collection('title_sponsorships');

  /// Get the currently active title sponsor
  Future<TitleSponsorshipModel?> getActiveSponsor() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _sponsorshipsCollection
          .where('status', isEqualTo: SponsorshipStatus.active.index)
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endDate', isGreaterThan: Timestamp.fromDate(now))
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return TitleSponsorshipModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      core.AppLogger.error('Error getting active sponsor: $e');
      return null;
    }
  }

  /// Stream of the currently active sponsor
  Stream<TitleSponsorshipModel?> watchActiveSponsor() {
    final now = DateTime.now();
    return _sponsorshipsCollection
        .where('status', isEqualTo: SponsorshipStatus.active.index)
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('endDate', isGreaterThan: Timestamp.fromDate(now))
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          return TitleSponsorshipModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        });
  }

  /// Create a new title sponsorship request
  Future<String> createSponsorship({
    required String sponsorId,
    required String sponsorName,
    required String logoUrl,
    String? websiteUrl,
    String? description,
    required DateTime startDate,
    required int durationMonths,
  }) async {
    try {
      // Check if there's already an active sponsor for the requested period
      final conflictingSponsor = await _checkForConflicts(
        startDate,
        durationMonths,
      );
      if (conflictingSponsor != null) {
        throw Exception(
          'A title sponsorship already exists for this time period. '
          'Current sponsor: ${conflictingSponsor.sponsorName}',
        );
      }

      final endDate = DateTime(
        startDate.year,
        startDate.month + durationMonths,
        startDate.day,
      );

      final totalPrice =
          TitleSponsorshipModel.baseMonthlyPrice * durationMonths;

      final sponsorship = TitleSponsorshipModel(
        id: '', // Will be set by Firestore
        sponsorId: sponsorId,
        sponsorName: sponsorName,
        logoUrl: logoUrl,
        websiteUrl: websiteUrl,
        description: description,
        startDate: startDate,
        endDate: endDate,
        status: SponsorshipStatus.pending,
        monthlyPrice: TitleSponsorshipModel.baseMonthlyPrice,
        durationMonths: durationMonths,
        totalPrice: totalPrice,
        createdAt: DateTime.now(),
      );

      final docRef = await _sponsorshipsCollection.add(sponsorship.toMap());
      return docRef.id;
    } catch (e) {
      core.AppLogger.error('Error creating sponsorship: $e');
      rethrow;
    }
  }

  /// Check for conflicting sponsorships
  Future<TitleSponsorshipModel?> _checkForConflicts(
    DateTime startDate,
    int durationMonths,
  ) async {
    final endDate = DateTime(
      startDate.year,
      startDate.month + durationMonths,
      startDate.day,
    );

    final querySnapshot = await _sponsorshipsCollection
        .where(
          'status',
          whereIn: [
            SponsorshipStatus.active.index,
            SponsorshipStatus.pending.index,
          ],
        )
        .where('startDate', isLessThan: Timestamp.fromDate(endDate))
        .get();

    for (final doc in querySnapshot.docs) {
      final sponsor = TitleSponsorshipModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
      if (sponsor.endDate.isAfter(startDate)) {
        return sponsor;
      }
    }

    return null;
  }

  /// Approve a sponsorship (admin only)
  Future<void> approveSponorship(String sponsorshipId, String adminId) async {
    try {
      await _sponsorshipsCollection.doc(sponsorshipId).update({
        'status': SponsorshipStatus.active.index,
        'approvedAt': Timestamp.fromDate(DateTime.now()),
        'approvedBy': adminId,
      });
    } catch (e) {
      core.AppLogger.error('Error approving sponsorship: $e');
      rethrow;
    }
  }

  /// Cancel a sponsorship
  Future<void> cancelSponsorship(String sponsorshipId) async {
    try {
      await _sponsorshipsCollection.doc(sponsorshipId).update({
        'status': SponsorshipStatus.cancelled.index,
      });
    } catch (e) {
      core.AppLogger.error('Error cancelling sponsorship: $e');
      rethrow;
    }
  }

  /// Update sponsorship analytics (impressions)
  Future<void> trackImpression(String sponsorshipId, String location) async {
    try {
      final doc = await _sponsorshipsCollection.doc(sponsorshipId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final analytics = data['analytics'] as Map<String, dynamic>? ?? {};

      final totalImpressions =
          (analytics['totalImpressions'] as num?)?.toInt() ?? 0;
      final locationImpressions =
          analytics['locations'] as Map<String, dynamic>? ?? {};
      final currentLocationCount =
          (locationImpressions[location] as num?)?.toInt() ?? 0;

      locationImpressions[location] = currentLocationCount + 1;

      await _sponsorshipsCollection.doc(sponsorshipId).update({
        'analytics': {
          'totalImpressions': totalImpressions + 1,
          'locations': locationImpressions,
          'lastImpressionAt': Timestamp.fromDate(DateTime.now()),
        },
      });
    } catch (e) {
      core.AppLogger.error('Error tracking impression: $e');
      // Don't rethrow - impression tracking shouldn't break the app
    }
  }

  /// Get all sponsorships for a specific sponsor
  Future<List<TitleSponsorshipModel>> getSponsorshipsBySponsor(
    String sponsorId,
  ) async {
    try {
      final querySnapshot = await _sponsorshipsCollection
          .where('sponsorId', isEqualTo: sponsorId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => TitleSponsorshipModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      core.AppLogger.error('Error getting sponsorships by sponsor: $e');
      return [];
    }
  }

  /// Get all sponsorships (admin only)
  Future<List<TitleSponsorshipModel>> getAllSponsorships() async {
    try {
      final querySnapshot = await _sponsorshipsCollection
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => TitleSponsorshipModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      core.AppLogger.error('Error getting all sponsorships: $e');
      return [];
    }
  }

  /// Get pending sponsorships (admin only)
  Future<List<TitleSponsorshipModel>> getPendingSponsorships() async {
    try {
      final querySnapshot = await _sponsorshipsCollection
          .where('status', isEqualTo: SponsorshipStatus.pending.index)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => TitleSponsorshipModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      core.AppLogger.error('Error getting pending sponsorships: $e');
      return [];
    }
  }

  /// Update sponsorship details
  Future<void> updateSponsorship(
    String sponsorshipId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _sponsorshipsCollection.doc(sponsorshipId).update(updates);
    } catch (e) {
      core.AppLogger.error('Error updating sponsorship: $e');
      rethrow;
    }
  }

  /// Check and expire old sponsorships (should be run periodically)
  Future<void> expireOldSponsorships() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _sponsorshipsCollection
          .where('status', isEqualTo: SponsorshipStatus.active.index)
          .where('endDate', isLessThan: Timestamp.fromDate(now))
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.update({'status': SponsorshipStatus.expired.index});
      }
    } catch (e) {
      core.AppLogger.error('Error expiring old sponsorships: $e');
    }
  }
}

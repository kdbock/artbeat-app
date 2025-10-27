import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sponsorship_model.dart';
import 'unified_payment_service.dart'; // Unified payment processing
import 'user_service.dart';
import '../utils/logger.dart';

/// Service for managing artist sponsorships
class SponsorshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UnifiedPaymentService _paymentService =
      UnifiedPaymentService(); // Unified payment service for all revenue streams
  final UserService _userService = UserService();

  /// Create a new sponsorship
  Future<SponsorshipModel> createSponsorship({
    required String artistId,
    required SponsorshipTier tier,
    required String paymentMethodId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get sponsor and artist information
      final sponsorProfile = await _userService.getUserProfile(user.uid);
      final artistProfile = await _userService.getUserProfile(artistId);

      if (sponsorProfile == null) throw Exception('Sponsor profile not found');
      if (artistProfile == null) throw Exception('Artist profile not found');

      // Create Stripe subscription using enhanced payment service
      final subscriptionResult = await _createSponsorshipSubscription(
        tier: tier,
        paymentMethodId: paymentMethodId,
        artistId: artistId,
        sponsorProfile: sponsorProfile,
        artistProfile: artistProfile,
      );

      if (!subscriptionResult.success) {
        throw Exception(
          subscriptionResult.error ?? 'Failed to create subscription',
        );
      }

      // Create sponsorship record
      final sponsorship = SponsorshipModel(
        id: _firestore.collection('sponsorships').doc().id,
        sponsorId: user.uid,
        sponsorName: sponsorProfile['displayName'] as String? ?? 'Anonymous',
        artistId: artistId,
        artistName: artistProfile['displayName'] as String? ?? 'Artist',
        tier: tier,
        monthlyAmount: tier.monthlyPrice,
        status: SponsorshipStatus.active,
        createdAt: DateTime.now(),
        nextBillingDate: DateTime.now().add(const Duration(days: 30)),
        stripeSubscriptionId: subscriptionResult.subscriptionId,
        benefits: tier.defaultBenefits,
        metadata: {
          'stripeCustomerId': subscriptionResult
              .subscriptionId, // Using subscriptionId as customer reference
          'stripePriceId': tier.name, // Using tier name as price reference
        },
      );

      // Save to Firestore
      await _firestore
          .collection('sponsorships')
          .doc(sponsorship.id)
          .set(sponsorship.toFirestore());

      // Update artist earnings
      await _updateArtistEarnings(
        artistId: artistId,
        amount: tier.monthlyPrice,
        sponsorId: user.uid,
        sponsorName: sponsorship.sponsorName,
      );

      return sponsorship;
    } catch (e) {
      throw Exception('Failed to create sponsorship: $e');
    }
  }

  /// Create sponsorship subscription using enhanced payment service
  Future<SubscriptionResult> _createSponsorshipSubscription({
    required SponsorshipTier tier,
    required String paymentMethodId,
    required String artistId,
    required Map<String, dynamic> sponsorProfile,
    required Map<String, dynamic> artistProfile,
  }) async {
    try {
      // Use the enhanced payment service to make authenticated request
      final body = {
        'tierApiName': tier.name.toLowerCase(),
        'paymentMethodId': paymentMethodId,
        'amount': (tier.monthlyPrice * 100).toInt(), // Convert to cents
        'currency': 'usd',
        'deviceFingerprint': await _paymentService.getDeviceFingerprint(),
        'metadata': {
          'type': 'sponsorship',
          'artistId': artistId,
          'tier': tier.name,
          'sponsorName':
              sponsorProfile['displayName'] as String? ?? 'Anonymous',
          'artistName': artistProfile['displayName'] as String? ?? 'Artist',
        },
      };

      final response = await _paymentService.makeAuthenticatedRequest(
        functionKey: 'processSponsorshipPayment',
        body: body,
      );

      if (response.statusCode != 200) {
        return SubscriptionResult(
          success: false,
          error: 'Failed to create sponsorship: ${response.body}',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      return SubscriptionResult(
        success: true,
        subscriptionId: data['subscriptionId'] as String?,
        clientSecret: data['clientSecret'] as String?,
      );
    } catch (e) {
      return SubscriptionResult(success: false, error: e.toString());
    }
  }

  /// Get sponsorships for a user (as sponsor)
  Future<List<SponsorshipModel>> getUserSponsorships() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _firestore
          .collection('sponsorships')
          .where('sponsorId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SponsorshipModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user sponsorships: $e');
    }
  }

  /// Get sponsorships for an artist (as recipient)
  Future<List<SponsorshipModel>> getArtistSponsorships(String artistId) async {
    try {
      final snapshot = await _firestore
          .collection('sponsorships')
          .where('artistId', isEqualTo: artistId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SponsorshipModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get artist sponsorships: $e');
    }
  }

  /// Get sponsorship statistics for an artist
  Future<Map<String, dynamic>> getArtistSponsorshipStats(
    String artistId,
  ) async {
    try {
      final sponsorships = await getArtistSponsorships(artistId);

      final stats = {
        'totalSponsors': sponsorships.length,
        'monthlyRevenue': sponsorships.fold<double>(
          0.0,
          (sum, sponsorship) => sum + sponsorship.monthlyAmount,
        ),
        'tierBreakdown': <String, int>{},
        'averageAmount': 0.0,
      };

      // Calculate tier breakdown
      for (final sponsorship in sponsorships) {
        final tierName = sponsorship.tier.displayName;
        final tierBreakdown = stats['tierBreakdown'] as Map<String, int>;
        tierBreakdown[tierName] = (tierBreakdown[tierName] ?? 0) + 1;
      }

      // Calculate average amount
      if (sponsorships.isNotEmpty) {
        final monthlyRevenue = stats['monthlyRevenue'] as double;
        stats['averageAmount'] = monthlyRevenue / sponsorships.length;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get sponsorship stats: $e');
    }
  }

  /// Cancel a sponsorship
  Future<void> cancelSponsorship(String sponsorshipId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get sponsorship
      final doc = await _firestore
          .collection('sponsorships')
          .doc(sponsorshipId)
          .get();

      if (!doc.exists) throw Exception('Sponsorship not found');

      final sponsorship = SponsorshipModel.fromFirestore(doc);

      // Verify user owns this sponsorship
      if (sponsorship.sponsorId != user.uid) {
        throw Exception('Not authorized to cancel this sponsorship');
      }

      // Cancel Stripe subscription using enhanced payment service
      if (sponsorship.stripeSubscriptionId != null) {
        final body = {
          'subscriptionId': sponsorship.stripeSubscriptionId,
          'deviceFingerprint': await _paymentService.getDeviceFingerprint(),
        };

        final response = await _paymentService.makeAuthenticatedRequest(
          functionKey: 'cancelSubscription',
          body: body,
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to cancel subscription: ${response.body}');
        }
      }

      // Update sponsorship status
      await _firestore.collection('sponsorships').doc(sponsorshipId).update({
        'status': SponsorshipStatus.cancelled.name,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to cancel sponsorship: $e');
    }
  }

  /// Pause a sponsorship
  Future<void> pauseSponsorship(String sponsorshipId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get sponsorship
      final doc = await _firestore
          .collection('sponsorships')
          .doc(sponsorshipId)
          .get();

      if (!doc.exists) throw Exception('Sponsorship not found');

      final sponsorship = SponsorshipModel.fromFirestore(doc);

      // Verify user owns this sponsorship
      if (sponsorship.sponsorId != user.uid) {
        throw Exception('Not authorized to pause this sponsorship');
      }

      // Pause Stripe subscription
      if (sponsorship.stripeSubscriptionId != null) {
        await _paymentService.pauseSubscription(
          subscriptionId: sponsorship.stripeSubscriptionId!,
        );
      }

      // Update sponsorship status
      await _firestore.collection('sponsorships').doc(sponsorshipId).update({
        'status': SponsorshipStatus.paused.name,
      });
    } catch (e) {
      throw Exception('Failed to pause sponsorship: $e');
    }
  }

  /// Resume a paused sponsorship
  Future<void> resumeSponsorship(String sponsorshipId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get sponsorship
      final doc = await _firestore
          .collection('sponsorships')
          .doc(sponsorshipId)
          .get();

      if (!doc.exists) throw Exception('Sponsorship not found');

      final sponsorship = SponsorshipModel.fromFirestore(doc);

      // Verify user owns this sponsorship
      if (sponsorship.sponsorId != user.uid) {
        throw Exception('Not authorized to resume this sponsorship');
      }

      // Resume Stripe subscription
      if (sponsorship.stripeSubscriptionId != null) {
        await _paymentService.resumeSubscription(
          subscriptionId: sponsorship.stripeSubscriptionId!,
        );
      }

      // Update sponsorship status
      await _firestore.collection('sponsorships').doc(sponsorshipId).update({
        'status': SponsorshipStatus.active.name,
        'nextBillingDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
      });
    } catch (e) {
      throw Exception('Failed to resume sponsorship: $e');
    }
  }

  /// Update sponsorship tier
  Future<void> updateSponsorshipTier({
    required String sponsorshipId,
    required SponsorshipTier newTier,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get sponsorship
      final doc = await _firestore
          .collection('sponsorships')
          .doc(sponsorshipId)
          .get();

      if (!doc.exists) throw Exception('Sponsorship not found');

      final sponsorship = SponsorshipModel.fromFirestore(doc);

      // Verify user owns this sponsorship
      if (sponsorship.sponsorId != user.uid) {
        throw Exception('Not authorized to update this sponsorship');
      }

      // Update Stripe subscription
      if (sponsorship.stripeSubscriptionId != null) {
        await _paymentService.updateSubscriptionPrice(
          subscriptionId: sponsorship.stripeSubscriptionId!,
          newPrice: newTier.monthlyPrice,
        );
      }

      // Update sponsorship
      await _firestore.collection('sponsorships').doc(sponsorshipId).update({
        'tier': newTier.name,
        'monthlyAmount': newTier.monthlyPrice,
        'benefits': newTier.defaultBenefits.map((b) => b.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to update sponsorship tier: $e');
    }
  }

  /// Get sponsorship payment history
  Future<List<SponsorshipPayment>> getSponsorshipPayments(
    String sponsorshipId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('sponsorship_payments')
          .where('sponsorshipId', isEqualTo: sponsorshipId)
          .orderBy('paymentDate', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => SponsorshipPayment.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get sponsorship payments: $e');
    }
  }

  /// Record a sponsorship payment (called by webhook)
  Future<void> recordSponsorshipPayment({
    required String sponsorshipId,
    required double amount,
    required String status,
    String? stripePaymentIntentId,
    String? failureReason,
  }) async {
    try {
      final payment = SponsorshipPayment(
        id: _firestore.collection('sponsorship_payments').doc().id,
        sponsorshipId: sponsorshipId,
        amount: amount,
        paymentDate: DateTime.now(),
        status: status,
        stripePaymentIntentId: stripePaymentIntentId,
        failureReason: failureReason,
      );

      await _firestore
          .collection('sponsorship_payments')
          .doc(payment.id)
          .set(payment.toFirestore());

      // If payment succeeded, update artist earnings
      if (status == 'succeeded') {
        final sponsorshipDoc = await _firestore
            .collection('sponsorships')
            .doc(sponsorshipId)
            .get();

        if (sponsorshipDoc.exists) {
          final sponsorship = SponsorshipModel.fromFirestore(sponsorshipDoc);
          await _updateArtistEarnings(
            artistId: sponsorship.artistId,
            amount: amount,
            sponsorId: sponsorship.sponsorId,
            sponsorName: sponsorship.sponsorName,
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to record sponsorship payment: $e');
    }
  }

  /// Update artist earnings when sponsorship payment is received
  Future<void> _updateArtistEarnings({
    required String artistId,
    required double amount,
    required String sponsorId,
    required String sponsorName,
  }) async {
    try {
      // This would integrate with the EarningsService
      // For now, we'll create a simple earnings transaction
      await _firestore.collection('earnings_transactions').add({
        'artistId': artistId,
        'type': 'sponsorship',
        'amount': amount,
        'fromUserId': sponsorId,
        'fromUserName': sponsorName,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'status': 'completed',
        'description': 'Monthly sponsorship payment',
      });
    } catch (e) {
      // Log error but don't fail the sponsorship creation
      AppLogger.info('Failed to update artist earnings: $e');
    }
  }

  /// Get available sponsorship tiers
  List<SponsorshipTier> getAvailableTiers() {
    return SponsorshipTier.values;
  }

  /// Check if user can sponsor an artist
  Future<bool> canSponsorArtist(String artistId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Check if user already sponsors this artist
      final existingSponsorship = await _firestore
          .collection('sponsorships')
          .where('sponsorId', isEqualTo: user.uid)
          .where('artistId', isEqualTo: artistId)
          .where('status', whereIn: ['active', 'paused'])
          .get();

      return existingSponsorship.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }
}

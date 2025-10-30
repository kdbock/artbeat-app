import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/commission_analytics_model.dart'
    show ArtistCommissionAnalytics;
import '../models/direct_commission_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

class CommissionAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate and store analytics for an artist
  Future<void> calculateArtistAnalytics(String artistId) async {
    try {
      // Get all commissions for artist
      final commissions = await _firestore
          .collection('direct_commissions')
          .where('artistId', isEqualTo: artistId)
          .get();

      if (commissions.docs.isEmpty) return;

      final models = commissions.docs
          .map((doc) => DirectCommissionModel.fromFirestore(doc))
          .toList();

      // Calculate metrics
      final completed = models
          .where((c) => c.status == CommissionStatus.completed)
          .length;
      final active = models
          .where(
            (c) =>
                c.status == CommissionStatus.inProgress ||
                c.status == CommissionStatus.accepted,
          )
          .length;
      final cancelled = models
          .where((c) => c.status == CommissionStatus.cancelled)
          .length;

      // Financial metrics
      double totalEarnings = 0;
      const double totalRefunded = 0;
      double estimatedEarnings = 0;

      for (final commission in models) {
        if (commission.status == CommissionStatus.completed ||
            commission.status == CommissionStatus.delivered) {
          totalEarnings += commission.totalPrice;
        } else if (commission.status == CommissionStatus.inProgress ||
            commission.status == CommissionStatus.accepted) {
          estimatedEarnings += commission.totalPrice;
        }
      }

      // Unique clients
      final uniqueClients = <String>{};
      for (final commission in models) {
        uniqueClients.add(commission.clientId);
      }

      // Commission by type breakdown
      final commissionByType = <String, int>{};
      final earningsByType = <String, double>{};

      for (final commission in models) {
        final typeName = commission.type.name;
        commissionByType[typeName] = (commissionByType[typeName] ?? 0) + 1;

        if (commission.status == CommissionStatus.completed ||
            commission.status == CommissionStatus.delivered) {
          earningsByType[typeName] =
              (earningsByType[typeName] ?? 0) + commission.totalPrice;
        }
      }

      // Get ratings
      final ratings = await _firestore
          .collection('commission_ratings')
          .where('ratedUserId', isEqualTo: artistId)
          .get();

      double avgRating = 0;
      if (ratings.docs.isNotEmpty) {
        double totalRating = 0;
        for (final doc in ratings.docs) {
          final data = doc.data();
          totalRating += (data['overallRating'] as num?)?.toDouble() ?? 0;
        }
        avgRating = totalRating / ratings.docs.length;
      }

      // Get artist name
      final artistDoc = await _firestore
          .collection('users')
          .doc(artistId)
          .get();
      final artistName =
          (artistDoc.data()?['displayName'] as String?) ?? 'Unknown Artist';

      final analytics = ArtistCommissionAnalytics(
        id: _firestore.collection('commission_analytics').doc().id,
        artistId: artistId,
        artistName: artistName,
        period: DateTime(DateTime.now().year, DateTime.now().month),
        totalCommissions: models.length,
        activeCommissions: active,
        completedCommissions: completed,
        cancelledCommissions: cancelled,
        totalEarnings: totalEarnings,
        averageCommissionValue: models.isNotEmpty
            ? totalEarnings / completed
            : 0,
        totalRefunded: totalRefunded,
        estimatedEarnings: estimatedEarnings,
        acceptanceRate: models.isNotEmpty
            ? (completed + active) / models.length
            : 0,
        completionRate: (active + completed) > 0
            ? completed / (active + completed)
            : 0,
        repeatClientRate: 0.0, // Calculate from client frequency
        averageRating: avgRating,
        ratingsCount: ratings.docs.length,
        revisionRequestsCount: 0, // Calculate from status changes
        disputesCount: 0, // Calculate from disputes collection
        averageTurnaroundDays: _calculateAvgTurnaround(models),
        onTimeDeliveryCount: _countOnTimeDeliveries(models),
        lateDeliveryCount: _countLateDeliveries(models),
        uniqueClients: uniqueClients.length,
        returningClients: _countReturningClients(models),
        topClientId: '',
        topClientName: '',
        commissionsByType: commissionByType,
        earningsByType: earningsByType,
        monthOverMonthGrowth: 0.0, // Calculate from previous month
        conversionRate: 0.0, // Calculate quote to accepted ratio
        createdAt: DateTime.now(),
        metadata: {},
      );

      await _firestore
          .collection('commission_analytics')
          .doc(analytics.id)
          .set(analytics.toFirestore());
    } catch (e) {
      AppLogger.error('Failed to calculate analytics: $e');
    }
  }

  /// Get artist analytics
  Future<ArtistCommissionAnalytics?> getArtistAnalytics(String artistId) async {
    try {
      // Get current month's analytics
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month);

      final query = await _firestore
          .collection('commission_analytics')
          .where('artistId', isEqualTo: artistId)
          .where('period', isEqualTo: Timestamp.fromDate(startOfMonth))
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        // Calculate new analytics
        await calculateArtistAnalytics(artistId);
        return getArtistAnalytics(artistId);
      }

      return ArtistCommissionAnalytics.fromFirestore(query.docs.first);
    } catch (e) {
      AppLogger.error('Failed to get analytics: $e');
      return null;
    }
  }

  /// Get analytics history (for charts)
  Future<List<ArtistCommissionAnalytics>> getAnalyticsHistory(
    String artistId, {
    int months = 6,
  }) async {
    try {
      final query = await _firestore
          .collection('commission_analytics')
          .where('artistId', isEqualTo: artistId)
          .orderBy('period', descending: true)
          .limit(months)
          .get();

      return query.docs
          .map((doc) => ArtistCommissionAnalytics.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get analytics history: $e');
    }
  }

  /// Calculate average turnaround days
  double _calculateAvgTurnaround(List<DirectCommissionModel> commissions) {
    final completedWithDates = commissions
        .where(
          (c) =>
              c.status == CommissionStatus.completed ||
              c.status == CommissionStatus.delivered,
        )
        .where((c) => c.acceptedAt != null && c.completedAt != null)
        .toList();

    if (completedWithDates.isEmpty) return 0;

    double totalDays = 0;
    for (final commission in completedWithDates) {
      final days = commission.completedAt!
          .difference(commission.acceptedAt!)
          .inDays;
      totalDays += days;
    }

    return totalDays / completedWithDates.length;
  }

  /// Count on-time deliveries
  int _countOnTimeDeliveries(List<DirectCommissionModel> commissions) {
    return commissions
        .where(
          (c) =>
              c.status == CommissionStatus.completed ||
              c.status == CommissionStatus.delivered,
        )
        .where(
          (c) =>
              c.deadline != null &&
              c.completedAt != null &&
              c.completedAt!.isBefore(c.deadline!),
        )
        .length;
  }

  /// Count late deliveries
  int _countLateDeliveries(List<DirectCommissionModel> commissions) {
    return commissions
        .where(
          (c) =>
              c.status == CommissionStatus.completed ||
              c.status == CommissionStatus.delivered,
        )
        .where(
          (c) =>
              c.deadline != null &&
              c.completedAt != null &&
              c.completedAt!.isAfter(c.deadline!),
        )
        .length;
  }

  /// Count returning clients
  int _countReturningClients(List<DirectCommissionModel> commissions) {
    final clientCounts = <String, int>{};
    for (final commission in commissions) {
      clientCounts[commission.clientId] =
          (clientCounts[commission.clientId] ?? 0) + 1;
    }
    return clientCounts.values.where((count) => count > 1).length;
  }
}

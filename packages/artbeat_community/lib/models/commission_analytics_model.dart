import 'package:cloud_firestore/cloud_firestore.dart';

/// Commission analytics for artists - comprehensive analytics dashboard
class ArtistCommissionAnalytics {
  final String id;
  final String artistId;
  final String artistName;
  final DateTime period; // Start of month/week

  // Basic metrics
  final int totalCommissions;
  final int activeCommissions;
  final int completedCommissions;
  final int cancelledCommissions;

  // Financial metrics
  final double totalEarnings;
  final double averageCommissionValue;
  final double totalRefunded;
  final double estimatedEarnings; // From in-progress commissions

  // Rate metrics
  final double acceptanceRate; // % of requests accepted
  final double completionRate; // % of accepted completed
  final double repeatClientRate; // % from repeat clients

  // Quality metrics
  final double averageRating;
  final int ratingsCount;
  final int revisionRequestsCount;
  final int disputesCount;

  // Timeline metrics
  final double averageTurnaroundDays;
  final int onTimeDeliveryCount;
  final int lateDeliveryCount;

  // Client metrics
  final int uniqueClients;
  final int returningClients;
  final String topClientId;
  final String topClientName;

  // Commission type breakdown
  final Map<String, int> commissionsByType; // {"digital": 5, "portrait": 3}
  final Map<String, double> earningsByType;

  // Growth metrics
  final double monthOverMonthGrowth;
  final double conversionRate; // Quotes to accepted

  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  ArtistCommissionAnalytics({
    required this.id,
    required this.artistId,
    required this.artistName,
    required this.period,
    required this.totalCommissions,
    required this.activeCommissions,
    required this.completedCommissions,
    required this.cancelledCommissions,
    required this.totalEarnings,
    required this.averageCommissionValue,
    required this.totalRefunded,
    required this.estimatedEarnings,
    required this.acceptanceRate,
    required this.completionRate,
    required this.repeatClientRate,
    required this.averageRating,
    required this.ratingsCount,
    required this.revisionRequestsCount,
    required this.disputesCount,
    required this.averageTurnaroundDays,
    required this.onTimeDeliveryCount,
    required this.lateDeliveryCount,
    required this.uniqueClients,
    required this.returningClients,
    required this.topClientId,
    required this.topClientName,
    required this.commissionsByType,
    required this.earningsByType,
    required this.monthOverMonthGrowth,
    required this.conversionRate,
    required this.createdAt,
    this.updatedAt,
    required this.metadata,
  });

  // Get summary stats
  Map<String, dynamic> getSummary() {
    return {
      'totalCommissions': totalCommissions,
      'completedCommissions': completedCommissions,
      'activeCommissions': activeCommissions,
      'totalEarnings': totalEarnings.toStringAsFixed(2),
      'averageRating': averageRating.toStringAsFixed(1),
      'completionRate': '${(completionRate * 100).toStringAsFixed(1)}%',
      'averageTurnaroundDays': averageTurnaroundDays.toStringAsFixed(1),
    };
  }

  factory ArtistCommissionAnalytics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ArtistCommissionAnalytics(
      id: doc.id,
      artistId: data['artistId'] as String? ?? '',
      artistName: data['artistName'] as String? ?? '',
      period: (data['period'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalCommissions: data['totalCommissions'] as int? ?? 0,
      activeCommissions: data['activeCommissions'] as int? ?? 0,
      completedCommissions: data['completedCommissions'] as int? ?? 0,
      cancelledCommissions: data['cancelledCommissions'] as int? ?? 0,
      totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      averageCommissionValue:
          (data['averageCommissionValue'] as num?)?.toDouble() ?? 0.0,
      totalRefunded: (data['totalRefunded'] as num?)?.toDouble() ?? 0.0,
      estimatedEarnings: (data['estimatedEarnings'] as num?)?.toDouble() ?? 0.0,
      acceptanceRate: (data['acceptanceRate'] as num?)?.toDouble() ?? 0.0,
      completionRate: (data['completionRate'] as num?)?.toDouble() ?? 0.0,
      repeatClientRate: (data['repeatClientRate'] as num?)?.toDouble() ?? 0.0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: data['ratingsCount'] as int? ?? 0,
      revisionRequestsCount: data['revisionRequestsCount'] as int? ?? 0,
      disputesCount: data['disputesCount'] as int? ?? 0,
      averageTurnaroundDays:
          (data['averageTurnaroundDays'] as num?)?.toDouble() ?? 0.0,
      onTimeDeliveryCount: data['onTimeDeliveryCount'] as int? ?? 0,
      lateDeliveryCount: data['lateDeliveryCount'] as int? ?? 0,
      uniqueClients: data['uniqueClients'] as int? ?? 0,
      returningClients: data['returningClients'] as int? ?? 0,
      topClientId: data['topClientId'] as String? ?? '',
      topClientName: data['topClientName'] as String? ?? '',
      commissionsByType: Map<String, int>.from(
        data['commissionsByType'] as Map<String, dynamic>? ?? {},
      ),
      earningsByType: Map<String, double>.from(
        (data['earningsByType'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      monthOverMonthGrowth:
          (data['monthOverMonthGrowth'] as num?)?.toDouble() ?? 0.0,
      conversionRate: (data['conversionRate'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'artistId': artistId,
      'artistName': artistName,
      'period': Timestamp.fromDate(period),
      'totalCommissions': totalCommissions,
      'activeCommissions': activeCommissions,
      'completedCommissions': completedCommissions,
      'cancelledCommissions': cancelledCommissions,
      'totalEarnings': totalEarnings,
      'averageCommissionValue': averageCommissionValue,
      'totalRefunded': totalRefunded,
      'estimatedEarnings': estimatedEarnings,
      'acceptanceRate': acceptanceRate,
      'completionRate': completionRate,
      'repeatClientRate': repeatClientRate,
      'averageRating': averageRating,
      'ratingsCount': ratingsCount,
      'revisionRequestsCount': revisionRequestsCount,
      'disputesCount': disputesCount,
      'averageTurnaroundDays': averageTurnaroundDays,
      'onTimeDeliveryCount': onTimeDeliveryCount,
      'lateDeliveryCount': lateDeliveryCount,
      'uniqueClients': uniqueClients,
      'returningClients': returningClients,
      'topClientId': topClientId,
      'topClientName': topClientName,
      'commissionsByType': commissionsByType,
      'earningsByType': earningsByType,
      'monthOverMonthGrowth': monthOverMonthGrowth,
      'conversionRate': conversionRate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
    };
  }
}

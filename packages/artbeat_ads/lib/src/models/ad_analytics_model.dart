import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for ad analytics data aggregation
class AdAnalyticsModel {
  final String adId;
  final String ownerId;
  final int totalImpressions;
  final int totalClicks;
  final double clickThroughRate;
  final double totalRevenue;
  final double averageViewDuration;
  final DateTime firstImpressionDate;
  final DateTime lastImpressionDate;
  final Map<String, int> locationBreakdown;
  final Map<String, int> dailyImpressions;
  final Map<String, int> dailyClicks;
  final DateTime lastUpdated;

  AdAnalyticsModel({
    required this.adId,
    required this.ownerId,
    required this.totalImpressions,
    required this.totalClicks,
    required this.clickThroughRate,
    required this.totalRevenue,
    required this.averageViewDuration,
    required this.firstImpressionDate,
    required this.lastImpressionDate,
    required this.locationBreakdown,
    required this.dailyImpressions,
    required this.dailyClicks,
    required this.lastUpdated,
  });

  /// Calculate click-through rate
  static double calculateCTR(int impressions, int clicks) {
    if (impressions == 0) return 0.0;
    return (clicks / impressions) * 100;
  }

  /// Factory constructor from Firestore data
  factory AdAnalyticsModel.fromMap(Map<String, dynamic> map) {
    return AdAnalyticsModel(
      adId: (map['adId'] ?? '') as String,
      ownerId: (map['ownerId'] ?? '') as String,
      totalImpressions: (map['totalImpressions'] ?? 0) as int,
      totalClicks: (map['totalClicks'] ?? 0) as int,
      clickThroughRate: ((map['clickThroughRate'] ?? 0.0) as num).toDouble(),
      totalRevenue: ((map['totalRevenue'] ?? 0.0) as num).toDouble(),
      averageViewDuration: ((map['averageViewDuration'] ?? 0.0) as num)
          .toDouble(),
      firstImpressionDate: map['firstImpressionDate'] != null
          ? (map['firstImpressionDate'] as Timestamp).toDate()
          : DateTime.now(),
      lastImpressionDate: map['lastImpressionDate'] != null
          ? (map['lastImpressionDate'] as Timestamp).toDate()
          : DateTime.now(),
      locationBreakdown: Map<String, int>.from(
        (map['locationBreakdown'] ?? <String, int>{}) as Map,
      ),
      dailyImpressions: Map<String, int>.from(
        (map['dailyImpressions'] ?? <String, int>{}) as Map,
      ),
      dailyClicks: Map<String, int>.from(
        (map['dailyClicks'] ?? <String, int>{}) as Map,
      ),
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'adId': adId,
      'ownerId': ownerId,
      'totalImpressions': totalImpressions,
      'totalClicks': totalClicks,
      'clickThroughRate': clickThroughRate,
      'totalRevenue': totalRevenue,
      'averageViewDuration': averageViewDuration,
      'firstImpressionDate': Timestamp.fromDate(firstImpressionDate),
      'lastImpressionDate': Timestamp.fromDate(lastImpressionDate),
      'locationBreakdown': locationBreakdown,
      'dailyImpressions': dailyImpressions,
      'dailyClicks': dailyClicks,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Copy with method for updates
  AdAnalyticsModel copyWith({
    String? adId,
    String? ownerId,
    int? totalImpressions,
    int? totalClicks,
    double? clickThroughRate,
    double? totalRevenue,
    double? averageViewDuration,
    DateTime? firstImpressionDate,
    DateTime? lastImpressionDate,
    Map<String, int>? locationBreakdown,
    Map<String, int>? dailyImpressions,
    Map<String, int>? dailyClicks,
    DateTime? lastUpdated,
  }) {
    return AdAnalyticsModel(
      adId: adId ?? this.adId,
      ownerId: ownerId ?? this.ownerId,
      totalImpressions: totalImpressions ?? this.totalImpressions,
      totalClicks: totalClicks ?? this.totalClicks,
      clickThroughRate: clickThroughRate ?? this.clickThroughRate,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      averageViewDuration: averageViewDuration ?? this.averageViewDuration,
      firstImpressionDate: firstImpressionDate ?? this.firstImpressionDate,
      lastImpressionDate: lastImpressionDate ?? this.lastImpressionDate,
      locationBreakdown: locationBreakdown ?? this.locationBreakdown,
      dailyImpressions: dailyImpressions ?? this.dailyImpressions,
      dailyClicks: dailyClicks ?? this.dailyClicks,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

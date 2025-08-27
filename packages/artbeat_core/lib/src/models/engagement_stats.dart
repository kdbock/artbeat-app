import 'package:cloud_firestore/cloud_firestore.dart';

class EngagementStats {
  final int connectCount;
  final int captureCount;
  final int shareCount;
  final int createdCount;
  final int celebrateCount;
  final DateTime lastUpdated;

  EngagementStats({
    this.connectCount = 0,
    this.captureCount = 0,
    this.shareCount = 0,
    this.createdCount = 0,
    this.celebrateCount = 0,
    required this.lastUpdated,
  });

  factory EngagementStats.fromJson(Map<String, dynamic> json) {
    return EngagementStats(
      connectCount: json['connectCount'] as int? ?? 0,
      captureCount: json['captureCount'] as int? ?? 0,
      shareCount: json['shareCount'] as int? ?? 0,
      createdCount: json['createdCount'] as int? ?? 0,
      celebrateCount: json['celebrateCount'] as int? ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? (json['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connectCount': connectCount,
      'captureCount': captureCount,
      'shareCount': shareCount,
      'createdCount': createdCount,
      'celebrateCount': celebrateCount,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  Map<String, dynamic> toFirestore() => toJson();
}

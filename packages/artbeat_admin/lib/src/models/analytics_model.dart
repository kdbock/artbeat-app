/// Date range options for analytics
enum DateRange {
  last7Days,
  last30Days,
  last90Days,
  lastYear;

  String get displayName {
    switch (this) {
      case DateRange.last7Days:
        return 'Last 7 Days';
      case DateRange.last30Days:
        return 'Last 30 Days';
      case DateRange.last90Days:
        return 'Last 90 Days';
      case DateRange.lastYear:
        return 'Last Year';
    }
  }

  DateTime get startDate {
    final now = DateTime.now();
    switch (this) {
      case DateRange.last7Days:
        return now.subtract(const Duration(days: 7));
      case DateRange.last30Days:
        return now.subtract(const Duration(days: 30));
      case DateRange.last90Days:
        return now.subtract(const Duration(days: 90));
      case DateRange.lastYear:
        return now.subtract(const Duration(days: 365));
    }
  }
}

/// Top content item model
class TopContentItem {
  final String id;
  final String title;
  final String type;
  final int views;
  final int likes;
  final String authorName;
  final DateTime createdAt;

  TopContentItem({
    required this.id,
    required this.title,
    required this.type,
    required this.views,
    required this.likes,
    required this.authorName,
    required this.createdAt,
  });

  factory TopContentItem.fromMap(Map<String, dynamic> map) {
    return TopContentItem(
      id: (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      type: (map['type'] as String?) ?? '',
      views: (map['views'] as int?) ?? 0,
      likes: (map['likes'] as int?) ?? 0,
      authorName: (map['authorName'] as String?) ?? '',
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'] as String)
          : (map['createdAt'] as DateTime?) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'views': views,
      'likes': likes,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Analytics data model
class AnalyticsModel {
  // User metrics
  final int totalUsers;
  final int activeUsers;
  final int newUsers;
  final double retentionRate;
  final double userGrowth;
  final double activeUserGrowth;
  final double newUserGrowth;
  final double retentionChange;

  // Content metrics
  final int totalArtworks;
  final int totalPosts;
  final int totalComments;
  final int totalEvents;
  final double artworkGrowth;
  final double postGrowth;
  final double commentGrowth;
  final double eventGrowth;

  // Engagement metrics
  final double avgSessionDuration;
  final int pageViews;
  final double bounceRate;
  final int totalLikes;
  final double sessionDurationChange;
  final double pageViewGrowth;
  final double bounceRateChange;
  final double likeGrowth;

  // Technical metrics
  final double errorRate;
  final double avgResponseTime;
  final int storageUsed;
  final int bandwidthUsed;
  final double errorRateChange;
  final double responseTimeChange;
  final double storageGrowth;
  final double bandwidthChange;

  // Top content
  final List<TopContentItem> topContent;

  // Meta data
  final DateTime startDate;
  final DateTime endDate;
  final DateTime generatedAt;

  AnalyticsModel({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsers,
    required this.retentionRate,
    required this.userGrowth,
    required this.activeUserGrowth,
    required this.newUserGrowth,
    required this.retentionChange,
    required this.totalArtworks,
    required this.totalPosts,
    required this.totalComments,
    required this.totalEvents,
    required this.artworkGrowth,
    required this.postGrowth,
    required this.commentGrowth,
    required this.eventGrowth,
    required this.avgSessionDuration,
    required this.pageViews,
    required this.bounceRate,
    required this.totalLikes,
    required this.sessionDurationChange,
    required this.pageViewGrowth,
    required this.bounceRateChange,
    required this.likeGrowth,
    required this.errorRate,
    required this.avgResponseTime,
    required this.storageUsed,
    required this.bandwidthUsed,
    required this.errorRateChange,
    required this.responseTimeChange,
    required this.storageGrowth,
    required this.bandwidthChange,
    required this.topContent,
    required this.startDate,
    required this.endDate,
    required this.generatedAt,
  });

  factory AnalyticsModel.fromMap(Map<String, dynamic> map) {
    return AnalyticsModel(
      totalUsers: (map['totalUsers'] as int?) ?? 0,
      activeUsers: (map['activeUsers'] as int?) ?? 0,
      newUsers: (map['newUsers'] as int?) ?? 0,
      retentionRate: ((map['retentionRate'] as num?) ?? 0.0).toDouble(),
      userGrowth: ((map['userGrowth'] as num?) ?? 0.0).toDouble(),
      activeUserGrowth: ((map['activeUserGrowth'] as num?) ?? 0.0).toDouble(),
      newUserGrowth: ((map['newUserGrowth'] as num?) ?? 0.0).toDouble(),
      retentionChange: ((map['retentionChange'] as num?) ?? 0.0).toDouble(),
      totalArtworks: (map['totalArtworks'] as int?) ?? 0,
      totalPosts: (map['totalPosts'] as int?) ?? 0,
      totalComments: (map['totalComments'] as int?) ?? 0,
      totalEvents: (map['totalEvents'] as int?) ?? 0,
      artworkGrowth: ((map['artworkGrowth'] as num?) ?? 0.0).toDouble(),
      postGrowth: ((map['postGrowth'] as num?) ?? 0.0).toDouble(),
      commentGrowth: ((map['commentGrowth'] as num?) ?? 0.0).toDouble(),
      eventGrowth: ((map['eventGrowth'] as num?) ?? 0.0).toDouble(),
      avgSessionDuration:
          ((map['avgSessionDuration'] as num?) ?? 0.0).toDouble(),
      pageViews: (map['pageViews'] as int?) ?? 0,
      bounceRate: ((map['bounceRate'] as num?) ?? 0.0).toDouble(),
      totalLikes: (map['totalLikes'] as int?) ?? 0,
      sessionDurationChange:
          ((map['sessionDurationChange'] as num?) ?? 0.0).toDouble(),
      pageViewGrowth: ((map['pageViewGrowth'] as num?) ?? 0.0).toDouble(),
      bounceRateChange: ((map['bounceRateChange'] as num?) ?? 0.0).toDouble(),
      likeGrowth: ((map['likeGrowth'] as num?) ?? 0.0).toDouble(),
      errorRate: ((map['errorRate'] as num?) ?? 0.0).toDouble(),
      avgResponseTime: ((map['avgResponseTime'] as num?) ?? 0.0).toDouble(),
      storageUsed: (map['storageUsed'] as int?) ?? 0,
      bandwidthUsed: (map['bandwidthUsed'] as int?) ?? 0,
      errorRateChange: ((map['errorRateChange'] as num?) ?? 0.0).toDouble(),
      responseTimeChange:
          ((map['responseTimeChange'] as num?) ?? 0.0).toDouble(),
      storageGrowth: ((map['storageGrowth'] as num?) ?? 0.0).toDouble(),
      bandwidthChange: ((map['bandwidthChange'] as num?) ?? 0.0).toDouble(),
      topContent: (map['topContent'] as List<dynamic>?)
              ?.map((item) =>
                  TopContentItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      startDate: map['startDate'] is String
          ? DateTime.parse(map['startDate'] as String)
          : (map['startDate'] as DateTime?) ?? DateTime.now(),
      endDate: map['endDate'] is String
          ? DateTime.parse(map['endDate'] as String)
          : (map['endDate'] as DateTime?) ?? DateTime.now(),
      generatedAt: map['generatedAt'] is String
          ? DateTime.parse(map['generatedAt'] as String)
          : (map['generatedAt'] as DateTime?) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'newUsers': newUsers,
      'retentionRate': retentionRate,
      'userGrowth': userGrowth,
      'activeUserGrowth': activeUserGrowth,
      'newUserGrowth': newUserGrowth,
      'retentionChange': retentionChange,
      'totalArtworks': totalArtworks,
      'totalPosts': totalPosts,
      'totalComments': totalComments,
      'totalEvents': totalEvents,
      'artworkGrowth': artworkGrowth,
      'postGrowth': postGrowth,
      'commentGrowth': commentGrowth,
      'eventGrowth': eventGrowth,
      'avgSessionDuration': avgSessionDuration,
      'pageViews': pageViews,
      'bounceRate': bounceRate,
      'totalLikes': totalLikes,
      'sessionDurationChange': sessionDurationChange,
      'pageViewGrowth': pageViewGrowth,
      'bounceRateChange': bounceRateChange,
      'likeGrowth': likeGrowth,
      'errorRate': errorRate,
      'avgResponseTime': avgResponseTime,
      'storageUsed': storageUsed,
      'bandwidthUsed': bandwidthUsed,
      'errorRateChange': errorRateChange,
      'responseTimeChange': responseTimeChange,
      'storageGrowth': storageGrowth,
      'bandwidthChange': bandwidthChange,
      'topContent': topContent.map((item) => item.toMap()).toList(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

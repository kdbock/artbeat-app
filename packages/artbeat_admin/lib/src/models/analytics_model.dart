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

/// Financial metrics model
class FinancialMetrics {
  final double totalRevenue;
  final double subscriptionRevenue;
  final double eventRevenue;
  final double commissionRevenue;
  final double averageRevenuePerUser;
  final double monthlyRecurringRevenue;
  final double churnRate;
  final double lifetimeValue;
  final int totalTransactions;
  final double revenueGrowth;
  final double subscriptionGrowth;
  final double commissionGrowth;
  final Map<String, double> revenueByCategory;
  final List<RevenueDataPoint> revenueTimeSeries;

  FinancialMetrics({
    required this.totalRevenue,
    required this.subscriptionRevenue,
    required this.eventRevenue,
    required this.commissionRevenue,
    required this.averageRevenuePerUser,
    required this.monthlyRecurringRevenue,
    required this.churnRate,
    required this.lifetimeValue,
    required this.totalTransactions,
    required this.revenueGrowth,
    required this.subscriptionGrowth,
    required this.commissionGrowth,
    required this.revenueByCategory,
    required this.revenueTimeSeries,
  });

  factory FinancialMetrics.fromMap(Map<String, dynamic> map) {
    return FinancialMetrics(
      totalRevenue: ((map['totalRevenue'] as num?) ?? 0.0).toDouble(),
      subscriptionRevenue:
          ((map['subscriptionRevenue'] as num?) ?? 0.0).toDouble(),
      eventRevenue: ((map['eventRevenue'] as num?) ?? 0.0).toDouble(),
      commissionRevenue: ((map['commissionRevenue'] as num?) ?? 0.0).toDouble(),
      averageRevenuePerUser:
          ((map['averageRevenuePerUser'] as num?) ?? 0.0).toDouble(),
      monthlyRecurringRevenue:
          ((map['monthlyRecurringRevenue'] as num?) ?? 0.0).toDouble(),
      churnRate: ((map['churnRate'] as num?) ?? 0.0).toDouble(),
      lifetimeValue: ((map['lifetimeValue'] as num?) ?? 0.0).toDouble(),
      totalTransactions: (map['totalTransactions'] as int?) ?? 0,
      revenueGrowth: ((map['revenueGrowth'] as num?) ?? 0.0).toDouble(),
      subscriptionGrowth:
          ((map['subscriptionGrowth'] as num?) ?? 0.0).toDouble(),
      commissionGrowth: ((map['commissionGrowth'] as num?) ?? 0.0).toDouble(),
      revenueByCategory: Map<String, double>.from(
          (map['revenueByCategory'] as Map<dynamic, dynamic>?) ?? {}),
      revenueTimeSeries: (map['revenueTimeSeries'] as List<dynamic>?)
              ?.map((item) =>
                  RevenueDataPoint.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalRevenue': totalRevenue,
      'subscriptionRevenue': subscriptionRevenue,
      'eventRevenue': eventRevenue,
      'commissionRevenue': commissionRevenue,
      'averageRevenuePerUser': averageRevenuePerUser,
      'monthlyRecurringRevenue': monthlyRecurringRevenue,
      'churnRate': churnRate,
      'lifetimeValue': lifetimeValue,
      'totalTransactions': totalTransactions,
      'revenueGrowth': revenueGrowth,
      'subscriptionGrowth': subscriptionGrowth,
      'commissionGrowth': commissionGrowth,
      'revenueByCategory': revenueByCategory,
      'revenueTimeSeries':
          revenueTimeSeries.map((item) => item.toMap()).toList(),
    };
  }
}

/// Revenue data point for time series
class RevenueDataPoint {
  final DateTime date;
  final double amount;
  final String category;

  RevenueDataPoint({
    required this.date,
    required this.amount,
    required this.category,
  });

  factory RevenueDataPoint.fromMap(Map<String, dynamic> map) {
    return RevenueDataPoint(
      date: map['date'] is String
          ? DateTime.parse(map['date'] as String)
          : (map['date'] as DateTime?) ?? DateTime.now(),
      amount: ((map['amount'] as num?) ?? 0.0).toDouble(),
      category: (map['category'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'category': category,
    };
  }
}

/// User cohort data
class CohortData {
  final String cohortMonth;
  final int totalUsers;
  final Map<int, double> retentionRates; // month -> retention rate
  final double averageLifetimeValue;

  CohortData({
    required this.cohortMonth,
    required this.totalUsers,
    required this.retentionRates,
    required this.averageLifetimeValue,
  });

  factory CohortData.fromMap(Map<String, dynamic> map) {
    return CohortData(
      cohortMonth: (map['cohortMonth'] as String?) ?? '',
      totalUsers: (map['totalUsers'] as int?) ?? 0,
      retentionRates: Map<int, double>.from(
          (map['retentionRates'] as Map<dynamic, dynamic>?) ?? {}),
      averageLifetimeValue:
          ((map['averageLifetimeValue'] as num?) ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cohortMonth': cohortMonth,
      'totalUsers': totalUsers,
      'retentionRates': retentionRates,
      'averageLifetimeValue': averageLifetimeValue,
    };
  }
}

/// User journey step
class UserJourneyStep {
  final String stepName;
  final int userCount;
  final double conversionRate;
  final double avgTimeSpent;

  UserJourneyStep({
    required this.stepName,
    required this.userCount,
    required this.conversionRate,
    required this.avgTimeSpent,
  });

  factory UserJourneyStep.fromMap(Map<String, dynamic> map) {
    return UserJourneyStep(
      stepName: (map['stepName'] as String?) ?? '',
      userCount: (map['userCount'] as int?) ?? 0,
      conversionRate: ((map['conversionRate'] as num?) ?? 0.0).toDouble(),
      avgTimeSpent: ((map['avgTimeSpent'] as num?) ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stepName': stepName,
      'userCount': userCount,
      'conversionRate': conversionRate,
      'avgTimeSpent': avgTimeSpent,
    };
  }
}

/// Enhanced analytics data model
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

  // Enhanced metrics
  final FinancialMetrics financialMetrics;
  final List<CohortData> cohortAnalysis;
  final Map<String, int> usersByCountry;
  final Map<String, int> deviceBreakdown;
  final List<UserJourneyStep> topUserJourneys;
  final Map<String, double> conversionFunnels;

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
    required this.financialMetrics,
    required this.cohortAnalysis,
    required this.usersByCountry,
    required this.deviceBreakdown,
    required this.topUserJourneys,
    required this.conversionFunnels,
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
      financialMetrics: map['financialMetrics'] != null
          ? FinancialMetrics.fromMap(
              map['financialMetrics'] as Map<String, dynamic>)
          : FinancialMetrics(
              totalRevenue: 0.0,
              subscriptionRevenue: 0.0,
              eventRevenue: 0.0,
              commissionRevenue: 0.0,
              averageRevenuePerUser: 0.0,
              monthlyRecurringRevenue: 0.0,
              churnRate: 0.0,
              lifetimeValue: 0.0,
              totalTransactions: 0,
              revenueGrowth: 0.0,
              subscriptionGrowth: 0.0,
              commissionGrowth: 0.0,
              revenueByCategory: {},
              revenueTimeSeries: [],
            ),
      cohortAnalysis: (map['cohortAnalysis'] as List<dynamic>?)
              ?.map((item) => CohortData.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      usersByCountry: Map<String, int>.from(
          (map['usersByCountry'] as Map<dynamic, dynamic>?) ?? {}),
      deviceBreakdown: Map<String, int>.from(
          (map['deviceBreakdown'] as Map<dynamic, dynamic>?) ?? {}),
      topUserJourneys: (map['topUserJourneys'] as List<dynamic>?)
              ?.map((item) =>
                  UserJourneyStep.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      conversionFunnels: Map<String, double>.from(
          (map['conversionFunnels'] as Map<dynamic, dynamic>?) ?? {}),
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
      'financialMetrics': financialMetrics.toMap(),
      'cohortAnalysis': cohortAnalysis.map((item) => item.toMap()).toList(),
      'usersByCountry': usersByCountry,
      'deviceBreakdown': deviceBreakdown,
      'topUserJourneys': topUserJourneys.map((item) => item.toMap()).toList(),
      'conversionFunnels': conversionFunnels,
      'topContent': topContent.map((item) => item.toMap()).toList(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

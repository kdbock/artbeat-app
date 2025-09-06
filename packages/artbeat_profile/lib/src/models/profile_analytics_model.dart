import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for user profile analytics (different from artist analytics)
class ProfileAnalyticsModel {
  final String userId;
  final int profileViews;
  final int totalFollowers;
  final int totalFollowing;
  final int totalPosts;
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final int totalMentions;
  final Map<String, int> dailyViews; // Date string -> view count
  final Map<String, int> weeklyEngagement; // Week -> engagement count
  final List<String> topViewers; // User IDs of top profile viewers
  final List<String> recentInteractions; // Recent user IDs who interacted
  final DateTime lastUpdated;
  final DateTime periodStart;
  final DateTime periodEnd;

  ProfileAnalyticsModel({
    required this.userId,
    this.profileViews = 0,
    this.totalFollowers = 0,
    this.totalFollowing = 0,
    this.totalPosts = 0,
    this.totalLikes = 0,
    this.totalComments = 0,
    this.totalShares = 0,
    this.totalMentions = 0,
    this.dailyViews = const {},
    this.weeklyEngagement = const {},
    this.topViewers = const [],
    this.recentInteractions = const [],
    required this.lastUpdated,
    required this.periodStart,
    required this.periodEnd,
  });

  factory ProfileAnalyticsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileAnalyticsModel(
      userId: doc.id,
      profileViews: (data['profileViews'] as num?)?.toInt() ?? 0,
      totalFollowers: (data['totalFollowers'] as num?)?.toInt() ?? 0,
      totalFollowing: (data['totalFollowing'] as num?)?.toInt() ?? 0,
      totalPosts: (data['totalPosts'] as num?)?.toInt() ?? 0,
      totalLikes: (data['totalLikes'] as num?)?.toInt() ?? 0,
      totalComments: (data['totalComments'] as num?)?.toInt() ?? 0,
      totalShares: (data['totalShares'] as num?)?.toInt() ?? 0,
      totalMentions: (data['totalMentions'] as num?)?.toInt() ?? 0,
      dailyViews: Map<String, int>.from(
        (data['dailyViews'] as Map<String, dynamic>?) ?? {},
      ),
      weeklyEngagement: Map<String, int>.from(
        (data['weeklyEngagement'] as Map<String, dynamic>?) ?? {},
      ),
      topViewers: List<String>.from(
        (data['topViewers'] as List<dynamic>?) ?? [],
      ),
      recentInteractions: List<String>.from(
        (data['recentInteractions'] as List<dynamic>?) ?? [],
      ),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      periodStart: (data['periodStart'] as Timestamp).toDate(),
      periodEnd: (data['periodEnd'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'profileViews': profileViews,
      'totalFollowers': totalFollowers,
      'totalFollowing': totalFollowing,
      'totalPosts': totalPosts,
      'totalLikes': totalLikes,
      'totalComments': totalComments,
      'totalShares': totalShares,
      'totalMentions': totalMentions,
      'dailyViews': dailyViews,
      'weeklyEngagement': weeklyEngagement,
      'topViewers': topViewers,
      'recentInteractions': recentInteractions,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
    };
  }

  ProfileAnalyticsModel copyWith({
    int? profileViews,
    int? totalFollowers,
    int? totalFollowing,
    int? totalPosts,
    int? totalLikes,
    int? totalComments,
    int? totalShares,
    int? totalMentions,
    Map<String, int>? dailyViews,
    Map<String, int>? weeklyEngagement,
    List<String>? topViewers,
    List<String>? recentInteractions,
    DateTime? lastUpdated,
  }) {
    return ProfileAnalyticsModel(
      userId: userId,
      profileViews: profileViews ?? this.profileViews,
      totalFollowers: totalFollowers ?? this.totalFollowers,
      totalFollowing: totalFollowing ?? this.totalFollowing,
      totalPosts: totalPosts ?? this.totalPosts,
      totalLikes: totalLikes ?? this.totalLikes,
      totalComments: totalComments ?? this.totalComments,
      totalShares: totalShares ?? this.totalShares,
      totalMentions: totalMentions ?? this.totalMentions,
      dailyViews: dailyViews ?? this.dailyViews,
      weeklyEngagement: weeklyEngagement ?? this.weeklyEngagement,
      topViewers: topViewers ?? this.topViewers,
      recentInteractions: recentInteractions ?? this.recentInteractions,
      lastUpdated: lastUpdated ?? DateTime.now(),
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  double get engagementRate {
    if (profileViews == 0) return 0.0;
    final totalEngagements = totalLikes + totalComments + totalShares;
    return (totalEngagements / profileViews) * 100;
  }

  int get totalEngagements => totalLikes + totalComments + totalShares;

  List<MapEntry<String, int>> get topDailyViews {
    final entries = dailyViews.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(7).toList(); // Top 7 days
  }
}

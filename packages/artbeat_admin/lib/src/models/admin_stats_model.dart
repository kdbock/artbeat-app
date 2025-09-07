import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing admin dashboard statistics
class AdminStatsModel {
  final int totalUsers;
  final int totalArtists;
  final int totalGalleries;
  final int totalModerators;
  final int totalAdmins;
  final int totalArtworks;
  final int totalCaptures;
  final int totalEvents;
  final int newUsersToday;
  final int newUsersThisWeek;
  final int newUsersThisMonth;
  final int activeUsersToday;
  final int activeUsersThisWeek;
  final int activeUsersThisMonth;
  final DateTime lastUpdated;

  const AdminStatsModel({
    required this.totalUsers,
    required this.totalArtists,
    required this.totalGalleries,
    required this.totalModerators,
    required this.totalAdmins,
    required this.totalArtworks,
    required this.totalCaptures,
    required this.totalEvents,
    required this.newUsersToday,
    required this.newUsersThisWeek,
    required this.newUsersThisMonth,
    required this.activeUsersToday,
    required this.activeUsersThisWeek,
    required this.activeUsersThisMonth,
    required this.lastUpdated,
  });

  factory AdminStatsModel.empty() {
    return AdminStatsModel(
      totalUsers: 0,
      totalArtists: 0,
      totalGalleries: 0,
      totalModerators: 0,
      totalAdmins: 0,
      totalArtworks: 0,
      totalCaptures: 0,
      totalEvents: 0,
      newUsersToday: 0,
      newUsersThisWeek: 0,
      newUsersThisMonth: 0,
      activeUsersToday: 0,
      activeUsersThisWeek: 0,
      activeUsersThisMonth: 0,
      lastUpdated: DateTime.now(),
    );
  }

  factory AdminStatsModel.fromFirestore(Map<String, dynamic> data) {
    return AdminStatsModel(
      totalUsers: data['totalUsers'] as int? ?? 0,
      totalArtists: data['totalArtists'] as int? ?? 0,
      totalGalleries: data['totalGalleries'] as int? ?? 0,
      totalModerators: data['totalModerators'] as int? ?? 0,
      totalAdmins: data['totalAdmins'] as int? ?? 0,
      totalArtworks: data['totalArtworks'] as int? ?? 0,
      totalCaptures: data['totalCaptures'] as int? ?? 0,
      totalEvents: data['totalEvents'] as int? ?? 0,
      newUsersToday: data['newUsersToday'] as int? ?? 0,
      newUsersThisWeek: data['newUsersThisWeek'] as int? ?? 0,
      newUsersThisMonth: data['newUsersThisMonth'] as int? ?? 0,
      activeUsersToday: data['activeUsersToday'] as int? ?? 0,
      activeUsersThisWeek: data['activeUsersThisWeek'] as int? ?? 0,
      activeUsersThisMonth: data['activeUsersThisMonth'] as int? ?? 0,
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalUsers': totalUsers,
      'totalArtists': totalArtists,
      'totalGalleries': totalGalleries,
      'totalModerators': totalModerators,
      'totalAdmins': totalAdmins,
      'totalArtworks': totalArtworks,
      'totalCaptures': totalCaptures,
      'totalEvents': totalEvents,
      'newUsersToday': newUsersToday,
      'newUsersThisWeek': newUsersThisWeek,
      'newUsersThisMonth': newUsersThisMonth,
      'activeUsersToday': activeUsersToday,
      'activeUsersThisWeek': activeUsersThisWeek,
      'activeUsersThisMonth': activeUsersThisMonth,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  AdminStatsModel copyWith({
    int? totalUsers,
    int? totalArtists,
    int? totalGalleries,
    int? totalModerators,
    int? totalAdmins,
    int? totalArtworks,
    int? totalCaptures,
    int? totalEvents,
    int? newUsersToday,
    int? newUsersThisWeek,
    int? newUsersThisMonth,
    int? activeUsersToday,
    int? activeUsersThisWeek,
    int? activeUsersThisMonth,
    DateTime? lastUpdated,
  }) {
    return AdminStatsModel(
      totalUsers: totalUsers ?? this.totalUsers,
      totalArtists: totalArtists ?? this.totalArtists,
      totalGalleries: totalGalleries ?? this.totalGalleries,
      totalModerators: totalModerators ?? this.totalModerators,
      totalAdmins: totalAdmins ?? this.totalAdmins,
      totalArtworks: totalArtworks ?? this.totalArtworks,
      totalCaptures: totalCaptures ?? this.totalCaptures,
      totalEvents: totalEvents ?? this.totalEvents,
      newUsersToday: newUsersToday ?? this.newUsersToday,
      newUsersThisWeek: newUsersThisWeek ?? this.newUsersThisWeek,
      newUsersThisMonth: newUsersThisMonth ?? this.newUsersThisMonth,
      activeUsersToday: activeUsersToday ?? this.activeUsersToday,
      activeUsersThisWeek: activeUsersThisWeek ?? this.activeUsersThisWeek,
      activeUsersThisMonth: activeUsersThisMonth ?? this.activeUsersThisMonth,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

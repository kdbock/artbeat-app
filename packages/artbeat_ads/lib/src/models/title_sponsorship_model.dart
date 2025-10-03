import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a title sponsorship
enum SponsorshipStatus { active, pending, expired, cancelled }

/// Title Sponsorship Model - Premium app-wide sponsorship
/// Price: $5,000/month for exclusive branding throughout the app
class TitleSponsorshipModel {
  final String id;
  final String sponsorId; // User ID of the sponsor
  final String sponsorName; // Organization name
  final String logoUrl; // Sponsor logo URL
  final String? websiteUrl; // Optional sponsor website
  final String? description; // Optional sponsor description
  final DateTime startDate;
  final DateTime endDate;
  final SponsorshipStatus status;
  final double monthlyPrice; // $5,000/month
  final int durationMonths; // Number of months
  final double totalPrice; // Total cost
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy; // Admin who approved
  final Map<String, dynamic>? analytics; // Impression tracking

  /// Monthly price for title sponsorship
  static const double baseMonthlyPrice = 5000.0;

  TitleSponsorshipModel({
    required this.id,
    required this.sponsorId,
    required this.sponsorName,
    required this.logoUrl,
    this.websiteUrl,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.monthlyPrice,
    required this.durationMonths,
    required this.totalPrice,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
    this.analytics,
  });

  /// Check if sponsorship is currently active
  bool get isActive {
    final now = DateTime.now();
    return status == SponsorshipStatus.active &&
        now.isAfter(startDate) &&
        now.isBefore(endDate);
  }

  /// Check if sponsorship is expired
  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }

  /// Days remaining in sponsorship
  int get daysRemaining {
    if (isExpired) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  /// Calculate total impressions from analytics
  int get totalImpressions {
    if (analytics == null) return 0;
    return (analytics!['totalImpressions'] as num?)?.toInt() ?? 0;
  }

  factory TitleSponsorshipModel.fromMap(Map<String, dynamic> map, String id) {
    final rawStatus = map['status'];
    final intStatus = rawStatus is int
        ? rawStatus
        : int.tryParse(rawStatus.toString()) ?? 0;

    SponsorshipStatus safeStatus;
    try {
      safeStatus = intStatus >= 0 && intStatus < SponsorshipStatus.values.length
          ? SponsorshipStatus.values[intStatus]
          : SponsorshipStatus.pending;
    } catch (e) {
      safeStatus = SponsorshipStatus.pending;
    }

    return TitleSponsorshipModel(
      id: id,
      sponsorId: map['sponsorId']?.toString() ?? '',
      sponsorName: map['sponsorName']?.toString() ?? '',
      logoUrl: map['logoUrl']?.toString() ?? '',
      websiteUrl: map['websiteUrl']?.toString(),
      description: map['description']?.toString(),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      status: safeStatus,
      monthlyPrice:
          (map['monthlyPrice'] as num?)?.toDouble() ?? baseMonthlyPrice,
      durationMonths: (map['durationMonths'] as num?)?.toInt() ?? 1,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? baseMonthlyPrice,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      approvedAt: map['approvedAt'] != null
          ? (map['approvedAt'] as Timestamp).toDate()
          : null,
      approvedBy: map['approvedBy']?.toString(),
      analytics: map['analytics'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
    'sponsorId': sponsorId,
    'sponsorName': sponsorName,
    'logoUrl': logoUrl,
    'websiteUrl': websiteUrl,
    'description': description,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'status': status.index,
    'monthlyPrice': monthlyPrice,
    'durationMonths': durationMonths,
    'totalPrice': totalPrice,
    'createdAt': Timestamp.fromDate(createdAt),
    'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    'approvedBy': approvedBy,
    'analytics': analytics,
  };

  TitleSponsorshipModel copyWith({
    String? id,
    String? sponsorId,
    String? sponsorName,
    String? logoUrl,
    String? websiteUrl,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    SponsorshipStatus? status,
    double? monthlyPrice,
    int? durationMonths,
    double? totalPrice,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? approvedBy,
    Map<String, dynamic>? analytics,
  }) {
    return TitleSponsorshipModel(
      id: id ?? this.id,
      sponsorId: sponsorId ?? this.sponsorId,
      sponsorName: sponsorName ?? this.sponsorName,
      logoUrl: logoUrl ?? this.logoUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      durationMonths: durationMonths ?? this.durationMonths,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      analytics: analytics ?? this.analytics,
    );
  }
}

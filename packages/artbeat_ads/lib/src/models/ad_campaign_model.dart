import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Represents an advertising campaign for coordinated marketing efforts
///
/// Provides campaign management capabilities with budget tracking, performance
/// monitoring, and automated optimization for multi-ad marketing strategies
/// designed to maximize ROI and reach target audiences effectively.
class AdCampaignModel {
  final String id;
  final String name;
  final String description;
  final String createdById;
  final DateTime createdAt;
  final DateTime? lastModified;
  final AdCampaignStatus status;
  final AdCampaignType campaignType;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final double spentAmount;
  final AdCampaignBidStrategy bidStrategy;
  final List<String> adIds;
  final List<String> targetLocations;
  final List<String> targetAudiences;
  final Map<String, dynamic> targetingCriteria;
  final Map<String, dynamic> performanceMetrics;
  final Map<String, dynamic> optimizationSettings;
  final bool isActive;
  final bool autoOptimize;
  final double? targetCPA;
  final double? targetROAS;
  final int priority;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  AdCampaignModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdById,
    required this.createdAt,
    this.lastModified,
    this.status = AdCampaignStatus.draft,
    required this.campaignType,
    required this.startDate,
    required this.endDate,
    required this.budget,
    this.spentAmount = 0.0,
    this.bidStrategy = AdCampaignBidStrategy.maximizeClicks,
    this.adIds = const [],
    this.targetLocations = const [],
    this.targetAudiences = const [],
    this.targetingCriteria = const {},
    this.performanceMetrics = const {},
    this.optimizationSettings = const {},
    this.isActive = false,
    this.autoOptimize = true,
    this.targetCPA,
    this.targetROAS,
    this.priority = 1,
    this.tags = const [],
    this.metadata = const {},
  });

  /// Create from Firestore document
  factory AdCampaignModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AdCampaignModel(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      createdById: (data['createdById'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastModified: (data['lastModified'] as Timestamp?)?.toDate(),
      status: AdCampaignStatus.fromString(
        (data['status'] ?? 'draft') as String,
      ),
      campaignType: AdCampaignType.fromString(
        (data['campaignType'] ?? 'awareness') as String,
      ),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate:
          (data['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      budget: ((data['budget'] ?? 0) as num).toDouble(),
      spentAmount: ((data['spentAmount'] ?? 0) as num).toDouble(),
      bidStrategy: AdCampaignBidStrategy.fromString(
        (data['bidStrategy'] ?? 'maximize_clicks') as String,
      ),
      adIds: (data['adIds'] as List<dynamic>?)?.cast<String>() ?? [],
      targetLocations:
          (data['targetLocations'] as List<dynamic>?)?.cast<String>() ?? [],
      targetAudiences:
          (data['targetAudiences'] as List<dynamic>?)?.cast<String>() ?? [],
      targetingCriteria:
          (data['targetingCriteria'] as Map<String, dynamic>?) ?? {},
      performanceMetrics:
          (data['performanceMetrics'] as Map<String, dynamic>?) ?? {},
      optimizationSettings:
          (data['optimizationSettings'] as Map<String, dynamic>?) ?? {},
      isActive: (data['isActive'] ?? false) as bool,
      autoOptimize: (data['autoOptimize'] ?? true) as bool,
      targetCPA: (data['targetCPA'] as num?)?.toDouble(),
      targetROAS: (data['targetROAS'] as num?)?.toDouble(),
      priority: ((data['priority'] ?? 1) as num).toInt(),
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      metadata: (data['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'createdById': createdById,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastModified != null)
        'lastModified': Timestamp.fromDate(lastModified!),
      'status': status.value,
      'campaignType': campaignType.value,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'budget': budget,
      'spentAmount': spentAmount,
      'bidStrategy': bidStrategy.value,
      'adIds': adIds,
      'targetLocations': targetLocations,
      'targetAudiences': targetAudiences,
      'targetingCriteria': targetingCriteria,
      'performanceMetrics': performanceMetrics,
      'optimizationSettings': optimizationSettings,
      'isActive': isActive,
      'autoOptimize': autoOptimize,
      if (targetCPA != null) 'targetCPA': targetCPA,
      if (targetROAS != null) 'targetROAS': targetROAS,
      'priority': priority,
      'tags': tags,
      'metadata': metadata,
    };
  }

  /// Create copy with updated fields
  AdCampaignModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdById,
    DateTime? createdAt,
    DateTime? lastModified,
    AdCampaignStatus? status,
    AdCampaignType? campaignType,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    double? spentAmount,
    AdCampaignBidStrategy? bidStrategy,
    List<String>? adIds,
    List<String>? targetLocations,
    List<String>? targetAudiences,
    Map<String, dynamic>? targetingCriteria,
    Map<String, dynamic>? performanceMetrics,
    Map<String, dynamic>? optimizationSettings,
    bool? isActive,
    bool? autoOptimize,
    double? targetCPA,
    double? targetROAS,
    int? priority,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return AdCampaignModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      status: status ?? this.status,
      campaignType: campaignType ?? this.campaignType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      spentAmount: spentAmount ?? this.spentAmount,
      bidStrategy: bidStrategy ?? this.bidStrategy,
      adIds: adIds ?? this.adIds,
      targetLocations: targetLocations ?? this.targetLocations,
      targetAudiences: targetAudiences ?? this.targetAudiences,
      targetingCriteria: targetingCriteria ?? this.targetingCriteria,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      optimizationSettings: optimizationSettings ?? this.optimizationSettings,
      isActive: isActive ?? this.isActive,
      autoOptimize: autoOptimize ?? this.autoOptimize,
      targetCPA: targetCPA ?? this.targetCPA,
      targetROAS: targetROAS ?? this.targetROAS,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if campaign is currently running
  bool get isRunning {
    final now = DateTime.now();
    return status == AdCampaignStatus.active &&
        isActive &&
        now.isAfter(startDate) &&
        now.isBefore(endDate);
  }

  /// Check if campaign has budget remaining
  bool get hasBudgetRemaining => remainingBudget > 0;

  /// Get remaining budget
  double get remainingBudget => budget - spentAmount;

  /// Get budget utilization percentage
  double get budgetUtilization => budget > 0 ? (spentAmount / budget) * 100 : 0;

  /// Get campaign duration in days
  int get durationDays => endDate.difference(startDate).inDays;

  /// Get days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Check if campaign is expired
  bool get isExpired => DateTime.now().isAfter(endDate);

  /// Get daily budget
  double get dailyBudget => durationDays > 0 ? budget / durationDays : budget;

  /// Get performance score (0-100)
  double get performanceScore {
    if (performanceMetrics.isEmpty) return 0;

    // Calculate based on key metrics
    final impressions = (performanceMetrics['impressions'] ?? 0) as num;
    final clicks = (performanceMetrics['clicks'] ?? 0) as num;
    final conversions = (performanceMetrics['conversions'] ?? 0) as num;

    double score = 0;
    if (impressions > 0) score += 25; // Has impressions
    if (clicks > 0) score += 25; // Has clicks
    if (conversions > 0) score += 30; // Has conversions
    if (spentAmount < budget) score += 20; // Within budget

    return score;
  }

  /// Get formatted budget display
  String get budgetFormatted =>
      NumberFormat.currency(symbol: '\$').format(budget);

  /// Get formatted spent amount display
  String get spentFormatted =>
      NumberFormat.currency(symbol: '\$').format(spentAmount);

  /// Get formatted remaining budget display
  String get remainingBudgetFormatted =>
      NumberFormat.currency(symbol: '\$').format(remainingBudget);

  /// Get campaign date range display
  String get dateRangeFormatted {
    final formatter = DateFormat('MMM dd, yyyy');
    return '${formatter.format(startDate)} - ${formatter.format(endDate)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdCampaignModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AdCampaignModel(id: $id, name: $name, status: $status, type: $campaignType)';
}

/// Campaign status enum
enum AdCampaignStatus {
  draft,
  scheduled,
  active,
  paused,
  completed,
  cancelled,
  archived;

  String get value => name;

  static AdCampaignStatus fromString(String value) {
    return AdCampaignStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AdCampaignStatus.draft,
    );
  }

  String get displayName {
    switch (this) {
      case AdCampaignStatus.draft:
        return 'Draft';
      case AdCampaignStatus.scheduled:
        return 'Scheduled';
      case AdCampaignStatus.active:
        return 'Active';
      case AdCampaignStatus.paused:
        return 'Paused';
      case AdCampaignStatus.completed:
        return 'Completed';
      case AdCampaignStatus.cancelled:
        return 'Cancelled';
      case AdCampaignStatus.archived:
        return 'Archived';
    }
  }

  /// Get color for status display
  String get colorHex {
    switch (this) {
      case AdCampaignStatus.draft:
        return '#9E9E9E'; // Grey
      case AdCampaignStatus.scheduled:
        return '#FF9800'; // Orange
      case AdCampaignStatus.active:
        return '#4CAF50'; // Green
      case AdCampaignStatus.paused:
        return '#2196F3'; // Blue
      case AdCampaignStatus.completed:
        return '#8BC34A'; // Light Green
      case AdCampaignStatus.cancelled:
        return '#F44336'; // Red
      case AdCampaignStatus.archived:
        return '#795548'; // Brown
    }
  }
}

/// Campaign type enum
enum AdCampaignType {
  awareness,
  conversion,
  traffic,
  engagement,
  leadGeneration,
  appPromotion,
  videoViews,
  brandConsideration;

  String get value => name;

  static AdCampaignType fromString(String value) {
    return AdCampaignType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AdCampaignType.awareness,
    );
  }

  String get displayName {
    switch (this) {
      case AdCampaignType.awareness:
        return 'Brand Awareness';
      case AdCampaignType.conversion:
        return 'Conversions';
      case AdCampaignType.traffic:
        return 'Website Traffic';
      case AdCampaignType.engagement:
        return 'Engagement';
      case AdCampaignType.leadGeneration:
        return 'Lead Generation';
      case AdCampaignType.appPromotion:
        return 'App Promotion';
      case AdCampaignType.videoViews:
        return 'Video Views';
      case AdCampaignType.brandConsideration:
        return 'Brand Consideration';
    }
  }

  String get description {
    switch (this) {
      case AdCampaignType.awareness:
        return 'Increase brand awareness and reach new audiences';
      case AdCampaignType.conversion:
        return 'Drive specific actions like purchases or sign-ups';
      case AdCampaignType.traffic:
        return 'Drive traffic to your website or landing page';
      case AdCampaignType.engagement:
        return 'Increase likes, comments, and shares on your content';
      case AdCampaignType.leadGeneration:
        return 'Generate leads and collect customer information';
      case AdCampaignType.appPromotion:
        return 'Promote app installs and in-app actions';
      case AdCampaignType.videoViews:
        return 'Increase video views and watch time';
      case AdCampaignType.brandConsideration:
        return 'Build interest and consideration for your brand';
    }
  }
}

/// Bid strategy enum
enum AdCampaignBidStrategy {
  maximizeClicks,
  maximizeConversions,
  targetCPA,
  targetROAS,
  manualCPC,
  enhancedCPC,
  maximizeImpressions;

  String get value =>
      name.replaceAll(RegExp(r'([A-Z])'), '_\$1').toLowerCase().substring(1);

  static AdCampaignBidStrategy fromString(String value) {
    final normalizedValue = value.replaceAll('_', '').toLowerCase();
    return AdCampaignBidStrategy.values.firstWhere(
      (strategy) => strategy.name.toLowerCase() == normalizedValue,
      orElse: () => AdCampaignBidStrategy.maximizeClicks,
    );
  }

  String get displayName {
    switch (this) {
      case AdCampaignBidStrategy.maximizeClicks:
        return 'Maximize Clicks';
      case AdCampaignBidStrategy.maximizeConversions:
        return 'Maximize Conversions';
      case AdCampaignBidStrategy.targetCPA:
        return 'Target CPA';
      case AdCampaignBidStrategy.targetROAS:
        return 'Target ROAS';
      case AdCampaignBidStrategy.manualCPC:
        return 'Manual CPC';
      case AdCampaignBidStrategy.enhancedCPC:
        return 'Enhanced CPC';
      case AdCampaignBidStrategy.maximizeImpressions:
        return 'Maximize Impressions';
    }
  }

  String get description {
    switch (this) {
      case AdCampaignBidStrategy.maximizeClicks:
        return 'Automatically sets bids to get as many clicks as possible within your budget';
      case AdCampaignBidStrategy.maximizeConversions:
        return 'Automatically sets bids to get as many conversions as possible within your budget';
      case AdCampaignBidStrategy.targetCPA:
        return 'Sets bids to achieve a target cost-per-acquisition';
      case AdCampaignBidStrategy.targetROAS:
        return 'Sets bids to achieve a target return on ad spend';
      case AdCampaignBidStrategy.manualCPC:
        return 'Manually set maximum cost-per-click bids for your ads';
      case AdCampaignBidStrategy.enhancedCPC:
        return 'Automatically adjusts manual bids to maximize conversions';
      case AdCampaignBidStrategy.maximizeImpressions:
        return 'Automatically sets bids to show your ads as often as possible';
    }
  }
}

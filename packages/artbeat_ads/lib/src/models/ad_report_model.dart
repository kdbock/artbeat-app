import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Represents a custom performance report for ad analytics
///
/// Provides structured reporting capabilities with customizable date ranges,
/// metrics selection, and export functionality for advanced business intelligence
/// and performance analysis.
class AdReportModel {
  final String id;
  final String title;
  final String description;
  final String createdById;
  final DateTime createdAt;
  final DateTime? lastModified;
  final AdReportType reportType;
  final AdReportStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> selectedMetrics;
  final List<String> selectedAdIds;
  final List<String> selectedLocations;
  final List<String> selectedOwnerIds;
  final AdReportFormat exportFormat;
  final Map<String, dynamic> filterCriteria;
  final Map<String, dynamic> reportData;
  final double? generationTimeSeconds;
  final String? exportUrl;
  final DateTime? exportExpiresAt;
  final List<String> sharedWithUserIds;
  final bool isPublic;
  final Map<String, dynamic> metadata;

  AdReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdById,
    required this.createdAt,
    this.lastModified,
    required this.reportType,
    this.status = AdReportStatus.draft,
    required this.startDate,
    required this.endDate,
    required this.selectedMetrics,
    this.selectedAdIds = const [],
    this.selectedLocations = const [],
    this.selectedOwnerIds = const [],
    this.exportFormat = AdReportFormat.json,
    this.filterCriteria = const {},
    this.reportData = const {},
    this.generationTimeSeconds,
    this.exportUrl,
    this.exportExpiresAt,
    this.sharedWithUserIds = const [],
    this.isPublic = false,
    this.metadata = const {},
  });

  /// Create from Firestore document
  factory AdReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AdReportModel(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      createdById: (data['createdById'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastModified: (data['lastModified'] as Timestamp?)?.toDate(),
      reportType: AdReportType.fromString(
        (data['reportType'] ?? 'performance') as String,
      ),
      status: AdReportStatus.fromString((data['status'] ?? 'draft') as String),
      startDate:
          (data['startDate'] as Timestamp?)?.toDate() ??
          DateTime.now().subtract(const Duration(days: 30)),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      selectedMetrics:
          (data['selectedMetrics'] as List<dynamic>?)?.cast<String>() ?? [],
      selectedAdIds:
          (data['selectedAdIds'] as List<dynamic>?)?.cast<String>() ?? [],
      selectedLocations:
          (data['selectedLocations'] as List<dynamic>?)?.cast<String>() ?? [],
      selectedOwnerIds:
          (data['selectedOwnerIds'] as List<dynamic>?)?.cast<String>() ?? [],
      exportFormat: AdReportFormat.fromString(
        (data['exportFormat'] ?? 'json') as String,
      ),
      filterCriteria: (data['filterCriteria'] as Map<String, dynamic>?) ?? {},
      reportData: (data['reportData'] as Map<String, dynamic>?) ?? {},
      generationTimeSeconds: (data['generationTimeSeconds'] as num?)
          ?.toDouble(),
      exportUrl: data['exportUrl'] as String?,
      exportExpiresAt: (data['exportExpiresAt'] as Timestamp?)?.toDate(),
      sharedWithUserIds:
          (data['sharedWithUserIds'] as List<dynamic>?)?.cast<String>() ?? [],
      isPublic: (data['isPublic'] ?? false) as bool,
      metadata: (data['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'createdById': createdById,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastModified != null)
        'lastModified': Timestamp.fromDate(lastModified!),
      'reportType': reportType.value,
      'status': status.value,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'selectedMetrics': selectedMetrics,
      'selectedAdIds': selectedAdIds,
      'selectedLocations': selectedLocations,
      'selectedOwnerIds': selectedOwnerIds,
      'exportFormat': exportFormat.value,
      'filterCriteria': filterCriteria,
      'reportData': reportData,
      if (generationTimeSeconds != null)
        'generationTimeSeconds': generationTimeSeconds,
      if (exportUrl != null) 'exportUrl': exportUrl,
      if (exportExpiresAt != null)
        'exportExpiresAt': Timestamp.fromDate(exportExpiresAt!),
      'sharedWithUserIds': sharedWithUserIds,
      'isPublic': isPublic,
      'metadata': metadata,
    };
  }

  /// Create copy with updated fields
  AdReportModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdById,
    DateTime? createdAt,
    DateTime? lastModified,
    AdReportType? reportType,
    AdReportStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? selectedMetrics,
    List<String>? selectedAdIds,
    List<String>? selectedLocations,
    List<String>? selectedOwnerIds,
    AdReportFormat? exportFormat,
    Map<String, dynamic>? filterCriteria,
    Map<String, dynamic>? reportData,
    double? generationTimeSeconds,
    String? exportUrl,
    DateTime? exportExpiresAt,
    List<String>? sharedWithUserIds,
    bool? isPublic,
    Map<String, dynamic>? metadata,
  }) {
    return AdReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      reportType: reportType ?? this.reportType,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedMetrics: selectedMetrics ?? this.selectedMetrics,
      selectedAdIds: selectedAdIds ?? this.selectedAdIds,
      selectedLocations: selectedLocations ?? this.selectedLocations,
      selectedOwnerIds: selectedOwnerIds ?? this.selectedOwnerIds,
      exportFormat: exportFormat ?? this.exportFormat,
      filterCriteria: filterCriteria ?? this.filterCriteria,
      reportData: reportData ?? this.reportData,
      generationTimeSeconds:
          generationTimeSeconds ?? this.generationTimeSeconds,
      exportUrl: exportUrl ?? this.exportUrl,
      exportExpiresAt: exportExpiresAt ?? this.exportExpiresAt,
      sharedWithUserIds: sharedWithUserIds ?? this.sharedWithUserIds,
      isPublic: isPublic ?? this.isPublic,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if report is ready for export
  bool get isReady =>
      status == AdReportStatus.completed && reportData.isNotEmpty;

  /// Check if report export has expired
  bool get isExportExpired =>
      exportExpiresAt != null && DateTime.now().isAfter(exportExpiresAt!);

  /// Get report duration in days
  int get durationDays => endDate.difference(startDate).inDays;

  /// Check if user has access to this report
  bool hasAccess(String userId) {
    return createdById == userId ||
        sharedWithUserIds.contains(userId) ||
        isPublic;
  }

  /// Get formatted date range
  String get dateRangeFormatted {
    final formatter = DateFormat('MMM dd, yyyy');
    return '${formatter.format(startDate)} - ${formatter.format(endDate)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdReportModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AdReportModel(id: $id, title: $title, type: $reportType, status: $status)';
}

/// Report type enum
enum AdReportType {
  performance,
  revenue,
  audience,
  comparison,
  campaign,
  custom;

  String get value => name;

  static AdReportType fromString(String value) {
    return AdReportType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AdReportType.performance,
    );
  }

  String get displayName {
    switch (this) {
      case AdReportType.performance:
        return 'Performance Report';
      case AdReportType.revenue:
        return 'Revenue Report';
      case AdReportType.audience:
        return 'Audience Report';
      case AdReportType.comparison:
        return 'Comparison Report';
      case AdReportType.campaign:
        return 'Campaign Report';
      case AdReportType.custom:
        return 'Custom Report';
    }
  }

  String get description {
    switch (this) {
      case AdReportType.performance:
        return 'Ad performance metrics including impressions, clicks, and CTR';
      case AdReportType.revenue:
        return 'Revenue analysis and financial performance metrics';
      case AdReportType.audience:
        return 'Audience demographics and behavior analysis';
      case AdReportType.comparison:
        return 'Comparative analysis between ads or time periods';
      case AdReportType.campaign:
        return 'Campaign-level performance and ROI analysis';
      case AdReportType.custom:
        return 'Custom report with user-defined metrics and filters';
    }
  }
}

/// Report status enum
enum AdReportStatus {
  draft,
  generating,
  completed,
  failed,
  archived;

  String get value => name;

  static AdReportStatus fromString(String value) {
    return AdReportStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AdReportStatus.draft,
    );
  }

  String get displayName {
    switch (this) {
      case AdReportStatus.draft:
        return 'Draft';
      case AdReportStatus.generating:
        return 'Generating';
      case AdReportStatus.completed:
        return 'Completed';
      case AdReportStatus.failed:
        return 'Failed';
      case AdReportStatus.archived:
        return 'Archived';
    }
  }

  /// Get color for status display
  String get colorHex {
    switch (this) {
      case AdReportStatus.draft:
        return '#9E9E9E'; // Grey
      case AdReportStatus.generating:
        return '#2196F3'; // Blue
      case AdReportStatus.completed:
        return '#4CAF50'; // Green
      case AdReportStatus.failed:
        return '#F44336'; // Red
      case AdReportStatus.archived:
        return '#795548'; // Brown
    }
  }
}

/// Report export format enum
enum AdReportFormat {
  json,
  csv,
  excel,
  pdf;

  String get value => name;

  static AdReportFormat fromString(String value) {
    return AdReportFormat.values.firstWhere(
      (format) => format.value == value,
      orElse: () => AdReportFormat.json,
    );
  }

  String get displayName {
    switch (this) {
      case AdReportFormat.json:
        return 'JSON';
      case AdReportFormat.csv:
        return 'CSV';
      case AdReportFormat.excel:
        return 'Excel';
      case AdReportFormat.pdf:
        return 'PDF';
    }
  }

  String get fileExtension {
    switch (this) {
      case AdReportFormat.json:
        return '.json';
      case AdReportFormat.csv:
        return '.csv';
      case AdReportFormat.excel:
        return '.xlsx';
      case AdReportFormat.pdf:
        return '.pdf';
    }
  }

  String get mimeType {
    switch (this) {
      case AdReportFormat.json:
        return 'application/json';
      case AdReportFormat.csv:
        return 'text/csv';
      case AdReportFormat.excel:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case AdReportFormat.pdf:
        return 'application/pdf';
    }
  }
}

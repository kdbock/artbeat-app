/// Payment-related data models for analytics and processing

/// Comprehensive payment metrics for analytics dashboard
class PaymentMetrics {
  final int totalTransactions;
  final double totalRevenue;
  final double successRate;
  final double averageTransactionValue;
  final int failedTransactions;
  final Map<String, int> paymentMethodBreakdown;
  final Map<String, double> geographicDistribution;
  final DateTime lastUpdated;

  PaymentMetrics({
    required this.totalTransactions,
    required this.totalRevenue,
    required this.successRate,
    required this.averageTransactionValue,
    required this.failedTransactions,
    required this.paymentMethodBreakdown,
    required this.geographicDistribution,
    required this.lastUpdated,
  });

  factory PaymentMetrics.fromJson(Map<String, dynamic> json) {
    return PaymentMetrics(
      totalTransactions: json['totalTransactions'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      successRate: (json['successRate'] as num?)?.toDouble() ?? 0.0,
      averageTransactionValue:
          (json['averageTransactionValue'] as num?)?.toDouble() ?? 0.0,
      failedTransactions: json['failedTransactions'] as int? ?? 0,
      paymentMethodBreakdown: Map<String, int>.from(
        json['paymentMethodBreakdown'] as Map? ?? {},
      ),
      geographicDistribution: Map<String, double>.from(
        json['geographicDistribution'] as Map? ?? {},
      ),
      lastUpdated: DateTime.parse(
        json['lastUpdated'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTransactions': totalTransactions,
      'totalRevenue': totalRevenue,
      'successRate': successRate,
      'averageTransactionValue': averageTransactionValue,
      'failedTransactions': failedTransactions,
      'paymentMethodBreakdown': paymentMethodBreakdown,
      'geographicDistribution': geographicDistribution,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Individual payment event for tracking and analytics
class PaymentEvent {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String status;
  final String? paymentMethod;
  final String? failureReason;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final DateTime? processedAt;

  PaymentEvent({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    this.paymentMethod,
    this.failureReason,
    required this.metadata,
    required this.timestamp,
    this.processedAt,
  });

  factory PaymentEvent.fromJson(Map<String, dynamic> json) {
    return PaymentEvent(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String?,
      failureReason: json['failureReason'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      timestamp: DateTime.parse(
        json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      ),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'failureReason': failureReason,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }
}

/// Risk trend analysis for fraud detection and monitoring
class RiskTrend {
  final String category;
  final double riskScore;
  final String riskLevel;
  final double trend;
  final int eventCount;
  final DateTime period;
  final Map<String, dynamic> factors;

  RiskTrend({
    required this.category,
    required this.riskScore,
    required this.riskLevel,
    required this.trend,
    required this.eventCount,
    required this.period,
    required this.factors,
  });

  factory RiskTrend.fromJson(Map<String, dynamic> json) {
    return RiskTrend(
      category: json['category'] as String? ?? '',
      riskScore: (json['riskScore'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['riskLevel'] as String? ?? 'low',
      trend: (json['trend'] as num?)?.toDouble() ?? 0.0,
      eventCount: json['eventCount'] as int? ?? 0,
      period: DateTime.parse(
        json['period'] as String? ?? DateTime.now().toIso8601String(),
      ),
      factors: Map<String, dynamic>.from(json['factors'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'riskScore': riskScore,
      'riskLevel': riskLevel,
      'trend': trend,
      'eventCount': eventCount,
      'period': period.toIso8601String(),
      'factors': factors,
    };
  }
}

/// Date range for analytics queries
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});

  factory DateRange.last7Days() {
    final now = DateTime.now();
    return DateRange(start: now.subtract(const Duration(days: 7)), end: now);
  }

  factory DateRange.last30Days() {
    final now = DateTime.now();
    return DateRange(start: now.subtract(const Duration(days: 30)), end: now);
  }

  factory DateRange.last90Days() {
    final now = DateTime.now();
    return DateRange(start: now.subtract(const Duration(days: 90)), end: now);
  }

  factory DateRange.custom(DateTime start, DateTime end) {
    return DateRange(start: start, end: end);
  }

  bool contains(DateTime date) {
    return date.isAfter(start) && date.isBefore(end);
  }

  Map<String, dynamic> toJson() {
    return {'start': start.toIso8601String(), 'end': end.toIso8601String()};
  }

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );
  }
}

/// Analytics report metadata
class AnalyticsReport {
  final String id;
  final String title;
  final String period;
  final DateTime generatedAt;
  final String generatedBy;
  final Map<String, dynamic> data;
  final String? downloadUrl;

  AnalyticsReport({
    required this.id,
    required this.title,
    required this.period,
    required this.generatedAt,
    required this.generatedBy,
    required this.data,
    this.downloadUrl,
  });

  factory AnalyticsReport.fromJson(Map<String, dynamic> json) {
    return AnalyticsReport(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      period: json['period'] as String? ?? '',
      generatedAt: DateTime.parse(
        json['generatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      generatedBy: json['generatedBy'] as String? ?? '',
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      downloadUrl: json['downloadUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'period': period,
      'generatedAt': generatedAt.toIso8601String(),
      'generatedBy': generatedBy,
      'data': data,
      'downloadUrl': downloadUrl,
    };
  }
}

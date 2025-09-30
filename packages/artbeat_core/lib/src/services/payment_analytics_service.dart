import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_models.dart';
import '../utils/logger.dart';

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
}

/// Payment metrics data structure
/// Enhanced payment analytics service with Firebase integration
class PaymentAnalyticsService {
  static final PaymentAnalyticsService _instance =
      PaymentAnalyticsService._internal();

  factory PaymentAnalyticsService() {
    return _instance;
  }

  PaymentAnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get comprehensive payment metrics for a date range
  Future<PaymentMetrics> getPaymentMetrics(DateRange range) async {
    try {
      AppLogger.info(
        '📊 Fetching payment metrics for range: ${range.start} to ${range.end}',
      );

      // Query payment events within the date range
      final paymentEventsQuery = await _firestore
          .collection('payment_events')
          .where('timestamp', isGreaterThanOrEqualTo: range.start)
          .where('timestamp', isLessThanOrEqualTo: range.end)
          .get();

      final paymentEvents = paymentEventsQuery.docs
          .map((doc) => PaymentEvent.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Calculate metrics
      final totalTransactions = paymentEvents.length;
      final successfulTransactions = paymentEvents
          .where((e) => e.status == 'completed')
          .length;
      final failedTransactions = paymentEvents
          .where((e) => e.status == 'failed')
          .length;
      final successRate = totalTransactions > 0
          ? successfulTransactions / totalTransactions
          : 0.0;

      // Calculate revenue from successful payments
      final totalRevenue = paymentEvents
          .where((e) => e.status == 'completed')
          .fold<double>(0.0, (sum, e) => sum + e.amount);

      final averageTransactionValue = successfulTransactions > 0
          ? totalRevenue / successfulTransactions
          : 0.0;

      // Payment method breakdown
      final paymentMethodBreakdown = <String, int>{};
      for (final event in paymentEvents) {
        final method = event.paymentMethod ?? 'unknown';
        paymentMethodBreakdown[method] =
            (paymentMethodBreakdown[method] ?? 0) + 1;
      }

      // Geographic distribution (mock data for now)
      final geographicDistribution = <String, double>{};
      // TODO(analytics): Implement actual geographic distribution based on user location data

      return PaymentMetrics(
        totalTransactions: totalTransactions,
        totalRevenue: totalRevenue,
        successRate: successRate,
        averageTransactionValue: averageTransactionValue,
        failedTransactions: failedTransactions,
        paymentMethodBreakdown: paymentMethodBreakdown,
        geographicDistribution: geographicDistribution,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('❌ Error fetching payment metrics: $e');
      return PaymentMetrics(
        totalTransactions: 0,
        totalRevenue: 0.0,
        successRate: 0.0,
        averageTransactionValue: 0.0,
        failedTransactions: 0,
        paymentMethodBreakdown: {},
        geographicDistribution: {},
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Get risk trends over time
  Future<List<RiskTrend>> getRiskTrends({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final riskEventsQuery = await _firestore
          .collection('payment_events')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .orderBy('timestamp')
          .get();

      final riskEvents = riskEventsQuery.docs
          .map((doc) => PaymentEvent.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Group by date
      final trends = <DateTime, List<PaymentEvent>>{};
      for (final event in riskEvents) {
        final date = DateTime(
          event.timestamp.year,
          event.timestamp.month,
          event.timestamp.day,
        );
        trends[date] = (trends[date] ?? [])..add(event);
      }

      // Calculate trends based on payment status and amount
      final riskTrends = <RiskTrend>[];
      for (final entry in trends.entries) {
        final events = entry.value;
        final failedEvents = events.where((e) => e.status == 'failed').length;
        final highAmountEvents = events.where((e) => e.amount > 1000).length;

        // Calculate risk score based on failure rate and high amounts
        final failureRate = events.isNotEmpty
            ? failedEvents / events.length
            : 0.0;
        final highAmountRate = events.isNotEmpty
            ? highAmountEvents / events.length
            : 0.0;
        final riskScore = (failureRate * 0.6) + (highAmountRate * 0.4);

        final riskFactors = <String, int>{};
        if (failedEvents > 0) riskFactors['payment_failures'] = failedEvents;
        if (highAmountEvents > 0)
          riskFactors['high_amount_transactions'] = highAmountEvents;

        riskTrends.add(
          RiskTrend(
            category: 'Payment Risk',
            riskScore: riskScore,
            riskLevel: riskScore > 0.7
                ? 'high'
                : riskScore > 0.4
                ? 'medium'
                : 'low',
            trend: 0.0, // TODO(analytics): Calculate actual trend
            eventCount: events.length,
            period: entry.key,
            factors: riskFactors,
          ),
        );
      }

      return riskTrends;
    } catch (e) {
      AppLogger.error('❌ Error fetching risk trends: $e');
      return [];
    }
  }

  /// Get conversion rates by payment method and amount range
  Future<Map<String, double>> getConversionRates() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final eventsQuery = await _firestore
          .collection('payment_events')
          .where('timestamp', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .get();

      final events = eventsQuery.docs
          .map((doc) => PaymentEvent.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Group by payment method
      final methodStats = <String, Map<String, int>>{};
      for (final event in events) {
        final method = event.paymentMethod ?? 'unknown';
        methodStats[method] ??= {'total': 0, 'success': 0};
        methodStats[method]!['total'] = methodStats[method]!['total']! + 1;
        if (event.status == 'completed') {
          methodStats[method]!['success'] =
              methodStats[method]!['success']! + 1;
        }
      }

      // Calculate conversion rates
      final conversionRates = <String, double>{};
      for (final entry in methodStats.entries) {
        final total = entry.value['total']!;
        final success = entry.value['success']!;
        conversionRates[entry.key] = total > 0 ? (success / total) * 100 : 0.0;
      }

      return conversionRates;
    } catch (e) {
      AppLogger.error('❌ Error fetching conversion rates: $e');
      return {};
    }
  }

  /// Get recent payment events for monitoring
  Future<List<PaymentEvent>> getRecentPayments({int limit = 50}) async {
    try {
      final eventsQuery = await _firestore
          .collection('payment_events')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return eventsQuery.docs
          .map((doc) => PaymentEvent.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching recent payments: $e');
      return [];
    }
  }

  /// Get payment method usage statistics
  Future<Map<String, int>> getPaymentMethodUsage({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final eventsQuery = await _firestore
          .collection('payment_events')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('event', isEqualTo: 'success')
          .get();

      final usage = <String, int>{};
      for (final doc in eventsQuery.docs) {
        final method = doc.data()['paymentMethod'] as String? ?? 'unknown';
        usage[method] = (usage[method] ?? 0) + 1;
      }

      return usage;
    } catch (e) {
      AppLogger.error('❌ Error fetching payment method usage: $e');
      return {};
    }
  }

  /// Get fraud detection effectiveness metrics
  Future<Map<String, dynamic>> getFraudMetrics({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      // Get fraud attempts
      final fraudQuery = await _firestore
          .collection('fraud_attempts')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .get();

      // Get risk assessments
      final riskQuery = await _firestore
          .collection('payment_events')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('riskScore', isGreaterThan: 0)
          .get();

      final fraudAttempts = fraudQuery.docs.length;
      final riskAssessments = riskQuery.docs.length;

      final highRiskPayments = riskQuery.docs
          .where((doc) => (doc.data()['riskScore'] as num? ?? 0) > 0.7)
          .length;

      return {
        'fraud_attempts': fraudAttempts,
        'risk_assessments': riskAssessments,
        'high_risk_payments': highRiskPayments,
        'fraud_detection_rate': riskAssessments > 0
            ? (highRiskPayments / riskAssessments) * 100
            : 0.0,
        'period_days': days,
      };
    } catch (e) {
      AppLogger.error('❌ Error fetching fraud metrics: $e');
      return {
        'fraud_attempts': 0,
        'risk_assessments': 0,
        'high_risk_payments': 0,
        'fraud_detection_rate': 0.0,
        'period_days': days,
      };
    }
  }

  /// Get geographic payment distribution
  Future<Map<String, int>> getGeographicDistribution({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final eventsQuery = await _firestore
          .collection('payment_events')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('event', isEqualTo: 'success')
          .get();

      final distribution = <String, int>{};
      for (final doc in eventsQuery.docs) {
        // Note: This would require storing location data in payment events
        // For now, return mock data structure
        final location = doc.data()['location'] as String? ?? 'unknown';
        distribution[location] = (distribution[location] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      AppLogger.error('❌ Error fetching geographic distribution: $e');
      return {};
    }
  }

  /// Export analytics data for reporting
  Future<String> exportAnalyticsData(DateRange range) async {
    try {
      final metrics = await getPaymentMetrics(range);
      final trends = await getRiskTrends(
        days: range.end.difference(range.start).inDays,
      );
      final conversionRates = await getConversionRates();

      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'date_range': {
          'start': range.start.toIso8601String(),
          'end': range.end.toIso8601String(),
        },
        'metrics': {
          'total_transactions': metrics.totalTransactions,
          'total_revenue': metrics.totalRevenue,
          'success_rate': metrics.successRate,
          'average_transaction_value': metrics.averageTransactionValue,
          'failed_transactions': metrics.failedTransactions,
          'payment_method_breakdown': metrics.paymentMethodBreakdown,
          'geographic_distribution': metrics.geographicDistribution,
          'last_updated': metrics.lastUpdated.toIso8601String(),
        },
        'risk_trends': trends
            .map(
              (t) => {
                'category': t.category,
                'risk_score': t.riskScore,
                'risk_level': t.riskLevel,
                'trend': t.trend,
                'event_count': t.eventCount,
                'period': t.period.toIso8601String(),
                'factors': t.factors,
              },
            )
            .toList(),
        'conversion_rates': conversionRates,
      };

      return json.encode(exportData);
    } catch (e) {
      AppLogger.error('❌ Error exporting analytics data: $e');
      return json.encode({
        'error': 'Failed to export analytics data',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Get real-time payment metrics stream
  Stream<PaymentMetrics> getPaymentMetricsStream() {
    return _firestore
        .collection('payment_metrics')
        .doc('current')
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return PaymentMetrics.fromJson(doc.data()!);
          }
          return PaymentMetrics(
            totalTransactions: 0,
            totalRevenue: 0.0,
            successRate: 0.0,
            averageTransactionValue: 0.0,
            failedTransactions: 0,
            paymentMethodBreakdown: <String, int>{},
            geographicDistribution: <String, double>{},
            lastUpdated: DateTime.now(),
          );
        });
  }

  /// Get recent payment events
  Future<List<PaymentEvent>> getRecentPaymentEvents({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('payment_events')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => PaymentEvent.fromJson(doc.data()))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching recent payment events: $e');
      return [];
    }
  }

  /// Get performance metrics
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final querySnapshot = await _firestore
          .collection('payment_events')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .get();

      final events = querySnapshot.docs
          .map((doc) => PaymentEvent.fromJson(doc.data()))
          .toList();

      final totalEvents = events.length;
      final successfulEvents = events
          .where((e) => e.status == 'completed')
          .length;
      final failedEvents = events.where((e) => e.status == 'failed').length;

      final conversionRate = totalEvents > 0
          ? successfulEvents / totalEvents
          : 0.0;
      final failureRate = totalEvents > 0 ? failedEvents / totalEvents : 0.0;

      // Calculate average processing time (mock data for now)
      const avgProcessingTime = 1500; // milliseconds

      return {
        'conversionRate': conversionRate,
        'failureRate': failureRate,
        'avgProcessingTime': avgProcessingTime,
        'totalEvents': totalEvents,
        'successfulEvents': successfulEvents,
        'failedEvents': failedEvents,
      };
    } catch (e) {
      AppLogger.error('❌ Error fetching performance metrics: $e');
      return {
        'conversionRate': 0.0,
        'failureRate': 0.0,
        'avgProcessingTime': 0,
        'totalEvents': 0,
        'successfulEvents': 0,
        'failedEvents': 0,
      };
    }
  }
}

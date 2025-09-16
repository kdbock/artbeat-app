import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Advanced payment analytics service for revenue reporting and financial insights
///
/// Provides comprehensive analytics including:
/// - Revenue tracking and forecasting
/// - Payment method analysis
/// - Geographic revenue distribution
/// - Customer lifetime value
/// - Churn and retention analytics
/// - Financial performance metrics
class PaymentAnalyticsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _paymentHistoryCollection = 'payment_history';

  /// Get comprehensive revenue analytics
  Future<Map<String, dynamic>> getRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? currency = 'USD',
  }) async {
    try {
      Query paymentsQuery = _firestore
          .collection(_paymentHistoryCollection)
          .where('currency', isEqualTo: currency);

      if (startDate != null) {
        paymentsQuery = paymentsQuery.where(
          'transactionDate',
          isGreaterThanOrEqualTo: startDate,
        );
      }

      if (endDate != null) {
        paymentsQuery = paymentsQuery.where(
          'transactionDate',
          isLessThanOrEqualTo: endDate,
        );
      }

      final paymentsSnapshot = await paymentsQuery.get();

      double totalRevenue = 0.0;
      double completedRevenue = 0.0;
      double refundedAmount = 0.0;
      double pendingRevenue = 0.0;
      int totalTransactions = 0;
      int successfulTransactions = 0;
      int failedTransactions = 0;
      int refundedTransactions = 0;

      final paymentMethodBreakdown = <String, Map<String, dynamic>>{};
      final dailyRevenue = <String, double>{};
      final userRevenue = <String, double>{};

      for (var doc in paymentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = ((data['amount'] as num?) ?? 0).toDouble();
        final refundAmount = ((data['refundAmount'] as num?) ?? 0).toDouble();
        final status = (data['status'] as String?) ?? 'pending';
        final paymentMethod = (data['paymentMethod'] as String?) ?? 'unknown';
        final userId = (data['userId'] as String?) ?? 'unknown';
        final transactionDate = (data['transactionDate'] as Timestamp?)
            ?.toDate();

        totalTransactions++;
        totalRevenue += amount;

        // Status analysis
        switch (status) {
          case 'completed':
            successfulTransactions++;
            completedRevenue += (amount - refundAmount);
            break;
          case 'failed':
          case 'cancelled':
            failedTransactions++;
            break;
          case 'refunded':
          case 'partially_refunded':
            refundedTransactions++;
            refundedAmount += refundAmount;
            completedRevenue += (amount - refundAmount);
            break;
          case 'pending':
          case 'processing':
            pendingRevenue += amount;
            break;
        }

        // Payment method breakdown
        if (!paymentMethodBreakdown.containsKey(paymentMethod)) {
          paymentMethodBreakdown[paymentMethod] = {
            'totalAmount': 0.0,
            'transactionCount': 0,
            'averageAmount': 0.0,
          };
        }
        paymentMethodBreakdown[paymentMethod]!['totalAmount'] =
            (paymentMethodBreakdown[paymentMethod]!['totalAmount'] as double) +
            amount;
        paymentMethodBreakdown[paymentMethod]!['transactionCount'] =
            (paymentMethodBreakdown[paymentMethod]!['transactionCount']
                as int) +
            1;

        // Daily revenue tracking
        if (transactionDate != null && status == 'completed') {
          final dateKey =
              '${transactionDate.year}-${transactionDate.month.toString().padLeft(2, '0')}-${transactionDate.day.toString().padLeft(2, '0')}';
          dailyRevenue[dateKey] =
              (dailyRevenue[dateKey] ?? 0.0) + (amount - refundAmount);
        }

        // User revenue tracking
        if (status == 'completed') {
          userRevenue[userId] =
              (userRevenue[userId] ?? 0.0) + (amount - refundAmount);
        }
      }

      // Calculate payment method averages
      for (var method in paymentMethodBreakdown.keys) {
        final data = paymentMethodBreakdown[method]!;
        final count = data['transactionCount'] as int;
        final total = data['totalAmount'] as double;
        data['averageAmount'] = count > 0 ? total / count : 0.0;
      }

      return {
        'totalRevenue': totalRevenue,
        'completedRevenue': completedRevenue,
        'refundedAmount': refundedAmount,
        'netRevenue': completedRevenue - refundedAmount,
        'pendingRevenue': pendingRevenue,
        'totalTransactions': totalTransactions,
        'successfulTransactions': successfulTransactions,
        'failedTransactions': failedTransactions,
        'refundedTransactions': refundedTransactions,
        'successRate': totalTransactions > 0
            ? (successfulTransactions / totalTransactions) * 100
            : 0.0,
        'refundRate': successfulTransactions > 0
            ? (refundedTransactions / successfulTransactions) * 100
            : 0.0,
        'averageTransactionAmount': successfulTransactions > 0
            ? completedRevenue / successfulTransactions
            : 0.0,
        'paymentMethodBreakdown': paymentMethodBreakdown,
        'dailyRevenue': dailyRevenue,
        'topCustomers': _getTopCustomers(userRevenue, 10),
        'currency': currency,
      };
    } catch (e) {
      AppLogger.error('Error getting revenue analytics: $e');
      return {};
    }
  }

  /// Get payment method performance analytics
  Future<List<Map<String, dynamic>>> getPaymentMethodAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(_paymentHistoryCollection);

      if (startDate != null) {
        query = query.where(
          'transactionDate',
          isGreaterThanOrEqualTo: startDate,
        );
      }

      if (endDate != null) {
        query = query.where('transactionDate', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      final methodStats = <String, Map<String, dynamic>>{};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final method = (data['paymentMethod'] as String?) ?? 'unknown';
        final amount = ((data['amount'] as num?) ?? 0).toDouble();
        final status = (data['status'] as String?) ?? 'pending';

        if (!methodStats.containsKey(method)) {
          methodStats[method] = {
            'method': method,
            'totalTransactions': 0,
            'successfulTransactions': 0,
            'failedTransactions': 0,
            'totalAmount': 0.0,
            'successfulAmount': 0.0,
            'averageAmount': 0.0,
            'successRate': 0.0,
          };
        }

        final stats = methodStats[method]!;
        stats['totalTransactions'] = (stats['totalTransactions'] as int) + 1;
        stats['totalAmount'] = (stats['totalAmount'] as double) + amount;

        if (status == 'completed') {
          stats['successfulTransactions'] =
              (stats['successfulTransactions'] as int) + 1;
          stats['successfulAmount'] =
              (stats['successfulAmount'] as double) + amount;
        } else if (status == 'failed' || status == 'cancelled') {
          stats['failedTransactions'] =
              (stats['failedTransactions'] as int) + 1;
        }
      }

      // Calculate derived metrics
      for (var stats in methodStats.values) {
        final totalTransactions = stats['totalTransactions'] as int;
        final successfulTransactions = stats['successfulTransactions'] as int;
        final successfulAmount = stats['successfulAmount'] as double;

        stats['successRate'] = totalTransactions > 0
            ? (successfulTransactions / totalTransactions) * 100
            : 0.0;
        stats['averageAmount'] = successfulTransactions > 0
            ? successfulAmount / successfulTransactions
            : 0.0;
      }

      // Sort by total successful amount
      final sortedMethods = methodStats.values.toList()
        ..sort(
          (a, b) => (b['successfulAmount'] as double).compareTo(
            a['successfulAmount'] as double,
          ),
        );

      return sortedMethods;
    } catch (e) {
      AppLogger.error('Error getting payment method analytics: $e');
      return [];
    }
  }

  /// Get customer analytics and segmentation
  Future<Map<String, dynamic>> getCustomerAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_paymentHistoryCollection)
          .where('status', isEqualTo: 'completed');

      if (startDate != null) {
        query = query.where(
          'transactionDate',
          isGreaterThanOrEqualTo: startDate,
        );
      }

      if (endDate != null) {
        query = query.where('transactionDate', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      final customerData = <String, Map<String, dynamic>>{};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = (data['userId'] as String?) ?? 'unknown';
        final amount = ((data['amount'] as num?) ?? 0).toDouble();
        final refundAmount = ((data['refundAmount'] as num?) ?? 0).toDouble();
        final transactionDate = (data['transactionDate'] as Timestamp?)
            ?.toDate();

        if (!customerData.containsKey(userId)) {
          customerData[userId] = {
            'userId': userId,
            'totalSpent': 0.0,
            'netSpent': 0.0,
            'transactionCount': 0,
            'refundedAmount': 0.0,
            'averageOrderValue': 0.0,
            'firstPurchase': transactionDate,
            'lastPurchase': transactionDate,
            'monthlySpending': <String, double>{},
          };
        }

        final customer = customerData[userId]!;
        customer['totalSpent'] = (customer['totalSpent'] as double) + amount;
        customer['netSpent'] =
            (customer['netSpent'] as double) + (amount - refundAmount);
        customer['transactionCount'] =
            (customer['transactionCount'] as int) + 1;
        customer['refundedAmount'] =
            (customer['refundedAmount'] as double) + refundAmount;

        // Update first and last purchase dates
        final firstPurchase = customer['firstPurchase'] as DateTime?;
        final lastPurchase = customer['lastPurchase'] as DateTime?;

        if (transactionDate != null) {
          if (firstPurchase == null ||
              transactionDate.isBefore(firstPurchase)) {
            customer['firstPurchase'] = transactionDate;
          }
          if (lastPurchase == null || transactionDate.isAfter(lastPurchase)) {
            customer['lastPurchase'] = transactionDate;
          }

          // Monthly spending
          final monthKey =
              '${transactionDate.year}-${transactionDate.month.toString().padLeft(2, '0')}';
          final monthlySpending =
              customer['monthlySpending'] as Map<String, double>;
          monthlySpending[monthKey] =
              (monthlySpending[monthKey] ?? 0.0) + (amount - refundAmount);
        }
      }

      // Calculate customer metrics
      final int totalCustomers = customerData.length;
      int oneTimeCustomers = 0;
      int repeatCustomers = 0;
      int highValueCustomers = 0;
      double totalCustomerLifetimeValue = 0.0;
      double averageOrderValue = 0.0;
      int totalOrders = 0;

      for (var customer in customerData.values) {
        final transactionCount = customer['transactionCount'] as int;
        final netSpent = customer['netSpent'] as double;

        totalCustomerLifetimeValue += netSpent;
        totalOrders += transactionCount;

        customer['averageOrderValue'] = transactionCount > 0
            ? netSpent / transactionCount
            : 0.0;

        if (transactionCount == 1) {
          oneTimeCustomers++;
        } else {
          repeatCustomers++;
        }

        if (netSpent > 50.0) {
          // High value threshold
          highValueCustomers++;
        }
      }

      averageOrderValue = totalOrders > 0
          ? totalCustomerLifetimeValue / totalOrders
          : 0.0;

      // Customer segmentation
      final segments = _segmentCustomers(customerData.values.toList());

      return {
        'totalCustomers': totalCustomers,
        'oneTimeCustomers': oneTimeCustomers,
        'repeatCustomers': repeatCustomers,
        'highValueCustomers': highValueCustomers,
        'repeatCustomerRate': totalCustomers > 0
            ? (repeatCustomers / totalCustomers) * 100
            : 0.0,
        'averageCustomerLifetimeValue': totalCustomers > 0
            ? totalCustomerLifetimeValue / totalCustomers
            : 0.0,
        'averageOrderValue': averageOrderValue,
        'totalCustomerLifetimeValue': totalCustomerLifetimeValue,
        'customerSegments': segments,
        'topCustomers': _getTopCustomersDetailed(customerData, 20),
      };
    } catch (e) {
      AppLogger.error('Error getting customer analytics: $e');
      return {};
    }
  }

  /// Get revenue forecasting based on historical data
  Future<Map<String, dynamic>> getRevenueForecast({
    required int forecastDays,
    int historicalDays = 90,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: historicalDays));

      final paymentsSnapshot = await _firestore
          .collection(_paymentHistoryCollection)
          .where('status', isEqualTo: 'completed')
          .where('transactionDate', isGreaterThanOrEqualTo: startDate)
          .where('transactionDate', isLessThanOrEqualTo: endDate)
          .orderBy('transactionDate')
          .get();

      // Group data by day
      final dailyRevenue = <DateTime, double>{};
      for (var doc in paymentsSnapshot.docs) {
        final data = doc.data();
        final amount = ((data['amount'] as num?) ?? 0).toDouble();
        final refundAmount = ((data['refundAmount'] as num?) ?? 0).toDouble();
        final transactionDate = (data['transactionDate'] as Timestamp?)
            ?.toDate();

        if (transactionDate != null) {
          final dayKey = DateTime(
            transactionDate.year,
            transactionDate.month,
            transactionDate.day,
          );
          dailyRevenue[dayKey] =
              (dailyRevenue[dayKey] ?? 0.0) + (amount - refundAmount);
        }
      }

      // Simple moving average forecast
      final revenueValues = dailyRevenue.values.toList();
      final double averageDailyRevenue = revenueValues.isNotEmpty
          ? revenueValues.reduce((a, b) => a + b) / revenueValues.length
          : 0.0;

      // Calculate trend (simple linear regression)
      double trend = 0.0;
      if (revenueValues.length > 1) {
        double sumX = 0;
        double sumY = 0;
        double sumXY = 0;
        double sumXX = 0;
        final int n = revenueValues.length;

        for (int i = 0; i < n; i++) {
          sumX += i;
          sumY += revenueValues[i];
          sumXY += i * revenueValues[i];
          sumXX += i * i;
        }

        trend = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
      }

      // Generate forecast
      final forecast = <Map<String, dynamic>>[];
      double currentRevenue = averageDailyRevenue;

      for (int i = 1; i <= forecastDays; i++) {
        currentRevenue += trend;
        final forecastDate = endDate.add(Duration(days: i));

        forecast.add({
          'date': forecastDate.toIso8601String().split('T')[0],
          'predictedRevenue': currentRevenue,
          'confidence': _calculateConfidence(i, forecastDays),
        });
      }

      final totalForecastRevenue = forecast.fold<double>(
        0.0,
        (sum, day) => sum + (day['predictedRevenue'] as double),
      );

      return {
        'historicalPeriodDays': historicalDays,
        'forecastPeriodDays': forecastDays,
        'averageDailyRevenue': averageDailyRevenue,
        'revenueGrowthTrend': trend,
        'totalForecastRevenue': totalForecastRevenue,
        'dailyForecast': forecast,
        'confidence': 'Medium', // Simple confidence rating
        'methodology': 'Linear trend analysis with moving average baseline',
      };
    } catch (e) {
      AppLogger.error('Error getting revenue forecast: $e');
      return {};
    }
  }

  /// Get churn and retention analytics
  Future<Map<String, dynamic>> getRetentionAnalytics({
    int analysisMonths = 12,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = DateTime(
        endDate.year,
        endDate.month - analysisMonths,
        1,
      );

      final paymentsSnapshot = await _firestore
          .collection(_paymentHistoryCollection)
          .where('status', isEqualTo: 'completed')
          .where('transactionDate', isGreaterThanOrEqualTo: startDate)
          .where('transactionDate', isLessThanOrEqualTo: endDate)
          .orderBy('transactionDate')
          .get();

      // Group customers by their activity months
      final customerActivity = <String, Set<String>>{};

      for (var doc in paymentsSnapshot.docs) {
        final data = doc.data();
        final userId = (data['userId'] as String?) ?? 'unknown';
        final transactionDate = (data['transactionDate'] as Timestamp?)
            ?.toDate();

        if (transactionDate != null) {
          final monthKey =
              '${transactionDate.year}-${transactionDate.month.toString().padLeft(2, '0')}';

          if (!customerActivity.containsKey(userId)) {
            customerActivity[userId] = <String>{};
          }
          customerActivity[userId]!.add(monthKey);
        }
      }

      // Calculate retention metrics
      final monthlyRetention = <String, Map<String, dynamic>>{};
      final allMonths = <String>[];

      // Generate month list
      for (int i = 0; i < analysisMonths; i++) {
        final month = DateTime(
          endDate.year,
          endDate.month - (analysisMonths - 1 - i),
          1,
        );
        final monthKey =
            '${month.year}-${month.month.toString().padLeft(2, '0')}';
        allMonths.add(monthKey);
      }

      for (int i = 0; i < allMonths.length - 1; i++) {
        final currentMonth = allMonths[i];
        final nextMonth = allMonths[i + 1];

        final currentMonthCustomers = customerActivity.keys
            .where((userId) => customerActivity[userId]!.contains(currentMonth))
            .toSet();

        final nextMonthCustomers = customerActivity.keys
            .where((userId) => customerActivity[userId]!.contains(nextMonth))
            .toSet();

        final retainedCustomers = currentMonthCustomers.intersection(
          nextMonthCustomers,
        );

        final retentionRate = currentMonthCustomers.isNotEmpty
            ? (retainedCustomers.length / currentMonthCustomers.length) * 100
            : 0.0;

        monthlyRetention[currentMonth] = {
          'month': currentMonth,
          'totalCustomers': currentMonthCustomers.length,
          'retainedCustomers': retainedCustomers.length,
          'churnedCustomers':
              currentMonthCustomers.length - retainedCustomers.length,
          'retentionRate': retentionRate,
          'churnRate': 100 - retentionRate,
        };
      }

      // Calculate overall metrics
      final retentionRates = monthlyRetention.values.map(
        (m) => m['retentionRate'] as double,
      );
      final averageRetentionRate = retentionRates.isNotEmpty
          ? retentionRates.reduce((a, b) => a + b) / retentionRates.length
          : 0.0;

      return {
        'analysisMonths': analysisMonths,
        'averageRetentionRate': averageRetentionRate,
        'averageChurnRate': 100 - averageRetentionRate,
        'totalUniqueCustomers': customerActivity.length,
        'monthlyRetention': monthlyRetention.values.toList(),
        'retentionTrend': _calculateRetentionTrend(
          monthlyRetention.values.toList(),
        ),
      };
    } catch (e) {
      AppLogger.error('Error getting retention analytics: $e');
      return {};
    }
  }

  // Private helper methods

  List<Map<String, dynamic>> _getTopCustomers(
    Map<String, double> userRevenue,
    int limit,
  ) {
    final sortedCustomers = userRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCustomers
        .take(limit)
        .map((entry) => {'userId': entry.key, 'totalRevenue': entry.value})
        .toList();
  }

  List<Map<String, dynamic>> _getTopCustomersDetailed(
    Map<String, Map<String, dynamic>> customerData,
    int limit,
  ) {
    final sortedCustomers = customerData.values.toList()
      ..sort(
        (a, b) => (b['netSpent'] as double).compareTo(a['netSpent'] as double),
      );

    return sortedCustomers.take(limit).toList();
  }

  Map<String, List<Map<String, dynamic>>> _segmentCustomers(
    List<Map<String, dynamic>> customers,
  ) {
    final segments = <String, List<Map<String, dynamic>>>{
      'highValue': [],
      'mediumValue': [],
      'lowValue': [],
      'atRisk': [],
      'loyal': [],
    };

    for (var customer in customers) {
      final netSpent = customer['netSpent'] as double;
      final transactionCount = customer['transactionCount'] as int;
      final lastPurchase = customer['lastPurchase'] as DateTime?;

      final daysSinceLastPurchase = lastPurchase != null
          ? DateTime.now().difference(lastPurchase).inDays
          : 999;

      // High value customers
      if (netSpent > 100.0) {
        segments['highValue']!.add(customer);
      }
      // Medium value customers
      else if (netSpent > 25.0) {
        segments['mediumValue']!.add(customer);
      }
      // Low value customers
      else {
        segments['lowValue']!.add(customer);
      }

      // At risk customers (no purchase in 60+ days)
      if (daysSinceLastPurchase > 60) {
        segments['atRisk']!.add(customer);
      }

      // Loyal customers (5+ transactions)
      if (transactionCount >= 5) {
        segments['loyal']!.add(customer);
      }
    }

    return segments;
  }

  double _calculateConfidence(int dayNumber, int totalDays) {
    // Confidence decreases as we forecast further into the future
    final confidenceScore = 1.0 - (dayNumber / totalDays);
    return (confidenceScore * 100).clamp(10.0, 100.0);
  }

  String _calculateRetentionTrend(List<Map<String, dynamic>> monthlyData) {
    if (monthlyData.length < 2) return 'insufficient_data';

    final first = monthlyData.first['retentionRate'] as double;
    final last = monthlyData.last['retentionRate'] as double;
    final change = last - first;

    if (change > 5) return 'improving';
    if (change < -5) return 'declining';
    return 'stable';
  }
}

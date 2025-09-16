import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../models/analytics_model.dart';

/// Service for managing financial data and analytics in admin dashboard
class FinancialService extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  FinancialService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get recent transactions for admin dashboard
  Future<List<TransactionModel>> getRecentTransactions({int limit = 10}) async {
    try {
      final transactions = <TransactionModel>[];

      // Get payment history from ads
      final adPayments = await _firestore
          .collection('payment_history')
          .orderBy('transactionDate', descending: true)
          .limit(limit ~/ 2)
          .get();

      for (final doc in adPayments.docs) {
        final data = doc.data();
        transactions.add(TransactionModel(
          id: doc.id,
          userId: data['userId'] as String? ?? '',
          userName: await _getUserName(data['userId'] as String? ?? ''),
          amount: ((data['amount'] as num?) ?? 0).toDouble(),
          currency: data['currency'] as String? ?? 'USD',
          type: 'ad_payment',
          status: data['status'] as String? ?? 'pending',
          paymentMethod: data['paymentMethod'] as String? ?? 'card',
          transactionDate: (data['transactionDate'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          description: 'Advertisement Payment',
          itemId: data['adId'] as String?,
          itemTitle: data['adTitle'] as String?,
          metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
        ));
      }

      // Get subscription payments (if they exist)
      try {
        final subscriptions = await _firestore
            .collection('subscriptions')
            .where('status', isEqualTo: 'active')
            .orderBy('createdAt', descending: true)
            .limit(limit ~/ 2)
            .get();

        for (final doc in subscriptions.docs) {
          final data = doc.data();
          transactions.add(TransactionModel(
            id: doc.id,
            userId: data['userId'] as String? ?? '',
            userName: await _getUserName(data['userId'] as String? ?? ''),
            amount: ((data['amount'] as num?) ?? 29.99).toDouble(),
            currency: 'USD',
            type: 'subscription',
            status: 'completed',
            paymentMethod: data['paymentMethod'] as String? ?? 'card',
            transactionDate:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            description: 'Monthly Subscription',
            itemTitle: data['planName'] as String? ?? 'Premium Plan',
          ));
        }
      } catch (e) {
        debugPrint('No subscriptions collection found: $e');
      }

      // Sort by date and return limited results
      transactions
          .sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return transactions.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching recent transactions: $e');
      return [];
    }
  }

  /// Get financial metrics for dashboard
  Future<FinancialMetrics> getFinancialMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Get ad payments
      final adPaymentsQuery = await _firestore
          .collection('payment_history')
          .where('transactionDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('transactionDate',
              isLessThanOrEqualTo: Timestamp.fromDate(end))
          .where('status', isEqualTo: 'completed')
          .get();

      double totalRevenue = 0;
      double adRevenue = 0;
      int totalTransactions = 0;
      final revenueByCategory = <String, double>{};
      final revenueTimeSeries = <RevenueDataPoint>[];

      // Process ad payments
      for (final doc in adPaymentsQuery.docs) {
        final data = doc.data();
        final amount = ((data['amount'] as num?) ?? 0).toDouble();
        final date =
            (data['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now();

        totalRevenue += amount;
        adRevenue += amount;
        totalTransactions++;

        revenueTimeSeries.add(RevenueDataPoint(
          date: date,
          amount: amount,
          category: 'advertisements',
        ));
      }

      // Get subscription revenue (if exists)
      double subscriptionRevenue = 0;
      try {
        final subscriptionsQuery = await _firestore
            .collection('subscriptions')
            .where('status', isEqualTo: 'active')
            .get();

        subscriptionRevenue =
            subscriptionsQuery.docs.length * 29.99; // Assuming $29.99/month
        totalRevenue += subscriptionRevenue;
      } catch (e) {
        debugPrint('No subscriptions found: $e');
      }

      // Get artwork sales (if exists)
      double artworkRevenue = 0;
      try {
        final artworkSalesQuery = await _firestore
            .collection('artwork_sales')
            .where('saleDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .where('status', isEqualTo: 'completed')
            .get();

        for (final doc in artworkSalesQuery.docs) {
          final data = doc.data();
          final amount = ((data['amount'] as num?) ?? 0).toDouble();
          artworkRevenue += amount;
          totalRevenue += amount;
          totalTransactions++;
        }
      } catch (e) {
        debugPrint('No artwork sales found: $e');
      }

      // Calculate metrics
      revenueByCategory['advertisements'] = adRevenue;
      revenueByCategory['subscriptions'] = subscriptionRevenue;
      revenueByCategory['artwork'] = artworkRevenue;

      final averageRevenuePerUser =
          totalTransactions > 0 ? totalRevenue / totalTransactions : 0.0;
      final monthlyRecurringRevenue = subscriptionRevenue;

      // Calculate growth (comparing to previous period)
      final previousPeriodStart = start.subtract(end.difference(start));
      final previousMetrics =
          await _getPreviousPeriodRevenue(previousPeriodStart, start);
      final revenueGrowth = previousMetrics > 0
          ? ((totalRevenue - previousMetrics) / previousMetrics) * 100
          : 0.0;

      return FinancialMetrics(
        totalRevenue: totalRevenue,
        subscriptionRevenue: subscriptionRevenue,
        eventRevenue: 0.0, // TODO: Implement event revenue
        commissionRevenue: artworkRevenue * 0.1, // 10% commission
        averageRevenuePerUser: averageRevenuePerUser,
        monthlyRecurringRevenue: monthlyRecurringRevenue,
        churnRate: 0.05, // TODO: Calculate actual churn rate
        lifetimeValue: averageRevenuePerUser * 12, // Rough estimate
        totalTransactions: totalTransactions,
        revenueGrowth: revenueGrowth,
        subscriptionGrowth: 0.0, // TODO: Calculate subscription growth
        commissionGrowth: 0.0, // TODO: Calculate commission growth
        revenueByCategory: revenueByCategory,
        revenueTimeSeries: revenueTimeSeries,
      );
    } catch (e) {
      debugPrint('Error calculating financial metrics: $e');
      return FinancialMetrics(
        totalRevenue: 0,
        subscriptionRevenue: 0,
        eventRevenue: 0,
        commissionRevenue: 0,
        averageRevenuePerUser: 0,
        monthlyRecurringRevenue: 0,
        churnRate: 0,
        lifetimeValue: 0,
        totalTransactions: 0,
        revenueGrowth: 0,
        subscriptionGrowth: 0,
        commissionGrowth: 0,
        revenueByCategory: {},
        revenueTimeSeries: [],
      );
    }
  }

  /// Get revenue breakdown by category
  Future<Map<String, double>> getRevenueBreakdown({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final metrics =
        await getFinancialMetrics(startDate: startDate, endDate: endDate);
    final total = metrics.totalRevenue;

    if (total == 0) {
      return {
        'Advertisements': 0,
        'Subscriptions': 0,
        'Artwork Sales': 0,
      };
    }

    return {
      'Advertisements':
          (metrics.revenueByCategory['advertisements'] ?? 0) / total * 100,
      'Subscriptions':
          (metrics.revenueByCategory['subscriptions'] ?? 0) / total * 100,
      'Artwork Sales':
          (metrics.revenueByCategory['artwork'] ?? 0) / total * 100,
    };
  }

  /// Get user name from user ID
  Future<String> _getUserName(String userId) async {
    if (userId.isEmpty) return 'Unknown User';

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['fullName'] as String? ??
            data['displayName'] as String? ??
            data['username'] as String? ??
            'Unknown User';
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }

    return 'Unknown User';
  }

  /// Get previous period revenue for growth calculation
  Future<double> _getPreviousPeriodRevenue(DateTime start, DateTime end) async {
    try {
      final adPaymentsQuery = await _firestore
          .collection('payment_history')
          .where('transactionDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('transactionDate',
              isLessThanOrEqualTo: Timestamp.fromDate(end))
          .where('status', isEqualTo: 'completed')
          .get();

      double totalRevenue = 0;
      for (final doc in adPaymentsQuery.docs) {
        final data = doc.data();
        final amount = ((data['amount'] as num?) ?? 0).toDouble();
        totalRevenue += amount;
      }

      return totalRevenue;
    } catch (e) {
      debugPrint('Error calculating previous period revenue: $e');
      return 0.0;
    }
  }

  /// Get top spending users
  Future<List<Map<String, dynamic>>> getTopSpendingUsers(
      {int limit = 5}) async {
    try {
      final userSpending = <String, double>{};
      final userNames = <String, String>{};

      // Get all completed payments
      final paymentsQuery = await _firestore
          .collection('payment_history')
          .where('status', isEqualTo: 'completed')
          .get();

      for (final doc in paymentsQuery.docs) {
        final data = doc.data();
        final userId = data['userId'] as String? ?? '';
        final amount = ((data['amount'] as num?) ?? 0).toDouble();

        if (userId.isNotEmpty) {
          userSpending[userId] = (userSpending[userId] ?? 0) + amount;
          if (!userNames.containsKey(userId)) {
            userNames[userId] = await _getUserName(userId);
          }
        }
      }

      // Sort and return top users
      final sortedUsers = userSpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedUsers
          .take(limit)
          .map((entry) => {
                'userId': entry.key,
                'userName': userNames[entry.key] ?? 'Unknown User',
                'totalSpent': entry.value,
                'formattedAmount': '\$${entry.value.toStringAsFixed(2)}',
              })
          .toList();
    } catch (e) {
      debugPrint('Error fetching top spending users: $e');
      return [];
    }
  }
}

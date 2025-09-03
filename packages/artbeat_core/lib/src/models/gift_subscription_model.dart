import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionFrequency { monthly, weekly, biweekly }

enum SubscriptionStatus { active, paused, cancelled, expired }

class GiftSubscriptionModel {
  final String id;
  final String senderId;
  final String recipientId;
  final double amount;
  final SubscriptionFrequency frequency;
  final SubscriptionStatus status;
  final Timestamp createdAt;
  final Timestamp? nextPaymentDate;
  final Timestamp? lastPaymentDate;
  final Timestamp? pausedAt;
  final Timestamp? cancelledAt;
  final String? stripeSubscriptionId;
  final String? message;
  final int totalPayments;
  final double totalAmount;
  final Map<String, dynamic> metadata;

  GiftSubscriptionModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.amount,
    this.frequency = SubscriptionFrequency.monthly,
    this.status = SubscriptionStatus.active,
    required this.createdAt,
    this.nextPaymentDate,
    this.lastPaymentDate,
    this.pausedAt,
    this.cancelledAt,
    this.stripeSubscriptionId,
    this.message,
    this.totalPayments = 0,
    this.totalAmount = 0.0,
    this.metadata = const {},
  });

  factory GiftSubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GiftSubscriptionModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      recipientId: data['recipientId'] as String? ?? '',
      amount: (data['amount'] as num? ?? 0).toDouble(),
      frequency: _parseFrequency(data['frequency'] as String?),
      status: _parseStatus(data['status'] as String?),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      nextPaymentDate: data['nextPaymentDate'] as Timestamp?,
      lastPaymentDate: data['lastPaymentDate'] as Timestamp?,
      pausedAt: data['pausedAt'] as Timestamp?,
      cancelledAt: data['cancelledAt'] as Timestamp?,
      stripeSubscriptionId: data['stripeSubscriptionId'] as String?,
      message: data['message'] as String?,
      totalPayments: data['totalPayments'] as int? ?? 0,
      totalAmount: (data['totalAmount'] as num? ?? 0).toDouble(),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'amount': amount,
      'frequency': frequency.name,
      'status': status.name,
      'createdAt': createdAt,
      if (nextPaymentDate != null) 'nextPaymentDate': nextPaymentDate,
      if (lastPaymentDate != null) 'lastPaymentDate': lastPaymentDate,
      if (pausedAt != null) 'pausedAt': pausedAt,
      if (cancelledAt != null) 'cancelledAt': cancelledAt,
      if (stripeSubscriptionId != null)
        'stripeSubscriptionId': stripeSubscriptionId,
      if (message != null) 'message': message,
      'totalPayments': totalPayments,
      'totalAmount': totalAmount,
      'metadata': metadata,
    };
  }

  static SubscriptionFrequency _parseFrequency(String? frequencyString) {
    switch (frequencyString) {
      case 'weekly':
        return SubscriptionFrequency.weekly;
      case 'biweekly':
        return SubscriptionFrequency.biweekly;
      default:
        return SubscriptionFrequency.monthly;
    }
  }

  static SubscriptionStatus _parseStatus(String? statusString) {
    switch (statusString) {
      case 'paused':
        return SubscriptionStatus.paused;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'expired':
        return SubscriptionStatus.expired;
      default:
        return SubscriptionStatus.active;
    }
  }

  // Helper methods
  bool get isActive => status == SubscriptionStatus.active;
  bool get isPaused => status == SubscriptionStatus.paused;
  bool get isCancelled => status == SubscriptionStatus.cancelled;
  bool get isExpired => status == SubscriptionStatus.expired;

  String get frequencyDisplayName {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return 'Weekly';
      case SubscriptionFrequency.biweekly:
        return 'Bi-weekly';
      case SubscriptionFrequency.monthly:
        return 'Monthly';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.paused:
        return 'Paused';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.expired:
        return 'Expired';
    }
  }

  Duration get frequencyDuration {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return const Duration(days: 7);
      case SubscriptionFrequency.biweekly:
        return const Duration(days: 14);
      case SubscriptionFrequency.monthly:
        return const Duration(days: 30);
    }
  }

  DateTime? get nextPaymentDateTime => nextPaymentDate?.toDate();
  DateTime? get lastPaymentDateTime => lastPaymentDate?.toDate();

  double get averageMonthlyAmount {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return amount * 4.33; // Average weeks per month
      case SubscriptionFrequency.biweekly:
        return amount * 2.17; // Average bi-weeks per month
      case SubscriptionFrequency.monthly:
        return amount;
    }
  }

  GiftSubscriptionModel copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    double? amount,
    SubscriptionFrequency? frequency,
    SubscriptionStatus? status,
    Timestamp? createdAt,
    Timestamp? nextPaymentDate,
    Timestamp? lastPaymentDate,
    Timestamp? pausedAt,
    Timestamp? cancelledAt,
    String? stripeSubscriptionId,
    String? message,
    int? totalPayments,
    double? totalAmount,
    Map<String, dynamic>? metadata,
  }) {
    return GiftSubscriptionModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      pausedAt: pausedAt ?? this.pausedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      message: message ?? this.message,
      totalPayments: totalPayments ?? this.totalPayments,
      totalAmount: totalAmount ?? this.totalAmount,
      metadata: metadata ?? this.metadata,
    );
  }
}

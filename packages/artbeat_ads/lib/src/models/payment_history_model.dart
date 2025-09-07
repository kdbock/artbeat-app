import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a payment transaction record for ad purchases
///
/// Tracks all payment-related information including transaction details,
/// payment method, status, and metadata for financial reporting and
/// user payment history.
class PaymentHistoryModel {
  final String id;
  final String userId;
  final String adId;
  final String adTitle;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final DateTime transactionDate;
  final String? stripePaymentIntentId;
  final String? receiptUrl;
  final Map<String, dynamic> metadata;
  final String? failureReason;
  final DateTime? refundedAt;
  final double? refundAmount;
  final String? refundReason;

  PaymentHistoryModel({
    required this.id,
    required this.userId,
    required this.adId,
    required this.adTitle,
    required this.amount,
    this.currency = 'USD',
    required this.paymentMethod,
    required this.status,
    required this.transactionDate,
    this.stripePaymentIntentId,
    this.receiptUrl,
    this.metadata = const {},
    this.failureReason,
    this.refundedAt,
    this.refundAmount,
    this.refundReason,
  });

  /// Create from Firestore document
  factory PaymentHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PaymentHistoryModel(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      adId: (data['adId'] as String?) ?? '',
      adTitle: (data['adTitle'] as String?) ?? '',
      amount: ((data['amount'] as num?) ?? 0).toDouble(),
      currency: (data['currency'] as String?) ?? 'USD',
      paymentMethod: PaymentMethod.fromString(
        (data['paymentMethod'] as String?) ?? 'card',
      ),
      status: PaymentStatus.fromString(
        (data['status'] as String?) ?? 'pending',
      ),
      transactionDate:
          (data['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stripePaymentIntentId: data['stripePaymentIntentId'] as String?,
      receiptUrl: data['receiptUrl'] as String?,
      metadata: Map<String, dynamic>.from((data['metadata'] as Map?) ?? {}),
      failureReason: data['failureReason'] as String?,
      refundedAt: (data['refundedAt'] as Timestamp?)?.toDate(),
      refundAmount: (data['refundAmount'] as num?)?.toDouble(),
      refundReason: data['refundReason'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'adId': adId,
      'adTitle': adTitle,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod.value,
      'status': status.value,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'stripePaymentIntentId': stripePaymentIntentId,
      'receiptUrl': receiptUrl,
      'metadata': metadata,
      'failureReason': failureReason,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
      'refundAmount': refundAmount,
      'refundReason': refundReason,
    };
  }

  /// Create copy with updated fields
  PaymentHistoryModel copyWith({
    String? id,
    String? userId,
    String? adId,
    String? adTitle,
    double? amount,
    String? currency,
    PaymentMethod? paymentMethod,
    PaymentStatus? status,
    DateTime? transactionDate,
    String? stripePaymentIntentId,
    String? receiptUrl,
    Map<String, dynamic>? metadata,
    String? failureReason,
    DateTime? refundedAt,
    double? refundAmount,
    String? refundReason,
  }) {
    return PaymentHistoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      adId: adId ?? this.adId,
      adTitle: adTitle ?? this.adTitle,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      transactionDate: transactionDate ?? this.transactionDate,
      stripePaymentIntentId:
          stripePaymentIntentId ?? this.stripePaymentIntentId,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      metadata: metadata ?? this.metadata,
      failureReason: failureReason ?? this.failureReason,
      refundedAt: refundedAt ?? this.refundedAt,
      refundAmount: refundAmount ?? this.refundAmount,
      refundReason: refundReason ?? this.refundReason,
    );
  }

  /// Check if payment was successful
  bool get isSuccessful => status == PaymentStatus.completed;

  /// Check if payment was refunded
  bool get isRefunded => status == PaymentStatus.refunded;

  /// Check if payment failed
  bool get hasFailed => status == PaymentStatus.failed;

  /// Get formatted amount with currency
  String get formattedAmount {
    final symbol = currency == 'USD' ? '\$' : currency;
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Get formatted refund amount
  String? get formattedRefundAmount {
    if (refundAmount == null) return null;
    final symbol = currency == 'USD' ? '\$' : currency;
    return '$symbol${refundAmount!.toStringAsFixed(2)}';
  }

  @override
  String toString() {
    return 'PaymentHistoryModel(id: $id, userId: $userId, amount: $amount, status: ${status.value})';
  }
}

/// Payment method enum
enum PaymentMethod {
  card,
  bankTransfer,
  applePay,
  googlePay,
  paypal;

  String get value => name;

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'card':
      case 'creditCard':
        return PaymentMethod.card;
      case 'bankTransfer':
        return PaymentMethod.bankTransfer;
      case 'applePay':
        return PaymentMethod.applePay;
      case 'googlePay':
        return PaymentMethod.googlePay;
      case 'paypal':
        return PaymentMethod.paypal;
      default:
        return PaymentMethod.card;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.card:
        return 'Credit Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.paypal:
        return 'PayPal';
    }
  }

  // Icon getter for test compatibility (returns a string for simplicity)
  String get icon {
    switch (this) {
      case PaymentMethod.card:
        return 'credit_card_icon';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer_icon';
      case PaymentMethod.applePay:
        return 'apple_pay_icon';
      case PaymentMethod.googlePay:
        return 'google_pay_icon';
      case PaymentMethod.paypal:
        return 'paypal_icon';
    }
  }
}

/// Payment status enum
enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded;

  String get value => name;

  static PaymentStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  /// Get color hex for status display
  String get colorHex {
    switch (this) {
      case PaymentStatus.pending:
        return '#FFA500'; // Orange
      case PaymentStatus.completed:
        return '#008000'; // Green
      case PaymentStatus.failed:
        return '#FF0000'; // Red
      case PaymentStatus.refunded:
        return '#0000FF'; // Blue
    }
  }

  /// Test-compatible isSuccessful getter
  bool get isSuccessful => this == PaymentStatus.completed;
}

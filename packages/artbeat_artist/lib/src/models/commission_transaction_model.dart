import 'package:cloud_firestore/cloud_firestore.dart';
import 'commission_model.dart'; // Import CommissionStatus from commission_model

/// Extension for CommissionStatus enum
extension CommissionStatusExtension on CommissionStatus {
  String get value {
    switch (this) {
      case CommissionStatus.pending:
        return 'pending';
      case CommissionStatus.active:
        return 'active';
      case CommissionStatus.completed:
        return 'completed';
      case CommissionStatus.paid:
        return 'paid';
      case CommissionStatus.cancelled:
        return 'cancelled';
    }
  }

  static CommissionStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return CommissionStatus.pending;
      case 'active':
        return CommissionStatus.active;
      case 'completed':
        return CommissionStatus.completed;
      case 'paid':
        return CommissionStatus.paid;
      case 'cancelled':
        return CommissionStatus.cancelled;
      default:
        return CommissionStatus.pending;
    }
  }
}

class CommissionTransactionModel {
  final String id;
  final String commissionId; // Links to the main CommissionModel
  final String artistId;
  final String galleryId;
  final double amount;
  final DateTime transactionDate;
  final CommissionStatus status; // e.g., pending, paid, refunded
  final String? paymentMethodId; // Optional: Stripe PaymentMethod ID or similar
  final String? externalTransactionId; // Optional: Stripe Charge ID or similar
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommissionTransactionModel({
    required this.id,
    required this.commissionId,
    required this.artistId,
    required this.galleryId,
    required this.amount,
    required this.transactionDate,
    required this.status,
    this.paymentMethodId,
    this.externalTransactionId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommissionTransactionModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    return CommissionTransactionModel(
      id: documentId,
      commissionId: map['commissionId'] as String? ?? '',
      artistId: map['artistId'] as String? ?? '',
      galleryId: map['galleryId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      transactionDate:
          (map['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: CommissionStatusExtension.fromString(map['status'] as String?),
      paymentMethodId: map['paymentMethodId'] as String?,
      externalTransactionId: map['externalTransactionId'] as String?,
      notes: map['notes'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commissionId': commissionId,
      'artistId': artistId,
      'galleryId': galleryId,
      'amount': amount,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'status': status.value,
      'paymentMethodId': paymentMethodId,
      'externalTransactionId': externalTransactionId,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

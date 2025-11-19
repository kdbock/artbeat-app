import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing payout requests and bank account information
class PayoutModel {
  final String id;
  final String artistId;
  final double amount;
  final String status; // pending, processing, completed, failed
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String payoutMethod; // bank_account, paypal
  final String accountId; // Reference to connected account
  final String? failureReason;
  final String? transactionId;

  PayoutModel({
    required this.id,
    required this.artistId,
    required this.amount,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    required this.payoutMethod,
    required this.accountId,
    this.failureReason,
    this.transactionId,
  });

  factory PayoutModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PayoutModel(
      id: doc.id,
      artistId: data['artistId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'pending',
      requestedAt:
          (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      payoutMethod: data['payoutMethod'] as String? ?? 'bank_account',
      accountId: data['accountId'] as String? ?? '',
      failureReason: data['failureReason'] as String?,
      transactionId: data['transactionId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'artistId': artistId,
      'amount': amount,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
      if (processedAt != null) 'processedAt': Timestamp.fromDate(processedAt!),
      'payoutMethod': payoutMethod,
      'accountId': accountId,
      if (failureReason != null) 'failureReason': failureReason,
      if (transactionId != null) 'transactionId': transactionId,
    };
  }

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}

/// Model for connected bank accounts and payment methods
class PayoutAccountModel {
  final String id;
  final String artistId;
  final String accountType; // bank_account, paypal
  final String accountHolderName;
  final String? bankName;
  final String accountNumber;
  final String routingNumber;
  final String? paypalEmail;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  PayoutAccountModel({
    required this.id,
    required this.artistId,
    required this.accountType,
    required this.accountHolderName,
    this.bankName,
    required this.accountNumber,
    required this.routingNumber,
    this.paypalEmail,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    this.verifiedAt,
  });

  factory PayoutAccountModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PayoutAccountModel(
      id: doc.id,
      artistId: data['artistId'] as String? ?? '',
      accountType: data['accountType'] as String? ?? 'bank_account',
      accountHolderName: data['accountHolderName'] as String? ?? '',
      bankName: data['bankName'] as String?,
      accountNumber: data['accountNumber'] as String? ?? '',
      routingNumber: data['routingNumber'] as String? ?? '',
      paypalEmail: data['paypalEmail'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      isVerified: data['isVerified'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'artistId': artistId,
      'accountType': accountType,
      'accountHolderName': accountHolderName,
      if (bankName != null) 'bankName': bankName,
      'accountNumber': accountNumber,
      'routingNumber': routingNumber,
      if (paypalEmail != null) 'paypalEmail': paypalEmail,
      'isActive': isActive,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      if (verifiedAt != null) 'verifiedAt': Timestamp.fromDate(verifiedAt!),
    };
  }

  String get displayName {
    if (accountType == 'paypal') {
      return 'PayPal - ${paypalEmail ?? 'Unknown'}';
    } else {
      final lastDigits = accountNumber.length >= 4
          ? accountNumber.substring(accountNumber.length - 4)
          : accountNumber;
      return '${bankName ?? 'Bank'} - ****$lastDigits';
    }
  }
}

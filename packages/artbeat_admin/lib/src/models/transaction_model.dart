import 'package:cloud_firestore/cloud_firestore.dart';

/// Transaction model for admin financial reporting
class TransactionModel {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final String currency;
  final String
      type; // 'subscription', 'artwork_purchase', 'event_ticket', 'ad_payment', 'commission'
  final String status; // 'completed', 'pending', 'failed', 'refunded'
  final String paymentMethod;
  final DateTime transactionDate;
  final String? description;
  final String? itemId; // artwork ID, event ID, ad ID, etc.
  final String? itemTitle;
  final Map<String, dynamic> metadata;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    this.currency = 'USD',
    required this.type,
    required this.status,
    required this.paymentMethod,
    required this.transactionDate,
    this.description,
    this.itemId,
    this.itemTitle,
    this.metadata = const {},
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TransactionModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Unknown User',
      amount: ((data['amount'] as num?) ?? 0).toDouble(),
      currency: data['currency'] as String? ?? 'USD',
      type: data['type'] as String? ?? 'unknown',
      status: data['status'] as String? ?? 'pending',
      paymentMethod: data['paymentMethod'] as String? ?? 'card',
      transactionDate:
          (data['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] as String?,
      itemId: data['itemId'] as String?,
      itemTitle: data['itemTitle'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'currency': currency,
      'type': type,
      'status': status,
      'paymentMethod': paymentMethod,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'description': description,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'metadata': metadata,
    };
  }

  String get formattedAmount {
    final symbol = currency == 'USD' ? '\$' : currency;
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  String get displayType {
    switch (type.toLowerCase()) {
      case 'subscription':
        return 'Subscription';
      case 'artwork_purchase':
        return 'Artwork Purchase';
      case 'event_ticket':
        return 'Event Ticket';
      case 'ad_payment':
        return 'Advertisement';
      case 'commission':
        return 'Commission';
      default:
        return type.toUpperCase();
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(transactionDate);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  bool get isSuccessful => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isRefunded => status.toLowerCase() == 'refunded';
}

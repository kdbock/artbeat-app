import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of the commission
enum CommissionStatus {
  pending, // Agreement established but not yet finalized
  active, // Commission is active
  completed, // Artwork has sold, commission pending payment
  paid, // Commission has been paid
  cancelled, // Commission agreement was cancelled
}

/// Model representing a commission agreement between a gallery and an artist
class CommissionModel {
  final String id;
  final String galleryId; // Gallery profile ID
  final String galleryUserId; // User ID of the gallery owner
  final String artistId; // Artist profile ID
  final String artistUserId; // User ID of the artist
  final double commissionRate; // Commission percentage (e.g., 30.0 for 30%)
  final CommissionStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final DateTime? paidAt;
  final List<String>? artworkIds; // Artwork covered by this commission
  final Map<String, dynamic>? terms; // Additional terms of the agreement
  final List<CommissionTransaction>? transactions; // Transaction history

  CommissionModel({
    required this.id,
    required this.galleryId,
    required this.galleryUserId,
    required this.artistId,
    required this.artistUserId,
    required this.commissionRate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.paidAt,
    this.artworkIds,
    this.terms,
    this.transactions,
  });

  /// Convert Firestore document to CommissionModel
  factory CommissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert transactions if they exist
    List<CommissionTransaction>? transactions;
    if (data['transactions'] != null) {
      transactions = List<Map<String, dynamic>>.from(data['transactions'])
          .map(
              (transactionMap) => CommissionTransaction.fromMap(transactionMap))
          .toList();
    }

    return CommissionModel(
      id: doc.id,
      galleryId: data['galleryId'],
      galleryUserId: data['galleryUserId'],
      artistId: data['artistId'],
      artistUserId: data['artistUserId'],
      commissionRate: (data['commissionRate'] as num).toDouble(),
      status: _statusFromString(data['status']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      paidAt: data['paidAt'] != null
          ? (data['paidAt'] as Timestamp).toDate()
          : null,
      artworkIds: data['artworkIds'] != null
          ? List<String>.from(data['artworkIds'])
          : null,
      terms: data['terms'] as Map<String, dynamic>?,
      transactions: transactions,
    );
  }

  /// Convert CommissionModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'galleryId': galleryId,
      'galleryUserId': galleryUserId,
      'artistId': artistId,
      'artistUserId': artistUserId,
      'commissionRate': commissionRate,
      'status': _statusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt':
          updatedAt != null ? Timestamp.fromDate(updatedAt as DateTime) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt as DateTime)
          : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt as DateTime) : null,
      'artworkIds': artworkIds,
      'terms': terms,
      'transactions': transactions?.map((t) => t.toMap()).toList(),
    };
  }

  /// Create a copy of the CommissionModel with updated fields
  CommissionModel copyWith({
    String? id,
    String? galleryId,
    String? galleryUserId,
    String? artistId,
    String? artistUserId,
    double? commissionRate,
    CommissionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? paidAt,
    List<String>? artworkIds,
    Map<String, dynamic>? terms,
    List<CommissionTransaction>? transactions,
  }) {
    return CommissionModel(
      id: id ?? this.id,
      galleryId: galleryId ?? this.galleryId,
      galleryUserId: galleryUserId ?? this.galleryUserId,
      artistId: artistId ?? this.artistId,
      artistUserId: artistUserId ?? this.artistUserId,
      commissionRate: commissionRate ?? this.commissionRate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      paidAt: paidAt ?? this.paidAt,
      artworkIds: artworkIds ?? this.artworkIds,
      terms: terms ?? this.terms,
      transactions: transactions ?? this.transactions,
    );
  }

  /// Helper to convert status string to enum
  static CommissionStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
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

  /// Helper to convert status enum to string
  static String _statusToString(CommissionStatus status) {
    switch (status) {
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
}

/// Model representing an individual commission transaction
class CommissionTransaction {
  final String? id;
  final String artworkId;
  final String artworkTitle;
  final double saleAmount;
  final double commissionAmount;
  final DateTime transactionDate;
  final String? paymentMethod;
  final String status; // 'pending', 'paid', 'failed'
  final String? receiptId;

  CommissionTransaction({
    this.id,
    required this.artworkId,
    required this.artworkTitle,
    required this.saleAmount,
    required this.commissionAmount,
    required this.transactionDate,
    this.paymentMethod,
    required this.status,
    this.receiptId,
  });

  /// Convert Map to CommissionTransaction
  factory CommissionTransaction.fromMap(Map<String, dynamic> map) {
    return CommissionTransaction(
      id: map['id'],
      artworkId: map['artworkId'],
      artworkTitle: map['artworkTitle'],
      saleAmount: (map['saleAmount'] as num).toDouble(),
      commissionAmount: (map['commissionAmount'] as num).toDouble(),
      transactionDate: (map['transactionDate'] as Timestamp).toDate(),
      paymentMethod: map['paymentMethod'],
      status: map['status'],
      receiptId: map['receiptId'],
    );
  }

  /// Convert CommissionTransaction to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'artworkId': artworkId,
      'artworkTitle': artworkTitle,
      'saleAmount': saleAmount,
      'commissionAmount': commissionAmount,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'paymentMethod': paymentMethod,
      'status': status,
      'receiptId': receiptId,
    };
  }

  /// Create a copy with new values
  CommissionTransaction copyWith({
    String? id,
    String? artworkId,
    String? artworkTitle,
    double? saleAmount,
    double? commissionAmount,
    DateTime? transactionDate,
    String? paymentMethod,
    String? status,
    String? receiptId,
  }) {
    return CommissionTransaction(
      id: id ?? this.id,
      artworkId: artworkId ?? this.artworkId,
      artworkTitle: artworkTitle ?? this.artworkTitle,
      saleAmount: saleAmount ?? this.saleAmount,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      transactionDate: transactionDate ?? this.transactionDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      receiptId: receiptId ?? this.receiptId,
    );
  }
}

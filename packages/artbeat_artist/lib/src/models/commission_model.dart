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
      transactions = (data['transactions'] as List<dynamic>?)
          ?.map((transactionMap) => CommissionTransaction.fromMap(
              transactionMap as Map<String, dynamic>))
          .toList();
    }

    return CommissionModel(
      id: doc.id,
      galleryId: data['galleryId'] != null ? data['galleryId'].toString() : '',
      galleryUserId:
          data['galleryUserId'] != null ? data['galleryUserId'].toString() : '',
      artistId: data['artistId'] != null ? data['artistId'].toString() : '',
      artistUserId:
          data['artistUserId'] != null ? data['artistUserId'].toString() : '',
      commissionRate: data['commissionRate'] is num
          ? (data['commissionRate'] as num).toDouble()
          : 0.0,
      status: _statusFromString(
          data['status'] != null ? data['status'].toString() : 'pending'),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] is Timestamp
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      paidAt: data['paidAt'] is Timestamp
          ? (data['paidAt'] as Timestamp).toDate()
          : null,
      artworkIds: data['artworkIds'] is List
          ? (data['artworkIds'] as List).map((e) => e.toString()).toList()
          : null,
      terms: data['terms'] is Map
          ? Map<String, dynamic>.from(data['terms'] as Map)
          : null,
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
    return switch (status) {
      CommissionStatus.pending => 'pending',
      CommissionStatus.active => 'active',
      CommissionStatus.completed => 'completed',
      CommissionStatus.paid => 'paid',
      CommissionStatus.cancelled => 'cancelled',
    };
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
      id: map['id'] != null ? map['id'].toString() : '',
      artworkId: map['artworkId'] != null ? map['artworkId'].toString() : '',
      artworkTitle:
          map['artworkTitle'] != null ? map['artworkTitle'].toString() : '',
      saleAmount: map['saleAmount'] is num
          ? (map['saleAmount'] as num).toDouble()
          : 0.0,
      commissionAmount: map['commissionAmount'] is num
          ? (map['commissionAmount'] as num).toDouble()
          : 0.0,
      transactionDate: map['transactionDate'] is Timestamp
          ? (map['transactionDate'] as Timestamp).toDate()
          : DateTime.now(),
      paymentMethod:
          map['paymentMethod'] != null ? map['paymentMethod'].toString() : null,
      status: map['status'] != null ? map['status'].toString() : '',
      receiptId: map['receiptId'] != null ? map['receiptId'].toString() : null,
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

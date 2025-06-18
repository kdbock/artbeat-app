import 'package:cloud_firestore/cloud_firestore.dart';

class GiftModel {
  final String id;
  final String senderId;
  final String recipientId;
  final String giftType; // Mini Palette, Brush Pack, etc.
  final double amount;
  final Timestamp createdAt;

  GiftModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.giftType,
    required this.amount,
    required this.createdAt,
  });

  factory GiftModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GiftModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      recipientId: data['recipientId'] as String? ?? '',
      giftType: data['giftType'] as String? ?? '',
      amount: (data['amount'] as num? ?? 0).toDouble(),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'giftType': giftType,
      'amount': amount,
      'createdAt': createdAt,
    };
  }
}

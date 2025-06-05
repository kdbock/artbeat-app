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
      senderId: data['senderId'] ?? '',
      recipientId: data['recipientId'] ?? '',
      giftType: data['giftType'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
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

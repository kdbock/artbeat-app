import 'package:cloud_firestore/cloud_firestore.dart';

enum GiftType {
  preset, // Preset gifts ($4.99, $9.99, $24.99, $49.99)
  custom, // Custom amount gifts
  campaign, // Campaign-related gifts
  subscription, // Recurring gift subscriptions
}

class GiftModel {
  final String id;
  final String senderId;
  final String recipientId;
  final String
  giftType; // Small Gift, Medium Gift, Large Gift, Premium Gift, or Custom
  final double amount;
  final Timestamp createdAt;
  final GiftType type;
  final String? message;
  final String? campaignId; // For campaign gifts
  final String? subscriptionId; // For subscription gifts
  final bool isRecurring;
  final String? paymentIntentId;
  final String status; // pending, completed, failed, refunded

  GiftModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.giftType,
    required this.amount,
    required this.createdAt,
    this.type = GiftType.preset,
    this.message,
    this.campaignId,
    this.subscriptionId,
    this.isRecurring = false,
    this.paymentIntentId,
    this.status = 'completed',
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
      type: _parseGiftType(data['type'] as String?),
      message: data['message'] as String?,
      campaignId: data['campaignId'] as String?,
      subscriptionId: data['subscriptionId'] as String?,
      isRecurring: data['isRecurring'] as bool? ?? false,
      paymentIntentId: data['paymentIntentId'] as String?,
      status: data['status'] as String? ?? 'completed',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'giftType': giftType,
      'amount': amount,
      'createdAt': createdAt,
      'type': type.name,
      if (message != null) 'message': message,
      if (campaignId != null) 'campaignId': campaignId,
      if (subscriptionId != null) 'subscriptionId': subscriptionId,
      'isRecurring': isRecurring,
      if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
      'status': status,
    };
  }

  static GiftType _parseGiftType(String? typeString) {
    switch (typeString) {
      case 'custom':
        return GiftType.custom;
      case 'campaign':
        return GiftType.campaign;
      case 'subscription':
        return GiftType.subscription;
      default:
        return GiftType.preset;
    }
  }

  // Helper methods
  bool get isCustomAmount => type == GiftType.custom;
  bool get isCampaignGift => type == GiftType.campaign && campaignId != null;
  bool get isSubscriptionGift =>
      type == GiftType.subscription && subscriptionId != null;
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  GiftModel copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? giftType,
    double? amount,
    Timestamp? createdAt,
    GiftType? type,
    String? message,
    String? campaignId,
    String? subscriptionId,
    bool? isRecurring,
    String? paymentIntentId,
    String? status,
  }) {
    return GiftModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      giftType: giftType ?? this.giftType,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      message: message ?? this.message,
      campaignId: campaignId ?? this.campaignId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      isRecurring: isRecurring ?? this.isRecurring,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      status: status ?? this.status,
    );
  }
}

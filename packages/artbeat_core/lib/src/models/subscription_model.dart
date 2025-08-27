import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription_tier.dart';

/// Model for user subscriptions
class SubscriptionModel {
  final String id;
  final String userId;
  final SubscriptionTier tier;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String? stripePriceId;
  final bool autoRenew;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.tier,
    required this.startDate,
    this.endDate,
    required this.isActive,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.stripePriceId,
    required this.autoRenew,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a SubscriptionModel from a Firestore document
  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SubscriptionModel(
      id: doc.id,
      userId: data['userId'] as String,
      tier: _parseTier(data['tier']),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] as bool? ?? false,
      stripeCustomerId: data['stripeCustomerId'] as String?,
      stripeSubscriptionId: data['stripeSubscriptionId'] as String?,
      stripePriceId: data['stripePriceId'] as String?,
      autoRenew: data['autoRenew'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert SubscriptionModel to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'tier': tier.apiName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'stripeCustomerId': stripeCustomerId,
      'stripeSubscriptionId': stripeSubscriptionId,
      'stripePriceId': stripePriceId,
      'autoRenew': autoRenew,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Parse subscription tier from string
  static SubscriptionTier _parseTier(dynamic value) {
    if (value is String) {
      return SubscriptionTier.fromLegacyName(value);
    }
    return SubscriptionTier.starter;
  }

  /// Create a copy of this SubscriptionModel with given fields replaced
  SubscriptionModel copyWith({
    String? userId,
    SubscriptionTier? tier,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    String? stripePriceId,
    bool? autoRenew,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      id: id,
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      stripePriceId: stripePriceId ?? this.stripePriceId,
      autoRenew: autoRenew ?? this.autoRenew,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

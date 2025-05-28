import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing the subscription types available
enum SubscriptionTier {
  free, // Basic plan
  standard, // Pro plan
  premium, // Gallery plan
}

/// Enum representing the user types
enum UserType {
  regular, // Regular user
  artist, // Individual artist
  gallery, // Gallery business
}

/// Model class representing a subscription
class SubscriptionModel {
  final String id;
  final String userId;
  final SubscriptionTier tier;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool autoRenew;
  final String? paymentMethod;
  final String? stripeCustomerId;
  final String? stripePriceId;
  final String? stripeSubscriptionId;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.tier,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.autoRenew = false,
    this.paymentMethod,
    this.stripeCustomerId,
    this.stripePriceId,
    this.stripeSubscriptionId,
  });

  /// Convert Firestore document to SubscriptionModel
  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      id: doc.id,
      userId: data['userId'] as String,
      tier: _tierFromString(data['tier'] as String),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool,
      autoRenew: data['autoRenew'] as bool? ?? false,
      paymentMethod: data['paymentMethod'] as String?,
      stripeCustomerId: data['stripeCustomerId'] as String?,
      stripePriceId: data['stripePriceId'] as String?,
      stripeSubscriptionId: data['stripeSubscriptionId'] as String?,
    );
  }

  /// Convert SubscriptionModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'tier': _tierToString(tier),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'autoRenew': autoRenew,
      'paymentMethod': paymentMethod,
      'stripeCustomerId': stripeCustomerId,
      'stripePriceId': stripePriceId,
      'stripeSubscriptionId': stripeSubscriptionId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Helper to convert string tier to enum
  static SubscriptionTier _tierFromString(String tier) {
    switch (tier.toLowerCase()) {
      case 'free':
        return SubscriptionTier.free;
      case 'standard':
        return SubscriptionTier.standard;
      case 'premium':
        return SubscriptionTier.premium;
      default:
        return SubscriptionTier.free;
    }
  }

  /// Helper to convert enum tier to string
  static String _tierToString(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'free';
      case SubscriptionTier.standard:
        return 'standard';
      case SubscriptionTier.premium:
        return 'premium';
    }
  }

  /// Create a copy of the subscription model with updated fields
  SubscriptionModel copyWith({
    String? id,
    String? userId,
    SubscriptionTier? tier,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? autoRenew,
    String? paymentMethod,
    String? stripeCustomerId,
    String? stripePriceId,
    String? stripeSubscriptionId,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      autoRenew: autoRenew ?? this.autoRenew,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripePriceId: stripePriceId ?? this.stripePriceId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
    );
  }
}

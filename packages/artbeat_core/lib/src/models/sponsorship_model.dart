import 'package:cloud_firestore/cloud_firestore.dart';

/// Enhanced sponsorship model with tiered recurring payments
class SponsorshipModel {
  final String id;
  final String sponsorId;
  final String sponsorName;
  final String artistId;
  final String artistName;
  final SponsorshipTier tier;
  final double monthlyAmount;
  final SponsorshipStatus status;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final DateTime nextBillingDate;
  final String? stripeSubscriptionId;
  final List<SponsorshipBenefit> benefits;
  final Map<String, dynamic> metadata;

  SponsorshipModel({
    required this.id,
    required this.sponsorId,
    required this.sponsorName,
    required this.artistId,
    required this.artistName,
    required this.tier,
    required this.monthlyAmount,
    required this.status,
    required this.createdAt,
    this.cancelledAt,
    required this.nextBillingDate,
    this.stripeSubscriptionId,
    required this.benefits,
    required this.metadata,
  });

  factory SponsorshipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SponsorshipModel(
      id: doc.id,
      sponsorId: data['sponsorId'] as String? ?? '',
      sponsorName: data['sponsorName'] as String? ?? '',
      artistId: data['artistId'] as String? ?? '',
      artistName: data['artistName'] as String? ?? '',
      tier: SponsorshipTier.fromString(data['tier'] as String? ?? 'bronze'),
      monthlyAmount: (data['monthlyAmount'] as num?)?.toDouble() ?? 0.0,
      status: SponsorshipStatus.fromString(
        data['status'] as String? ?? 'active',
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      nextBillingDate:
          (data['nextBillingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stripeSubscriptionId: data['stripeSubscriptionId'] as String?,
      benefits:
          (data['benefits'] as List<dynamic>?)
              ?.map(
                (b) => SponsorshipBenefit.fromMap(b as Map<String, dynamic>),
              )
              .toList() ??
          [],
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sponsorId': sponsorId,
      'sponsorName': sponsorName,
      'artistId': artistId,
      'artistName': artistName,
      'tier': tier.name,
      'monthlyAmount': monthlyAmount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      if (cancelledAt != null) 'cancelledAt': Timestamp.fromDate(cancelledAt!),
      'nextBillingDate': Timestamp.fromDate(nextBillingDate),
      if (stripeSubscriptionId != null)
        'stripeSubscriptionId': stripeSubscriptionId,
      'benefits': benefits.map((b) => b.toMap()).toList(),
      'metadata': metadata,
    };
  }

  bool get isActive => status == SponsorshipStatus.active;
  bool get isCancelled => status == SponsorshipStatus.cancelled;
  bool get isPaused => status == SponsorshipStatus.paused;
}

/// Sponsorship tiers with different pricing and benefits
enum SponsorshipTier {
  bronze(5.0, 'Bronze', 'Basic supporter badge, monthly updates'),
  silver(15.0, 'Silver', 'Priority messaging, exclusive content access'),
  gold(50.0, 'Gold', 'Monthly video calls, commission discounts'),
  platinum(100.0, 'Platinum', 'Custom artwork, direct collaboration');

  const SponsorshipTier(this.monthlyPrice, this.displayName, this.description);

  final double monthlyPrice;
  final String displayName;
  final String description;

  static SponsorshipTier fromString(String value) {
    switch (value.toLowerCase()) {
      case 'bronze':
        return SponsorshipTier.bronze;
      case 'silver':
        return SponsorshipTier.silver;
      case 'gold':
        return SponsorshipTier.gold;
      case 'platinum':
        return SponsorshipTier.platinum;
      default:
        return SponsorshipTier.bronze;
    }
  }

  List<SponsorshipBenefit> get defaultBenefits {
    switch (this) {
      case SponsorshipTier.bronze:
        return [
          SponsorshipBenefit(
            id: 'supporter_badge',
            name: 'Supporter Badge',
            description: 'Special badge on your profile',
            isActive: true,
          ),
          SponsorshipBenefit(
            id: 'monthly_updates',
            name: 'Monthly Updates',
            description: 'Exclusive monthly progress updates',
            isActive: true,
          ),
        ];
      case SponsorshipTier.silver:
        return [
          ...bronze.defaultBenefits,
          SponsorshipBenefit(
            id: 'priority_messaging',
            name: 'Priority Messaging',
            description: 'Your messages get priority response',
            isActive: true,
          ),
          SponsorshipBenefit(
            id: 'exclusive_content',
            name: 'Exclusive Content',
            description: 'Access to sponsor-only content',
            isActive: true,
          ),
        ];
      case SponsorshipTier.gold:
        return [
          ...silver.defaultBenefits,
          SponsorshipBenefit(
            id: 'monthly_calls',
            name: 'Monthly Video Calls',
            description: '30-minute monthly video call',
            isActive: true,
          ),
          SponsorshipBenefit(
            id: 'commission_discount',
            name: 'Commission Discount',
            description: '15% discount on commissioned work',
            isActive: true,
          ),
        ];
      case SponsorshipTier.platinum:
        return [
          ...gold.defaultBenefits,
          SponsorshipBenefit(
            id: 'custom_artwork',
            name: 'Custom Artwork',
            description: 'Monthly custom artwork piece',
            isActive: true,
          ),
          SponsorshipBenefit(
            id: 'direct_collaboration',
            name: 'Direct Collaboration',
            description: 'Collaborate on artistic projects',
            isActive: true,
          ),
        ];
    }
  }
}

/// Sponsorship status
enum SponsorshipStatus {
  active('Active'),
  paused('Paused'),
  cancelled('Cancelled'),
  pending('Pending');

  const SponsorshipStatus(this.displayName);

  final String displayName;

  static SponsorshipStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return SponsorshipStatus.active;
      case 'paused':
        return SponsorshipStatus.paused;
      case 'cancelled':
        return SponsorshipStatus.cancelled;
      case 'pending':
        return SponsorshipStatus.pending;
      default:
        return SponsorshipStatus.pending;
    }
  }
}

/// Individual sponsorship benefit
class SponsorshipBenefit {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final Map<String, dynamic>? config;

  SponsorshipBenefit({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    this.config,
  });

  factory SponsorshipBenefit.fromMap(Map<String, dynamic> data) {
    return SponsorshipBenefit(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
      config: data['config'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
      if (config != null) 'config': config,
    };
  }
}

/// Sponsorship payment record
class SponsorshipPayment {
  final String id;
  final String sponsorshipId;
  final double amount;
  final DateTime paymentDate;
  final String status; // succeeded, failed, pending
  final String? stripePaymentIntentId;
  final String? failureReason;

  SponsorshipPayment({
    required this.id,
    required this.sponsorshipId,
    required this.amount,
    required this.paymentDate,
    required this.status,
    this.stripePaymentIntentId,
    this.failureReason,
  });

  factory SponsorshipPayment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SponsorshipPayment(
      id: doc.id,
      sponsorshipId: data['sponsorshipId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate:
          (data['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'pending',
      stripePaymentIntentId: data['stripePaymentIntentId'] as String?,
      failureReason: data['failureReason'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sponsorshipId': sponsorshipId,
      'amount': amount,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'status': status,
      if (stripePaymentIntentId != null)
        'stripePaymentIntentId': stripePaymentIntentId,
      if (failureReason != null) 'failureReason': failureReason,
    };
  }

  bool get isSucceeded => status == 'succeeded';
  bool get isFailed => status == 'failed';
  bool get isPending => status == 'pending';
}

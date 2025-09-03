import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of coupons available
enum CouponType {
  /// Full access to all features for free
  fullAccess('full_access'),

  /// Percentage discount on subscription
  percentageDiscount('percentage_discount'),

  /// Fixed amount discount on subscription
  fixedDiscount('fixed_discount'),

  /// Free trial period
  freeTrial('free_trial');

  const CouponType(this.value);
  final String value;

  static CouponType fromString(String value) {
    return CouponType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CouponType.fullAccess,
    );
  }
}

/// Status of a coupon
enum CouponStatus {
  /// Coupon is active and can be used
  active('active'),

  /// Coupon has been deactivated
  inactive('inactive'),

  /// Coupon has expired
  expired('expired'),

  /// Coupon usage limit has been reached
  exhausted('exhausted');

  const CouponStatus(this.value);
  final String value;

  static CouponStatus fromString(String value) {
    return CouponStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CouponStatus.active,
    );
  }
}

/// Model for promotional coupons that provide free or discounted access
class CouponModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final CouponType type;
  final CouponStatus status;
  final double? discountAmount;
  final int? discountPercentage;
  final int? maxUses;
  final int currentUses;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final List<String>? allowedSubscriptionTiers;
  final Map<String, dynamic>? metadata;

  const CouponModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    this.discountAmount,
    this.discountPercentage,
    this.maxUses,
    required this.currentUses,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.allowedSubscriptionTiers,
    this.metadata,
  });

  /// Create a CouponModel from a Firestore document
  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CouponModel(
      id: doc.id,
      code: data['code'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      type: CouponType.fromString(data['type'] as String),
      status: CouponStatus.fromString(data['status'] as String),
      discountAmount: data['discountAmount'] as double?,
      discountPercentage: data['discountPercentage'] as int?,
      maxUses: data['maxUses'] as int?,
      currentUses: data['currentUses'] as int? ?? 0,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String,
      allowedSubscriptionTiers: data['allowedSubscriptionTiers'] != null
          ? List<String>.from(data['allowedSubscriptionTiers'] as List)
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'title': title,
      'description': description,
      'type': type.value,
      'status': status.value,
      'discountAmount': discountAmount,
      'discountPercentage': discountPercentage,
      'maxUses': maxUses,
      'currentUses': currentUses,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'allowedSubscriptionTiers': allowedSubscriptionTiers,
      'metadata': metadata,
    };
  }

  /// Check if the coupon is valid for use
  bool get isValid {
    // Check status
    if (status != CouponStatus.active) return false;

    // Check expiration
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;

    // Check usage limit
    if (maxUses != null && currentUses >= maxUses!) return false;

    return true;
  }

  /// Check if coupon can be applied to a specific subscription tier
  bool canApplyToTier(String tierApiName) {
    if (allowedSubscriptionTiers == null || allowedSubscriptionTiers!.isEmpty) {
      return true; // No restrictions
    }
    return allowedSubscriptionTiers!.contains(tierApiName);
  }

  /// Calculate the discounted price for a given amount
  double calculateDiscountedPrice(double originalPrice) {
    switch (type) {
      case CouponType.fullAccess:
        return 0.0;
      case CouponType.percentageDiscount:
        if (discountPercentage == null) return originalPrice;
        return originalPrice * (1 - discountPercentage! / 100);
      case CouponType.fixedDiscount:
        if (discountAmount == null) return originalPrice;
        return (originalPrice - discountAmount!).clamp(0.0, double.infinity);
      case CouponType.freeTrial:
        // Free trial handled separately in subscription logic
        return originalPrice;
    }
  }

  /// Create a copy with updated fields
  CouponModel copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    CouponType? type,
    CouponStatus? status,
    double? discountAmount,
    int? discountPercentage,
    int? maxUses,
    int? currentUses,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<String>? allowedSubscriptionTiers,
    Map<String, dynamic>? metadata,
  }) {
    return CouponModel(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      maxUses: maxUses ?? this.maxUses,
      currentUses: currentUses ?? this.currentUses,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      allowedSubscriptionTiers:
          allowedSubscriptionTiers ?? this.allowedSubscriptionTiers,
      metadata: metadata ?? this.metadata,
    );
  }
}


/// A model representing a payment method with full Stripe compatibility
class PaymentMethodModel {
  final String id;
  final String type;
  final PaymentCardModel? card;
  final bool isDefault;
  final Map<String, dynamic>? billingDetails;

  PaymentMethodModel({
    required this.id,
    this.type = 'card',
    this.card,
    this.isDefault = false,
    this.billingDetails,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'],
      type: json['type'] ?? 'card',
      card:
          json['card'] != null ? PaymentCardModel.fromJson(json['card']) : null,
      isDefault: json['isDefault'] ?? false,
      billingDetails: json['billing_details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      if (card != null) 'card': card!.toJson(),
      'isDefault': isDefault,
      if (billingDetails != null) 'billing_details': billingDetails,
    };
  }

  /// Get a display name for the payment method
  String get displayName {
    if (type == 'card' && card != null) {
      final brandDisplay = card!.brand?.toUpperCase() ?? 'Card';
      return '$brandDisplay •••• ${card!.last4 ?? ''}';
    }
    return type;
  }

  /// Check if the payment method is expired
  bool get isExpired {
    if (card?.expMonth == null || card?.expYear == null) {
      return false;
    }

    final now = DateTime.now();
    final expiry = DateTime(card!.expYear!, card!.expMonth!);
    return now.isAfter(expiry);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentMethodModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  PaymentMethodModel copyWith({
    String? type,
    PaymentCardModel? card,
    bool? isDefault,
    Map<String, dynamic>? billingDetails,
  }) {
    return PaymentMethodModel(
      id: id,
      type: type ?? this.type,
      card: card ?? this.card,
      isDefault: isDefault ?? this.isDefault,
      billingDetails: billingDetails ?? this.billingDetails,
    );
  }
}

/// A model representing a payment card with full details
class PaymentCardModel {
  final String? brand;
  final int? expMonth;
  final int? expYear;
  final String? last4;
  final String? country;
  final String? funding;

  PaymentCardModel({
    this.brand,
    this.expMonth,
    this.expYear,
    this.last4,
    this.country,
    this.funding,
  });

  factory PaymentCardModel.fromJson(Map<String, dynamic> json) {
    return PaymentCardModel(
      brand: json['brand'],
      expMonth: json['exp_month'] is int
          ? json['exp_month']
          : int.tryParse(json['exp_month']?.toString() ?? ''),
      expYear: json['exp_year'] is int
          ? json['exp_year']
          : int.tryParse(json['exp_year']?.toString() ?? ''),
      last4: json['last4'],
      country: json['country'],
      funding: json['funding'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (brand != null) 'brand': brand,
      if (expMonth != null) 'exp_month': expMonth,
      if (expYear != null) 'exp_year': expYear,
      if (last4 != null) 'last4': last4,
      if (country != null) 'country': country,
      if (funding != null) 'funding': funding,
    };
  }

  /// Get expiry date in MM/YY format
  String? get expiryDate {
    if (expMonth != null && expYear != null) {
      final month = expMonth.toString().padLeft(2, '0');
      final year = expYear.toString().substring(2);
      return '$month/$year';
    }
    return null;
  }

  @override
  String toString() {
    return '${brand ?? 'Card'} •••• ${last4 ?? ''}';
  }

  PaymentCardModel copyWith({
    String? brand,
    int? expMonth,
    int? expYear,
    String? last4,
    String? country,
    String? funding,
  }) {
    return PaymentCardModel(
      brand: brand ?? this.brand,
      expMonth: expMonth ?? this.expMonth,
      expYear: expYear ?? this.expYear,
      last4: last4 ?? this.last4,
      country: country ?? this.country,
      funding: funding ?? this.funding,
    );
  }
}

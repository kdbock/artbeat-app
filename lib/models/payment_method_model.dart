/// A simplified representation of a payment method
class PaymentMethodModel {
  final String id;
  final PaymentCardModel? card;

  PaymentMethodModel({
    required this.id,
    this.card,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'],
      card:
          json['card'] != null ? PaymentCardModel.fromJson(json['card']) : null,
    );
  }
}

/// A simplified representation of a payment card
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
      expMonth: json['exp_month'],
      expYear: json['exp_year'],
      last4: json['last4'],
      country: json['country'],
      funding: json['funding'],
    );
  }
}

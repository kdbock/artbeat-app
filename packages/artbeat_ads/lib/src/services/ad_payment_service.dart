import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling ad payments (stub, extend for Stripe integration)
class AdPaymentService {
  final _paymentsRef = FirebaseFirestore.instance.collection('ad_payments');

  Future<String> recordPayment({
    required String adId,
    required String payerId,
    required double amount,
    required DateTime paidAt,
    String? paymentMethodId,
  }) async {
    final doc = await _paymentsRef.add({
      'adId': adId,
      'payerId': payerId,
      'amount': amount,
      'paidAt': Timestamp.fromDate(paidAt),
      'paymentMethodId': paymentMethodId,
    });
    return doc.id;
  }

  Stream<List<Map<String, dynamic>>> getPaymentsForAd(String adId) {
    return _paymentsRef
        .where('adId', isEqualTo: adId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}

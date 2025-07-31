import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class GiftController extends ChangeNotifier {
  final PaymentService _paymentService;

  GiftController(this._paymentService);

  List<GiftModel> _sentGifts = [];
  List<GiftModel> get sentGifts => _sentGifts;

  Future<void> sendGift(
    GiftModel gift, {
    String? paymentMethodId,
    String? message,
  }) async {
    try {
      // Get payment method ID if not provided
      final paymentMethod =
          paymentMethodId ?? await _paymentService.getDefaultPaymentMethodId();
      if (paymentMethod == null) {
        throw Exception(
          'No payment method available. Please set up a payment method in your profile first.',
        );
      }

      await _paymentService.processGiftPayment(
        gift,
        paymentMethodId: paymentMethod,
        message: message,
      );
      _sentGifts.add(gift);
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending gift: $e');
      rethrow;
    }
  }

  Future<List<GiftModel>> fetchSentGifts() async {
    try {
      _sentGifts = await _paymentService.getSentGifts();
      notifyListeners();
      return _sentGifts;
    } catch (e) {
      debugPrint('Error fetching sent gifts: $e');
      return [];
    }
  }

  void handleGift(GiftModel gift) {
    // Updated to use unified GiftModel
  }
}

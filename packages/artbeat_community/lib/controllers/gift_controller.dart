import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

// Re-export GiftModel from core
import '../models/gift_model_export.dart';

class GiftController extends ChangeNotifier {
  final PaymentService _paymentService;

  GiftController(this._paymentService);

  List<GiftModel> _sentGifts = [];
  List<GiftModel> get sentGifts => _sentGifts;

  Future<void> sendGift(GiftModel gift) async {
    try {
      await _paymentService.processGiftPayment(gift);
      _sentGifts.add(gift);
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending gift: $e');
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

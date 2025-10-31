import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class GiftController extends ChangeNotifier {
  final PaymentService _paymentService;
  final EnhancedGiftService _enhancedGiftService;

  GiftController(this._paymentService)
    : _enhancedGiftService = EnhancedGiftService();

  List<GiftModel> _sentGifts = [];
  List<GiftModel> get sentGifts => _sentGifts;

  // Enhanced gift analytics
  Map<String, dynamic>? _giftAnalytics;
  Map<String, dynamic>? get giftAnalytics => _giftAnalytics;

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
      AppLogger.error('Error sending gift: $e');
      rethrow;
    }
  }

  Future<void> sendPresetGift({
    required String recipientId,
    required String giftType,
    String? message,
    String? campaignId,
  }) async {
    try {
      final paymentMethodId = await _paymentService.getDefaultPaymentMethodId();
      if (paymentMethodId == null) {
        throw Exception(
          'No payment method available. Please set up a payment method in your profile first.',
        );
      }

      await _enhancedGiftService.sendPresetGift(
        recipientId: recipientId,
        giftType: giftType,
        paymentMethodId: paymentMethodId,
        message: message,
        campaignId: campaignId,
      );

      // Refresh sent gifts
      await fetchSentGifts();
    } catch (e) {
      AppLogger.error('Error sending preset gift: $e');
      rethrow;
    }
  }

  Future<String> createGiftSubscription({
    required String recipientId,
    required double amount,
    required SubscriptionFrequency frequency,
    String? message,
  }) async {
    try {
      final paymentMethodId = await _paymentService.getDefaultPaymentMethodId();
      if (paymentMethodId == null) {
        throw Exception(
          'No payment method available. Please set up a payment method in your profile first.',
        );
      }

      final subscriptionId = await _enhancedGiftService.createGiftSubscription(
        recipientId: recipientId,
        amount: amount,
        frequency: frequency,
        message: message,
        paymentMethodId: paymentMethodId,
      );

      notifyListeners();
      return subscriptionId;
    } catch (e) {
      AppLogger.error('Error creating gift subscription: $e');
      rethrow;
    }
  }

  Future<List<GiftModel>> fetchSentGifts() async {
    try {
      _sentGifts = await _paymentService.getSentGifts();
      notifyListeners();
      return _sentGifts;
    } catch (e) {
      AppLogger.error('Error fetching sent gifts: $e');
      return [];
    }
  }

  Future<void> loadGiftAnalytics(String userId) async {
    try {
      _giftAnalytics = await _enhancedGiftService.getGiftAnalytics(userId);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading gift analytics: $e');
    }
  }

  // Get preset gift types for backward compatibility
  Map<String, double> getPresetGiftTypes() {
    return _enhancedGiftService.getPresetGiftTypes();
  }

  // Get custom gift amount suggestions
  List<double> getCustomGiftSuggestions() {
    return [5.0, 10.0, 15.0, 25.0, 50.0];
  }

  void handleGift(GiftModel gift) {
    // Updated to use unified GiftModel
  }
}

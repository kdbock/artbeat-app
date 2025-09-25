import 'package:flutter/material.dart';
import '../services/enhanced_payment_service_working.dart';
import '../models/subscription_tier.dart';

// ignore_for_file: avoid_print

/// Example usage of the Enhanced Payment Service
/// This demonstrates how to integrate the new payment features
class PaymentServiceExample {
  final EnhancedPaymentService _paymentService = EnhancedPaymentService();

  /// Example: Process a standard payment with risk assessment
  Future<void> processStandardPayment({
    required String clientSecret,
    required double amount,
    required String currency,
  }) async {
    try {
      final result = await _paymentService.processPaymentWithRiskAssessment(
        paymentIntentClientSecret: clientSecret,
        amount: amount,
        currency: currency,
        metadata: {
          'payment_type': 'artwork_purchase',
          'item_id': 'artwork_123',
        },
      );

      if (result.success) {
        print('✅ Payment successful!');
        print('Risk Score: ${result.riskAssessment?.riskScore}');
        print('Risk Factors: ${result.riskAssessment?.factors}');
      } else {
        print('❌ Payment failed: ${result.error}');
      }
    } catch (e) {
      print('❌ Error processing payment: $e');
    }
  }

  /// Example: Process digital wallet payment
  Future<void> processWalletPayment({
    required String walletType,
    required double amount,
    required String currency,
  }) async {
    try {
      final result = await _paymentService.processDigitalWalletPayment(
        walletType: walletType, // 'apple_pay', 'google_pay', 'paypal'
        amount: amount,
        currency: currency,
        metadata: {'wallet_payment': true, 'device_verified': true},
      );

      if (result.success) {
        print('✅ $walletType payment successful!');
      } else {
        print('❌ $walletType payment failed: ${result.error}');
      }
    } catch (e) {
      print('❌ Error processing wallet payment: $e');
    }
  }

  /// Example: Process one-click payment
  Future<void> processOneClickPayment({
    required String paymentMethodId,
    required double amount,
    required String currency,
  }) async {
    try {
      final result = await _paymentService.processOneClickPayment(
        paymentMethodId: paymentMethodId,
        amount: amount,
        currency: currency,
        metadata: {'one_click': true, 'saved_payment_method': true},
      );

      if (result.success) {
        print('✅ One-click payment successful!');
      } else {
        print('❌ One-click payment failed: ${result.error}');
      }
    } catch (e) {
      print('❌ Error processing one-click payment: $e');
    }
  }

  /// Example: Get payment methods with risk assessment
  Future<void> getPaymentMethodsWithRisk() async {
    try {
      final methods = await _paymentService.getPaymentMethodsWithRisk();

      for (final method in methods) {
        print('Payment Method: ${method.displayName}');
        print('Risk Score: ${method.riskScore}');
        print('Risk Factors: ${method.riskFactors}');
        print('Last Validated: ${method.lastValidated}');
        print('---');
      }
    } catch (e) {
      print('❌ Error getting payment methods: $e');
    }
  }

  /// Example: Create enhanced subscription
  Future<void> createSubscription({
    required SubscriptionTier tier,
    required String paymentMethodId,
  }) async {
    try {
      final result = await _paymentService.createEnhancedSubscription(
        tier: tier,
        paymentMethodId: paymentMethodId,
        metadata: {'subscription_type': 'premium_artist', 'auto_renew': true},
      );

      if (result.success) {
        print('✅ Subscription created successfully!');
        print('Subscription ID: ${result.subscriptionId}');
        print('Risk Score: ${result.riskAssessment?.riskScore}');
      } else {
        print('❌ Subscription creation failed: ${result.error}');
      }
    } catch (e) {
      print('❌ Error creating subscription: $e');
    }
  }

  /// Example: Initialize Stripe in your app
  Future<void> initializeStripe() async {
    // This should be called in your main.dart or app initialization
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Stripe with your publishable key
    // Stripe.publishableKey = 'your_stripe_publishable_key_here'; // Replaced with in-app purchases

    // The EnhancedPaymentService will automatically initialize
    // device fingerprinting and other features
  }
}

/// Example integration in a Flutter widget
class PaymentExampleWidget extends StatefulWidget {
  const PaymentExampleWidget({super.key});

  @override
  State<PaymentExampleWidget> createState() => _PaymentExampleWidgetState();
}

class _PaymentExampleWidgetState extends State<PaymentExampleWidget> {
  final PaymentServiceExample _paymentExample = PaymentServiceExample();

  @override
  void initState() {
    super.initState();
    _initializeStripe();
  }

  Future<void> _initializeStripe() async {
    await _paymentExample.initializeStripe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enhanced Payment Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _processStandardPayment(),
              child: const Text('Process Standard Payment'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _processWalletPayment(),
              child: const Text('Process Apple Pay'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _getPaymentMethods(),
              child: const Text('Get Payment Methods'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processStandardPayment() async {
    // Example payment processing
    await _paymentExample.processStandardPayment(
      clientSecret: 'pi_test_client_secret_here',
      amount: 29.99,
      currency: 'usd',
    );
  }

  Future<void> _processWalletPayment() async {
    await _paymentExample.processWalletPayment(
      walletType: 'apple_pay',
      amount: 49.99,
      currency: 'usd',
    );
  }

  Future<void> _getPaymentMethods() async {
    await _paymentExample.getPaymentMethodsWithRisk();
  }
}

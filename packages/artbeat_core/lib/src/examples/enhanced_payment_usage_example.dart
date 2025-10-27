import 'package:flutter/material.dart';
import '../services/unified_payment_service.dart';
import '../models/subscription_tier.dart';

// ignore_for_file: avoid_print

/// Example usage of the Enhanced Payment Service
/// This demonstrates how to integrate the new payment features
class PaymentServiceExample {
  final UnifiedPaymentService _paymentService = UnifiedPaymentService();

  /// Example: Process a standard payment with risk assessment
  Future<void> processStandardPayment({
    required String clientSecret,
    required double amount,
    required String currency,
  }) async {
    try {
      final result = await _paymentService.processPaymentWithRiskAssessment(
        clientSecret: clientSecret,
        amount: amount,
        currency: currency,
        description: 'Artwork Purchase',
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
    required String walletId,
    required double amount,
    required String currency,
  }) async {
    try {
      final result = await _paymentService.processDigitalWalletPayment(
        walletId: walletId, // Wallet identifier
        amount: amount,
        currency: currency,
      );

      if (result.success) {
        print('✅ $walletId payment successful!');
      } else {
        print('❌ $walletId payment failed: ${result.error}');
      }
    } catch (e) {
      print('❌ Error processing wallet payment: $e');
    }
  }

  /// Example: Process one-click payment
  Future<void> processOneClickPayment({
    required String paymentMethodId,
    required double amount,
  }) async {
    try {
      final result = await _paymentService.processOneClickPayment(
        paymentMethodId: paymentMethodId,
        amount: amount,
        description: 'One-Click Payment',
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
  Future<void> getPaymentMethodsWithRisk(String customerId) async {
    try {
      final methods = await _paymentService.getPaymentMethodsWithRisk(
        customerId,
      );

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
    required String customerId,
    required SubscriptionTier tier,
    required String paymentMethodId,
  }) async {
    try {
      final result = await _paymentService.createEnhancedSubscription(
        customerId: customerId,
        tier: tier,
        paymentMethodId: paymentMethodId,
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
      walletId: 'wallet_apple_pay_123',
      amount: 49.99,
      currency: 'usd',
    );
  }

  Future<void> _getPaymentMethods() async {
    await _paymentExample.getPaymentMethodsWithRisk('customer_123');
  }
}

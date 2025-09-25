import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const PaymentTestApp());
}

class PaymentTestApp extends StatelessWidget {
  const PaymentTestApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(title: 'Payment Sheet Test', home: PaymentTestScreen());
}

class PaymentTestScreen extends StatefulWidget {
  const PaymentTestScreen({super.key});

  @override
  _PaymentTestScreenState createState() => _PaymentTestScreenState();
}

class _PaymentTestScreenState extends State<PaymentTestScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  String _result = '';

  Future<void> _testGiftPayment() async {
    setState(() {
      _isLoading = true;
      _result = 'Processing payment...';
    });

    try {
      final result = await _paymentService.processDirectGiftPayment(
        recipientId: 'test_recipient_id',
        amount: 5,
        giftType: 'tip',
        message: 'Test gift payment',
      );

      setState(() {
        _result = 'Success: ${result['message']}';
      });
    } on Exception catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Payment Sheet Test')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Test Direct Gift Payment',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _testGiftPayment,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text(r'Send $5 Gift'),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _result.isEmpty ? 'No result yet' : _result,
              style: TextStyle(
                color: _result.startsWith('Error') ? Colors.red : Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'This will open Stripe\'s payment sheet where you can enter card details.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

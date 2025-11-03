// ignore_for_file: implementation_imports, cascade_invocations

import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_core/src/services/in_app_gift_service.dart';
import 'package:artbeat_core/src/services/in_app_purchase_service.dart';
import 'package:flutter/material.dart';

/// Simple debug screen to test gift functionality
class DebugGiftTestScreen extends StatefulWidget {
  const DebugGiftTestScreen({super.key});

  @override
  State<DebugGiftTestScreen> createState() => _DebugGiftTestScreenState();
}

class _DebugGiftTestScreenState extends State<DebugGiftTestScreen> {
  final InAppGiftService _giftService = InAppGiftService();
  final InAppPurchaseService _purchaseService = InAppPurchaseService();
  String _status = 'Checking...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking gift system status...';
    });

    final buffer = StringBuffer();

    // Check in-app purchase availability
    buffer
      ..writeln('🛒 In-App Purchase Service:')
      ..writeln('   Available: ${_purchaseService.isAvailable}')
      // Check gift service availability
      ..writeln('\n🎁 Gift Service:')
      ..writeln('   Available: ${_giftService.isAvailable}')
      // Check available gift products
      ..writeln('\n📦 Available Gift Products:');
    final giftProducts = [
      'artbeat_gift_small',
      'artbeat_gift_medium',
      'artbeat_gift_large',
      'artbeat_gift_premium',
    ];
    for (final productId in giftProducts) {
      final details = _giftService.getGiftProductDetails(productId);
      if (details != null) {
        buffer.writeln(
          '   ✅ $productId: \$${details['amount']} - ${details['title']}',
        );
      } else {
        buffer.writeln('   ❌ $productId: Not found');
      }
    }

    // Check store products
    buffer.writeln('\n🏪 Store Products:');
    final storeProducts = _purchaseService.getGiftProducts();
    if (storeProducts.isEmpty) {
      buffer.writeln('   ❌ No products loaded from store');
    } else {
      for (final product in storeProducts) {
        buffer.writeln(
          '   ✅ ${product.id}: ${product.price} - ${product.title}',
        );
      }
    }

    setState(() {
      _status = buffer.toString();
      _isLoading = false;
    });
  }

  Future<void> _testGiftPurchase() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing gift purchase...';
    });

    try {
      // Test with a dummy recipient ID (use your own user ID for testing)
      const testRecipientId = 'test_recipient_id';
      const testGiftId = 'artbeat_gift_small';

      AppLogger.info('🧪 Testing gift purchase...');

      final success = await _giftService.purchaseGift(
        recipientId: testRecipientId,
        giftProductId: testGiftId,
        message: 'Test gift purchase',
      );

      setState(() {
        _status = success
            ? '✅ Gift purchase test successful!'
            : '❌ Gift purchase test failed - check logs for details';
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _status = '❌ Gift purchase test error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Gift Debug Test'),
      backgroundColor: Colors.amber,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gift System Debug',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkStatus,
                  child: const Text('Refresh Status'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _testGiftPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  child: const Text('Test Gift Purchase'),
                ),
              ),
            ],
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    ),
  );
}

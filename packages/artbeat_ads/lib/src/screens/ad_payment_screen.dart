import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ad_model.dart';
import '../models/ad_location.dart';
import '../models/ad_duration.dart';

/// Screen for handling ad payments
class AdPaymentScreen extends StatefulWidget {
  final AdModel ad;
  final AdLocation location;
  final AdDuration duration;

  const AdPaymentScreen({
    super.key,
    required this.ad,
    required this.location,
    required this.duration,
  });

  @override
  State<AdPaymentScreen> createState() => _AdPaymentScreenState();
}

class _AdPaymentScreenState extends State<AdPaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _pricingData;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  Future<void> _loadPricing() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pricing = await _paymentService.getAdPricing(
        adType: widget.ad.type.name,
        duration: widget.duration.days,
        location: widget.location.name,
      );

      setState(() {
        _pricingData = pricing;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load pricing: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // No bottom navigation for this screen
      appBar: const EnhancedUniversalHeader(title: 'Ad Payment'),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAdSummary(),
                  const SizedBox(height: 24),
                  _buildPricingBreakdown(),
                  const SizedBox(height: 24),
                  _buildPaymentSection(),
                  const SizedBox(height: 32),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _pricingData != null ? _handlePayment : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: Text(
                        _pricingData != null
                            ? 'Pay \$${_pricingData!['totalPrice'].toStringAsFixed(2)}'
                            : 'Loading...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAdSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ad Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Title', widget.ad.title),
            _buildSummaryRow('Type', _getAdTypeName(widget.ad.type)),
            _buildSummaryRow('Location', _getLocationName(widget.location)),
            _buildSummaryRow('Duration', '${widget.duration.days} days'),
            _buildSummaryRow('Start Date', _formatDate(widget.ad.startDate)),
            _buildSummaryRow('End Date', _formatDate(widget.ad.endDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingBreakdown() {
    if (_pricingData == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPricingRow(
              'Base Price',
              '\$${_pricingData!['basePrice'].toStringAsFixed(2)}',
            ),
            _buildPricingRow(
              'Location Multiplier',
              '×${_pricingData!['locationMultiplier'].toStringAsFixed(1)}',
            ),
            _buildPricingRow(
              'Duration Multiplier',
              '×${_pricingData!['durationMultiplier'].toStringAsFixed(1)}',
            ),
            const Divider(),
            _buildPricingRow(
              'Total',
              '\$${_pricingData!['totalPrice'].toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your ad will be submitted for review after payment. Once approved, it will be displayed according to your selected schedule.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Payment will be processed securely through Stripe. You can manage your payment methods in settings.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildPricingRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'User not authenticated. Please log in.';
      });
      return;
    }

    if (_pricingData == null) {
      setState(() {
        _errorMessage = 'Pricing data not available. Please try again.';
      });
      return;
    }

    // Navigate to OrderReviewScreen for enhanced payment processing
    final orderDetails = OrderDetails(
      type: TransactionType.advertisement,
      title: 'Advertisement Payment',
      description:
          'Payment for ${widget.ad.title} advertisement (${widget.duration.displayName} in ${widget.location.displayName})',
      originalAmount: (_pricingData!['totalPrice'] as num).toDouble(),
      metadata: {
        'adId': widget.ad.id,
        'adType': widget.ad.type.name,
        'duration': widget.duration.days,
        'location': widget.location.name,
        'adTitle': widget.ad.title,
      },
    );

    if (mounted) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (context) => OrderReviewScreen(
            orderDetails: orderDetails,
            onPaymentComplete: (paymentResult) {
              // Handle successful payment
              if (paymentResult['status'] == 'succeeded') {
                Navigator.pop(context, true);
              }
            },
          ),
        ),
      );

      // If payment was successful, return to previous screen
      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  String _getAdTypeName(dynamic type) {
    return type.toString().split('.').last.toUpperCase();
  }

  String _getLocationName(AdLocation location) {
    return location.toString().split('.').last.toUpperCase();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

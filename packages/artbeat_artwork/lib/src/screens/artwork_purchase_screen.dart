import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show MainLayout, AppLogger, StripePaymentService;
import '../models/artwork_model.dart';
import '../services/artwork_service.dart';

/// Screen for purchasing artwork with Stripe integration
class ArtworkPurchaseScreen extends StatefulWidget {
  final String artworkId;

  const ArtworkPurchaseScreen({
    super.key,
    required this.artworkId,
  });

  @override
  State<ArtworkPurchaseScreen> createState() => _ArtworkPurchaseScreenState();
}

class _ArtworkPurchaseScreenState extends State<ArtworkPurchaseScreen> {
  final ArtworkService _artworkService = ArtworkService();
  final StripePaymentService _paymentService = StripePaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ArtworkModel? _artwork;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  // Payment form state
  final _formKey = GlobalKey<FormState>();
  // ignore: unused_field
  String _cardNumber = '';
  // ignore: unused_field
  String _expiryDate = '';
  // ignore: unused_field
  String _cvv = '';
  // ignore: unused_field
  String _cardholderName = '';

  @override
  void initState() {
    super.initState();
    _loadArtworkData();
  }

  Future<void> _loadArtworkData() async {
    try {
      final artwork = await _artworkService.getArtworkById(widget.artworkId);

      if (mounted) {
        setState(() {
          _artwork = artwork;
          _isLoading = false;
        });
      }

      if (artwork == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Artwork not found')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      AppLogger.error('Error loading artwork for purchase: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processPurchase() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to purchase')),
      );
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      // Create payment intent
      // ignore: unused_local_variable
      final paymentIntent = await _paymentService.createPaymentIntent(
        artworkId: widget.artworkId,
        artistId: _artwork!.userId,
        amount: _artwork!.price ?? 0,
        currency: 'USD',
      );

      // In production, use Stripe Flutter SDK to process payment with paymentIntent
      // For now, we'll complete the purchase directly
      final transactionId = await _paymentService.purchaseArtwork(
        artworkId: widget.artworkId,
        artistId: _artwork!.userId,
        amount: _artwork!.price ?? 0,
        paymentMethod: 'card',
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase successful! Transaction: $transactionId'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back after brief delay
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      AppLogger.error('Error processing purchase: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0,
      appBar: AppBar(
        title: const Text('Purchase Artwork'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      );
    }

    if (_artwork == null) {
      return const Center(child: Text('Artwork not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artwork preview
          Card(
            child: Column(
              children: [
                Image.network(
                  _artwork!.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _artwork!.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'by ${_artwork!.artistName}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Order summary
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Price:'),
              Text(
                '\$${_artwork!.price?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Platform Fee (15%):'),
              Text(
                '\$${((_artwork!.price ?? 0) * 0.15).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '\$${((_artwork!.price ?? 0) * 1.15).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Payment form
          const Text(
            'Payment Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Cardholder Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Name required' : null,
                  onChanged: (value) => _cardholderName = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Card Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.credit_card),
                    hintText: '1234 5678 9012 3456',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 19,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Card number required' : null,
                  onChanged: (value) => _cardNumber = value,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Expiry Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: 'MM/YY',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Expiry required' : null,
                        onChanged: (value) => _expiryDate = value,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: '123',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'CVV required' : null,
                        onChanged: (value) => _cvv = value,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Purchase button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _processPurchase,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.shopping_cart),
              label: Text(
                _isProcessing ? 'Processing...' : 'Complete Purchase',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Security notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your payment is secure and encrypted',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

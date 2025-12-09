import 'package:flutter/material.dart';
import '../../services/in_app_purchase_manager.dart';
import '../../services/in_app_purchase_setup.dart';
import '../../theme/artbeat_colors.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  final InAppPurchaseManager _purchaseManager = InAppPurchaseManager();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePurchases();
  }

  Future<void> _initializePurchases() async {
    final setup = InAppPurchaseSetup();
    final initialized = await setup.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = initialized;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Promote Artwork'),
      backgroundColor: ArtbeatColors.primary,
      foregroundColor: Colors.white,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advertisement Packages',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Get more visibility for your artwork',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          _buildAdCategory(
            'Small Ads',
            [
              {
                'productId': 'ad_small_1w',
                'duration': '1 Week',
                'price': '\$4.99',
                'impressions': '~5,000',
              },
              {
                'productId': 'ad_small_1m',
                'duration': '1 Month',
                'price': '\$14.99',
                'impressions': '~20,000',
                'isPopular': true,
              },
              {
                'productId': 'ad_small_3m',
                'duration': '3 Months',
                'price': '\$34.99',
                'impressions': '~60,000',
              },
            ],
          ),
          const SizedBox(height: 24),
          _buildAdCategory(
            'Large Ads',
            [
              {
                'productId': 'ad_big_1w',
                'duration': '1 Week',
                'price': '\$9.99',
                'impressions': '~15,000',
              },
              {
                'productId': 'ad_big_1m',
                'duration': '1 Month',
                'price': '\$24.99',
                'impressions': '~60,000',
                'isPopular': true,
              },
              {
                'productId': 'ad_big_3m',
                'duration': '3 Months',
                'price': '\$54.99',
                'impressions': '~180,000',
              },
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    ),
  );

  Widget _buildAdCategory(String title, List<Map<String, dynamic>> ads) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...ads.map((ad) {
          final isPopular = ad['isPopular'] as bool? ?? false;
          return Column(
            children: [
              Card(
                elevation: isPopular ? 8 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isPopular
                      ? const BorderSide(color: ArtbeatColors.primary, width: 2)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.campaign,
                                    color: ArtbeatColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ad['duration'] as String,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        '${ad['impressions']} impressions',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                ad['price'] as String,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: ArtbeatColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (isPopular)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ArtbeatColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Popular',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _handleAdPurchase(
                            ad['productId'] as String,
                            ad['duration'] as String,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPopular
                                ? ArtbeatColors.primary
                                : Colors.grey[300],
                            foregroundColor: isPopular
                                ? Colors.white
                                : Colors.black,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Promote Now'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }).toList(),
      ],
    );
  }

  Future<void> _handleAdPurchase(String productId, String duration) async {
    if (!_isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('In-app purchases not available. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final success = await _purchaseManager.purchaseAdPackage(
        adProductId: productId,
        artworkId: 'demo_artwork',
        targetingOptions: {
          'ageRange': '18-65',
          'interests': ['Art'],
          'location': 'global',
          'deviceTypes': ['mobile', 'tablet'],
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Ad campaign initiated for $duration!'
                  : 'Failed to complete ad purchase',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e, _) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

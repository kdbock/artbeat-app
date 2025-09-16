import 'package:flutter/material.dart';
import '../services/in_app_purchase_manager.dart';
import '../utils/logger.dart';

/// Widget for purchasing ad packages
class AdPurchaseWidget extends StatefulWidget {
  final String? artworkId;
  final String? artworkTitle;
  final void Function(String)? onAdPurchased;
  final void Function(String)? onError;

  const AdPurchaseWidget({
    super.key,
    this.artworkId,
    this.artworkTitle,
    this.onAdPurchased,
    this.onError,
  });

  @override
  State<AdPurchaseWidget> createState() => _AdPurchaseWidgetState();
}

class _AdPurchaseWidgetState extends State<AdPurchaseWidget> {
  final InAppPurchaseManager _purchaseManager = InAppPurchaseManager();

  bool _isLoading = false;
  String? _selectedAdPackageId;
  List<Map<String, dynamic>> _availablePackages = [];
  final Map<String, dynamic> _targetingOptions = {
    'ageRange': '18-65',
    'interests': <String>[],
    'location': 'global',
    'deviceTypes': ['mobile', 'tablet'],
  };

  final List<String> _availableInterests = [
    'Art',
    'Photography',
    'Design',
    'Culture',
    'Museums',
    'Galleries',
    'Contemporary Art',
    'Abstract Art',
    'Painting',
    'Sculpture',
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailablePackages();
  }

  void _loadAvailablePackages() {
    setState(() {
      _availablePackages = _purchaseManager.getAvailableAdPackages();
    });
  }

  Future<void> _purchaseAdPackage() async {
    if (_selectedAdPackageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an ad package'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final artworkId = widget.artworkId;
    if (artworkId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No artwork selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _purchaseManager.purchaseAdPackage(
        adProductId: _selectedAdPackageId!,
        artworkId: artworkId,
        targetingOptions: _targetingOptions,
      );

      if (success) {
        widget.onAdPurchased?.call(_selectedAdPackageId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad campaign purchase initiated!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        widget.onError?.call('Failed to initiate ad purchase');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to initiate ad purchase'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error purchasing ad package: $e');
      widget.onError?.call(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promote Artwork'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _purchaseAdPackage,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Purchase'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork info
            if (widget.artworkTitle != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.image),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Promoting:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            widget.artworkTitle!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Package selection
            const Text(
              'Choose an ad package:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ..._availablePackages.map((package) {
              final isSelected = _selectedAdPackageId == package['productId'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAdPackageId = package['productId'] as String;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1)
                          : Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    package['title'] as String,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${package['amount'].toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).primaryColor,
                                  size: 32,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            package['description'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Package details
                          Row(
                            children: [
                              _buildDetailChip(
                                '${package['impressions']} impressions',
                                Icons.visibility,
                              ),
                              const SizedBox(width: 8),
                              _buildDetailChip(
                                '${package['duration_days']} days',
                                Icons.schedule,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Features
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: (package['features'] as List<String>)
                                .map(
                                  (feature) => Chip(
                                    label: Text(
                                      feature,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: isSelected
                                        ? Theme.of(
                                            context,
                                          ).primaryColor.withValues(alpha: 0.2)
                                        : Colors.grey.shade100,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Targeting options
            const Text(
              'Targeting Options:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Age range
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Age Range:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _targetingOptions['ageRange'] as String?,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: '18-24', child: Text('18-24')),
                        DropdownMenuItem(value: '25-34', child: Text('25-34')),
                        DropdownMenuItem(value: '35-44', child: Text('35-44')),
                        DropdownMenuItem(value: '45-54', child: Text('45-54')),
                        DropdownMenuItem(value: '55-65', child: Text('55-65')),
                        DropdownMenuItem(
                          value: '18-65',
                          child: Text('18-65 (All)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _targetingOptions['ageRange'] = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Interests
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Interests:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _availableInterests.map((interest) {
                        final isSelected =
                            (_targetingOptions['interests'] as List<String>)
                                .contains(interest);

                        return FilterChip(
                          label: Text(interest),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              final interests =
                                  _targetingOptions['interests']
                                      as List<String>;
                              if (selected) {
                                interests.add(interest);
                              } else {
                                interests.remove(interest);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _targetingOptions['location'] as String?,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'global',
                          child: Text('Global'),
                        ),
                        DropdownMenuItem(
                          value: 'us',
                          child: Text('United States'),
                        ),
                        DropdownMenuItem(value: 'eu', child: Text('Europe')),
                        DropdownMenuItem(value: 'asia', child: Text('Asia')),
                        DropdownMenuItem(
                          value: 'local',
                          child: Text('Local Area'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _targetingOptions['location'] = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Purchase button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _purchaseAdPackage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        _selectedAdPackageId != null
                            ? 'Start Campaign (\$${_availablePackages.firstWhere((p) => p['productId'] == _selectedAdPackageId)['amount'].toStringAsFixed(2)})'
                            : 'Select a Package',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Terms
            const Text(
              'Your ad campaign will start immediately after purchase. You can monitor performance and make adjustments in your dashboard.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// Simple ad package card widget
class AdPackageCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final bool isSelected;
  final VoidCallback? onTap;

  const AdPackageCard({
    super.key,
    required this.package,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 4 : 2,
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${package['amount'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  package['description'] as String,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${package['impressions']} impressions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${package['duration_days']} days',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

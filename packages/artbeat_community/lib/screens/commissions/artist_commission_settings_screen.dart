import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';
import '../../theme/community_colors.dart';

class ArtistCommissionSettingsScreen extends StatefulWidget {
  const ArtistCommissionSettingsScreen({super.key});

  @override
  State<ArtistCommissionSettingsScreen> createState() =>
      _ArtistCommissionSettingsScreenState();
}

class _ArtistCommissionSettingsScreenState
    extends State<ArtistCommissionSettingsScreen> {
  final DirectCommissionService _commissionService = DirectCommissionService();
  final _formKey = GlobalKey<FormState>();
  final _basePriceController = TextEditingController();
  final _termsController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  // Form fields
  bool _acceptingCommissions = false;
  List<CommissionType> _availableTypes = [];
  Map<CommissionType, double> _typePricing = {};
  Map<String, double> _sizePricing = {};
  int _maxActiveCommissions = 5;
  int _averageTurnaroundDays = 14;
  double _depositPercentage = 50.0;
  List<String> _portfolioImages = [];

  final Map<CommissionType, String> _typeDescriptions = {
    CommissionType.digital: 'Digital artwork delivered as files',
    CommissionType.physical: 'Physical artwork shipped to client',
    CommissionType.portrait: 'Custom portraits of people or pets',
    CommissionType.commercial: 'Artwork for commercial use',
  };

  final List<String> _commonSizes = [
    'Small (up to 8x10")',
    'Medium (11x14" to 16x20")',
    'Large (18x24" to 24x36")',
    'Extra Large (30x40"+)',
    'Custom Size',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final settings = await _commissionService.getArtistSettings(user.uid);

      setState(() {
        if (settings != null) {
          _acceptingCommissions = settings.acceptingCommissions;
          _availableTypes = List.from(settings.availableTypes);
          _typePricing = Map.from(settings.typePricing);
          _sizePricing = Map.from(settings.sizePricing);
          _maxActiveCommissions = settings.maxActiveCommissions;
          _averageTurnaroundDays = settings.averageTurnaroundDays;
          _depositPercentage = settings.depositPercentage;
          _portfolioImages = List.from(settings.portfolioImages);
          _basePriceController.text = settings.basePrice.toString();
          _termsController.text = settings.terms;
        } else {
          // Initialize with defaults
          _initializeDefaults();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
      }
    }
  }

  void _initializeDefaults() {
    _acceptingCommissions = false;
    _availableTypes = [CommissionType.digital];
    _typePricing = {
      CommissionType.digital: 0.0,
      CommissionType.physical: 50.0,
      CommissionType.portrait: 25.0,
      CommissionType.commercial: 100.0,
    };
    _sizePricing = {
      'Small (up to 8x10")': 0.0,
      'Medium (11x14" to 16x20")': 25.0,
      'Large (18x24" to 24x36")': 75.0,
      'Extra Large (30x40"+)': 150.0,
      'Custom Size': 0.0,
    };
    _basePriceController.text = '50.0';
    _termsController.text =
        '''
Commission Terms & Conditions:

1. Payment: 50% deposit required to start work, remaining balance due upon completion.
2. Revisions: Up to 2 minor revisions included in base price.
3. Timeline: Estimated completion time provided with quote.
4. Copyright: Client receives usage rights, artist retains copyright unless otherwise agreed.
5. Cancellation: Deposit is non-refundable after work begins.

Please contact me with any questions before placing your commission request.
    '''
            .trim();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final settings = ArtistCommissionSettings(
        artistId: user.uid,
        acceptingCommissions: _acceptingCommissions,
        availableTypes: _availableTypes,
        basePrice: double.tryParse(_basePriceController.text) ?? 0.0,
        typePricing: _typePricing,
        sizePricing: _sizePricing,
        maxActiveCommissions: _maxActiveCommissions,
        averageTurnaroundDays: _averageTurnaroundDays,
        depositPercentage: _depositPercentage,
        terms: _termsController.text,
        portfolioImages: _portfolioImages,
        lastUpdated: DateTime.now(),
      );

      await _commissionService.updateArtistSettings(settings);

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commission settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: 3,
      appBar: const core.EnhancedUniversalHeader(
        title: 'Commission Settings',
        showBackButton: true,
        showSearch: false,
        backgroundGradient: CommunityColors.communityGradient,
        titleGradient: LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        foregroundColor: Colors.white,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Status Card
                  _buildStatusCard(),
                  const SizedBox(height: 16),

                  // Basic Settings
                  _buildBasicSettingsCard(),
                  const SizedBox(height: 16),

                  // Commission Types
                  _buildCommissionTypesCard(),
                  const SizedBox(height: 16),

                  // Pricing
                  _buildPricingCard(),
                  const SizedBox(height: 16),

                  // Business Settings
                  _buildBusinessSettingsCard(),
                  const SizedBox(height: 16),

                  // Terms & Conditions
                  _buildTermsCard(),
                  const SizedBox(height: 16),

                  // Portfolio Images
                  _buildPortfolioCard(),
                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CommunityColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Save Settings'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: _acceptingCommissions
          ? Colors.green.shade50
          : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _acceptingCommissions
                      ? Icons.check_circle
                      : Icons.pause_circle,
                  color: _acceptingCommissions ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _acceptingCommissions
                        ? 'Currently Accepting Commissions'
                        : 'Not Accepting Commissions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _acceptingCommissions
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
                Switch(
                  value: _acceptingCommissions,
                  onChanged: (value) {
                    setState(() => _acceptingCommissions = value);
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _acceptingCommissions
                  ? 'Your commission request form is visible to clients'
                  : 'Clients cannot request new commissions from you',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Settings',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _basePriceController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Base Price (\$)',
                hintText: 'Starting price for commissions',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a base price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Max Active Commissions: $_maxActiveCommissions'),
                      Slider(
                        value: _maxActiveCommissions.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: _maxActiveCommissions.toString(),
                        onChanged: (value) {
                          setState(() => _maxActiveCommissions = value.round());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Average Turnaround: $_averageTurnaroundDays days'),
                      Slider(
                        value: _averageTurnaroundDays.toDouble(),
                        min: 1,
                        max: 90,
                        divisions: 89,
                        label: '$_averageTurnaroundDays days',
                        onChanged: (value) {
                          setState(
                            () => _averageTurnaroundDays = value.round(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deposit Percentage: ${_depositPercentage.round()}%',
                      ),
                      Slider(
                        value: _depositPercentage,
                        min: 25,
                        max: 100,
                        divisions: 15,
                        label: '${_depositPercentage.round()}%',
                        onChanged: (value) {
                          setState(() => _depositPercentage = value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionTypesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commission Types',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the types of commissions you offer',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ...CommissionType.values.map((type) {
              final isSelected = _availableTypes.contains(type);
              return CheckboxListTile(
                title: Text(type.displayName),
                subtitle: Text(_typeDescriptions[type] ?? ''),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _availableTypes.add(type);
                    } else {
                      _availableTypes.remove(type);
                    }
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing Modifiers',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Additional charges for different types and sizes',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Type Pricing
            Text(
              'Type Pricing (added to base price)',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...CommissionType.values.map((type) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 120, child: Text(type.displayName)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _typePricing[type]?.toString() ?? '0',
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixText: '+\$',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _typePricing[type] = double.tryParse(value) ?? 0.0;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Size Pricing
            Text(
              'Size Pricing (added to base price)',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ..._commonSizes.map((size) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: Text(size, style: const TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _sizePricing[size]?.toString() ?? '0',
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixText: '+\$',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _sizePricing[size] = double.tryParse(value) ?? 0.0;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Settings',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text('Average Turnaround: $_averageTurnaroundDays days'),
              subtitle: const Text('How long commissions typically take'),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: Text('Deposit: ${_depositPercentage.round()}%'),
              subtitle: const Text('Percentage required upfront'),
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: Text('Max Active: $_maxActiveCommissions'),
              subtitle: const Text('Maximum concurrent commissions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms & Conditions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'These terms will be shown to clients before they request a commission',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _termsController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Terms & Conditions',
                hintText: 'Enter your commission terms...',
              ),
              maxLines: 8,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your terms and conditions';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Portfolio Images',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _addPortfolioImage,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add Image'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Showcase your work to potential clients',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            if (_portfolioImages.isEmpty)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No portfolio images added',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _portfolioImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(_portfolioImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePortfolioImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _addPortfolioImage() {
    // TODO: Implement image picker and upload
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Image upload coming soon!')));
  }

  void _removePortfolioImage(int index) {
    setState(() {
      _portfolioImages.removeAt(index);
    });
  }
}

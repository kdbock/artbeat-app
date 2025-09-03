import 'package:flutter/material.dart';

import 'package:artbeat_core/artbeat_core.dart' as core;
import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';
import '../../theme/community_colors.dart';

class CommissionRequestScreen extends StatefulWidget {
  final String artistId;
  final String artistName;
  final ArtistCommissionSettings? artistSettings;

  const CommissionRequestScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    this.artistSettings,
  });

  @override
  State<CommissionRequestScreen> createState() =>
      _CommissionRequestScreenState();
}

class _CommissionRequestScreenState extends State<CommissionRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sizeController = TextEditingController();
  final _mediumController = TextEditingController();
  final _styleController = TextEditingController();
  final _customRequirementsController = TextEditingController();

  final DirectCommissionService _commissionService = DirectCommissionService();

  CommissionType _selectedType = CommissionType.digital;
  String _selectedColorScheme = 'Full Color';
  int _revisions = 1;
  bool _commercialUse = false;
  String _deliveryFormat = 'High-res PNG';
  DateTime? _deadline;

  bool _isLoading = false;
  double? _estimatedPrice;

  final List<String> _colorSchemes = [
    'Full Color',
    'Black & White',
    'Sepia',
    'Monochrome',
    'Custom Palette',
  ];

  final Map<CommissionType, List<String>> _deliveryFormats = {
    CommissionType.digital: [
      'High-res PNG',
      'High-res JPEG',
      'Vector (SVG)',
      'PSD File',
      'Print-ready PDF',
    ],
    CommissionType.physical: [
      'Physical Shipping',
      'Local Pickup',
      'Digital Photo + Physical',
    ],
    CommissionType.portrait: [
      'High-res PNG',
      'High-res JPEG',
      'Physical Print',
      'Canvas Print',
    ],
    CommissionType.commercial: [
      'High-res PNG',
      'Vector (SVG)',
      'Print-ready PDF',
      'Full Rights Package',
    ],
  };

  @override
  void initState() {
    super.initState();
    _updateDeliveryFormat();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    _mediumController.dispose();
    _styleController.dispose();
    _customRequirementsController.dispose();
    super.dispose();
  }

  void _updateDeliveryFormat() {
    final formats = _deliveryFormats[_selectedType] ?? [];
    if (formats.isNotEmpty && !formats.contains(_deliveryFormat)) {
      _deliveryFormat = formats.first;
    }
  }

  Future<void> _calculatePrice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final specs = CommissionSpecs(
        size: _sizeController.text,
        medium: _mediumController.text,
        style: _styleController.text,
        colorScheme: _selectedColorScheme,
        revisions: _revisions,
        commercialUse: _commercialUse,
        deliveryFormat: _deliveryFormat,
        customRequirements: {'description': _customRequirementsController.text},
      );

      final price = await _commissionService.calculateCommissionPrice(
        artistId: widget.artistId,
        type: _selectedType,
        specs: specs,
      );

      setState(() {
        _estimatedPrice = price;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error calculating price: $e')));
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final specs = CommissionSpecs(
        size: _sizeController.text,
        medium: _mediumController.text,
        style: _styleController.text,
        colorScheme: _selectedColorScheme,
        revisions: _revisions,
        commercialUse: _commercialUse,
        deliveryFormat: _deliveryFormat,
        customRequirements: {'description': _customRequirementsController.text},
      );

      final commissionId = await _commissionService.createCommissionRequest(
        artistId: widget.artistId,
        artistName: widget.artistName,
        type: _selectedType,
        title: _titleController.text,
        description: _descriptionController.text,
        specs: specs,
        deadline: _deadline,
        metadata: {
          'estimatedPrice': _estimatedPrice,
          'requestedAt': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commission request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, commissionId);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting request: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: 3,
      appBar: const core.EnhancedUniversalHeader(
        title: 'Request Commission',
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
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Artist Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commissioning: ${widget.artistName}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (widget.artistSettings != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Base Price: \$${widget.artistSettings!.basePrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Average Turnaround: ${widget.artistSettings!.averageTurnaroundDays} days',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Commission Type
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commission Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<CommissionType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Type',
                      ),
                      items: CommissionType.values.map((type) {
                        final isAvailable =
                            widget.artistSettings?.availableTypes.contains(
                              type,
                            ) ??
                            true;
                        return DropdownMenuItem(
                          value: type,
                          enabled: isAvailable,
                          child: Text(
                            type.displayName,
                            style: TextStyle(
                              color: isAvailable ? null : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                            _updateDeliveryFormat();
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null)
                          return 'Please select a commission type';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Basic Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Commission Title',
                        hintText: 'e.g., "Portrait of my dog"',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Description',
                        hintText: 'Describe what you want in detail...',
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Specifications
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Specifications',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sizeController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Size',
                              hintText: 'e.g., "16x20 inches"',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter size';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _mediumController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Medium',
                              hintText: 'e.g., "Digital", "Oil"',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter medium';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _styleController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Style',
                              hintText: 'e.g., "Realistic", "Abstract"',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter style';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedColorScheme,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Color Scheme',
                            ),
                            items: _colorSchemes.map((scheme) {
                              return DropdownMenuItem(
                                value: scheme,
                                child: Text(scheme),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedColorScheme = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _deliveryFormat,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Delivery Format',
                      ),
                      items: (_deliveryFormats[_selectedType] ?? []).map((
                        format,
                      ) {
                        return DropdownMenuItem(
                          value: format,
                          child: Text(format),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _deliveryFormat = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Options',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Revisions: $_revisions'),
                              Slider(
                                value: _revisions.toDouble(),
                                min: 1,
                                max: 5,
                                divisions: 4,
                                label: _revisions.toString(),
                                onChanged: (value) {
                                  setState(() => _revisions = value.round());
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      title: const Text('Commercial Use'),
                      subtitle: const Text('Allow commercial use of artwork'),
                      value: _commercialUse,
                      onChanged: (value) {
                        setState(() => _commercialUse = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Timeline
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timeline',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        _deadline == null
                            ? 'No deadline set'
                            : 'Deadline: ${_deadline!.toLocal().toString().split(' ')[0]}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              _deadline ??
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now().add(
                            const Duration(days: 1),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() => _deadline = date);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Additional Requirements
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Requirements',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _customRequirementsController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Special requests or requirements',
                        hintText:
                            'Any additional details, references, or special requests...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Price Estimation
            if (_estimatedPrice != null)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Price',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${_estimatedPrice!.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This is an estimate. The artist will provide the final quote.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _calculatePrice,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Calculate Price'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CommunityColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
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
                        : const Text('Submit Request'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

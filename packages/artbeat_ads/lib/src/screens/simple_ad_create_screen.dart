import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import '../models/ad_model.dart';
import '../models/ad_type.dart';
import '../models/ad_location.dart';
import '../models/ad_package.dart';
import '../models/ad_status.dart';
import '../models/ad_duration.dart';
import '../models/image_fit.dart';
import '../models/ad_size.dart';
import '../services/simple_ad_service.dart';

/// Redesigned ad creation screen using fixed IAP packages
class SimpleAdCreateScreen extends StatefulWidget {
  const SimpleAdCreateScreen({super.key});

  @override
  State<SimpleAdCreateScreen> createState() => _SimpleAdCreateScreenState();
}

class _SimpleAdCreateScreenState extends State<SimpleAdCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _destinationUrlController = TextEditingController();
  final _ctaTextController = TextEditingController();

  AdType _selectedType = AdType.banner_ad;
  AdPackage? _selectedPackage;
  ImageFit _selectedImageFit = ImageFit.cover;

  List<File> _selectedImages = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  final InAppAdService _adService = InAppAdService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _destinationUrlController.dispose();
    _ctaTextController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final limitedImages = images.take(4).toList();
        setState(() {
          _selectedImages = limitedImages
              .map((xFile) => File(xFile.path))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
      }
    }
  }

  Future<void> _processPaymentAndCreateAd() async {
    final confirmed = await _showPaymentConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      await _processIAPPurchase();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment successful! Your ad has been created and will be reviewed.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showPaymentConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ad Title: ${_titleController.text}'),
                const SizedBox(height: 8),
                if (_selectedPackage != null) ...[
                  Text('Package: ${_selectedPackage!.displayName}'),
                  Text('Zone: ${_selectedPackage!.zoneGroup.displayName}'),
                  Text('Size: ${_selectedPackage!.adSize.displayName}'),
                  Text('Duration: ${_selectedPackage!.durationDays} days'),
                  const Divider(),
                  Text(
                    'Total Cost: \$${_selectedPackage!.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'You will be charged immediately upon confirmation.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Proceed to Payment'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _processIAPPurchase() async {
    try {
      if (_selectedPackage == null) {
        throw Exception('No package selected');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.info(
        '🛒 Processing IAP purchase for: ${_selectedPackage!.productId}',
      );

      final success = await _adService.purchaseAdPackage(
        adProductId: _selectedPackage!.productId,
        artworkId: 'artwork_${DateTime.now().millisecondsSinceEpoch}',
        targetingOptions: {
          'package': _selectedPackage!.name,
          'zone_group': _selectedPackage!.zoneGroup.name,
          'zone': _selectedPackage!.zoneGroup.primaryZone.name,
          'size': _selectedPackage!.adSize.name,
          'duration_days': _selectedPackage!.durationDays,
          'imageFit': _selectedImageFit.name,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'destinationUrl': _destinationUrlController.text.trim().isEmpty
              ? null
              : _destinationUrlController.text.trim(),
          'ctaText': _ctaTextController.text.trim().isEmpty
              ? null
              : _ctaTextController.text.trim(),
        },
      );

      if (!success) {
        throw Exception('Ad purchase failed');
      }

      await _createAdFromPackage(user);
      AppLogger.info('✅ Ad created successfully');
    } catch (e) {
      throw Exception('Ad purchase error: $e');
    }
  }

  Future<void> _createAdFromPackage(User user) async {
    if (_selectedPackage == null) return;

    final now = DateTime.now();
    // Map duration days to AdDuration enum
    AdDuration duration;
    switch (_selectedPackage!.durationDays) {
      case 1:
        duration = AdDuration.oneDay;
        break;
      case 7:
        duration = AdDuration.oneWeek;
        break;
      case 14:
        duration = AdDuration.twoWeeks;
        break;
      case 30:
        duration = AdDuration.oneMonth;
        break;
      default:
        duration = AdDuration.custom;
    }

    final ad = AdModel(
      id: '',
      ownerId: user.uid,
      type: _selectedType,
      size: _selectedPackage!.adSize,
      imageUrl: '',
      artworkUrls: [],
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: AdLocation.fluidDashboard,
      zone: _selectedPackage!.zoneGroup.primaryZone,
      duration: duration,
      startDate: now,
      endDate: now.add(Duration(days: _selectedPackage!.durationDays)),
      status: AdStatus.pending,
      destinationUrl: _destinationUrlController.text.trim().isEmpty
          ? null
          : _destinationUrlController.text.trim(),
      ctaText: _ctaTextController.text.trim().isEmpty
          ? null
          : _ctaTextController.text.trim(),
      imageFit: _selectedImageFit,
    );

    final adService = SimpleAdService();
    await adService.createAdWithImages(ad, _selectedImages);
  }

  Future<void> _createAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an ad package')),
      );
      return;
    }
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    await _processPaymentAndCreateAd();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      appBar: const EnhancedUniversalHeader(title: 'Create Ad'),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Package Selection'),
              _buildPackageSelector(),
              const SizedBox(height: 24),

              if (_selectedPackage != null) ...[
                _buildPackageInfo(),
                const SizedBox(height: 24),
              ],

              _buildSectionTitle('Ad Content'),
              _buildContentFields(),
              const SizedBox(height: 24),

              _buildSectionTitle('Images'),
              _buildImagePicker(),
              const SizedBox(height: 24),

              _buildSectionTitle('Advanced Options'),
              _buildAdvancedOptions(),
              const SizedBox(height: 32),

              if (_selectedPackage != null) _buildCostSummary(),
              const SizedBox(height: 24),

              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPackageSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Your Ad Package',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Group packages by tier for better organization
            ...['Basic', 'Standard', 'Premium'].map((tier) {
              final tierPackages = AdPackage.values
                  .where((pkg) => pkg.tierName == tier)
                  .toList();

              return ExpansionTile(
                title: Text(
                  '$tier Packages (${tier == 'Basic'
                      ? '7'
                      : tier == 'Standard'
                      ? '14'
                      : '30'} days)',
                ),
                children: tierPackages.map((package) {
                  return RadioListTile<AdPackage>(
                    value: package,
                    groupValue: _selectedPackage,
                    onChanged: (value) =>
                        setState(() => _selectedPackage = value),
                    title: Text(package.displayName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(package.description),
                        Text(
                          '\$${package.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageInfo() {
    if (_selectedPackage == null) return const SizedBox();

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Package: ${_selectedPackage!.displayName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Zone Group: ${_selectedPackage!.zoneGroup.description}'),
            Text('Ad Size: ${_selectedPackage!.adSize.displayName}'),
            Text('Duration: ${_selectedPackage!.durationDays} days'),
            Text(
              'Price: \$${_selectedPackage!.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentFields() {
    return Column(
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Ad Title',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Title is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Ad Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Description is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _destinationUrlController,
          decoration: const InputDecoration(
            labelText: 'Destination URL (Optional)',
            border: OutlineInputBorder(),
            hintText: 'https://example.com',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _ctaTextController,
          decoration: const InputDecoration(
            labelText: 'Call-to-Action Text (Optional)',
            border: OutlineInputBorder(),
            hintText: 'e.g., Shop Now, Learn More',
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.photo),
          label: Text(
            _selectedImages.isEmpty ? 'Select Images' : 'Change Images',
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedImages.isNotEmpty) ...[
          Text('Selected Images (${_selectedImages.length}/4):'),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImages[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Image Fit:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<ImageFit>(
          value: _selectedImageFit,
          decoration: const InputDecoration(
            labelText: 'How images should be displayed',
            border: OutlineInputBorder(),
          ),
          items: ImageFit.values.map((fit) {
            return DropdownMenuItem(value: fit, child: Text(fit.displayName));
          }).toList(),
          onChanged: (value) =>
              setState(() => _selectedImageFit = value ?? ImageFit.cover),
        ),
      ],
    );
  }

  Widget _buildCostSummary() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Cost Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Package: ${_selectedPackage!.displayName}'),
            Text('Duration: ${_selectedPackage!.durationDays} days'),
            const Divider(),
            Text(
              'Total Cost: \$${_selectedPackage!.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your ad will be reviewed before going live',
                      style: TextStyle(color: Colors.blue),
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

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createAd,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _selectedPackage != null
                    ? 'Create Ad - \$${_selectedPackage!.price.toStringAsFixed(2)}'
                    : 'Select a Package First',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

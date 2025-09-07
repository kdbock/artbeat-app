import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import '../models/ad_model.dart';
import '../models/ad_type.dart';
import '../models/ad_size.dart';
import '../models/ad_location.dart';
import '../models/ad_status.dart';
import '../models/ad_duration.dart';
import '../models/image_fit.dart';
import '../services/simple_ad_service.dart';

/// Simplified unified ad creation screen for all user types
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
  AdSize _selectedSize = AdSize.small;
  AdLocation _selectedLocation = AdLocation.dashboard;
  ImageFit _selectedImageFit = ImageFit.cover;
  int _selectedDays = 7;

  List<File> _selectedImages = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

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
        // Limit to 4 images maximum
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

  Future<void> _createAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user (simplified - you may need to adjust based on your auth system)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Calculate dates
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: _selectedDays));

      // Create duration object based on selected days
      AdDuration duration;
      switch (_selectedDays) {
        case 1:
          duration = AdDuration.oneDay;
          break;
        case 3:
          duration = AdDuration.threeDays;
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
          break;
      }

      // Create ad model
      final ad = AdModel(
        id: '', // Will be set by service
        ownerId: user.uid,
        type: _selectedType,
        size: _selectedSize,
        imageUrl: '', // Will be set after upload
        artworkUrls: [], // Will be set after upload
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _selectedLocation,
        duration: duration,
        startDate: startDate,
        endDate: endDate,
        status: AdStatus.pending,
        destinationUrl: _destinationUrlController.text.trim().isEmpty
            ? null
            : _destinationUrlController.text.trim(),
        ctaText: _ctaTextController.text.trim().isEmpty
            ? null
            : _ctaTextController.text.trim(),
        imageFit: _selectedImageFit,
      );

      // Create ad with images using SimpleAdService
      final adService = SimpleAdService();
      await adService.createAdWithImages(ad, _selectedImages);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ad created successfully! It will be reviewed before going live.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating ad: $e'),
            backgroundColor: Colors.red,
          ),
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

  double get _totalCost => _selectedSize.pricePerDay * _selectedDays;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // No bottom navigation for this screen
      appBar: const EnhancedUniversalHeader(title: 'Create Ad'),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ad Type Selection
              _buildSectionTitle('Ad Type'),
              _buildAdTypeSelector(),
              const SizedBox(height: 24),

              // Ad Size Selection
              _buildSectionTitle('Ad Size & Pricing'),
              _buildAdSizeSelector(),
              const SizedBox(height: 24),

              // Image Fit Selection
              _buildSectionTitle('Image Display Mode'),
              _buildImageFitSelector(),
              const SizedBox(height: 24),

              // Location Selection
              _buildSectionTitle('Display Location'),
              _buildLocationSelector(),
              const SizedBox(height: 24),

              // Duration Selection
              _buildSectionTitle('Duration'),
              _buildDurationSelector(),
              const SizedBox(height: 24),

              // Images Selection
              _buildSectionTitle('Images (1-4 images)'),
              _buildImageSelector(),
              const SizedBox(height: 24),

              // Ad Details
              _buildSectionTitle('Ad Details'),
              _buildAdDetailsForm(),
              const SizedBox(height: 24),

              // Cost Summary
              _buildCostSummary(),
              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Ad', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildAdTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: AdType.values.map((type) {
            return RadioListTile<AdType>(
              value: type,
              groupValue: _selectedType,
              onChanged: (AdType? value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
              title: Text(
                _getAdTypeDisplayName(type),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                _getAdTypeDescription(type),
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAdSizeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: AdSize.values.map((size) {
            return RadioListTile<AdSize>(
              value: size,
              groupValue: _selectedSize,
              onChanged: (AdSize? value) {
                if (value != null) {
                  setState(() {
                    _selectedSize = value;
                  });
                }
              },
              title: Text(
                size.displayName,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '\$${size.pricePerDay.toStringAsFixed(0)}/day',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildImageFitSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: ImageFit.values.map((fit) {
            return RadioListTile<ImageFit>(
              value: fit,
              groupValue: _selectedImageFit,
              onChanged: (ImageFit? value) {
                if (value != null) {
                  setState(() {
                    _selectedImageFit = value;
                  });
                }
              },
              title: Text(
                fit.displayName,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                _getImageFitDescription(fit),
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<AdLocation>(
              value: _selectedLocation,
              decoration: const InputDecoration(
                labelText: 'Select Display Location',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              dropdownColor: Colors.white,
              items: AdLocation.values.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(
                    location.displayName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (AdLocation? value) {
                if (value != null) {
                  setState(() {
                    _selectedLocation = value;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              _selectedLocation.description,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Duration: $_selectedDays days',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Slider(
              value: _selectedDays.toDouble(),
              min: 1,
              max: 365,
              divisions: 364,
              label: '$_selectedDays days',
              onChanged: (double value) {
                setState(() {
                  _selectedDays = value.round();
                });
              },
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1 day',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  '365 days (1 year)',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Quick Select:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDurationChip('1 Week', 7),
                _buildDurationChip('2 Weeks', 14),
                _buildDurationChip('1 Month', 30),
                _buildDurationChip('3 Months', 90),
                _buildDurationChip('6 Months', 180),
                _buildDurationChip('1 Year', 365),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(String label, int days) {
    final isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDays = days;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_selectedImages.isEmpty)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text('Tap to select images'),
                      Text(
                        '(1-4 images)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
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
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_selectedImages.length < 4)
                        TextButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add),
                          label: const Text('Add More Images'),
                        ),
                      const Spacer(),
                      Text('${_selectedImages.length}/4 images'),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdDetailsForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Ad Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destinationUrlController,
              decoration: const InputDecoration(
                labelText: 'Destination URL (optional)',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ctaTextController,
              decoration: const InputDecoration(
                labelText: 'Call-to-Action Text (optional)',
                hintText: 'Shop Now, Learn More, etc.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostSummary() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cost Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Size: ${_selectedSize.displayName}'),
                Text('\$${_selectedSize.pricePerDay.toStringAsFixed(0)}/day'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Duration: $_selectedDays days'),
                Text('× $_selectedDays'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Cost:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${_totalCost.toStringAsFixed(0)}',
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
    );
  }

  String _getAdTypeDisplayName(AdType type) {
    switch (type) {
      case AdType.banner_ad:
        return 'Banner Ad';
      case AdType.feed_ad:
        return 'Feed Ad';
    }
  }

  String _getAdTypeDescription(AdType type) {
    switch (type) {
      case AdType.banner_ad:
        return 'Horizontal banner displayed at top/bottom of screens';
      case AdType.feed_ad:
        return 'Integrated into content feeds and lists';
    }
  }

  String _getImageFitDescription(ImageFit fit) {
    switch (fit) {
      case ImageFit.cover:
        return 'Fills entire ad space, may crop image';
      case ImageFit.contain:
        return 'Fits image within ad space, may show empty areas';
      case ImageFit.fill:
        return 'Stretches image to fill ad space exactly';
      case ImageFit.fitWidth:
        return 'Fits image width, may crop height';
      case ImageFit.fitHeight:
        return 'Fits image height, may crop width';
      case ImageFit.none:
        return 'Shows original image size and aspect ratio';
      case ImageFit.scaleDown:
        return 'Scales down image to fit.';
    }
  }
}

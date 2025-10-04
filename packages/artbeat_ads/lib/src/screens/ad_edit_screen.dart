import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ad_model.dart';
import '../models/ad_type.dart';
import '../models/ad_size.dart';
import '../models/ad_location.dart';
import '../models/ad_zone.dart';
import '../models/ad_duration.dart';
import '../models/image_fit.dart';
import '../services/simple_ad_service.dart';

/// Dedicated ad editing interface for modifying existing advertisements
///
/// Provides comprehensive editing capabilities for ad content, images,
/// targeting, and settings with real-time preview and validation.
/// Supports all ad types with specialized editing workflows.
class AdEditScreen extends StatefulWidget {
  final AdModel ad;
  final VoidCallback? onAdUpdated;

  const AdEditScreen({super.key, required this.ad, this.onAdUpdated});

  @override
  State<AdEditScreen> createState() => _AdEditScreenState();
}

class _AdEditScreenState extends State<AdEditScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _simpleAdService = SimpleAdService();
  final _picker = ImagePicker();

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _ctaTextController;
  late TextEditingController _linkUrlController;
  late TextEditingController _contactInfoController;

  // Form state
  late AdType _selectedType;
  late AdSize _selectedSize;
  late AdLocation _selectedLocation;
  AdZone? _selectedZone;
  late AdDuration _selectedDuration;
  late ImageFit _selectedImageFit;

  // Image management
  List<String> _currentImageUrls = [];
  List<File?> _newImages = [];
  List<bool> _imageToDelete = [];

  // UI state
  bool _isLoading = false;
  bool _hasChanges = false;
  late TabController _tabController;

  // Validation
  String? _titleError;
  String? _descriptionError;
  String? _linkUrlError;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCurrentData();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ctaTextController.dispose();
    _linkUrlController.dispose();
    _contactInfoController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _ctaTextController = TextEditingController();
    _linkUrlController = TextEditingController();
    _contactInfoController = TextEditingController();

    // Add change listeners
    _titleController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);
    _ctaTextController.addListener(_onFormChanged);
    _linkUrlController.addListener(_onFormChanged);
    _contactInfoController.addListener(_onFormChanged);
  }

  void _loadCurrentData() {
    final ad = widget.ad;

    _titleController.text = ad.title;
    _descriptionController.text = ad.description;
    _ctaTextController.text = ad.ctaText ?? '';
    _linkUrlController.text = ad.destinationUrl ?? '';
    _contactInfoController.text = ''; // Not available in current model

    _selectedType = ad.type;
    _selectedSize = ad.size;
    _selectedLocation = ad.location;
    _selectedZone = ad.zone; // Load zone if available
    _selectedDuration = ad.duration;
    _selectedImageFit = ad.imageFit;

    _currentImageUrls = List.from(ad.artworkUrls);
    if (_currentImageUrls.isEmpty && ad.imageUrl.isNotEmpty) {
      _currentImageUrls.add(ad.imageUrl);
    }
    _newImages = List.filled(4, null);
    _imageToDelete = List.filled(_currentImageUrls.length, false);
  }

  void _onFormChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (index < _newImages.length) {
            _newImages[index] = File(image.path);
          }
          _hasChanges = true;
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  void _removeImage(int index, bool isExisting) {
    setState(() {
      if (isExisting && index < _imageToDelete.length) {
        _imageToDelete[index] = true;
      } else if (!isExisting && index < _newImages.length) {
        _newImages[index] = null;
      }
      _hasChanges = true;
    });
  }

  void _restoreImage(int index) {
    setState(() {
      if (index < _imageToDelete.length) {
        _imageToDelete[index] = false;
        _hasChanges = true;
      }
    });
  }

  bool _validateForm() {
    bool isValid = true;

    setState(() {
      _titleError = null;
      _descriptionError = null;
      _linkUrlError = null;
    });

    if (_titleController.text.trim().isEmpty) {
      setState(() {
        _titleError = 'Title is required';
      });
      isValid = false;
    } else if (_titleController.text.trim().length < 3) {
      setState(() {
        _titleError = 'Title must be at least 3 characters';
      });
      isValid = false;
    }

    if (_descriptionController.text.trim().isEmpty) {
      setState(() {
        _descriptionError = 'Description is required';
      });
      isValid = false;
    } else if (_descriptionController.text.trim().length < 10) {
      setState(() {
        _descriptionError = 'Description must be at least 10 characters';
      });
      isValid = false;
    }

    if (_linkUrlController.text.isNotEmpty &&
        !_isValidUrl(_linkUrlController.text)) {
      setState(() {
        _linkUrlError = 'Please enter a valid URL';
      });
      isValid = false;
    }

    // Check if we have at least one image
    final bool hasImages =
        _currentImageUrls.any(
          (url) => !_imageToDelete[_currentImageUrls.indexOf(url)],
        ) ||
        _newImages.any((img) => img != null);

    if (!hasImages) {
      _showError('At least one image is required');
      isValid = false;
    }

    return isValid;
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveChanges() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated ad model
      final updatedAd = widget.ad.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        ctaText: _ctaTextController.text.trim().isEmpty
            ? null
            : _ctaTextController.text.trim(),
        linkUrl: _linkUrlController.text.trim().isEmpty
            ? null
            : _linkUrlController.text.trim(),
        contactInfo: _contactInfoController.text.trim().isEmpty
            ? null
            : _contactInfoController.text.trim(),
        type: _selectedType,
        size: _selectedSize,
        location: _selectedLocation,
        zone: _selectedZone, // Save zone
        duration: _selectedDuration,
        imageFit: _selectedImageFit,
        updatedAt: DateTime.now(),
      );

      // Prepare images for update
      final List<File> imagesToUpload = [];
      final List<String> imageUrlsToKeep = [];

      // Process existing images
      for (int i = 0; i < _currentImageUrls.length; i++) {
        if (!_imageToDelete[i]) {
          imageUrlsToKeep.add(_currentImageUrls[i]);
        }
      }

      // Process new images
      for (final newImage in _newImages) {
        if (newImage != null) {
          imagesToUpload.add(newImage);
        }
      }

      // Update the ad
      await _simpleAdService.updateAdWithImages(
        updatedAd,
        imagesToUpload,
        imageUrlsToKeep,
      );

      setState(() {
        _hasChanges = false;
      });

      // Call callback
      widget.onAdUpdated?.call();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Error updating ad: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Ad'),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Content'),
              Tab(text: 'Images'),
              Tab(text: 'Settings'),
              Tab(text: 'Preview'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildContentTab(),
            _buildImagesTab(),
            _buildSettingsTab(),
            _buildPreviewTab(),
          ],
        ),
        floatingActionButton: _hasChanges
            ? FloatingActionButton(
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.save),
              )
            : null,
      ),
    );
  }

  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Ad Title *',
                errorText: _titleError,
                border: const OutlineInputBorder(),
              ),
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description *',
                errorText: _descriptionError,
                border: const OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ctaTextController,
              decoration: const InputDecoration(
                labelText: 'Call-to-Action Text (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., "Learn More", "Shop Now"',
              ),
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _linkUrlController,
              decoration: InputDecoration(
                labelText: 'Link URL (optional)',
                errorText: _linkUrlError,
                border: const OutlineInputBorder(),
                hintText: 'https://example.com',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactInfoController,
              decoration: const InputDecoration(
                labelText: 'Contact Info (optional)',
                border: OutlineInputBorder(),
                hintText: 'Email or phone number',
              ),
              maxLength: 100,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ad Images',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can add up to 4 images. At least one image is required.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => _buildImageSlot(index),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSlot(int index) {
    // Check if we have an existing image at this position
    final bool hasExistingImage = index < _currentImageUrls.length;
    final bool isExistingDeleted = hasExistingImage && _imageToDelete[index];
    final File? newImage = index < _newImages.length ? _newImages[index] : null;

    Widget imageWidget;
    bool hasImage = false;

    if (newImage != null) {
      // Show new image
      imageWidget = Image.file(newImage, fit: BoxFit.cover);
      hasImage = true;
    } else if (hasExistingImage && !isExistingDeleted) {
      // Show existing image
      imageWidget = Image.network(
        _currentImageUrls[index],
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          );
        },
      );
      hasImage = true;
    } else {
      // Show placeholder
      imageWidget = Container(
        color: Colors.grey[200],
        child: const Icon(
          Icons.add_photo_alternate,
          size: 48,
          color: Colors.grey,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onTap: () => _pickImage(index),
                child: imageWidget,
              ),
            ),
          ),
          if (hasImage)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 16),
                  onPressed: () => _removeImage(
                    index,
                    hasExistingImage && !isExistingDeleted,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ),
            ),
          if (isExistingDeleted)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete, color: Colors.white),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => _restoreImage(index),
                        child: const Text(
                          'Restore',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSettingCard(
            'Ad Type',
            DropdownButtonFormField<AdType>(
              value: _selectedType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: AdType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    _hasChanges = true;
                  });
                }
              },
            ),
          ),
          _buildSettingCard(
            'Ad Size',
            DropdownButtonFormField<AdSize>(
              value: _selectedSize,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: AdSize.values.map((size) {
                return DropdownMenuItem(
                  value: size,
                  child: Text(
                    '${size.displayName} - +\$${size.pricePerDay}/day',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSize = value;
                    _hasChanges = true;
                  });
                }
              },
            ),
          ),
          _buildSettingCard(
            'Ad Zone (Recommended)',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<AdZone>(
                  value: _selectedZone,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select a zone',
                  ),
                  items: AdZone.values.map((zone) {
                    return DropdownMenuItem(
                      value: zone,
                      child: Row(
                        children: [
                          Icon(zone.iconData, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${zone.displayName} - \$${zone.pricePerDay}/day',
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedZone = value;
                      _hasChanges = true;
                    });
                  },
                ),
                if (_selectedZone != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedZone!.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Expected impressions: ${_selectedZone!.expectedImpressions}/day',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildSettingCard(
            'Legacy Location (Deprecated)',
            DropdownButtonFormField<AdLocation>(
              value: _selectedLocation,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                helperText: 'Use zones instead for better targeting',
              ),
              items: AdLocation.values.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(location.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLocation = value;
                    _hasChanges = true;
                  });
                }
              },
            ),
          ),
          _buildSettingCard(
            'Duration',
            DropdownButtonFormField<AdDuration>(
              value: _selectedDuration,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: AdDuration.values.map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text(duration.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedDuration = value;
                    _hasChanges = true;
                  });
                }
              },
            ),
          ),
          _buildSettingCard(
            'Image Fit',
            DropdownButtonFormField<ImageFit>(
              value: _selectedImageFit,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ImageFit.values.map((fit) {
                return DropdownMenuItem(
                  value: fit,
                  child: Text(fit.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedImageFit = value;
                    _hasChanges = true;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(String title, Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ad Preview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildAdPreview(),
          ),
          const SizedBox(height: 16),
          _buildPreviewInfo(),
        ],
      ),
    );
  }

  Widget _buildAdPreview() {
    // Simple ad preview - this would normally use your ad display widget
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_getPreviewImageUrl() != null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: _getPreviewImageProvider()!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            _titleController.text.isNotEmpty
                ? _titleController.text
                : 'Ad Title',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : 'Ad Description',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (_ctaTextController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              child: Text(_ctaTextController.text),
            ),
          ],
        ],
      ),
    );
  }

  String? _getPreviewImageUrl() {
    // Get first available image
    for (int i = 0; i < _newImages.length; i++) {
      if (_newImages[i] != null) return 'new_image_$i';
    }

    for (int i = 0; i < _currentImageUrls.length; i++) {
      if (!_imageToDelete[i]) return _currentImageUrls[i];
    }

    return null;
  }

  ImageProvider? _getPreviewImageProvider() {
    // Get first available image provider
    for (int i = 0; i < _newImages.length; i++) {
      if (_newImages[i] != null) return FileImage(_newImages[i]!);
    }

    for (int i = 0; i < _currentImageUrls.length; i++) {
      if (!_imageToDelete[i]) return NetworkImage(_currentImageUrls[i]);
    }

    return null;
  }

  Widget _buildPreviewInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ad Configuration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Type', _selectedType.displayName),
            _buildInfoRow('Size', _selectedSize.displayName),
            if (_selectedZone != null)
              _buildInfoRow('Zone', _selectedZone!.displayName)
            else
              _buildInfoRow('Location', _selectedLocation.displayName),
            _buildInfoRow('Duration', _selectedDuration.displayName),
            _buildInfoRow(
              'Price',
              _selectedZone != null
                  ? '\$${(_selectedZone!.pricePerDay + _selectedSize.pricePerDay).toStringAsFixed(0)}/day (Zone: \$${_selectedZone!.pricePerDay} + Size: \$${_selectedSize.pricePerDay})'
                  : '\$${_selectedSize.pricePerDay}/day',
            ),
            if (_linkUrlController.text.isNotEmpty)
              _buildInfoRow('Link URL', _linkUrlController.text),
            if (_contactInfoController.text.isNotEmpty)
              _buildInfoRow('Contact', _contactInfoController.text),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

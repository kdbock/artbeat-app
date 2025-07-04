import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Screen for editing existing artwork
class ArtworkEditScreen extends StatefulWidget {
  final String artworkId;
  final ArtworkModel? artwork;

  const ArtworkEditScreen({
    super.key,
    required this.artworkId,
    this.artwork,
  });

  @override
  State<ArtworkEditScreen> createState() => _ArtworkEditScreenState();
}

class _ArtworkEditScreenState extends State<ArtworkEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _artworkService = ArtworkService();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _materialsController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _yearController = TextEditingController();
  final _tagController = TextEditingController();

  // State variables
  ArtworkModel? _artwork;
  File? _newImageFile;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isForSale = false;
  bool _isPublic = true;
  String _medium = '';
  List<String> _styles = [];
  List<String> _tags = [];

  // Available options
  final List<String> _availableMediums = [
    'Oil Paint',
    'Acrylic',
    'Watercolor',
    'Charcoal',
    'Pastel',
    'Digital',
    'Mixed Media',
    'Sculpture',
    'Photography',
    'Textiles',
    'Ceramics',
    'Printmaking',
    'Pen & Ink',
    'Pencil'
  ];

  final List<String> _availableStyles = [
    'Abstract',
    'Realism',
    'Impressionism',
    'Expressionism',
    'Minimalism',
    'Pop Art',
    'Surrealism',
    'Cubism',
    'Contemporary',
    'Folk Art',
    'Street Art',
    'Illustration',
    'Fantasy',
    'Portrait'
  ];

  @override
  void initState() {
    super.initState();
    _loadArtworkData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dimensionsController.dispose();
    _materialsController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _yearController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  /// Load artwork data
  Future<void> _loadArtworkData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use provided artwork or fetch from service
      _artwork = widget.artwork ?? await _artworkService.getArtworkById(widget.artworkId);
      
      if (_artwork != null) {
        _titleController.text = _artwork!.title;
        _descriptionController.text = _artwork!.description;
        _dimensionsController.text = _artwork!.dimensions ?? '';
        _materialsController.text = _artwork!.materials ?? '';
        _locationController.text = _artwork!.location ?? '';
        _priceController.text = _artwork!.price?.toString() ?? '';
        _yearController.text = _artwork!.yearCreated?.toString() ?? '';
        
        _isForSale = _artwork!.isForSale;
        _isPublic = _artwork!.isPublic;
        _medium = _artwork!.medium;
        _styles = List<String>.from(_artwork!.styles);
        _tags = List<String>.from(_artwork!.tags ?? []);
        
        // Set tags in text field
        _tagController.text = _tags.join(', ');
      }
    } catch (e) {
      debugPrint('Error loading artwork: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading artwork: $e')),
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

  /// Pick new image
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _newImageFile = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  /// Save artwork changes
  Future<void> _saveArtwork() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Parse tags
      _tags = _tagController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Update artwork
      await _artworkService.updateArtwork(
        artworkId: widget.artworkId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        medium: _medium,
        styles: _styles,
        tags: _tags,
        dimensions: _dimensionsController.text.trim().isEmpty 
            ? null 
            : _dimensionsController.text.trim(),
        materials: _materialsController.text.trim().isEmpty 
            ? null 
            : _materialsController.text.trim(),
        location: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
        price: _priceController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_priceController.text.trim()),
        isForSale: _isForSale,
        yearCreated: _yearController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_yearController.text.trim()),
        isPublic: _isPublic,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artwork updated successfully')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('Error updating artwork: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating artwork: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Delete artwork
  Future<void> _deleteArtwork() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Artwork'),
        content: const Text('Are you sure you want to delete this artwork? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isSaving = true;
      });

      try {
        await _artworkService.deleteArtwork(widget.artworkId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Artwork deleted successfully')),
          );
          Navigator.of(context).pop(true); // Return true to indicate deletion
        }
      } catch (e) {
        debugPrint('Error deleting artwork: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting artwork: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: const UniversalHeader(
          title: 'Edit Artwork',
          showLogo: false,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _artwork == null
                ? const Center(child: Text('Artwork not found'))
                : _buildEditForm(),
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section
            _buildImageSection(),
            const SizedBox(height: 24),
            
            // Basic information
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            
            // Medium and styles
            _buildMediumAndStylesSection(),
            const SizedBox(height: 24),
            
            // Additional details
            _buildAdditionalDetailsSection(),
            const SizedBox(height: 24),
            
            // Tags
            _buildTagsSection(),
            const SizedBox(height: 24),
            
            // Sale information
            _buildSaleInfoSection(),
            const SizedBox(height: 24),
            
            // Privacy settings
            _buildPrivacySection(),
            const SizedBox(height: 32),
            
            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Artwork Image',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _newImageFile != null
              ? Image.file(_newImageFile!, fit: BoxFit.cover)
              : _artwork!.imageUrl.isNotEmpty
                  ? Image.network(_artwork!.imageUrl, fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 64, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.photo_library),
          label: const Text('Change Image'),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title *',
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
      ],
    );
  }

  Widget _buildMediumAndStylesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Medium & Styles',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _medium.isEmpty ? null : _medium,
          decoration: const InputDecoration(
            labelText: 'Medium *',
            border: OutlineInputBorder(),
          ),
          items: _availableMediums.map((medium) {
            return DropdownMenuItem(
              value: medium,
              child: Text(medium),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _medium = value ?? '';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a medium';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text('Styles:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableStyles.map((style) {
            final isSelected = _styles.contains(style);
            return FilterChip(
              label: Text(style),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _styles.add(style);
                  } else {
                    _styles.remove(style);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAdditionalDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dimensionsController,
          decoration: const InputDecoration(
            labelText: 'Dimensions',
            hintText: 'e.g., 24" x 36"',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _materialsController,
          decoration: const InputDecoration(
            labelText: 'Materials',
            hintText: 'e.g., Canvas, Oil Paint',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Location',
            hintText: 'e.g., New York, NY',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _yearController,
          decoration: const InputDecoration(
            labelText: 'Year Created',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final year = int.tryParse(value);
              if (year == null || year < 1000 || year > DateTime.now().year) {
                return 'Please enter a valid year';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _tagController,
          decoration: const InputDecoration(
            labelText: 'Tags (comma-separated)',
            hintText: 'e.g., landscape, nature, peaceful',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildSaleInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sale Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Available for Sale'),
          value: _isForSale,
          onChanged: (value) {
            setState(() {
              _isForSale = value;
            });
          },
        ),
        if (_isForSale) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Price (\$)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_isForSale && (value == null || value.trim().isEmpty)) {
                return 'Please enter a price';
              }
              if (value != null && value.isNotEmpty) {
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Privacy Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Public Artwork'),
          subtitle: const Text('Make this artwork visible to other users'),
          value: _isPublic,
          onChanged: (value) {
            setState(() {
              _isPublic = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveArtwork,
            style: ElevatedButton.styleFrom(
              backgroundColor: ArtbeatColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Changes'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isSaving ? null : _deleteArtwork,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Delete Artwork'),
          ),
        ),
      ],
    );
  }
}
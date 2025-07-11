import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Screen for editing existing art walks
class ArtWalkEditScreen extends StatefulWidget {
  final String artWalkId;
  final ArtWalkModel? artWalk;

  const ArtWalkEditScreen({super.key, required this.artWalkId, this.artWalk});

  @override
  State<ArtWalkEditScreen> createState() => _ArtWalkEditScreenState();
}

class _ArtWalkEditScreenState extends State<ArtWalkEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _artWalkService = ArtWalkService();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  final _estimatedDistanceController = TextEditingController();

  // State variables
  ArtWalkModel? _artWalk;
  File? _newCoverImage;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isPublic = true;
  List<String> _artworkIds = [];

  @override
  void initState() {
    super.initState();
    _loadArtWalkData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _zipCodeController.dispose();
    _estimatedDurationController.dispose();
    _estimatedDistanceController.dispose();
    super.dispose();
  }

  /// Load art walk data
  Future<void> _loadArtWalkData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use provided art walk or fetch from service
      _artWalk =
          widget.artWalk ??
          await _artWalkService.getArtWalkById(widget.artWalkId);

      if (_artWalk != null) {
        _titleController.text = _artWalk!.title;
        _descriptionController.text = _artWalk!.description;
        _zipCodeController.text = _artWalk!.zipCode ?? '';
        _estimatedDurationController.text =
            _artWalk!.estimatedDuration?.toString() ?? '';
        _estimatedDistanceController.text =
            _artWalk!.estimatedDistance?.toString() ?? '';

        _isPublic = _artWalk!.isPublic;
        _artworkIds = List<String>.from(_artWalk!.artworkIds);
      }
    } catch (e) {
      debugPrint('Error loading art walk: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading art walk: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Pick new cover image
  Future<void> _pickCoverImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _newCoverImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  /// Save art walk changes including cover image
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Update art walk data
      await _artWalkService.updateArtWalk(
        walkId: widget.artWalkId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        zipCode: _zipCodeController.text.trim(),
        estimatedDuration: _estimatedDurationController.text.isNotEmpty
            ? double.parse(_estimatedDurationController.text)
            : null,
        estimatedDistance: _estimatedDistanceController.text.isNotEmpty
            ? double.parse(_estimatedDistanceController.text)
            : null,
        artworkIds: _artworkIds,
        isPublic: _isPublic,
        coverImageFile: _newCoverImage,
      );

      if (mounted) {
        Navigator.of(
          context,
        ).pop(true); // Return true to indicate successful save
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating art walk: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Delete art walk
  Future<void> _deleteArtWalk() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Art Walk'),
        content: const Text(
          'Are you sure you want to delete this art walk? This action cannot be undone.',
        ),
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
        await _artWalkService.deleteArtWalk(widget.artWalkId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Art walk deleted successfully')),
          );
          Navigator.of(context).pop(true); // Return true to indicate deletion
        }
      } catch (e) {
        debugPrint('Error deleting art walk: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting art walk: $e')),
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
        appBar: const EnhancedUniversalHeader(title: 'Edit Art Walk', showLogo: false),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _artWalk == null
            ? const Center(child: Text('Art walk not found'))
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
            // Cover image section
            _buildCoverImageSection(),
            const SizedBox(height: 24),

            // Basic information
            _buildBasicInfoSection(),
            const SizedBox(height: 24),

            // Location and details
            _buildLocationAndDetailsSection(),
            const SizedBox(height: 24),

            // Artwork selection
            _buildArtworkSection(),
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

  Widget _buildCoverImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cover Image',
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
          child: _newCoverImage != null
              ? Image.file(_newCoverImage!, fit: BoxFit.cover)
              : _artWalk!.coverImageUrl?.isNotEmpty == true
              ? Image.network(_artWalk!.coverImageUrl!, fit: BoxFit.cover)
              : const Icon(Icons.image, size: 64, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickCoverImage,
          icon: const Icon(Icons.photo_library),
          label: const Text('Change Cover Image'),
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

  Widget _buildLocationAndDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location & Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _zipCodeController,
          decoration: const InputDecoration(
            labelText: 'ZIP Code',
            hintText: 'e.g., 12345',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (value.length != 5 || int.tryParse(value) == null) {
                return 'Please enter a valid 5-digit ZIP code';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _estimatedDurationController,
          decoration: const InputDecoration(
            labelText: 'Estimated Duration (hours)',
            hintText: 'e.g., 2.5',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final duration = double.tryParse(value);
              if (duration == null || duration <= 0) {
                return 'Please enter a valid duration';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _estimatedDistanceController,
          decoration: const InputDecoration(
            labelText: 'Estimated Distance (miles)',
            hintText: 'e.g., 3.2',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final distance = double.tryParse(value);
              if (distance == null || distance <= 0) {
                return 'Please enter a valid distance';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildArtworkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Artwork Selection',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Artwork: ${_artworkIds.length} items',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Use the map or browse features to add artwork to this walk.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Navigate to artwork selection screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Artwork selection feature coming soon'),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Artwork'),
              ),
            ],
          ),
        ),
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
          title: const Text('Public Art Walk'),
          subtitle: const Text('Make this art walk visible to other users'),
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
            onPressed: _isSaving ? null : _saveChanges,
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
            onPressed: _isSaving ? null : _deleteArtWalk,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Delete Art Walk'),
          ),
        ),
      ],
    );
  }
}

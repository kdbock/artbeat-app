import 'package:artbeat_core/artbeat_core.dart'
    show CaptureModel, CaptureService, ArtistModel;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class CaptureUploadScreen extends StatefulWidget {
  final CaptureModel capture;
  final void Function(CaptureModel) onUploadComplete;

  const CaptureUploadScreen({
    super.key,
    required this.capture,
    required this.onUploadComplete,
  });

  @override
  State<CaptureUploadScreen> createState() => _CaptureUploadScreenState();
}

class _CaptureUploadScreenState extends State<CaptureUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _locationController = TextEditingController();
  final _artistController = TextEditingController();
  bool _isPublic = false;
  String? _selectedArtType;
  String? _selectedArtMedium;
  GeoPoint? _selectedLocation;
  ArtistModel? _selectedArtist;
  final CaptureService _captureService = CaptureService();
  bool _isSaving = false;
  String? _imageLoadError;

  final List<String> _artTypes = [
    'Painting',
    'Sculpture',
    'Mural',
    'Installation',
    'Performance',
    'Photography',
    'Digital Art',
    'Mixed Media',
    'Street Art',
    // Add more from the list in to_do.md as needed
  ];

  final List<String> _artMediums = [
    'Oil',
    'Acrylic',
    'Watercolor',
    'Digital',
    'Mixed Media',
    'Sculpture',
    'Photography',
    'Spray Paint',
    'Metal',
    // Add more from the list in to_do.md as needed
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _titleController.text = widget.capture.title ?? '';
    _descriptionController.text = widget.capture.description ?? '';
    _tagsController.text = widget.capture.tags?.join(', ') ?? '';
    _locationController.text = widget.capture.location != null
        ? 'Lat:  A0${widget.capture.location!.latitude}, Lng: ${widget.capture.location!.longitude}'
        : 'Location captured';
    _artistController.text = widget.capture.artistName ?? '';
    _isPublic = widget.capture.isPublic;
    _selectedArtType = widget.capture.artType;
    _selectedArtMedium = widget.capture.artMedium;
    _selectedLocation = widget.capture.location;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _locationController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canSave || _isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      // Upload image to Firebase Storage if needed
      String imageUrl = widget.capture.imageUrl;
      debugPrint('Upload: initial imageUrl = $imageUrl');
      if (imageUrl.startsWith('file://')) {
        final file = File.fromUri(Uri.parse(imageUrl));
        final fileExists = await file.exists();
        debugPrint('Upload: file.exists = $fileExists, path = \\${file.path}');
        if (!fileExists) {
          throw Exception('Image file does not exist at path: \\${file.path}');
        }
        final storagePath =
            'capture_images/${widget.capture.userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        debugPrint('Upload: Firebase Storage path = $storagePath');
        final ref = FirebaseStorage.instance.ref().child(storagePath);
        try {
          final uploadTask = ref.putFile(file);
          final snapshot = await uploadTask.whenComplete(() {});
          if (snapshot.state == TaskState.success) {
            imageUrl = await ref.getDownloadURL();
            debugPrint('Upload: uploaded to Firebase, downloadUrl = $imageUrl');
          } else {
            final error = await uploadTask.catchError((Object e) => e);
            debugPrint('Upload: uploadTask error = $error');
            throw Exception(
              'Image upload failed: \\${snapshot.state}, error: $error',
            );
          }
        } catch (e) {
          debugPrint('Upload: Firebase Storage upload exception: $e');
          rethrow;
        }
      }
      final updatedCapture = widget.capture.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        location: _selectedLocation,
        locationName: null, // Don't show address
        isPublic: _isPublic,
        artType: _selectedArtType,
        artMedium: _selectedArtMedium,
        artistName: _artistController.text.trim(),
        imageUrl: imageUrl,
      );
      final savedCapture = await _captureService.saveCapture(
        imageUrl: updatedCapture.imageUrl,
        title: updatedCapture.title ?? '',
        description: updatedCapture.description ?? '',
        artistId: updatedCapture.artistId ?? '',
        location: updatedCapture.location,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Capture saved successfully')),
        );
        Navigator.pop(context, savedCapture);
      }
    } catch (e) {
      debugPrint('❌ Error saving capture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving capture: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Check if required fields are filled
  bool get _canSave {
    if (_isSaving) return false;
    if (_titleController.text.trim().isEmpty) return false;
    if (_descriptionController.text.trim().isEmpty) return false;
    if (_imageLoadError != null) return false;
    return true;
  }

  Widget _buildImagePreview() {
    final previewUrl = widget.capture.imageUrl;
    debugPrint('Preview: using imageUrl = $previewUrl');
    if (previewUrl.isEmpty) {
      return _buildImageError('No image URL provided');
    }
    if (previewUrl.startsWith('file://')) {
      // Local file preview
      try {
        final file = File.fromUri(Uri.parse(previewUrl));
        debugPrint('Preview: displaying local file image');
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Error loading local file image: $error');
                debugPrint('Stack trace: $stackTrace');
                _imageLoadError = error.toString();
                return _buildImageError('Failed to load local image');
              },
            ),
          ),
        );
      } catch (e) {
        debugPrint('❌ Exception loading local file image: $e');
        return _buildImageError('Invalid local image path');
      }
    } else if (previewUrl.startsWith('http')) {
      // Network image preview
      debugPrint('Preview: displaying network image');
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            previewUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                _imageLoadError = null; // Clear any previous errors
                return child;
              }
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Error loading capture image: $error');
              debugPrint('Stack trace: $stackTrace');
              _imageLoadError = error.toString();
              return _buildImageError('Failed to load image');
            },
          ),
        ),
      );
    } else {
      debugPrint('❌ Unknown image URL scheme: $previewUrl');
      return _buildImageError('Unknown image URL scheme');
    }
  }

  Widget _buildImageError(String message) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.error,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              if (_imageLoadError != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _imageLoadError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Capture'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : (_canSave ? _save : null),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview Image
              _buildImagePreview(),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter a title for this artwork',
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Artist Entry (simple text field)
              TextFormField(
                controller: _artistController,
                decoration: const InputDecoration(
                  labelText: 'Artist',
                  hintText: 'Enter artist name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Art Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedArtType,
                decoration: const InputDecoration(
                  labelText: 'Art Type',
                  hintText: 'Select art type',
                ),
                items: _artTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedArtType = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Art Medium Dropdown
              DropdownButtonFormField<String>(
                value: _selectedArtMedium,
                decoration: const InputDecoration(
                  labelText: 'Art Medium',
                  hintText: 'Select medium',
                ),
                items: _artMediums
                    .map(
                      (medium) =>
                          DropdownMenuItem(value: medium, child: Text(medium)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedArtMedium = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe this artwork',
                ),
                validator: (value) => value?.isEmpty == true
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 16),

              // Tags Field
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'Enter tags separated by commas',
                ),
              ),
              const SizedBox(height: 16),

              // Location Field (auto, read-only, no address)
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Location captured',
                  suffixIcon: Icon(Icons.location_on),
                ),
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Public/Private Toggle
              SwitchListTile(
                title: const Text('Make Public'),
                subtitle: const Text(
                  'Allow this capture to be visible in public art walks',
                ),
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

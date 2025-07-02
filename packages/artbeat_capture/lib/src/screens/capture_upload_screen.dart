import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../services/storage_service.dart';
import '../services/capture_service.dart';

class CaptureUploadScreen extends StatefulWidget {
  final File imageFile;

  const CaptureUploadScreen({Key? key, required this.imageFile})
    : super(key: key);

  @override
  State<CaptureUploadScreen> createState() => _CaptureUploadScreenState();
}

class _CaptureUploadScreenState extends State<CaptureUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _photographerController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final StorageService _storageService = StorageService();
  final CaptureService _captureService = CaptureService();
  final core.UserService _userService = core.UserService();

  bool _uploading = false;
  bool _locationPermissionGranted = false;
  bool _disclaimerAccepted = false;
  Position? _currentPosition;
  String _uploadStatus = '';

  String? _selectedArtType;
  String? _selectedArtMedium;

  // Static lists to ensure they're properly initialized
  static const List<String> _artTypes = [
    'Mural',
    'Street Art',
    'Sculpture',
    'Statue',
    'Graffiti',
    'Monument',
    'Memorial',
    'Fountain',
    'Installation',
    'Mosaic',
    'Public Art',
    'Wall Art',
    'Building Art',
    'Bridge Art',
    'Park Art',
    'Garden Art',
    'Plaza Art',
    'Architecture',
    'Relief',
    'Transit Art',
    'Playground Art',
    'Community Art',
    'Cultural Art',
    'Historical Marker',
    'Signage Art',
    'Other',
    'I don\'t know',
  ];

  static const List<String> _artMediums = [
    'Paint',
    'Spray Paint',
    'Acrylic',
    'Oil Paint',
    'Watercolor',
    'Bronze',
    'Steel',
    'Iron',
    'Aluminum',
    'Copper',
    'Stone',
    'Marble',
    'Granite',
    'Limestone',
    'Concrete',
    'Brick',
    'Wood',
    'Glass',
    'Stained Glass',
    'Ceramic',
    'Tile',
    'Mosaic Tile',
    'Metal',
    'Plaster',
    'Fiberglass',
    'Resin',
    'Mixed Media',
    'Digital/LED',
    'Neon',
    'Chalk',
    'Charcoal',
    'Fabric',
    'Plastic',
    'Vinyl',
    'Paper',
    'Canvas',
    'Other',
    'Unknown',
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('CaptureUploadScreen: Art types count: ${_artTypes.length}');
    debugPrint('CaptureUploadScreen: Art mediums count: ${_artMediums.length}');
    debugPrint(
      'CaptureUploadScreen: First few art types: ${_artTypes.take(5).toList()}',
    );
    _initializeForm();
  }

  void _initializeForm() async {
    // Auto-populate photographer name from current user
    final currentUserModel = await _userService.getCurrentUserModel();
    if (currentUserModel != null && mounted) {
      _photographerController.text = currentUserModel.fullName;
    }
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permissions are permanently denied, we cannot request permissions.',
          ),
        ),
      );
      return;
    }

    // Get current location
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      setState(() {
        _locationPermissionGranted = true;
        _locationController.text =
            'Current Location (${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)})';
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
  }

  Future<void> _submitCapture() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_disclaimerAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the public art disclaimer'),
        ),
      );
      return;
    }

    setState(() {
      _uploading = true;
      _uploadStatus = 'Preparing upload...';
    });

    try {
      // Validate user is logged in
      if (_userService.currentUser?.uid == null) {
        throw Exception('User not logged in');
      }

      setState(() => _uploadStatus = 'Uploading image...');

      // Debug: Print selected values
      debugPrint('CaptureUpload: Selected art type: $_selectedArtType');
      debugPrint('CaptureUpload: Selected art medium: $_selectedArtMedium');
      debugPrint('CaptureUpload: Art types available: ${_artTypes.length}');
      debugPrint('CaptureUpload: Art mediums available: ${_artMediums.length}');

      // Upload image to storage (should work now with correct bucket)
      final imageUrl = await _storageService.uploadImage(widget.imageFile);

      // Create capture model
      final capture = core.CaptureModel(
        id: '', // Will be set by Firestore
        userId: _userService.currentUser!.uid,
        title: _titleController.text.trim(),
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        artistName: _artistController.text.trim().isEmpty
            ? null
            : _artistController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        location: _currentPosition != null
            ? GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude)
            : null,
        locationName: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        artType: _selectedArtType,
        artMedium: _selectedArtMedium,
        isPublic: true, // Since disclaimer was accepted
        tags: [], // Could be enhanced later
      );

      setState(() => _uploadStatus = 'Saving to database...');
      // Save to database
      await _captureService.createCapture(capture);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Capture uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Upload failed';

        if (e.toString().contains('Failed to upload image')) {
          errorMessage =
              'Failed to upload image. Please check your internet connection.';
        } else if (e.toString().contains('User not logged in')) {
          errorMessage = 'Please log in to upload captures.';
        } else if (e.toString().contains('permission-denied')) {
          errorMessage =
              'Permission denied. Please check your account permissions.';
        } else if (e.toString().contains('network')) {
          errorMessage =
              'Network error. Please check your internet connection.';
        } else {
          errorMessage = 'Upload failed: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: core.UniversalHeader(
        title: 'Upload Capture',
        showLogo: false,
        actions: [
          TextButton(
            onPressed: _uploading ? null : _submitCapture,
            child: _uploading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _uploadStatus.isEmpty ? 'Uploading...' : _uploadStatus,
                      ),
                    ],
                  )
                : const Text('Submit'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image preview
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(widget.imageFile, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Artist field
                  TextFormField(
                    controller: _artistController,
                    decoration: const InputDecoration(
                      labelText: 'Artist',
                      border: OutlineInputBorder(),
                      hintText: 'Leave blank if unknown',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Photographer field (auto-populated)
                  TextFormField(
                    controller: _photographerController,
                    decoration: const InputDecoration(
                      labelText: 'Photographer',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),

                  // Location field with button
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _uploading
                            ? null
                            : _requestLocationPermission,
                        icon: Icon(
                          _locationPermissionGranted
                              ? Icons.check
                              : Icons.location_on,
                        ),
                        label: Text(
                          _locationPermissionGranted
                              ? 'Located'
                              : 'Get Location',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Art Type dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedArtType,
                    decoration: const InputDecoration(
                      labelText: 'Art Type',
                      filled: true,
                      fillColor: core
                          .ArtbeatColors
                          .backgroundPrimary, // match login_screen
                      border: OutlineInputBorder(),
                    ),
                    dropdownColor: core
                        .ArtbeatColors
                        .backgroundPrimary, // match login_screen
                    style: const TextStyle(color: Colors.black),
                    isExpanded: true,
                    items: _artTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type,
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedArtType = value;
                      });
                    },
                    hint: const Text(
                      'Select art type',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Art Medium dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedArtMedium,
                    decoration: const InputDecoration(
                      labelText: 'Art Medium',
                      filled: true,
                      fillColor: core
                          .ArtbeatColors
                          .backgroundPrimary, // match login_screen
                      border: OutlineInputBorder(),
                    ),
                    dropdownColor: core
                        .ArtbeatColors
                        .backgroundPrimary, // match login_screen
                    style: const TextStyle(color: Colors.black),
                    isExpanded: true,
                    items: _artMediums.map((String medium) {
                      return DropdownMenuItem<String>(
                        value: medium,
                        child: Text(
                          medium,
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedArtMedium = value;
                      });
                    },
                    hint: const Text(
                      'Select art medium',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      hintText: 'Describe the artwork...',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Disclaimer checkbox
                  CheckboxListTile(
                    value: _disclaimerAccepted,
                    onChanged: (value) {
                      setState(() => _disclaimerAccepted = value ?? false);
                    },
                    title: const Text('Public Art Disclaimer'),
                    subtitle: const Text(
                      'I confirm this is public art in a safe, accessible location. No private property, unsafe areas, nudity, or derogatory content.',
                      style: TextStyle(fontSize: 12),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),

          // Upload overlay
          if (_uploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _uploadStatus.isEmpty
                              ? 'Uploading...'
                              : _uploadStatus,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please wait while we upload your capture',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _photographerController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

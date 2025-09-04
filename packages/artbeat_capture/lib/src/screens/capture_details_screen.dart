import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_capture/artbeat_capture.dart';

import 'capture_confirmation_screen.dart';

/// Screen for adding details about the captured art
class CaptureDetailsScreen extends StatefulWidget {
  final File imageFile;

  const CaptureDetailsScreen({Key? key, required this.imageFile})
    : super(key: key);

  @override
  State<CaptureDetailsScreen> createState() => _CaptureDetailsScreenState();
}

class _CaptureDetailsScreenState extends State<CaptureDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _photographerController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final core.UserService _userService = core.UserService();

  Position? _currentPosition;

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
        _locationController.text =
            'Current Location (${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)})';
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
  }

  void _proceedToConfirmation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Create capture model with details
    final capture = core.CaptureModel(
      id: '', // Will be set later
      userId: _userService.currentUser!.uid,
      title: _titleController.text.trim(),
      imageUrl: '', // Will be set during upload
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
      isPublic: true,
      tags: [],
      status: core.CaptureStatus.pending,
    );

    final result = await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (context) => CaptureConfirmationScreen(
          imageFile: widget.imageFile,
          captureData: capture,
        ),
      ),
    );

    // Pass the result back if capture was successful
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CaptureDrawer(),
      appBar: const core.EnhancedUniversalHeader(
        title: 'Add Details',
        showLogo: false,
        showBackButton: true,
        backgroundGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [core.ArtbeatColors.primaryPurple, Colors.pink],
        ),
        titleGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [core.ArtbeatColors.primaryPurple, Colors.pink],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(widget.imageFile, fit: BoxFit.cover),
                ),
              ),

              const SizedBox(height: 24),

              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Enter a title for this artwork',
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

              // Artist name field
              TextFormField(
                controller: _artistController,
                decoration: const InputDecoration(
                  labelText: 'Artist Name',
                  hintText: 'Enter the artist\'s name (if known)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Photographer field
              TextFormField(
                controller: _photographerController,
                decoration: const InputDecoration(
                  labelText: 'Photographer',
                  hintText: 'Your name as photographer',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),

              const SizedBox(height: 16),

              // Art type dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedArtType,
                decoration: const InputDecoration(
                  labelText: 'Art Type',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.black),
                dropdownColor: Colors.white,
                items: _artTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type,
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedArtType = newValue;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Art medium dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedArtMedium,
                decoration: const InputDecoration(
                  labelText: 'Art Medium',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.black),
                dropdownColor: Colors.white,
                items: _artMediums.map((String medium) {
                  return DropdownMenuItem<String>(
                    value: medium,
                    child: Text(
                      medium,
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedArtMedium = newValue;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the artwork (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Location section
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'Enter location or get current location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _requestLocationPermission,
                    icon: const Icon(Icons.my_location),
                    style: IconButton.styleFrom(
                      backgroundColor: core.ArtbeatColors.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: core.ArtbeatColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue to Review',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
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

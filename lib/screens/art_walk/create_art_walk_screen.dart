import 'dart:io';

import 'package:artbeat/models/public_art_model.dart';
import 'package:artbeat/services/art_walk_service.dart';
import 'package:artbeat/widgets/art_walk_info_card.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Required for GeoPoint
import 'package:geolocator/geolocator.dart'; // Added for location services
import 'package:artbeat/utils/location_utils.dart'; // Added for ZIP code utility

class CreateArtWalkScreen extends StatefulWidget {
  static const String routeName = '/create-art-walk';

  const CreateArtWalkScreen({super.key});

  @override
  _CreateArtWalkScreenState createState() => _CreateArtWalkScreenState();
}

class _CreateArtWalkScreenState extends State<CreateArtWalkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _coverImageFile;
  final List<String> _selectedArtIds = [];
  List<PublicArtModel> _availablePublicArt = [];
  bool _isLoading = false;
  bool _isPublic = true;

  final ArtWalkService _artWalkService = ArtWalkService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAvailablePublicArt();
  }

  Future<void> _loadAvailablePublicArt() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // TODO: Replace with a more appropriate method if available, e.g., getAllPublicArt()
      // Using getPublicArtNearLocation with a very large radius to fetch as much art as possible.
      // This is not ideal for performance with large datasets.
      // Consider adding a dedicated method in ArtWalkService to get all public art
      // or public art suitable for selection in an art walk.
      final artWorks = await _artWalkService.getPublicArtNearLocation(
        latitude:
            35.7796, // Default to a central NC latitude or user's current if available
        longitude:
            -78.6382, // Default to a central NC longitude or user's current if available
        radiusKm: 100000, // Large radius to capture more art
      );
      setState(() {
        _availablePublicArt = artWorks;
      });
    } catch (e) {
      print('Error loading public art: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading public art: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickCoverImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _coverImageFile = File(pickedFile.path);
      });
    }
  }

  void _toggleArtSelection(String artId) {
    setState(() {
      if (_selectedArtIds.contains(artId)) {
        _selectedArtIds.remove(artId);
      } else {
        _selectedArtIds.add(artId);
      }
    });
  }

  Future<void> _saveArtWalk() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedArtIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one art piece.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? zipCode;
    try {
      // Get current location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Location permissions are permanently denied, we cannot fetch your current location.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Get ZIP code from location
      zipCode = await LocationUtils.getZipCodeFromGeoPoint(
          GeoPoint(position.latitude, position.longitude));

      if (zipCode != null) {
        // Optionally update user's profile with this ZIP code if needed
        // await _ncLocationHelper.updateUserZipCode(zipCode);
      } else {
        print('Could not determine ZIP code from current location.');
        // Decide if you want to proceed without a ZIP code or show an error
      }
    } catch (e) {
      print('Error getting location or ZIP code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
      // Decide if you want to proceed without a ZIP code or stop
    }

    try {
      final artWalkId = await _artWalkService.createArtWalk(
        title: _titleController.text,
        description: _descriptionController.text,
        artIds: _selectedArtIds,
        coverImageFile: _coverImageFile,
        zipCode: zipCode, // Pass the determined ZIP code
        isPublic: _isPublic,
        // routePolyline, distanceKm, estimatedMinutes can be added later or calculated
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Art Walk "$artWalkId" created successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      print('Error creating art walk: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating art walk: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Art Walk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ArtWalkInfoCard(
                  onDismiss: () {
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading && _availablePublicArt.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Art Walk Title',
                        border: OutlineInputBorder(),
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
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Make this Art Walk public?'),
                        Switch(
                          value: _isPublic,
                          onChanged: (value) {
                            setState(() {
                              _isPublic = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCoverImagePicker(),
                    const SizedBox(height: 24),
                    Text(
                      'Select Public Art Pieces',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildPublicArtSelectionList(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveArtWalk,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Create Art Walk'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCoverImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cover Image (Optional)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickCoverImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _coverImageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_coverImageFile!, fit: BoxFit.cover),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Tap to select an image'),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPublicArtSelectionList() {
    if (_isLoading && _availablePublicArt.isEmpty) {
      return const Center(child: Text("Loading art pieces..."));
    }
    if (_availablePublicArt.isEmpty) {
      return const Center(
          child:
              Text('No public art found. Try adding some public art first!'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _availablePublicArt.length,
      itemBuilder: (context, index) {
        final artPiece = _availablePublicArt[index];
        final isSelected = _selectedArtIds.contains(artPiece.id);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: artPiece.imageUrl.isNotEmpty
                ? Image.network(
                    artPiece.imageUrl, // Corrected: was imageUrls[0]
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50),
                  )
                : const Icon(Icons.image_not_supported, size: 50),
            title: Text(artPiece.title),
            subtitle: Text(artPiece.artistName ??
                'Unknown Artist'), // Corrected: was artist
            trailing: Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                _toggleArtSelection(artPiece.id);
              },
            ),
            onTap: () {
              _toggleArtSelection(artPiece.id);
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

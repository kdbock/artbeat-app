import 'dart:io';

import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for GeoPoint
import 'package:image_cropper/image_cropper.dart';

// Create Art Walk specific colors
class CreateArtWalkColors {
  static const Color primaryViolet = Color(0xFF7B1FA2);
  static const Color primaryVioletLight = Color(0xFF9C27B0);
  static const Color primaryVioletDark = Color(0xFF4A148C);
  static const Color accentGold = Color(0xFFFFB300);
  static const Color accentGoldLight = Color(0xFFFFC107);
  static const Color backgroundGradientStart = Color(0xFFF3E5F5);
  static const Color backgroundGradientEnd = Color(0xFFE8EAF6);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2E0B47);
  static const Color textSecondary = Color(0xFF673AB7);
}

class CreateArtWalkScreen extends StatefulWidget {
  static const String routeName = '/create-art-walk';

  final String? artWalkId; // For editing existing art walk
  final ArtWalkModel? artWalkToEdit; // Pre-loaded art walk data

  const CreateArtWalkScreen({super.key, this.artWalkId, this.artWalkToEdit});

  @override
  State<CreateArtWalkScreen> createState() => CreateArtWalkScreenState();
}

class CreateArtWalkScreenState extends State<CreateArtWalkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _coverImageFile;
  final List<String> _selectedArtIds = [];
  List<PublicArtModel> _availablePublicArt = [];
  bool _isLoading = false;
  bool _isPublic = true;
  Position? _currentPosition; // Added for location
  final ArtWalkService _artWalkService = ArtWalkService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Initialize form if editing existing art walk
    if (widget.artWalkToEdit != null) {
      _initializeEditingMode();
    }

    // Check for passed capture and pre-select it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['capture'] != null) {
        final capture = args['capture'];
        // Try to cast to PublicArtModel or convert if needed
        if (capture is PublicArtModel) {
          setState(() {
            _selectedArtIds.add(capture.id);
          });
        } else if (capture is CaptureModel) {
          // Convert CaptureModel to PublicArtModel if needed
          final publicArt = PublicArtModel(
            id: capture.id,
            title: capture.title ?? 'Captured Art',
            artistName: capture.artistName ?? '',
            imageUrl: capture.imageUrl,
            location: capture.location ?? const GeoPoint(0, 0),
            description: capture.description ?? '',
            tags: capture.tags ?? [],
            userId: capture.userId,
            usersFavorited: const [],
            createdAt: Timestamp.fromDate(capture.createdAt),
          );
          setState(() {
            _selectedArtIds.add(publicArt.id);
            _availablePublicArt.insert(0, publicArt);
          });
        }
      }
    });
    _loadAvailablePublicArt();
    _getCurrentLocation(); // Added
  }

  void _initializeEditingMode() {
    final artWalk = widget.artWalkToEdit!;
    _titleController.text = artWalk.title;
    _descriptionController.text = artWalk.description;
    _isPublic = artWalk.isPublic;
    _selectedArtIds.addAll(artWalk.artworkIds);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Handle location services disabled...
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Handle permission denied...
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      // Handle the error appropriately...
    }
  }

  Future<void> _loadAvailablePublicArt() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Use current position if available, otherwise default to central NC
      final latitude = _currentPosition?.latitude ?? 35.7796;
      final longitude = _currentPosition?.longitude ?? -78.6382;

      // Fetch all captures (like dashboard)
      final captureService = CaptureService();
      final captures = await captureService.getAllCaptures(limit: 50);
      final List<PublicArtModel> captureArt = captures
          .map(
            (capture) => PublicArtModel(
              id: capture.id,
              title: capture.title ?? 'Captured Art',
              artistName: capture.artistName ?? '',
              imageUrl: capture.imageUrl,
              location: capture.location ?? const GeoPoint(0, 0),
              description: capture.description ?? '',
              tags: capture.tags ?? [],
              userId: capture.userId,
              usersFavorited: const [],
              createdAt: Timestamp.fromDate(capture.createdAt),
            ),
          )
          .toList();

      // Optionally, also fetch public art near location
      final publicArt = await _artWalkService.getPublicArtNearLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: 50.0,
      );

      setState(() {
        _availablePublicArt = [...publicArt, ...captureArt];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading art: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickCoverImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      // Launch cropper for optimal visual
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Cover Image',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Cover Image',
            aspectRatioLockEnabled: false,
          ),
        ],
      );
      if (croppedFile != null) {
        setState(() {
          _coverImageFile = File(croppedFile.path);
        });
      }
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final isEditing = widget.artWalkId != null;

      if (isEditing) {
        // Update existing art walk
        await _artWalkService.updateArtWalk(
          walkId: widget.artWalkId!,
          title: _titleController.text,
          description: _descriptionController.text,
          artworkIds: _selectedArtIds,
          coverImageFile: _coverImageFile,
          isPublic: _isPublic,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Art Walk updated successfully!')),
          );
          Navigator.of(context).pop();
        }
      } else {
        // Create new art walk
        // Ensure we have a location
        if (_currentPosition == null) {
          throw Exception(
            'Location not available. Please enable location services.',
          );
        }

        // Create a route data string (simplified for now)
        final routeData = _selectedArtIds.join(',');

        // Create an art walk
        final artWalkId = await _artWalkService.createArtWalk(
          title: _titleController.text,
          description: _descriptionController.text,
          artworkIds: _selectedArtIds,
          startLocation: GeoPoint(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          routeData: routeData,
          coverImageFile: _coverImageFile,
          isPublic: _isPublic,
        );

        if (mounted && artWalkId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Art Walk created successfully!')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${widget.artWalkId != null ? 'updating' : 'creating'} art walk: $e',
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.artWalkId != null ? 'Edit Art Walk' : 'Create New Art Walk',
        ),
        backgroundColor: CreateArtWalkColors.primaryViolet,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog<void>(
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CreateArtWalkColors.backgroundGradientStart,
              CreateArtWalkColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: _isLoading && _availablePublicArt.isEmpty
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
                          activeColor: CreateArtWalkColors.accentGold,
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
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: CreateArtWalkColors.accentGold,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Create Art Walk',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
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
        child: Text('No public art found. Try adding some public art first!'),
      );
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
            subtitle: Text(
              artPiece.artistName ?? 'Unknown Artist',
            ), // Corrected: was artist
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

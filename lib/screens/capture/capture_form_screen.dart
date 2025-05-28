import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

class CaptureFormScreen extends StatefulWidget {
  final XFile imageFile;
  const CaptureFormScreen({super.key, required this.imageFile});

  @override
  State<CaptureFormScreen> createState() => _CaptureFormScreenState();
}

class _CaptureFormScreenState extends State<CaptureFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _artistNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingLocation = false;
  bool _isArtCapture = false;

  Position? _currentPosition;
  String? _currentAddress;
  String? _selectedArtType;

  final List<String> _artTypes = [
    'Mural',
    'Graffiti',
    'Sculpture',
    'Installation',
    'Mosaic',
    'Street Art',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Get address from coordinates
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.locality,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        setState(() {
          _currentPosition = position;
          _currentAddress = address;
          _addressController.text = address;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get file path
      final file = File(widget.imageFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (_isArtCapture && _currentPosition != null) {
        // Handle as public art - upload to public_art_images
        final ref = FirebaseStorage.instance
            .ref()
            .child('public_art_images')
            .child(user.uid)
            .child(fileName);

        final uploadTask = await ref.putFile(file);
        final imageUrl = await uploadTask.ref.getDownloadURL();

        // Save to publicArt collection with location data
        await FirebaseFirestore.instance.collection('publicArt').add({
          'userId': user.uid,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'artistName': _artistNameController.text.trim(),
          'imageUrl': imageUrl,
          'location':
              GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
          'address': _addressController.text.trim(),
          'artType': _selectedArtType ?? 'Other',
          'tags': [], // Could add tag input later
          'isVerified': false,
          'viewCount': 0,
          'likeCount': 0,
          'usersFavorited': [user.uid],
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          // Show success message with option to view on map
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Public Art Added!'),
              content: const Text(
                  'Your art has been added to the public art collection. Would you like to view it on the map or add it to an art walk?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Later'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.of(context).pushNamed('/art-walk/map');
                  },
                  child: const Text('View on Map'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.of(context).pushNamed('/art-walk/create');
                  },
                  child: const Text('Create Art Walk'),
                ),
              ],
            ),
          );
        }
      } else {
        // Handle as regular capture
        final ref = FirebaseStorage.instance
            .ref()
            .child('capture_images')
            .child(user.uid)
            .child(fileName);

        final uploadTask = await ref.putFile(file);
        final imageUrl = await uploadTask.ref.getDownloadURL();

        // Base capture data
        final captureData = {
          'userId': user.uid,
          'imageUrl': imageUrl,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'timestamp': Timestamp.now(),
          'isPublic': true, // Default to public
        }; // Add location data if available
        if (_currentPosition != null) {
          captureData['location'] =
              GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude);

          // Only add address if not null, using proper Firestore approach
          final address = _currentAddress;
          if (address != null) {
            captureData['address'] = address;
          }
        }

        // Save metadata to Firestore
        await FirebaseFirestore.instance
            .collection('captures')
            .add(captureData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Capture uploaded successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Capture Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.file(
                    File(widget.imageFile.path),
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 16),

                  // Capture type selector
                  SwitchListTile(
                    title: const Text('This is Public Art',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                        'Enable this if you\'re capturing street art, murals, sculptures, etc.'),
                    value: _isArtCapture,
                    onChanged: (value) {
                      setState(() {
                        _isArtCapture = value;
                      });
                    },
                  ),

                  const Divider(),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic capture fields
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            hintText: 'Give your capture a title',
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Enter a title' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Describe what you captured',
                          ),
                          maxLines: 3,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Enter a description'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Location indicator
                        if (_isLoadingLocation)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else if (_currentAddress != null)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: Colors.red),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Location',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: _getCurrentLocation,
                                        child: const Text('Refresh'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentAddress!,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Get Current Location'),
                          ),

                        const SizedBox(height: 16),

                        // Additional fields for art capture
                        if (_isArtCapture) ...[
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Art Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),

                          // Artist name field
                          TextFormField(
                            controller: _artistNameController,
                            decoration: const InputDecoration(
                              labelText: 'Artist Name',
                              hintText: 'Name of the artist (if known)',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Address field
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              hintText: 'Location of the artwork',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Art type dropdown
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Art Type',
                              hintText: 'What type of art is this?',
                            ),
                            value: _selectedArtType,
                            items: _artTypes.map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              setState(() {
                                _selectedArtType = value;
                              });
                            },
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(_isArtCapture
                                ? 'Add to Art Collection'
                                : 'Submit Capture'),
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
}

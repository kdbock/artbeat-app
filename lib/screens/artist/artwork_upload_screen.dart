import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat/models/subscription_model.dart';
import 'package:artbeat/services/subscription_service.dart';

/// Screen for uploading and editing artwork
class ArtworkUploadScreen extends StatefulWidget {
  final String? artworkId; // For editing existing artwork

  const ArtworkUploadScreen({super.key, this.artworkId});

  @override
  State<ArtworkUploadScreen> createState() => _ArtworkUploadScreenState();
}

class _ArtworkUploadScreenState extends State<ArtworkUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _priceController = TextEditingController();
  final _yearController = TextEditingController();

  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  final _subscriptionService = SubscriptionService();

  File? _imageFile;
  String? _imageUrl;
  bool _isForSale = false;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _canUpload = true;
  int _artworkCount = 0;
  SubscriptionTier? _tierLevel;
  String _medium = '';
  String _style = '';
  List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();

  // Available options (would typically come from backend)
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
    _checkUploadLimit();
    if (widget.artworkId != null) {
      _loadArtworkData();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dimensionsController.dispose();
    _priceController.dispose();
    _yearController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  // Check if user can upload more artwork based on subscription
  Future<void> _checkUploadLimit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user's current subscription
      final subscription = await _subscriptionService.getUserSubscription();
      _tierLevel = subscription?.tier ?? SubscriptionTier.free;

      // Get count of user's existing artwork
      final userId = _subscriptionService.getCurrentUserId();
      if (userId != null) {
        final snapshot = await _firestore
            .collection('artwork')
            .where('userId', isEqualTo: userId)
            .get();

        _artworkCount = snapshot.docs.length;

        // Check if user can upload more artwork
        if (_tierLevel == SubscriptionTier.free && _artworkCount >= 5) {
          _canUpload = false;
        }
      }
    } catch (e) {
      print('Error checking upload limit: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Load artwork data if editing
  Future<void> _loadArtworkData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doc =
          await _firestore.collection('artwork').doc(widget.artworkId).get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Artwork not found')),
          );
          Navigator.pop(context);
        }
        return;
      }

      final data = doc.data()!;

      if (mounted) {
        setState(() {
          _titleController.text = data['title'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _dimensionsController.text = data['dimensions'] ?? '';
          _priceController.text = data['price']?.toString() ?? '';
          _yearController.text = data['year']?.toString() ?? '';
          _imageUrl = data['imageUrl'];
          _isForSale = data['isForSale'] ?? false;
          _medium = data['medium'] ?? '';
          _style = data['style'] ?? '';
          _tags = List<String>.from(data['tags'] ?? []);
        });
      }
    } catch (e) {
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

  // Pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Save artwork
  Future<void> _saveArtwork() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null && _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }
    if (_medium.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a medium')),
      );
      return;
    }
    if (_style.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a style')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = _subscriptionService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      String imageUrl = _imageUrl ?? '';

      // Upload image if changed
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      final price = _isForSale && _priceController.text.isNotEmpty
          ? double.tryParse(_priceController.text) ?? 0.0
          : 0.0;

      final year = int.tryParse(_yearController.text) ?? DateTime.now().year;

      // Create artwork data
      final artworkData = {
        'userId': userId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
        'medium': _medium,
        'style': _style,
        'dimensions': _dimensionsController.text,
        'isForSale': _isForSale,
        'price': price,
        'year': year,
        'tags': _tags,
        'likeCount': 0,
        'viewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      if (widget.artworkId != null) {
        await _firestore.collection('artwork').doc(widget.artworkId).update({
          ...artworkData,
          'createdAt':
              FieldValue.serverTimestamp(), // Keep original creation date
        });
      } else {
        await _firestore.collection('artwork').add(artworkData);
      }

      // Also add to artist's artwork subcollection
      final artistProfile =
          await _subscriptionService.getCurrentArtistProfile();
      if (artistProfile != null) {
        await _firestore
            .collection('artistProfiles')
            .doc(artistProfile.id)
            .collection('artwork')
            .doc(widget.artworkId)
            .set({
          'artworkId': widget.artworkId,
          'addedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artwork saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving artwork: $e')),
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

  // Upload image to Firebase Storage
  Future<String> _uploadImage(File imageFile) async {
    final userId = _subscriptionService.getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId';
    final artworkId = widget.artworkId ?? 'new';
    final ref =
        _storage.ref().child('artwork_images/$userId/$artworkId/$fileName');

    final uploadTask = ref.putFile(imageFile);
    final snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  // Add tag to the list
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  // Remove tag from the list
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Upload Artwork')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show upgrade prompt if user can't upload more artwork
    if (!_canUpload && widget.artworkId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Upload Artwork')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 72, color: Colors.grey),
                const SizedBox(height: 24),
                const Text(
                  'Free Plan Artwork Limit Reached',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'You\'ve reached the maximum of 5 artwork pieces for the Artist Basic Plan. '
                  'Upgrade to Artist Pro for unlimited artwork uploads.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                        context, '/artist/subscription');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Upgrade Now'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.artworkId == null ? 'Upload Artwork' : 'Edit Artwork'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artwork Image
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : _imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: _imageFile == null && _imageUrl == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_photo_alternate, size: 64),
                              SizedBox(height: 8),
                              Text('Select Image'),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
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

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Year
              TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Medium dropdown
              DropdownButtonFormField<String>(
                value: _medium.isEmpty ? null : _medium,
                decoration: const InputDecoration(
                  labelText: 'Medium',
                  border: OutlineInputBorder(),
                ),
                items: _availableMediums.map((medium) {
                  return DropdownMenuItem<String>(
                    value: medium,
                    child: Text(medium),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _medium = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a medium';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Style dropdown
              DropdownButtonFormField<String>(
                value: _style.isEmpty ? null : _style,
                decoration: const InputDecoration(
                  labelText: 'Style',
                  border: OutlineInputBorder(),
                ),
                items: _availableStyles.map((style) {
                  return DropdownMenuItem<String>(
                    value: style,
                    child: Text(style),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _style = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a style';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Dimensions
              TextFormField(
                controller: _dimensionsController,
                decoration: const InputDecoration(
                  labelText: 'Dimensions (e.g. 24" x 36")',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // For Sale switch
              SwitchListTile(
                title: const Text('Available for sale'),
                value: _isForSale,
                onChanged: (value) {
                  setState(() {
                    _isForSale = value;
                  });
                },
              ),

              // Price if for sale
              if (_isForSale)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price (USD)',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    validator: (value) {
                      if (_isForSale && (value == null || value.isEmpty)) {
                        return 'Please enter a price';
                      }
                      return null;
                    },
                  ),
                ),
              const SizedBox(height: 16),

              // Tags section
              const Text(
                'Tags',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Add tags',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. landscape, nature',
                      ),
                      onEditingComplete: _addTag,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addTag,
                    icon: const Icon(Icons.add),
                    tooltip: 'Add tag',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveArtwork,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator()
                      : Text(
                          widget.artworkId == null
                              ? 'Upload Artwork'
                              : 'Save Changes',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

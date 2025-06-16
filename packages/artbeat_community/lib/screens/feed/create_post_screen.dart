import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/community_service.dart';
import '../../services/storage_service.dart';
import 'package:artbeat_core/artbeat_core.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<File> _selectedImages = [];
  bool _isPublic = true;
  bool _isLoading = false;
  String? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    // In a real app, would use geolocator package to get actual location
    setState(() {
      _currentLocation = 'San Francisco, CA';
      _locationController.text = _currentLocation!;
    });
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();

    try {
      final List<XFile> pickedFiles = await picker.pickMultiImage();

      if (!mounted) return;

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to create a post')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get user data from UserService
      final userService = Provider.of<UserService>(context, listen: false);
      final userModel = await userService.getUserById(user.uid);

      if (!mounted) return;

      if (userModel == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User profile not found')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Upload images to Firebase Storage
      final StorageService storageService = StorageService();
      List<String> imageUrls = [];

      for (File image in _selectedImages) {
        final fileName =
            'post_${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.jpg';
        final path = 'post_images/${user.uid}/$fileName';

        final url = await storageService.uploadFile(image, path);
        if (url != null) {
          imageUrls.add(url);
        }
      }

      if (!mounted) return;

      if (imageUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload images')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Parse tags from the input
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Create GeoPoint for location (would come from actual location in a real app)
      const geoPoint = GeoPoint(37.7749, -122.4194); // Example: San Francisco

      // Create the post using community service
      final communityService =
          Provider.of<CommunityService>(context, listen: false);

      if (!mounted) return;

      final postId = await communityService.createPost(
        userId: user.uid,
        userName: userModel.fullName,
        userPhotoUrl: userModel.profileImageUrl ?? '',
        content: _contentController.text,
        imageUrls: imageUrls,
        tags: tags,
        location: _locationController.text,
        geoPoint: geoPoint,
        zipCode: '94103', // Example ZIP for San Francisco
        isPublic: _isPublic,
      );

      if (!mounted) return;

      if (postId != null) {
        Navigator.pop(context, true); // Return success to previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create post')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
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
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitPost,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image selection area
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedImages.isEmpty
                    ? Center(
                        child: TextButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add Photos'),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            _selectedImages.length + 1, // +1 for the add button
                        itemBuilder: (context, index) {
                          if (index == _selectedImages.length) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: IconButton(
                                onPressed: _pickImages,
                                icon: const Icon(Icons.add_circle),
                              ),
                            );
                          }

                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImages[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),

              // Content field
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Share your thoughts about this artwork...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please add some content to your post';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Where was this created?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please add a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tags field
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText:
                      'Add tags separated by commas (e.g. oil, portrait, abstract)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 16),

              // Privacy toggle
              SwitchListTile(
                title: const Text('Public Post'),
                subtitle: const Text('Make this post visible to everyone'),
                value: _isPublic,
                onChanged: (bool value) {
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

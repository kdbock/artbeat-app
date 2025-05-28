import 'dart:io';
import 'package:flutter/material.dart';
import 'package:artbeat/services/community_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Screen for creating a new community post
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPublic = true;
  String? _userZipCode;
  List<File> _selectedImages = [];
  
  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }
  
  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserLocation() async {
    final userId = _communityService.getCurrentUserId();
    if (userId == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
          
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        
        if (userData.containsKey('location') && userData['location'] != null) {
          setState(() {
            _locationController.text = userData['location'];
          });
        }
        
        if (userData.containsKey('zipCode') && userData['zipCode'] != null) {
          setState(() {
            _userZipCode = userData['zipCode'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user location: $e');
    }
  }
  
  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _communityService.pickPostImages();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles);
          if (_selectedImages.length > 5) {
            _selectedImages = _selectedImages.sublist(0, 5); // Limit to 5 images
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _createPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some content for your post')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final location = _locationController.text.trim();
      final tagText = _tagsController.text.trim();
      List<String> tags = [];
      
      if (tagText.isNotEmpty) {
        // Parse comma-separated or space-separated tags
        tags = tagText
            .split(RegExp(r'[,\s]'))
            .where((tag) => tag.isNotEmpty)
            .map((tag) => tag.startsWith('#') ? tag.substring(1) : tag)
            .toList();
      }
      
      await _communityService.createPost(
        content: content,
        images: _selectedImages.isNotEmpty ? _selectedImages : null,
        location: location.isNotEmpty ? location : null,
        zipCode: _userZipCode,
        tags: tags.isNotEmpty ? tags : null,
        isPublic: _isPublic,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: ${e.toString()}')),
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
  
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _createPost,
                  child: const Text('POST'),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
              ),
              maxLines: 5,
              keyboardType: TextInputType.multiline,
            ),
            if (_selectedImages.isNotEmpty) _buildSelectedImages(),
            const Divider(),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _pickImages,
                  tooltip: 'Add photos',
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () {
                    // Capture photo from camera
                  },
                  tooltip: 'Take a photo',
                ),
                IconButton(
                  icon: const Icon(Icons.tag),
                  onPressed: () {
                    // Show tags input
                    _showTagsDialog();
                  },
                  tooltip: 'Add tags',
                ),
                IconButton(
                  icon: const Icon(Icons.location_on),
                  onPressed: () {
                    // Show location input
                    _showLocationDialog();
                  },
                  tooltip: 'Add location',
                ),
                const Spacer(),
                Switch(
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                ),
                Text(_isPublic ? 'Public' : 'Private'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSelectedImages() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: FileImage(_selectedImages[index]),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 12,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _showLocationDialog() async {
    final TextEditingController controller = TextEditingController(
      text: _locationController.text,
    );
    
    final location = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Location'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter your location',
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () => Navigator.of(context).pop(controller.text),
            ),
          ],
        );
      },
    );
    
    if (location != null) {
      setState(() {
        _locationController.text = location;
      });
    }
  }
  
  Future<void> _showTagsDialog() async {
    final TextEditingController controller = TextEditingController(
      text: _tagsController.text,
    );
    
    final tags = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Tags'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Separate tags with commas',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Example: nature, photography, vacation',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () => Navigator.of(context).pop(controller.text),
            ),
          ],
        );
      },
    );
    
    if (tags != null) {
      setState(() {
        _tagsController.text = tags;
      });
    }
  }
}
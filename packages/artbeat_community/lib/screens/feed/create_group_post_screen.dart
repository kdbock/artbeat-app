import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/group_models.dart';

/// Screen for creating posts in different group types
class CreateGroupPostScreen extends StatefulWidget {
  final GroupType groupType;
  final String postType;

  const CreateGroupPostScreen({
    super.key,
    required this.groupType,
    required this.postType,
  });

  @override
  State<CreateGroupPostScreen> createState() => _CreateGroupPostScreenState();
}

class _CreateGroupPostScreenState extends State<CreateGroupPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  List<File> _selectedImages = [];
  String _selectedLocation = '';
  String _selectedMedium = '';
  String _selectedStyle = '';

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // Not a main navigation screen
      scaffoldKey: _scaffoldKey,
      appBar: EnhancedUniversalHeader(
        title: 'Create ${widget.groupType.title} Post',
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: true,
        backgroundColor: _getGroupColor(),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handlePost,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      drawer: const ArtbeatDrawer(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPostTypeHeader(),
                    const SizedBox(height: 20),
                    _buildContentField(),
                    const SizedBox(height: 20),
                    _buildSpecializedFields(),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostTypeHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getGroupColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getGroupColor().withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(_getGroupIcon(), color: _getGroupColor(), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPostTypeTitle(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getGroupColor(),
                  ),
                ),
                Text(
                  _getPostTypeDescription(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: ArtbeatColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentField() {
    return TextFormField(
      controller: _contentController,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: 'What would you like to share?',
        hintText: _getContentHint(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _getGroupColor(), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter some content';
        }
        return null;
      },
    );
  }

  Widget _buildSpecializedFields() {
    // This would contain different fields based on the group type and post type
    // For now, showing a placeholder
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Fields',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getGroupColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Specialized fields for ${widget.groupType.title} posts will be implemented here.',
            style: const TextStyle(
              fontSize: 14,
              color: ArtbeatColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Image picker button
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_a_photo),
            label: Text(
              _selectedImages.isEmpty
                  ? 'Add Photos'
                  : '${_selectedImages.length} photo(s) selected',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _getGroupColor(),
              side: BorderSide(color: _getGroupColor()),
            ),
          ),

          const SizedBox(height: 8),

          // Location button
          OutlinedButton.icon(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.location_on),
            label: Text(
              _selectedLocation.isEmpty ? 'Add Location' : 'Location added',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _getGroupColor(),
              side: BorderSide(color: _getGroupColor()),
            ),
          ),

          // Artist-specific fields
          if (widget.groupType == GroupType.artist) ...[
            const SizedBox(height: 8),

            // Medium selection
            OutlinedButton.icon(
              onPressed: _showMediumSelection,
              icon: const Icon(Icons.brush),
              label: Text(
                _selectedMedium.isEmpty ? 'Select Medium' : _selectedMedium,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _getGroupColor(),
                side: BorderSide(color: _getGroupColor()),
              ),
            ),

            const SizedBox(height: 8),

            // Style selection
            OutlinedButton.icon(
              onPressed: _showStyleSelection,
              icon: const Icon(Icons.palette),
              label: Text(
                _selectedStyle.isEmpty ? 'Select Style' : _selectedStyle,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _getGroupColor(),
                side: BorderSide(color: _getGroupColor()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handlePost,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getGroupColor(),
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Post to Community'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePost() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to create a post')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get user profile information
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final userName =
          userData['displayName'] ?? currentUser.displayName ?? 'Anonymous';
      final userPhotoUrl =
          userData['profileImageUrl'] ?? currentUser.photoURL ?? '';

      // Create the post data based on group type
      Map<String, dynamic> postData;

      if (widget.groupType == GroupType.artist) {
        // Create artist post
        postData = {
          'userId': currentUser.uid,
          'userName': userName,
          'userPhotoUrl': userPhotoUrl,
          'content': _contentController.text.trim(),
          'imageUrls': await _uploadImages(),
          'tags': _extractHashtags(_contentController.text),
          'location': _selectedLocation,
          'createdAt': FieldValue.serverTimestamp(),
          'applauseCount': 0,
          'commentCount': 0,
          'shareCount': 0,
          'isPublic': true,
          'isUserVerified': userData['isVerified'] ?? false,
          'groupType': 'artist',
          // Artist-specific fields
          'artistId': currentUser.uid,
          'artworkTitle': _getArtworkTitle(),
          'artworkDescription': _contentController.text.trim(),
          'medium': _getMedium(),
          'style': _getStyle(),
          'price': null,
          'isForSale': false,
          'techniques': <String>[],
        };
      } else {
        // For other group types, create a basic post structure
        postData = {
          'userId': currentUser.uid,
          'userName': userName,
          'userPhotoUrl': userPhotoUrl,
          'content': _contentController.text.trim(),
          'imageUrls': <String>[],
          'tags': _extractHashtags(_contentController.text),
          'location': '',
          'createdAt': FieldValue.serverTimestamp(),
          'applauseCount': 0,
          'commentCount': 0,
          'shareCount': 0,
          'isPublic': true,
          'isUserVerified': userData['isVerified'] ?? false,
          'groupType': widget.groupType.value,
        };
      }

      // Save to Firestore - use 'posts' collection so it appears in unified feed
      await FirebaseFirestore.instance.collection('posts').add(postData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.groupType.title} post created successfully!',
            ),
            backgroundColor: _getGroupColor(),
          ),
        );
        // Return true to indicate successful post creation
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error creating post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> _extractHashtags(String text) {
    final hashtagRegex = RegExp(r'#\w+');
    return hashtagRegex
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toList();
  }

  String _getArtworkTitle() {
    // Extract title from content or use post type
    switch (widget.postType) {
      case 'artwork':
        return 'New Artwork';
      case 'process':
        return 'Creative Process';
      case 'update':
        return 'Artist Update';
      default:
        return 'Untitled';
    }
  }

  String _getMedium() {
    if (_selectedMedium.isNotEmpty) {
      return _selectedMedium;
    }
    // Default fallback
    switch (widget.postType) {
      case 'artwork':
        return 'Mixed Media';
      case 'process':
        return 'Process Documentation';
      default:
        return 'Digital';
    }
  }

  String _getStyle() {
    if (_selectedStyle.isNotEmpty) {
      return _selectedStyle;
    }
    // Default fallback
    return 'Contemporary';
  }

  Color _getGroupColor() {
    switch (widget.groupType) {
      case GroupType.artist:
        return ArtbeatColors.primaryPurple;
      case GroupType.event:
        return ArtbeatColors.primaryGreen;
      case GroupType.artWalk:
        return ArtbeatColors.secondaryTeal;
      case GroupType.artistWanted:
        return ArtbeatColors.accentYellow;
    }
  }

  IconData _getGroupIcon() {
    switch (widget.groupType) {
      case GroupType.artist:
        return Icons.palette;
      case GroupType.event:
        return Icons.event;
      case GroupType.artWalk:
        return Icons.directions_walk;
      case GroupType.artistWanted:
        return Icons.work;
    }
  }

  String _getPostTypeTitle() {
    switch (widget.postType) {
      case 'artwork':
        return 'Share Artwork';
      case 'process':
        return 'Process Video';
      case 'update':
        return 'Artist Update';
      case 'hosting':
        return 'Hosting Event';
      case 'attending':
        return 'Attending Event';
      case 'photos':
        return 'Event Photos';
      case 'artwalk':
        return 'Art Walk Adventure';
      case 'route':
        return 'New Route';
      case 'project':
        return 'Project Request';
      case 'services':
        return 'Offer Services';
      default:
        return 'Create Post';
    }
  }

  String _getPostTypeDescription() {
    switch (widget.postType) {
      case 'artwork':
        return 'Share photos and details of your latest creation';
      case 'process':
        return 'Show your creative process with videos or photos';
      case 'update':
        return 'Share thoughts, updates, or announcements';
      case 'hosting':
        return 'Tell the community about an event you\'re organizing';
      case 'attending':
        return 'Share an event you\'re planning to attend';
      case 'photos':
        return 'Share photos from an art event or exhibition';
      case 'artwalk':
        return 'Share up to 5 photos from your art walk adventure';
      case 'route':
        return 'Create a new art walking route for others to follow';
      case 'project':
        return 'Describe your project and what kind of artist you need';
      case 'services':
        return 'Let others know about your availability and skills';
      default:
        return 'Share with the community';
    }
  }

  String _getContentHint() {
    switch (widget.postType) {
      case 'artwork':
        return 'Describe your artwork, inspiration, or technique...';
      case 'process':
        return 'Share details about your creative process...';
      case 'update':
        return 'What\'s on your mind? Share with fellow artists...';
      case 'hosting':
        return 'Tell us about your event - what, when, where...';
      case 'attending':
        return 'Why are you excited about this event?...';
      case 'photos':
        return 'Share your experience at this event...';
      case 'artwalk':
        return 'Describe your art walk route and discoveries...';
      case 'route':
        return 'Describe the route, highlights, and difficulty...';
      case 'project':
        return 'Describe your project, timeline, and requirements...';
      case 'services':
        return 'Describe your skills, experience, and availability...';
      default:
        return 'Share your thoughts...';
    }
  }

  /// Pick images from gallery or camera
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((xFile) => File(xFile.path)).toList();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${images.length} image(s) selected')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick images: $e')));
      }
    }
  }

  /// Upload selected images to Firebase Storage
  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];

    try {
      final storageService = EnhancedStorageService();
      final List<String> imageUrls = [];

      for (final image in _selectedImages) {
        final result = await storageService.uploadImageWithOptimization(
          imageFile: image,
          category: 'community_posts',
          generateThumbnail: true,
        );

        if (result['url'] != null) {
          imageUrls.add(result['url']!);
        }
      }

      return imageUrls;
    } catch (e) {
      debugPrint('Failed to upload images: $e');
      return [];
    }
  }

  /// Get current location
  Future<void> _getCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _selectedLocation = '${position.latitude}, ${position.longitude}';
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Location added')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    }
  }

  /// Show medium selection dialog
  Future<void> _showMediumSelection() async {
    final mediums = [
      'Oil Painting',
      'Acrylic Painting',
      'Watercolor',
      'Digital Art',
      'Photography',
      'Sculpture',
      'Mixed Media',
      'Pencil Drawing',
      'Charcoal',
      'Pastel',
      'Ink',
      'Printmaking',
      'Collage',
      'Installation',
      'Performance Art',
      'Video Art',
      'Other',
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Medium'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: mediums.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(mediums[index]),
                onTap: () => Navigator.pop(context, mediums[index]),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedMedium = selected;
      });
    }
  }

  /// Show style selection dialog
  Future<void> _showStyleSelection() async {
    final styles = [
      'Abstract',
      'Realism',
      'Impressionism',
      'Expressionism',
      'Surrealism',
      'Pop Art',
      'Minimalism',
      'Contemporary',
      'Classical',
      'Modern',
      'Street Art',
      'Folk Art',
      'Conceptual',
      'Figurative',
      'Landscape',
      'Portrait',
      'Still Life',
      'Other',
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Style'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: styles.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(styles[index]),
                onTap: () => Navigator.pop(context, styles[index]),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedStyle = selected;
      });
    }
  }
}

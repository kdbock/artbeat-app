import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_artist/artbeat_artist.dart' show SubscriptionService;
import 'package:artbeat_core/artbeat_core.dart'
    show
        SubscriptionTier,
        ArtbeatColors,
        EnhancedStorageService,
        EnhancedUniversalHeader,
        MainLayout;

/// Enhanced artwork upload screen with support for multiple media types
class EnhancedArtworkUploadScreen extends StatefulWidget {
  final String? artworkId; // For editing existing artwork
  final File? imageFile; // For new artwork from capture
  final Position? location; // For location data from capture

  const EnhancedArtworkUploadScreen({
    super.key,
    this.artworkId,
    this.imageFile,
    this.location,
  });

  @override
  State<EnhancedArtworkUploadScreen> createState() =>
      _EnhancedArtworkUploadScreenState();
}

class _EnhancedArtworkUploadScreenState
    extends State<EnhancedArtworkUploadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _materialsController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _yearController = TextEditingController();
  final _tagController = TextEditingController();
  final _hashtagController = TextEditingController();
  final _keywordController = TextEditingController();

  // Firebase instances
  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _subscriptionService = SubscriptionService();

  // State variables
  File? _mainImageFile;
  final List<File> _additionalImageFiles = [];
  final List<File> _videoFiles = [];
  final List<File> _audioFiles = [];

  String? _imageUrl;
  List<String> _additionalImageUrls = [];
  List<String> _videoUrls = [];
  List<String> _audioUrls = [];

  bool _isForSale = false;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _canUpload = true;
  int _artworkCount = 0;
  SubscriptionTier? _tierLevel;
  String _medium = '';
  List<String> _styles = [];
  List<String> _tags = [];
  List<String> _hashtags = [];
  List<String> _keywords = [];

  // Available options
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
    'Pencil',
    'Video Art',
    'Sound Art',
    'Performance Art',
    'Installation',
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
    'Portrait',
    'Landscape',
    'Still Life',
    'Conceptual',
    'Photorealistic',
  ];

  @override
  void initState() {
    super.initState();
    _checkUploadLimit();
    if (widget.artworkId != null) {
      _loadArtworkData();
    }
    if (widget.imageFile != null) {
      _mainImageFile = widget.imageFile;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dimensionsController.dispose();
    _materialsController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _yearController.dispose();
    _tagController.dispose();
    _hashtagController.dispose();
    _keywordController.dispose();
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
      _tierLevel = subscription?.tier ?? SubscriptionTier.starter;

      // Get count of user's existing artwork
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final snapshot = await _firestore
            .collection('artwork')
            .where('userId', isEqualTo: userId)
            .get();

        _artworkCount = snapshot.docs.length;

        // Check if user can upload more artwork
        if (_tierLevel == SubscriptionTier.starter && _artworkCount >= 5) {
          _canUpload = false;
        }
      }
    } catch (e) {
      // debugPrint('Error checking upload limit: $e');
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
          _titleController.text = (data['title'] ?? '').toString();
          _descriptionController.text = (data['description'] ?? '').toString();
          _dimensionsController.text = (data['dimensions'] ?? '').toString();
          _materialsController.text = (data['materials'] ?? '').toString();
          _locationController.text = (data['location'] ?? '').toString();
          _priceController.text =
              data['price'] != null ? data['price'].toString() : '';
          _yearController.text =
              data['yearCreated'] != null ? data['yearCreated'].toString() : '';
          _imageUrl = data['imageUrl'] as String?;
          _additionalImageUrls =
              (data['additionalImageUrls'] as List<dynamic>? ?? [])
                  .cast<String>();
          _videoUrls =
              (data['videoUrls'] as List<dynamic>? ?? []).cast<String>();
          _audioUrls =
              (data['audioUrls'] as List<dynamic>? ?? []).cast<String>();
          _isForSale = data['isForSale'] as bool? ?? false;
          _medium = (data['medium'] ?? '').toString();
          _styles = (data['styles'] is List
              ? (data['styles'] as List).map((e) => e.toString()).toList()
              : <String>[]);
          _tags = (data['tags'] is List
              ? (data['tags'] as List).map((e) => e.toString()).toList()
              : <String>[]);
          _hashtags = (data['hashtags'] is List
              ? (data['hashtags'] as List).map((e) => e.toString()).toList()
              : <String>[]);
          _keywords = (data['keywords'] is List
              ? (data['keywords'] as List).map((e) => e.toString()).toList()
              : <String>[]);
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

  // Pick main image - let ImagePicker handle permissions automatically
  Future<void> _pickMainImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _mainImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  // Pick additional images
  Future<void> _pickAdditionalImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _additionalImageFiles.addAll(
          result.files.map((file) => File(file.path!)).toList(),
        );
      });
    }
  }

  // Pick videos
  Future<void> _pickVideos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _videoFiles.addAll(
          result.files.map((file) => File(file.path!)).toList(),
        );
      });
    }
  }

  // Pick audio files
  Future<void> _pickAudioFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _audioFiles.addAll(
          result.files.map((file) => File(file.path!)).toList(),
        );
      });
    }
  }

  // Remove additional image
  void _removeAdditionalImage(int index) {
    setState(() {
      _additionalImageFiles.removeAt(index);
    });
  }

  // Remove video
  void _removeVideo(int index) {
    setState(() {
      _videoFiles.removeAt(index);
    });
  }

  // Remove audio file
  void _removeAudioFile(int index) {
    setState(() {
      _audioFiles.removeAt(index);
    });
  }

  // Upload file to Firebase Storage using EnhancedStorageService for images
  Future<String> _uploadFile(File file, String folder) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Use enhanced storage service for image uploads
    if (folder == 'artwork_images') {
      try {
        final enhancedStorage = EnhancedStorageService();
        final uploadResult = await enhancedStorage.uploadImageWithOptimization(
          imageFile: file,
          category: 'artwork',
          generateThumbnail: true,
        );
        return uploadResult['imageUrl']!;
      } catch (e) {
        debugPrint(
            '❌ Enhanced upload failed, falling back to legacy method: $e');
      }
    }

    // Fallback to legacy method for non-images or if enhanced upload fails
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    // Remove the problematic 'new' subdirectory
    final ref = _storage.ref().child('$folder/$userId/$fileName');

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;

    return snapshot.ref.getDownloadURL();
  }

  // Upload all media files
  Future<void> _uploadAllMedia() async {
    // Upload main image
    if (_mainImageFile != null) {
      _imageUrl = await _uploadFile(_mainImageFile!, 'artwork_images');
    }

    // Upload additional images
    for (final file in _additionalImageFiles) {
      final url = await _uploadFile(file, 'artwork_images');
      _additionalImageUrls.add(url);
    }

    // Upload videos
    for (final file in _videoFiles) {
      final url = await _uploadFile(file, 'artwork_videos');
      _videoUrls.add(url);
    }

    // Upload audio files
    for (final file in _audioFiles) {
      final url = await _uploadFile(file, 'artwork_audio');
      _audioUrls.add(url);
    }
  }

  // Save artwork
  Future<void> _saveArtwork() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mainImageFile == null && _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a main image')),
      );
      return;
    }
    if (_medium.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a medium')),
      );
      return;
    }
    if (_styles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one style')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Upload all media files
      await _uploadAllMedia();

      final price = _isForSale && _priceController.text.isNotEmpty
          ? double.tryParse(_priceController.text) ?? 0.0
          : 0.0;

      // Create artwork data
      final artworkData = {
        'userId': userId,
        'artistProfileId': userId, // For now, use userId as artistProfileId
        'title': _titleController.text,
        'description': _descriptionController.text,
        'imageUrl': _imageUrl,
        'additionalImageUrls': _additionalImageUrls,
        'videoUrls': _videoUrls,
        'audioUrls': _audioUrls,
        'medium': _medium,
        'styles': _styles,
        'dimensions': _dimensionsController.text,
        'materials': _materialsController.text,
        'location': _locationController.text,
        'isForSale': _isForSale,
        'isSold': false,
        'price': price,
        'yearCreated': int.tryParse(_yearController.text),
        'tags': _tags,
        'hashtags': _hashtags,
        'keywords': _keywords,
        'isFeatured': false,
        'isPublic': true,
        'viewCount': 0,
        'likeCount': 0,
        'commentCount': 0,
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

  // Add tag
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  // Add hashtag
  void _addHashtag() {
    final hashtag = _hashtagController.text.trim();
    if (hashtag.isNotEmpty && !_hashtags.contains(hashtag)) {
      setState(() {
        _hashtags.add(hashtag.startsWith('#') ? hashtag : '#$hashtag');
        _hashtagController.clear();
      });
    }
  }

  // Add keyword
  void _addKeyword() {
    final keyword = _keywordController.text.trim();
    if (keyword.isNotEmpty && !_keywords.contains(keyword)) {
      setState(() {
        _keywords.add(keyword);
        _keywordController.clear();
      });
    }
  }

  // Remove tag
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  // Remove hashtag
  void _removeHashtag(String hashtag) {
    setState(() {
      _hashtags.remove(hashtag);
    });
  }

  // Remove keyword
  void _removeKeyword(String keyword) {
    setState(() {
      _keywords.remove(keyword);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MainLayout(
        currentIndex: -1,
        child: Scaffold(
          appBar: EnhancedUniversalHeader(
            title: 'Upload Artwork',
            showLogo: false,
          ),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Show upgrade prompt if user can't upload more artwork
    if (!_canUpload && widget.artworkId == null) {
      return MainLayout(
        currentIndex: -1,
        child: Scaffold(
          appBar: const EnhancedUniversalHeader(
            title: 'Upload Artwork',
            showLogo: false,
          ),
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
        ),
      );
    }

    return MainLayout(
        currentIndex: -1,
        child: Scaffold(
          appBar: EnhancedUniversalHeader(
            title: widget.artworkId == null ? 'Upload Artwork' : 'Edit Artwork',
            showLogo: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Image Section
                  _buildMainImageSection(),
                  const SizedBox(height: 24),

                  // Additional Images Section
                  _buildAdditionalImagesSection(),
                  const SizedBox(height: 24),

                  // Videos Section
                  _buildVideosSection(),
                  const SizedBox(height: 24),

                  // Audio Files Section
                  _buildAudioFilesSection(),
                  const SizedBox(height: 24),

                  // Basic Information
                  _buildBasicInformation(),
                  const SizedBox(height: 24),

                  // Media and Styles
                  _buildMediaAndStyles(),
                  const SizedBox(height: 24),

                  // Tags, Hashtags, Keywords
                  _buildTagsSection(),
                  const SizedBox(height: 24),

                  // Pricing
                  _buildPricingSection(),
                  const SizedBox(height: 32),

                  // Save Button
                  _buildSaveButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildMainImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Main Image *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: _pickMainImage,
            child: Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                image: _mainImageFile != null
                    ? DecorationImage(
                        image: FileImage(_mainImageFile!),
                        fit: BoxFit.cover,
                      )
                    : _imageUrl != null && _isValidImageUrl(_imageUrl)
                        ? DecorationImage(
                            image: NetworkImage(_imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
              ),
              child: _mainImageFile == null && _imageUrl == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 64),
                        SizedBox(height: 8),
                        Text('Select Main Image'),
                      ],
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Additional Images',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _pickAdditionalImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_additionalImageFiles.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _additionalImageFiles.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(_additionalImageFiles[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeAdditionalImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (_additionalImageFiles.isEmpty)
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Text(
                'No additional images selected',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Videos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _pickVideos,
              icon: const Icon(Icons.video_library),
              label: const Text('Add Videos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_videoFiles.isNotEmpty)
          Column(
            children: _videoFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.video_file),
                  title: Text(file.path.split('/').last),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeVideo(index),
                  ),
                ),
              );
            }).toList(),
          ),
        if (_videoFiles.isEmpty)
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Text(
                'No videos selected',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAudioFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Audio Files',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _pickAudioFiles,
              icon: const Icon(Icons.audiotrack),
              label: const Text('Add Audio'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_audioFiles.isNotEmpty)
          Column(
            children: _audioFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.audio_file),
                  title: Text(file.path.split('/').last),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeAudioFile(index),
                  ),
                ),
              );
            }).toList(),
          ),
        if (_audioFiles.isEmpty)
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Text(
                'No audio files selected',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBasicInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

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

        // Year and Dimensions
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _dimensionsController,
                decoration: const InputDecoration(
                  labelText: 'Dimensions',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Materials and Location
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _materialsController,
                decoration: const InputDecoration(
                  labelText: 'Materials',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaAndStyles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Medium & Styles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Medium dropdown
        DropdownButtonFormField<String>(
          initialValue: _medium.isEmpty ? null : _medium,
          decoration: const InputDecoration(
            labelText: 'Medium',
            filled: true,
            fillColor: ArtbeatColors.backgroundPrimary,
            border: OutlineInputBorder(),
          ),
          dropdownColor: ArtbeatColors.backgroundPrimary,
          style: const TextStyle(color: Colors.black),
          items: _availableMediums.map((medium) {
            return DropdownMenuItem<String>(
              value: medium,
              child: Text(medium, style: const TextStyle(color: Colors.black)),
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

        // Styles Multi-Select
        const Text(
          'Styles',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableStyles.map((style) {
            final isSelected = _styles.contains(style);
            return FilterChip(
              label: Text(style),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _styles.add(style);
                  } else {
                    _styles.remove(style);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags, Hashtags & Keywords',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Tags
        _buildTagInput('Tags', _tagController, _tags, _addTag, _removeTag),
        const SizedBox(height: 16),

        // Hashtags
        _buildTagInput('Hashtags', _hashtagController, _hashtags, _addHashtag,
            _removeHashtag),
        const SizedBox(height: 16),

        // Keywords
        _buildTagInput('Keywords', _keywordController, _keywords, _addKeyword,
            _removeKeyword),
      ],
    );
  }

  Widget _buildTagInput(
      String label,
      TextEditingController controller,
      List<String> list,
      VoidCallback addFunction,
      void Function(String) removeFunction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Add $label',
                  border: const OutlineInputBorder(),
                  hintText: label == 'Hashtags'
                      ? 'e.g. #art, #painting'
                      : 'e.g. landscape, nature',
                ),
                onEditingComplete: addFunction,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: addFunction,
              icon: const Icon(Icons.add),
              tooltip: 'Add $label',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (list.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: list.map((item) {
              return Chip(
                label: Text(item),
                onDeleted: () => removeFunction(item),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pricing',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
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
                    ? 'Upload Enhanced Artwork'
                    : 'Save Changes',
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty || url.trim().isEmpty) return false;

    // Check for invalid file URLs
    if (url == 'file:///' || url.startsWith('file:///') && url.length <= 8) {
      return false;
    }

    // Check for just the file scheme with no actual path
    if (url == 'file://' || url == 'file:') {
      return false;
    }

    // Check for malformed URLs that start with file:// but have no host
    if (url.startsWith('file://') && !url.startsWith('file:///')) {
      return false;
    }

    // Check for valid URL schemes
    return url.startsWith('http://') ||
        url.startsWith('https://') ||
        (url.startsWith('file:///') && url.length > 8);
  }
}

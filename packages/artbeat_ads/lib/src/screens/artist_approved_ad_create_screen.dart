import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/ad_artist_approved_model.dart';
import '../models/ad_type.dart' as model;
import '../models/ad_location.dart' as model;
import '../models/ad_duration.dart';
import '../models/ad_status.dart';
import '../services/ad_artist_approved_service.dart';
import '../widgets/ad_location_picker_widget.dart';
import '../widgets/ad_duration_picker_widget.dart';
import '../widgets/ad_display_widget.dart';
import '../widgets/artist_approved_ad_widget.dart';
import '../widgets/ads_header.dart';
import '../widgets/ads_drawer.dart';

class ArtistApprovedAdCreateScreen extends StatefulWidget {
  const ArtistApprovedAdCreateScreen({super.key});

  @override
  State<ArtistApprovedAdCreateScreen> createState() =>
      _ArtistApprovedAdCreateScreenState();
}

class _ArtistApprovedAdCreateScreenState
    extends State<ArtistApprovedAdCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _taglineController = TextEditingController();
  final _ctaController = TextEditingController();
  final _destinationUrlController = TextEditingController();

  XFile? _avatarImageFile;
  final List<XFile?> _artworkImageFiles = [null, null, null, null];
  model.AdLocation _adLocation = model.AdLocation.dashboard;
  int _durationDays = 7;
  double _pricePerDay = 10.0; // Higher price for artist approved ads
  int _animationSpeed = 1000; // 1 second per image
  bool _autoPlay = true;
  bool _isProcessing = false;
  String? _error;

  final AdArtistApprovedService _adService = AdArtistApprovedService();

  @override
  void initState() {
    super.initState();
    // Set default values
    _ctaController.text = 'View Art';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _taglineController.dispose();
    _ctaController.dispose();
    _destinationUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatarImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _avatarImageFile = picked);
    }
  }

  Future<void> _pickArtworkImage(int index) async {
    if (index < 0 || index >= 4) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() => _artworkImageFiles[index] = picked);
    }
  }

  void _removeArtworkImage(int index) {
    if (index < 0 || index >= 4) return;
    setState(() => _artworkImageFiles[index] = null);
  }

  Future<String> _uploadImage(File imageFile, String folder) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileName =
          '${folder}/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) return false;

    if (_avatarImageFile == null) {
      setState(() => _error = 'Please select an avatar image');
      return false;
    }

    final selectedArtworkCount = _artworkImageFiles
        .where((file) => file != null)
        .length;
    if (selectedArtworkCount < 4) {
      setState(
        () => _error = 'Please select all 4 artwork images for the animation',
      );
      return false;
    }

    return true;
  }

  void _submitAd() async {
    if (!_validateForm()) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Upload avatar image
      final avatarUrl = await _uploadImage(
        File(_avatarImageFile!.path),
        'artist_approved_ads/avatars',
      );

      // Upload artwork images
      final List<String> artworkUrls = [];
      for (int i = 0; i < _artworkImageFiles.length; i++) {
        if (_artworkImageFiles[i] != null) {
          final url = await _uploadImage(
            File(_artworkImageFiles[i]!.path),
            'artist_approved_ads/artwork',
          );
          artworkUrls.add(url);
        }
      }

      // Create the ad
      final now = DateTime.now();
      final ad = AdArtistApprovedModel(
        id: '',
        ownerId: user.uid,
        artistId: user.uid,
        type: model.AdType.artistApproved,
        avatarImageUrl: avatarUrl,
        artworkImageUrls: artworkUrls,
        tagline: _taglineController.text.trim(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        location: _adLocation,
        duration: AdDuration(days: _durationDays),
        pricePerDay: _pricePerDay,
        startDate: now,
        endDate: now.add(Duration(days: _durationDays)),
        status: AdStatus.pending,
        destinationUrl: _destinationUrlController.text.trim().isNotEmpty
            ? _destinationUrlController.text.trim()
            : null,
        ctaText: _ctaController.text.trim().isNotEmpty
            ? _ctaController.text.trim()
            : null,
        animationSpeed: _animationSpeed,
        autoPlay: _autoPlay,
        createdAt: now,
        updatedAt: now,
      );

      await _adService.createArtistApprovedAd(ad);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artist Approved Ad submitted for review!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdsHeader(
        title: 'Create Artist Approved Ad',
        showBackButton: true,
      ),
      drawer: const AdsDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFF8FBFF),
              Color(0xFFE1F5FE),
              Color(0xFFBBDEFB),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Artist Approved Ad',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create a premium animated ad featuring your artwork. This ad will cycle through 4 of your artwork images with your artist profile.',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Avatar Image Section
                  _buildSectionHeader('Artist Avatar/Headshot'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickAvatarImage,
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: _avatarImageFile == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_add,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Add Photo',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.file(
                                File(_avatarImageFile!.path),
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Artwork Images Section
                  _buildSectionHeader(
                    'Artwork Images (4 required for animation)',
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                    itemCount: 4,
                    itemBuilder: (context, index) =>
                        _buildArtworkImagePicker(index),
                  ),

                  const SizedBox(height: 24),

                  // Basic Info
                  _buildSectionHeader('Ad Information'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Artist Name/Title',
                      hintText: 'Your artist name or title',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _taglineController,
                    decoration: const InputDecoration(
                      labelText: 'Artist Tagline',
                      hintText: 'A short tagline describing your art style',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Ad Description',
                      hintText: 'Describe your art or what viewers should know',
                    ),
                    maxLines: 3,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),

                  const SizedBox(height: 24),

                  // Animation Settings
                  _buildSectionHeader('Animation Settings'),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Auto-play Animation'),
                    subtitle: const Text(
                      'Automatically cycle through artwork images',
                    ),
                    value: _autoPlay,
                    onChanged: (value) => setState(() => _autoPlay = value),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Animation Speed:'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Slider(
                          value: _animationSpeed.toDouble(),
                          min: 500,
                          max: 3000,
                          divisions: 5,
                          label:
                              '${(_animationSpeed / 1000).toStringAsFixed(1)}s',
                          onChanged: (value) =>
                              setState(() => _animationSpeed = value.toInt()),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Call to Action
                  _buildSectionHeader('Call to Action (Optional)'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ctaController,
                    decoration: const InputDecoration(
                      labelText: 'Button Text',
                      hintText: 'e.g., "View Art", "Visit Gallery"',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _destinationUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Destination URL (Optional)',
                      hintText: 'Your website or portfolio URL',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Ad Settings
                  _buildSectionHeader('Ad Placement & Duration'),
                  const SizedBox(height: 12),
                  AdLocationPickerWidget(
                    selectedLocation: _adLocation,
                    availableLocations: model.AdLocation.values,
                    onLocationChanged: (model.AdLocation? loc) => setState(
                      () => _adLocation = loc ?? model.AdLocation.dashboard,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AdDurationPickerWidget(
                    selectedDays: _durationDays,
                    onChanged: (days) => setState(() => _durationDays = days),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Price per day:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: _pricePerDay.toStringAsFixed(2),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(prefixText: '\$'),
                          onChanged: (v) {
                            final val = double.tryParse(v);
                            if (val != null) setState(() => _pricePerDay = val);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Preview Section
                  if (_canShowPreview())
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Preview'),
                        const SizedBox(height: 12),
                        Center(child: _buildPreview()),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Error message
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _submitAd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send),
                                const SizedBox(width: 8),
                                Text(
                                  'Submit for Review (\$${(_pricePerDay * _durationDays).toStringAsFixed(2)})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildArtworkImagePicker(int index) {
    return GestureDetector(
      onTap: () => _pickArtworkImage(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _artworkImageFiles[index] == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 32,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Artwork ${index + 1}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_artworkImageFiles[index]!.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeArtworkImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
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
      ),
    );
  }

  bool _canShowPreview() {
    return _avatarImageFile != null &&
        _artworkImageFiles.where((file) => file != null).length >= 2 &&
        _titleController.text.isNotEmpty &&
        _taglineController.text.isNotEmpty;
  }

  Widget _buildPreview() {
    if (!_canShowPreview()) return const SizedBox.shrink();

    // Create a mock ad for preview
    final mockAd = AdArtistApprovedModel(
      id: 'preview',
      ownerId: 'preview',
      artistId: 'preview',
      type: model.AdType.artistApproved,
      avatarImageUrl: _avatarImageFile!.path,
      artworkImageUrls: _artworkImageFiles
          .where((file) => file != null)
          .map((file) => file!.path)
          .toList(),
      tagline: _taglineController.text.isNotEmpty
          ? _taglineController.text
          : 'Your tagline here',
      title: _titleController.text.isNotEmpty
          ? _titleController.text
          : 'Your Name',
      description: _descController.text.isNotEmpty
          ? _descController.text
          : 'Your description here',
      location: _adLocation,
      duration: AdDuration(days: _durationDays),
      pricePerDay: _pricePerDay,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: _durationDays)),
      status: AdStatus.pending,
      ctaText: _ctaController.text.isNotEmpty ? _ctaController.text : null,
      animationSpeed: _animationSpeed,
      autoPlay: _autoPlay,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return ArtistApprovedAdWidget(
      ad: mockAd,
      displayType: AdDisplayType.rectangle,
      analyticsLocation: 'preview',
    );
  }
}

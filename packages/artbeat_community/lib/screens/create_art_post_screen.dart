import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/art_community_service.dart';
import '../services/firebase_storage_service.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Simplified create post screen focused on art sharing
class CreateArtPostScreen extends StatefulWidget {
  const CreateArtPostScreen({super.key});

  @override
  State<CreateArtPostScreen> createState() => _CreateArtPostScreenState();
}

class _CreateArtPostScreenState extends State<CreateArtPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final ArtCommunityService _communityService = ArtCommunityService();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  List<File> _selectedImages = [];
  bool _isArtistPost = false;
  bool _isLoading = false;
  bool _isPickingImages = false;
  bool _isUploadingImages = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // Check if user is an artist
    _checkIfUserIsArtist();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    _communityService.dispose();
    super.dispose();
  }

  Future<void> _checkIfUserIsArtist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _communityService.getArtistProfile(user.uid);
      if (mounted && profile != null) {
        setState(() => _isArtistPost = true);
      }
    }
  }

  Future<void> _pickImages() async {
    if (_isPickingImages) return; // Prevent multiple simultaneous picks

    setState(() => _isPickingImages = true);

    final ImagePicker picker = ImagePicker();

    try {
      final List<XFile> pickedFiles = await picker.pickMultiImage(limit: 5);

      if (!mounted) return;

      if (pickedFiles.isNotEmpty) {
        if (kDebugMode) {
          print(
            '📷 DEBUG: Picked ${pickedFiles.length} files from image picker',
          );
        }

        // Validate file sizes
        final validFiles = <File>[];
        final invalidFiles = <String>[];

        for (int i = 0; i < pickedFiles.length; i++) {
          final file = pickedFiles[i];
          File imageFile = File(file.path);

          if (kDebugMode) {
            final fileSize = imageFile.lengthSync();
            final maxSize = _storageService.maxFileSizeBytes;
            print('📷 DEBUG: File $i: ${file.name}');
            print(
              '📷 DEBUG: File size: ${fileSize} bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)',
            );
            print(
              '📷 DEBUG: Max allowed: ${maxSize} bytes (${(maxSize / 1024 / 1024).toStringAsFixed(2)} MB)',
            );
            print('📷 DEBUG: Valid: ${fileSize <= maxSize}');
          }

          // If file is too large, try to compress it
          if (!_storageService.isValidFileSize(imageFile)) {
            if (kDebugMode) {
              print(
                '📷 DEBUG: File $i is too large, attempting compression...',
              );
            }

            try {
              imageFile = await _storageService.compressImage(imageFile);

              if (kDebugMode) {
                final newSize = imageFile.lengthSync();
                print(
                  '📷 DEBUG: After compression: ${(newSize / 1024 / 1024).toStringAsFixed(2)} MB',
                );
                print(
                  '📷 DEBUG: Now valid: ${_storageService.isValidFileSize(imageFile)}',
                );
              }
            } catch (e) {
              if (kDebugMode) {
                print('📷 ERROR: Compression failed for file $i: $e');
              }
            }
          }

          // Check again after potential compression
          if (_storageService.isValidFileSize(imageFile)) {
            validFiles.add(imageFile);
          } else {
            invalidFiles.add(file.name);
          }
        }

        // Show warning for invalid files
        if (invalidFiles.isNotEmpty) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Some images were too large and skipped: ${invalidFiles.join(", ")}',
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }

        // Update state with valid files
        if (kDebugMode) {
          print(
            '📷 DEBUG: Valid files: ${validFiles.length}/${pickedFiles.length}',
          );
          print(
            '📷 DEBUG: Invalid files: ${invalidFiles.length} (${invalidFiles.join(", ")})',
          );
        }

        if (validFiles.isNotEmpty) {
          setState(() {
            _selectedImages = validFiles;
          });

          if (kDebugMode) {
            print(
              '📷 DEBUG: Updated _selectedImages with ${validFiles.length} files',
            );
          }
        } else {
          if (kDebugMode) {
            print(
              '📷 DEBUG: No valid files found, _selectedImages remains empty',
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
    } finally {
      if (mounted) {
        setState(() => _isPickingImages = false);
      }
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content or images')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = [];

      // Upload images to Firebase Storage if any are selected
      if (_selectedImages.isNotEmpty) {
        if (kDebugMode) {
          print(
            '📷 DEBUG: Found ${_selectedImages.length} selected images to upload',
          );
          for (int i = 0; i < _selectedImages.length; i++) {
            print('📷 DEBUG: Image $i path: ${_selectedImages[i].path}');
          }
        }

        setState(() => _isUploadingImages = true);

        // Show upload progress
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading images...'),
            duration: Duration(seconds: 2),
          ),
        );

        // Upload all images
        imageUrls = await _storageService.uploadImages(_selectedImages);

        setState(() => _isUploadingImages = false);

        // Check if all images were uploaded successfully
        if (imageUrls.length != _selectedImages.length) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Warning: ${imageUrls.length}/${_selectedImages.length} images uploaded successfully',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      // Parse tags
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Debug: Log the image URLs before creating post
      if (kDebugMode) {
        print('🖼️ DEBUG: Creating post with ${imageUrls.length} image URLs:');
        for (int i = 0; i < imageUrls.length; i++) {
          print('🖼️ Image $i: ${imageUrls[i]}');
        }
      }

      // Create the post with real image URLs
      final postId = await _communityService.createPost(
        content: _contentController.text.trim(),
        imageUrls: imageUrls,
        tags: tags,
        isArtistPost: _isArtistPost,
      );

      if (!mounted) return;

      if (postId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to create post')));
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating post: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImages = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Your Art'),
        backgroundColor: ArtbeatColors.primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: (_isLoading || _isUploadingImages) ? null : _createPost,
            child: _isLoading || _isUploadingImages
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image picker area
            if (_selectedImages.isEmpty)
              GestureDetector(
                onTap: _isPickingImages ? null : _pickImages,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: ArtbeatColors.textSecondary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: ArtbeatColors.surface,
                  ),
                  child: _isPickingImages
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading images...'),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: ArtbeatColors.primaryPurple,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Add your artwork',
                              style: TextStyle(
                                fontSize: 16,
                                color: ArtbeatColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to select images (max 5MB each)',
                              style: TextStyle(
                                fontSize: 14,
                                color: ArtbeatColors.textSecondary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Selected Images',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (_isUploadingImages)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        TextButton.icon(
                          onPressed: (_isPickingImages || _isUploadingImages)
                              ? null
                              : _pickImages,
                          icon: const Icon(Icons.add),
                          label: const Text('Add More'),
                        ),
                    ],
                  ),
                  if (_isUploadingImages)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: ArtbeatColors.surface,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          ArtbeatColors.primaryPurple,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemExtent: 108, // 100 + 8 margin
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 100,
                          height: 100,
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  fit: BoxFit.cover,
                                  cacheWidth: 200,
                                  cacheHeight: 200,
                                ),
                              ),
                              if (_isUploadingImages)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: _isUploadingImages
                                      ? null
                                      : () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
                                          });
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
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
                ],
              ),

            const SizedBox(height: 24),

            // Content input
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell us about your art...',
                hintStyle: TextStyle(
                  color: ArtbeatColors.textSecondary.withValues(alpha: 0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ArtbeatColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: ArtbeatColors.primaryPurple,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: ArtbeatColors.surface,
              ),
            ),

            const SizedBox(height: 16),

            // Tags input
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                hintText: 'Add tags (separate with commas)',
                hintStyle: TextStyle(
                  color: ArtbeatColors.textSecondary.withValues(alpha: 0.7),
                ),
                prefixIcon: const Icon(Icons.tag),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ArtbeatColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: ArtbeatColors.primaryPurple,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: ArtbeatColors.surface,
                helperText: 'Example: painting, abstract, oil',
              ),
            ),

            const SizedBox(height: 24),

            // Artist post toggle
            if (_isArtistPost)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: ArtbeatColors.primaryPurple),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This will be posted as an artist post, showcasing your professional work.',
                        style: TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Quick tag suggestions
            const Text(
              'Quick Tags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                    'Painting',
                    'Digital Art',
                    'Photography',
                    'Sculpture',
                    'Abstract',
                    'Realism',
                    'Watercolor',
                    'Charcoal',
                    'Mixed Media',
                    'Street Art',
                  ].map((tag) {
                    return GestureDetector(
                      onTap: () {
                        final currentTags = _tagsController.text;
                        final newTag = currentTags.isEmpty
                            ? tag
                            : '$currentTags, $tag';
                        _tagsController.text = newTag;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ArtbeatColors.primaryPurple.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ArtbeatColors.primaryPurple.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 14,
                            color: ArtbeatColors.primaryPurple,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

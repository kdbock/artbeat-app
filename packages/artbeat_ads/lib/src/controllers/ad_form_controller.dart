import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ad_type.dart';
import '../models/ad_location.dart';
import '../models/ad_status.dart';
import '../services/ad_upload_service.dart';
import '../services/ad_business_service.dart';

/// Centralized controller for all ad creation forms
/// Manages form state, validation, and submission logic
class AdFormController extends ChangeNotifier {
  // Form controllers
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final ctaController = TextEditingController();
  final urlController = TextEditingController();
  final taglineController = TextEditingController();
  final destinationUrlController = TextEditingController();

  // Services
  final AdUploadService _uploadService = AdUploadService();
  final AdBusinessService _businessService = AdBusinessService();

  // Form state
  AdType _adType = AdType.square;
  AdLocation _adLocation = AdLocation.dashboard;
  int _durationDays = 7;
  double _pricePerDay = 5.0;
  bool _isProcessing = false;
  String? _error;
  double _uploadProgress = 0.0;

  // Image state
  XFile? _selectedImage;
  XFile? _avatarImage;
  final List<XFile?> _artworkImages = [null, null, null, null];

  // Animation settings (for artist approved ads)
  int _animationSpeed = 1000;
  bool _autoPlay = true;

  // Getters
  AdType get adType => _adType;
  AdLocation get adLocation => _adLocation;
  int get durationDays => _durationDays;
  double get pricePerDay => _pricePerDay;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;
  XFile? get selectedImage => _selectedImage;
  XFile? get avatarImage => _avatarImage;
  List<XFile?> get artworkImages => _artworkImages;
  int get animationSpeed => _animationSpeed;
  bool get autoPlay => _autoPlay;

  // Calculated properties
  double get totalPrice => _pricePerDay * _durationDays;
  bool get hasSelectedImage {
    if (_adType == AdType.artistApproved) {
      return _avatarImage != null &&
          _artworkImages.any((image) => image != null);
    } else {
      return _artworkImages.any((image) => image != null);
    }
  }

  bool get isFormValid => formKey.currentState?.validate() ?? false;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    ctaController.dispose();
    urlController.dispose();
    taglineController.dispose();
    destinationUrlController.dispose();
    super.dispose();
  }

  /// Initialize controller for specific ad type
  void initializeForAdType(AdType type) {
    _adType = type;
    _pricePerDay = _businessService.getPriceForAdType(type);
    _clearError();
    notifyListeners();
  }

  /// Update ad type and recalculate pricing
  void setAdType(AdType type) {
    _adType = type;
    _pricePerDay = _businessService.getPriceForAdType(type);
    notifyListeners();
  }

  /// Update ad location
  void setAdLocation(AdLocation location) {
    _adLocation = location;
    notifyListeners();
  }

  /// Update duration and recalculate pricing
  void setDuration(int days) {
    _durationDays = days;
    notifyListeners();
  }

  /// Update price per day
  void setPricePerDay(double price) {
    _pricePerDay = price;
    notifyListeners();
  }

  /// Update animation settings for artist approved ads
  void setAnimationSpeed(int speed) {
    _animationSpeed = speed;
    notifyListeners();
  }

  void setAutoPlay(bool autoPlay) {
    _autoPlay = autoPlay;
    notifyListeners();
  }

  /// Select main image
  Future<void> selectImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _selectedImage = image;
        _clearError();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to select image: $e');
    }
  }

  /// Select avatar image (for artist approved ads)
  Future<void> selectAvatarImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _avatarImage = image;
        _clearError();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to select avatar image: $e');
    }
  }

  /// Select artwork image at specific index (for artist approved ads)
  Future<void> selectArtworkImage(int index) async {
    if (index < 0 || index >= 4) return;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _artworkImages[index] = image;
        _clearError();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to select artwork image: $e');
    }
  }

  /// Remove artwork image at specific index
  void removeArtworkImage(int index) {
    if (index < 0 || index >= 4) return;
    _artworkImages[index] = null;
    notifyListeners();
  }

  /// Validate form based on ad type
  bool validateForm() {
    _clearError();

    // Basic form validation
    if (!isFormValid) {
      _setError('Please fill in all required fields');
      return false;
    }

    // Image validation based on ad type
    switch (_adType) {
      case AdType.artistApproved:
        return _validateArtistApprovedForm();
      default:
        return _validateStandardForm();
    }
  }

  bool _validateStandardForm() {
    // Check if at least one artwork image is selected
    final selectedArtworkCount = _artworkImages
        .where((image) => image != null)
        .length;

    if (selectedArtworkCount == 0) {
      _setError('Please select at least one image');
      return false;
    }
    return true;
  }

  bool _validateArtistApprovedForm() {
    if (_avatarImage == null) {
      _setError('Please select an avatar image');
      return false;
    }

    final selectedArtworkCount = _artworkImages
        .where((image) => image != null)
        .length;

    if (selectedArtworkCount < 4) {
      _setError('Please select all 4 artwork images for the animation');
      return false;
    }

    return true;
  }

  /// Submit ad form
  Future<bool> submitAd({
    required String userId,
    required String userType, // 'artist', 'gallery', 'user', 'admin'
  }) async {
    if (!validateForm()) return false;

    _setProcessing(true);

    try {
      // Upload images with progress tracking
      final uploadResults = await _uploadImages(userId, userType);

      // Create ad model based on type
      final adData = _buildAdData(userId, uploadResults);

      // Submit to appropriate service based on user type
      await _businessService.submitAd(adData, userType);

      _setProcessing(false);
      return true;
    } catch (e) {
      _setError('Failed to submit ad: $e');
      _setProcessing(false);
      return false;
    }
  }

  /// Upload all required images
  Future<Map<String, String>> _uploadImages(
    String userId,
    String userType,
  ) async {
    final results = <String, String>{};

    // Upload main image
    if (_selectedImage != null) {
      _updateProgress(0.2);
      results['imageUrl'] = await _uploadService.uploadImage(
        File(_selectedImage!.path),
        userId: userId,
        category: _getImageCategory(userType),
        onProgress: (double progress) =>
            _updateProgress(0.2 + (progress * 0.3)),
      );
    }

    // Upload avatar image (artist approved ads)
    if (_avatarImage != null) {
      _updateProgress(0.5);
      results['avatarUrl'] = await _uploadService.uploadImage(
        File(_avatarImage!.path),
        userId: userId,
        category: 'artist_approved_ads/avatars',
        onProgress: (double progress) =>
            _updateProgress(0.5 + (progress * 0.2)),
      );
    }

    // Upload artwork images
    final artworkUrls = <String>[];
    final artworkCount = _artworkImages.where((image) => image != null).length;

    for (int i = 0; i < _artworkImages.length; i++) {
      if (_artworkImages[i] != null) {
        final imageIndex = artworkUrls.length; // Current image being uploaded
        final category = _adType == AdType.artistApproved
            ? 'artist_approved_ads/artwork'
            : _getImageCategory(userType);
        final url = await _uploadService.uploadImage(
          File(_artworkImages[i]!.path),
          userId: userId,
          category: category,
          onProgress: (double progress) {
            // Calculate progress: 0.7 to 1.0 divided among all artwork images
            final baseProgress = 0.7;
            final totalArtworkProgress = 0.3;
            final progressPerImage = totalArtworkProgress / artworkCount;
            final currentProgress =
                baseProgress +
                (imageIndex * progressPerImage) +
                (progress * progressPerImage);
            _updateProgress(currentProgress.clamp(0.0, 1.0));
          },
        );
        artworkUrls.add(url);
      }
    }

    if (artworkUrls.isNotEmpty) {
      results['artworkUrls'] = artworkUrls.join(',');
    }

    _updateProgress(1.0);
    return results;
  }

  /// Build ad data map for submission
  Map<String, dynamic> _buildAdData(
    String userId,
    Map<String, String> uploadResults,
  ) {
    final baseData = {
      'ownerId': userId,
      'type': _adType.index,
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'location': _adLocation.index,
      'duration': {'days': _durationDays},
      'pricePerDay': _pricePerDay,
      'startDate': DateTime.now(),
      'endDate': DateTime.now().add(Duration(days: _durationDays)),
      'status': AdStatus.pending.index,
      'createdAt': DateTime.now(),
    };

    // Handle image URLs based on ad type
    if (_adType == AdType.artistApproved) {
      // Artist approved ads use specific URLs
      baseData.addAll(uploadResults);
    } else {
      // Standard ads (including admin) use artwork images
      if (uploadResults.containsKey('artworkUrls') &&
          uploadResults['artworkUrls'] != null) {
        final artworkUrls = uploadResults['artworkUrls']!.split(',');
        // Use first artwork image as main imageUrl for compatibility
        baseData['imageUrl'] = artworkUrls.first;
        // Also store the full list
        baseData['artworkUrls'] = uploadResults['artworkUrls']!;
      } else if (uploadResults.containsKey('imageUrl') &&
          uploadResults['imageUrl'] != null) {
        // Fallback for single image uploads
        baseData['imageUrl'] = uploadResults['imageUrl']!;
      }
    }

    // Add type-specific data
    switch (_adType) {
      case AdType.artistApproved:
        baseData.addAll({
          'tagline': taglineController.text.trim(),
          'ctaText': ctaController.text.trim(),
          'destinationUrl': destinationUrlController.text.trim(),
          'animationSpeed': _animationSpeed,
          'autoPlay': _autoPlay,
        });
        break;
      default:
        if (ctaController.text.isNotEmpty) {
          baseData['ctaText'] = ctaController.text.trim();
        }
        if (urlController.text.isNotEmpty) {
          baseData['targetUrl'] = urlController.text.trim();
        }
    }

    return baseData;
  }

  String _getImageCategory(String userType) {
    switch (userType) {
      case 'artist':
        return 'artist_ads';
      case 'gallery':
        return 'gallery_ads';
      case 'admin':
        return 'admin_ads';
      default:
        return 'user_ads';
    }
  }

  /// Reset form to initial state
  void resetForm() {
    titleController.clear();
    descriptionController.clear();
    ctaController.clear();
    urlController.clear();
    taglineController.clear();
    destinationUrlController.clear();

    _selectedImage = null;
    _avatarImage = null;
    for (int i = 0; i < _artworkImages.length; i++) {
      _artworkImages[i] = null;
    }

    _adType = AdType.square;
    _adLocation = AdLocation.dashboard;
    _durationDays = 7;
    _pricePerDay = 5.0;
    _animationSpeed = 1000;
    _autoPlay = true;

    _clearError();
    _uploadProgress = 0.0;
    notifyListeners();
  }

  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _updateProgress(double progress) {
    // Ensure progress is valid and within bounds
    if (progress.isNaN || progress.isInfinite) {
      _uploadProgress = 0.0;
    } else {
      _uploadProgress = progress.clamp(0.0, 1.0);
    }
    notifyListeners();
  }
}

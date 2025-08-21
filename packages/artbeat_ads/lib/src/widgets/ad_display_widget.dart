import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/placeholder_images.dart';
import '../models/ad_model.dart';
import '../models/ad_location.dart';
import '../services/ad_service.dart';

/// A widget that displays rotating ads, now loading real ads from Firebase
class AdDisplayWidget extends StatefulWidget {
  // Accept old parameters for compatibility but ignore them
  final String? imageUrl;
  final List<String>? artworkUrls;
  final String? title;
  final String? description;
  final String? ctaText;
  final VoidCallback? onTap;
  final dynamic displayType; // Accept any type but ignore it
  final AdLocation? location; // NEW: Location to fetch ads from

  const AdDisplayWidget({
    super.key,
    this.imageUrl,
    this.artworkUrls,
    this.title,
    this.description,
    this.ctaText,
    this.onTap,
    this.displayType,
    this.location,
  });

  @override
  State<AdDisplayWidget> createState() => _AdDisplayWidgetState();
}

class _AdDisplayWidgetState extends State<AdDisplayWidget> {
  Timer? _rotationTimer;
  int _currentImageIndex = 0;
  static const Duration _rotationInterval = Duration(seconds: 3);

  // Firebase ad loading
  final AdService _adService = AdService();
  List<AdModel> _loadedAds = [];
  int _currentAdIndex = 0;
  bool _isLoading = true;
  bool _hasError = false;
  StreamSubscription<List<AdModel>>? _adSubscription;

  @override
  void initState() {
    super.initState();
    _loadAdsFromFirebase();
  }

  void _loadAdsFromFirebase() {
    if (widget.location != null) {
      // Load real ads from Firebase for the specified location
      _adSubscription = _adService
          .getAdsByLocation(widget.location!)
          .listen(
            (ads) {
              if (mounted) {
                setState(() {
                  _loadedAds = ads;
                  _isLoading = false;
                  _hasError = false;
                  _currentAdIndex = 0;
                  _currentImageIndex = 0;
                });

                // DEBUG: Print ad details
                for (int i = 0; i < ads.length; i++) {
                  final ad = ads[i];
                  print('🔍 DEBUG Ad $i: "${ad.title}"');
                  print('   - imageUrl: ${ad.imageUrl}');
                  print('   - artworkUrls: ${ad.artworkUrls}');
                  print('   - artworkUrls length: ${ad.artworkUrls.length}');
                  print('   - artworkUrls type: ${ad.artworkUrls.runtimeType}');
                }

                // Start rotation - either real ads or placeholder fallback
                if (ads.isNotEmpty) {
                  print(
                    '🎯 Loaded ${ads.length} real ads, starting real ad rotation',
                  );
                  _startRotation();
                } else {
                  print('📦 No real ads available, using placeholder rotation');
                  _startPlaceholderRotation();
                }
              }
            },
            onError: (Object error) {
              print('🚨 Error loading ads: $error');
              if (mounted) {
                setState(() {
                  _loadedAds = [];
                  _isLoading = false;
                  _hasError = true;
                });
                // Fallback to placeholder rotation
                print(
                  '⚠️ Firebase error, falling back to placeholder rotation',
                );
                _startPlaceholderRotation();
              }
            },
          );
    } else {
      // Fallback to placeholder rotation if no location specified
      print('📍 No location specified, using placeholder rotation');
      setState(() {
        _isLoading = false;
        _loadedAds = [];
      });
      _startPlaceholderRotation();
    }
  }

  void _startRotation() {
    _stopRotation();
    if (_loadedAds.isEmpty) {
      print('⚠️ No real ads to rotate, starting placeholder fallback');
      _startPlaceholderRotation();
      return;
    }

    print('🎬 Starting real ad rotation with ${_loadedAds.length} ads');
    _rotationTimer = Timer.periodic(_rotationInterval, (timer) {
      if (mounted) {
        setState(() {
          final currentAd = _loadedAds[_currentAdIndex];
          if (currentAd.artworkUrls.isNotEmpty) {
            // Rotate through images within current ad
            _currentImageIndex =
                (_currentImageIndex + 1) % currentAd.artworkUrls.length;

            // If we've cycled through all images of current ad, move to next ad
            if (_currentImageIndex == 0 && _loadedAds.length > 1) {
              _currentAdIndex = (_currentAdIndex + 1) % _loadedAds.length;
            }
          } else {
            // Move to next ad if current one has no images
            _currentAdIndex = (_currentAdIndex + 1) % _loadedAds.length;
            _currentImageIndex = 0;
          }
        });
        print(
          '🖼️ Real ad ${_currentAdIndex + 1}/${_loadedAds.length}, image ${_currentImageIndex + 1}',
        );
      }
    });
  }

  void _startPlaceholderRotation() {
    _stopRotation();
    setState(() {
      _isLoading = false;
      _hasError = false;
      _loadedAds = []; // Ensure no real ads are mixed in
    });

    print('📦 Starting placeholder rotation');
    const int totalPlaceholderImages = 4;
    _rotationTimer = Timer.periodic(_rotationInterval, (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex =
              (_currentImageIndex + 1) % totalPlaceholderImages;
        });
        print(
          '🖼️ Placeholder image ${_currentImageIndex + 1}/$totalPlaceholderImages',
        );
      }
    });
  }

  void _stopRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
  }

  @override
  void dispose() {
    _stopRotation();
    _adSubscription?.cancel();
    super.dispose();
  }

  Widget _buildAdImage() {
    // Only show real Firebase ads if we have loaded ads
    if (_loadedAds.isNotEmpty && !_hasError) {
      final currentAd = _loadedAds[_currentAdIndex];
      if (currentAd.artworkUrls.isNotEmpty) {
        final imageUrl = currentAd.artworkUrls[_currentImageIndex];
        return CachedNetworkImage(
          key: ValueKey('real_ad_${_currentAdIndex}_${_currentImageIndex}'),
          imageUrl: imageUrl,
          width: 300,
          height: 200,
          fit: BoxFit.cover,
          placeholder: (context, url) => PlaceholderImages.generateWidget(
            300,
            200,
            index: _currentImageIndex,
          ),
          errorWidget: (context, url, error) =>
              PlaceholderImages.generateWidget(
                300,
                200,
                index: _currentImageIndex,
              ),
        );
      }
    }

    // Fallback to placeholder - only when no real ads are available
    return PlaceholderImages.generateWidget(
      300,
      200,
      index: _currentImageIndex,
      key: ValueKey('placeholder_$_currentImageIndex'),
    );
  }

  String _getCurrentAdTitle() {
    if (_loadedAds.isNotEmpty && !_hasError) {
      return _loadedAds[_currentAdIndex].title;
    }
    return 'Discover Amazing Art';
  }

  String _getCurrentAdDescription() {
    if (_loadedAds.isNotEmpty && !_hasError) {
      return _loadedAds[_currentAdIndex].description;
    }
    return 'Explore local artists and their incredible artwork';
  }

  String _getCurrentCtaText() {
    if (_loadedAds.isNotEmpty && !_hasError) {
      return _loadedAds[_currentAdIndex].ctaText ?? 'Learn More';
    }
    return 'Learn More';
  }

  void _handleAdTap() {
    if (_loadedAds.isNotEmpty) {
      final currentAd = _loadedAds[_currentAdIndex];
      print('🎯 Ad tapped: ${currentAd.title}');
      // TODO: Handle ad tap - navigate to destination URL or target
      // if (currentAd.destinationUrl != null) {
      //   launch(currentAd.destinationUrl!);
      // }
    }

    // Call the provided onTap callback
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: 300,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: 300,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Rotating ad images
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _buildAdImage(),
            ),
            // Ad content overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getCurrentAdTitle(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCurrentAdDescription(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _handleAdTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(_getCurrentCtaText()),
                    ),
                  ],
                ),
              ),
            ),
            // Image indicator dots - show based on current mode
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  _loadedAds.isNotEmpty && !_hasError
                      ? _loadedAds[_currentAdIndex].artworkUrls.length
                      : 4, // placeholder count
                  (index) {
                    return Container(
                      margin: const EdgeInsets.only(left: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/public_art_model.dart';
import '../widgets/instant_discovery_radar.dart';
import '../widgets/discovery_capture_modal.dart';

/// Full-screen Instant Discovery Radar
class InstantDiscoveryRadarScreen extends StatefulWidget {
  final Position userPosition;
  final List<PublicArtModel> initialNearbyArt;

  const InstantDiscoveryRadarScreen({
    super.key,
    required this.userPosition,
    required this.initialNearbyArt,
  });

  @override
  State<InstantDiscoveryRadarScreen> createState() =>
      _InstantDiscoveryRadarScreenState();
}

class _InstantDiscoveryRadarScreenState
    extends State<InstantDiscoveryRadarScreen> {
  late List<PublicArtModel> _nearbyArt;
  bool _hasDiscoveries = false;

  @override
  void initState() {
    super.initState();
    _nearbyArt = widget.initialNearbyArt;
  }

  Future<void> _handleArtTap(PublicArtModel art, double distance) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => DiscoveryCaptureModal(
          art: art,
          distance: distance,
          userPosition: widget.userPosition,
        ),
      ),
    );

    // If discovery was captured, remove from list and mark as having discoveries
    if (result == true && mounted) {
      setState(() {
        _nearbyArt.removeWhere((a) => a.id == art.id);
        _hasDiscoveries = true;
      });

      // If no more art nearby, show message and close
      if (_nearbyArt.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 You discovered all nearby art!'),
              duration: Duration(seconds: 2),
            ),
          );
          await Future<void>.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pop(context, true); // Return true to refresh dashboard
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Return true if discoveries were made to refresh dashboard
          Navigator.pop(context, _hasDiscoveries);
        }
      },
      child: Scaffold(
        body: InstantDiscoveryRadar(
          userPosition: widget.userPosition,
          nearbyArt: _nearbyArt,
          radiusMeters: 500,
          onArtTap: _handleArtTap,
        ),
      ),
    );
  }
}

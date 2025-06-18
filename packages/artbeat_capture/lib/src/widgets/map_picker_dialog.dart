import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerDialog extends StatefulWidget {
  final GeoPoint? initialLocation;
  final String? initialAddress;

  const MapPickerDialog({
    super.key,
    this.initialLocation,
    this.initialAddress,
  });

  @override
  State<MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<MapPickerDialog> {
  late GoogleMapController _controller;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
    }
    _selectedAddress = widget.initialAddress;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      _controller.animateCamera(CameraUpdate.newLatLng(latLng));
      await _updateSelectedLocation(latLng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get current location')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSelectedLocation(LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _isLoading = true;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _selectedAddress = [
          if (place.name?.isNotEmpty == true) place.name,
          if (place.locality?.isNotEmpty == true) place.locality,
          if (place.administrativeArea?.isNotEmpty == true)
            place.administrativeArea,
        ].join(', ');
      }
    } catch (e) {
      _selectedAddress = 'Location selected';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Location'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (_selectedLocation != null)
              TextButton(
                onPressed: () => Navigator.of(context).pop({
                  'location': GeoPoint(
                    _selectedLocation!.latitude,
                    _selectedLocation!.longitude,
                  ),
                  'address': _selectedAddress,
                }),
                child: const Text('Select'),
              ),
          ],
        ),
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation ??
                    const LatLng(37.7749, -122.4194), // Default to SF
                zoom: 15,
              ),
              onMapCreated: (controller) => _controller = controller,
              markers: _selectedLocation == null
                  ? {}
                  : {
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: _selectedLocation!,
                      ),
                    },
              onTap: _updateSelectedLocation,
            ),
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: null,
                onPressed: _isLoading ? null : _getCurrentLocation,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.my_location),
              ),
            ),
            if (_selectedAddress != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _selectedAddress!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

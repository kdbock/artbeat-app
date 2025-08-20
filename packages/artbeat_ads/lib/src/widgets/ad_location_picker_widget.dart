import 'package:flutter/material.dart';
import '../models/ad_location.dart';

/// Widget for picking ad location - simplified for new enum
class AdLocationPickerWidget extends StatelessWidget {
  final AdLocation? selectedLocation;
  final List<AdLocation> availableLocations;
  final ValueChanged<AdLocation?> onLocationChanged;
  final String? errorText;

  const AdLocationPickerWidget({
    super.key,
    this.selectedLocation,
    required this.availableLocations,
    required this.onLocationChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ad Location',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<AdLocation>(
          value: selectedLocation,
          decoration: InputDecoration(
            labelText: 'Select Location',
            border: const OutlineInputBorder(),
            errorText: errorText,
          ),
          style: const TextStyle(color: Colors.black),
          items: availableLocations.map((location) {
            return DropdownMenuItem(
              value: location,
              child: Text(
                _getLocationDisplayName(location),
                style: const TextStyle(color: Colors.black),
              ),
            );
          }).toList(),
          onChanged: onLocationChanged,
          validator: (value) {
            if (value == null) {
              return 'Please select a location';
            }
            return null;
          },
        ),
      ],
    );
  }

  String _getLocationDisplayName(AdLocation location) {
    switch (location) {
      case AdLocation.dashboard:
        return 'Dashboard';
      case AdLocation.artWalkDashboard:
        return 'Art Walk Dashboard';
      case AdLocation.captureDashboard:
        return 'Capture Dashboard';
      case AdLocation.communityDashboard:
        return 'Community Dashboard';
      case AdLocation.eventsDashboard:
        return 'Events Dashboard';
      case AdLocation.communityFeed:
        return 'Community Feed';
    }
  }
}

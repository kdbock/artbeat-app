import 'package:flutter/material.dart';

/// Widget to pick ad display location (industry standard: e.g., Home, Discover, Profile, etc.)
class AdLocationPickerWidget extends StatelessWidget {
  final String selectedLocation;
  final List<String> availableLocations;
  final ValueChanged<String> onChanged;

  const AdLocationPickerWidget({
    super.key,
    required this.selectedLocation,
    required this.availableLocations,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Location:'),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: selectedLocation,
          items: availableLocations
              .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ],
    );
  }
}

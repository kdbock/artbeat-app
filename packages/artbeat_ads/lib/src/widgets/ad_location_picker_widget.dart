import 'package:flutter/material.dart';
import '../models/ad_location.dart' as model;

class AdLocationPickerWidget extends StatelessWidget {
  final model.AdLocation selectedLocation;
  final List<model.AdLocation> availableLocations;
  final ValueChanged<model.AdLocation> onChanged;

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
        DropdownButton<model.AdLocation>(
          value: selectedLocation,
          items: availableLocations
              .map(
                (model.AdLocation loc) =>
                    DropdownMenuItem(value: loc, child: Text(loc.name)),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ],
    );
  }
}

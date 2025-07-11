import 'package:flutter/material.dart';
import '../models/ad_type.dart' as model;

class AdTypePickerWidget extends StatelessWidget {
  final model.AdType selectedType;
  final ValueChanged<model.AdType> onChanged;

  const AdTypePickerWidget({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Ad Type:'),
        const SizedBox(width: 8),
        DropdownButton<model.AdType>(
          value: selectedType,
          items: const [
            DropdownMenuItem(
              value: model.AdType.square,
              child: Text('Square (1:1)'),
            ),
            DropdownMenuItem(
              value: model.AdType.rectangle,
              child: Text('Rectangle (2:1)'),
            ),
          ],
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ],
    );
  }
}

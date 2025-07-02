import 'package:flutter/material.dart';

/// Widget to pick ad type (square or rectangle, industry standard sizes)
enum AdType { square, rectangle }

class AdTypePickerWidget extends StatelessWidget {
  final AdType selectedType;
  final ValueChanged<AdType> onChanged;

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
        DropdownButton<AdType>(
          value: selectedType,
          items: const [
            DropdownMenuItem(value: AdType.square, child: Text('Square (1:1)')),
            DropdownMenuItem(
              value: AdType.rectangle,
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

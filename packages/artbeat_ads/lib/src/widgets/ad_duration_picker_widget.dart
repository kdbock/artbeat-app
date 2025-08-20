import 'package:flutter/material.dart';

/// Widget to pick ad duration in days (industry standard: 1-30 days)
class AdDurationPickerWidget extends StatelessWidget {
  final int selectedDays;
  final ValueChanged<int> onChanged;
  final int minDays;
  final int maxDays;

  const AdDurationPickerWidget({
    super.key,
    required this.selectedDays,
    required this.onChanged,
    this.minDays = 1,
    this.maxDays = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Duration:'),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: selectedDays,
          style: const TextStyle(color: Colors.black),
          items: List.generate(
            maxDays - minDays + 1,
            (i) => DropdownMenuItem(
              value: minDays + i,
              child: Text(
                '${minDays + i} day${minDays + i == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ],
    );
  }
}

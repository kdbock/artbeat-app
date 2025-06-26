import 'package:flutter/material.dart';
import '../../models/filter_types.dart';

class SortFilter extends StatelessWidget {
  final SortOption currentSort;
  final bool ascending;
  final void Function(SortOption, bool) onSortChanged;

  const SortFilter({
    super.key,
    required this.currentSort,
    required this.ascending,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sort By',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...SortOption.values.map((option) {
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(option.displayName),
                    if (currentSort == option) ...[
                      const SizedBox(width: 4),
                      Icon(
                        ascending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                selected: currentSort == option,
                onSelected: (selected) {
                  if (selected) {
                    if (currentSort == option) {
                      // Toggle direction if same option selected
                      onSortChanged(option, !ascending);
                    } else {
                      // New option selected, use default direction
                      onSortChanged(option, true);
                    }
                  }
                },
              );
            }),
          ],
        ),
      ],
    );
  }
}

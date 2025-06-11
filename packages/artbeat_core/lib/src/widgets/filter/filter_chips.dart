import 'package:flutter/material.dart';

class FilterChips<T> extends StatelessWidget {
  final List<T> options;
  final List<T> selected;
  final String Function(T) getLabel;
  final Function(List<T>) onSelectionChanged;

  const FilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.getLabel,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(
            getLabel(option),
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          selected: isSelected,
          onSelected: (isSelected) {
            final newSelection = List<T>.from(selected);
            if (isSelected) {
              newSelection.add(option);
            } else {
              newSelection.remove(option);
            }
            onSelectionChanged(newSelection);
          },
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedColor: Theme.of(context).colorScheme.primary,
          checkmarkColor: Theme.of(context).colorScheme.onPrimary,
          showCheckmark: true,
          elevation: 0,
          pressElevation: 2,
        );
      }).toList(),
    );
  }
}

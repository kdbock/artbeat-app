import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangeFilter extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime?, DateTime?) onDateRangeChanged;

  const DateRangeFilter({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DatePickerField(
                label: 'Start Date',
                date: startDate,
                onDateSelected: (date) {
                  onDateRangeChanged(date, endDate);
                },
                dateFormat: dateFormat,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _DatePickerField(
                label: 'End Date',
                date: endDate,
                onDateSelected: (date) {
                  onDateRangeChanged(startDate, date);
                },
                dateFormat: dateFormat,
                minimumDate: startDate,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final void Function(DateTime?) onDateSelected;
  final DateFormat dateFormat;
  final DateTime? minimumDate;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onDateSelected,
    required this.dateFormat,
    this.minimumDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: minimumDate ?? DateTime(2000),
          lastDate: DateTime(2100),
        );
        onDateSelected(selected);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: date != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onDateSelected(null),
                )
              : const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null ? dateFormat.format(date!) : 'Select date',
          style: date != null
              ? null
              : TextStyle(color: Theme.of(context).hintColor),
        ),
      ),
    );
  }
}

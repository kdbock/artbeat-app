import 'package:flutter/material.dart';
import '../services/moderation_service.dart';

/// Dialog for reporting content or users
class ReportDialog extends StatefulWidget {
  final String reportedUserId;
  final String contentId;
  final String contentType;
  final String? reportingUserId;
  final VoidCallback? onReportSubmitted;

  const ReportDialog({
    super.key,
    required this.reportedUserId,
    required this.contentId,
    required this.contentType,
    this.reportingUserId,
    this.onReportSubmitted,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final ModerationService _moderationService = ModerationService();
  final TextEditingController _descriptionController = TextEditingController();
  ReportReason? _selectedReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await _moderationService.reportContent(
        reportedUserId: widget.reportedUserId,
        contentId: widget.contentId,
        contentType: widget.contentType,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
        reportingUserId: widget.reportingUserId,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report submitted. Thank you for helping keep our community safe.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
          widget.onReportSubmitted?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit report. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Content'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please tell us why you\'re reporting this content:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            DropdownButton<ReportReason>(
              isExpanded: true,
              value: _selectedReason,
              hint: const Text('Select a reason'),
              items: ReportReason.values.map((reason) {
                return DropdownMenuItem(
                  value: reason,
                  child: Text(reason.displayName),
                );
              }).toList(),
              onChanged: (ReportReason? value) {
                setState(() => _selectedReason = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Additional details (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Report'),
        ),
      ],
    );
  }
}

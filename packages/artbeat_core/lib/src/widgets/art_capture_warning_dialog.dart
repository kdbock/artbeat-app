import 'package:flutter/material.dart';

class ArtCaptureWarningDialog extends StatelessWidget {
  const ArtCaptureWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Art Capture Guidelines'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please follow these guidelines when capturing art:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('• Only capture art in public spaces'),
            Text('• Do not photograph private property'),
            Text('• Respect "No Photography" signs'),
            Text('• Ask permission when photographing commissioned works'),
            Text('• Credit artists when known'),
            SizedBox(height: 16),
            Text(
              'By proceeding, you confirm that you will follow these guidelines.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('I Understand'),
        ),
      ],
    );
  }
}

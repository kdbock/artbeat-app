import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'voice_recorder_widget.dart';
import '../services/voice_recording_service.dart';

class AttachmentButton extends StatelessWidget {
  final void Function(XFile) onImageSelected;
  final void Function(XFile) onVideoSelected;
  final void Function(XFile) onFileSelected;
  final void Function(String voiceFilePath, Duration duration)? onVoiceRecorded;

  const AttachmentButton({
    super.key,
    required this.onImageSelected,
    required this.onVideoSelected,
    required this.onFileSelected,
    this.onVoiceRecorded,
  });

  Future<void> _showAttachmentOptions(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  onImageSelected(image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? video = await picker.pickVideo(
                  source: ImageSource.gallery,
                );
                if (video != null) {
                  onVideoSelected(video);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('File'),
              onTap: () async {
                Navigator.pop(context);
                // Implement file picking logic
              },
            ),
            if (onVoiceRecorded != null)
              ListTile(
                leading: const Icon(Icons.mic),
                title: const Text('Voice Message'),
                onTap: () {
                  Navigator.pop(context);
                  _showVoiceRecorder(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showVoiceRecorder(BuildContext context) async {
    // Pre-check permissions and initialize service
    final service = VoiceRecordingService();

    try {
      log('🔧 Initializing voice recording service...');
      await service.initialize();
      log('✅ Voice recording service initialized');

      // Check permissions upfront
      log('🔐 Pre-checking microphone permissions...');
      final permissionResult = await service.checkMicrophonePermission();
      log('🔍 Pre-check permission result: $permissionResult');

      if (permissionResult == PermissionResult.permanentlyDenied) {
        log('🚫 Permission permanently denied, showing settings dialog');
        _showPermissionSettingsDialog(context, service);
        return;
      }
    } catch (e) {
      log('❌ Failed to initialize voice recording service: $e');
      _showInitializationErrorDialog(context);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeNotifierProvider.value(
        value: service,
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: VoiceRecorderWidget(
            onVoiceRecorded: (voiceFilePath, duration) {
              Navigator.pop(context);
              onVoiceRecorded?.call(voiceFilePath, duration);
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  void _showPermissionSettingsDialog(
    BuildContext context,
    VoiceRecordingService service,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Microphone Permission Required'),
          content: const Text(
            'ARTbeat needs microphone access to record voice messages. '
            'Please go to Settings > ARTbeat > Microphone and enable access.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await service.openDeviceSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showInitializationErrorDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Voice Recording Unavailable'),
          content: const Text(
            'Unable to initialize voice recording. Please check your device settings and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.attach_file),
      onPressed: () => _showAttachmentOptions(context),
    );
  }
}

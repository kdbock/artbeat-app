import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AttachmentButton extends StatelessWidget {
  final Function(XFile) onImageSelected;
  final Function(XFile) onVideoSelected;
  final Function(XFile) onFileSelected;

  const AttachmentButton({
    super.key,
    required this.onImageSelected,
    required this.onVideoSelected,
    required this.onFileSelected,
  });

  Future<void> _showAttachmentOptions(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    await showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
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
              ],
            ),
          ),
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

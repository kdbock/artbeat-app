import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show ArtbeatColors, EnhancedUniversalHeader, MainLayout;

class UploadChoiceScreen extends StatelessWidget {
  const UploadChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 2,
      child: SingleChildScrollView(
        child: Column(
          children: [
            EnhancedUniversalHeader(
              title: 'upload_choice_title'.tr(),
              showBackButton: true,
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  UploadOptionCard(
                    icon: Icons.image_outlined,
                    title: 'upload_choice_visual_title'.tr(),
                    description: 'upload_choice_visual_desc'.tr(),
                    color: ArtbeatColors.primaryGreen,
                    onTap: () {
                      Navigator.of(context).pushNamed('/artwork/upload/visual');
                    },
                  ),
                  const SizedBox(height: 20),
                  UploadOptionCard(
                    icon: Icons.book_outlined,
                    title: 'upload_choice_written_title'.tr(),
                    description: 'upload_choice_written_desc'.tr(),
                    color: const Color(0xFF6C63FF),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed('/artwork/upload/written');
                    },
                  ),
                  const SizedBox(height: 20),
                  UploadOptionCard(
                    icon: Icons.mic_outlined,
                    title: 'upload_choice_audio_title'.tr(),
                    description: 'upload_choice_audio_desc'.tr(),
                    color: const Color(0xFFFF6B9D),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('upload_choice_audio_coming_soon'.tr())),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  UploadOptionCard(
                    icon: Icons.theaters_outlined,
                    title: 'upload_choice_video_title'.tr(),
                    description: 'upload_choice_video_desc'.tr(),
                    color: const Color(0xFFFFA500),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('upload_choice_video_coming_soon'.tr())),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UploadOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const UploadOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.black54,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

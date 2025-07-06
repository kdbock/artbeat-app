import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Widget to display an ad in either square or rectangle format.
/// Accepts image, title, description, and call-to-action.
class AdDisplayWidget extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String? ctaText;
  final VoidCallback? onTap;
  final AdDisplayType displayType; // square or rectangle

  const AdDisplayWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    this.ctaText,
    this.onTap,
    this.displayType = AdDisplayType.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final size = displayType == AdDisplayType.square
        ? const Size(300, 300)
        : const Size(400, 200); // Example sizes
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size.width,
        height: size.height,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: ImageManagementService().getOptimizedImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: size.width,
                  height: size.height * 0.6,
                  isThumbnail: true,
                  errorWidget: const Icon(Icons.broken_image, size: 48),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ctaText != null)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: onTap,
                          child: Text(ctaText!),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AdDisplayType { square, rectangle }

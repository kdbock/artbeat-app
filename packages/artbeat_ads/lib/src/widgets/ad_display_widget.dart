import 'dart:io';
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

    // Check if imageUrl is a local file path
    final isLocalFile =
        imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http') &&
        File(imageUrl).existsSync();

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
                child: imageUrl.isEmpty
                    ? Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      )
                    : isLocalFile
                    ? Image.file(
                        File(imageUrl),
                        fit: BoxFit.cover,
                        width: size.width,
                        height: size.height * 0.6,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 48),
                      )
                    : ImageManagementService().getOptimizedImage(
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate if we have enough space for all content
                    final hasSpaceForButton = constraints.maxHeight > 80;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title - always visible
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Description - flexible to available space
                        Expanded(
                          child: Text(
                            description,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.black54),
                            maxLines: hasSpaceForButton ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Button - only show if we have enough space
                        if (ctaText != null && hasSpaceForButton)
                          SizedBox(
                            height: 28, // Compact button height
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: onTap,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  ctaText!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
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

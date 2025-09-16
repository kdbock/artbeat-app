import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Utility class for generating local placeholder images
class PlaceholderImages {
  static const List<String> _texts = [
    'Image 1',
    'Image 2',
    'Image 3',
    'Image 4',
    'Artwork',
    'Photo',
    'Gallery',
    'Art',
  ];

  /// Generates a placeholder widget for the given dimensions
  static Widget generateWidget(int width, int height, {int index = 0}) {
    final colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
    ];

    final color = colors[index % colors.length];
    final text = _texts[index % _texts.length];

    return Container(
      width: width.toDouble(),
      height: height.toDouble(),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: math.min(width, height) * 0.3,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generates a placeholder widget with specific parameters
  static Widget generatePlaceholder({
    required double width,
    required double height,
    required int index,
    required String text,
  }) {
    final colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
    ];

    final color = colors[index % colors.length];

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: math.min(width, height) * 0.3,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generate a list of placeholder widgets for rotation
  static List<Widget> generatePlaceholderList({
    required double width,
    required double height,
    int count = 4,
  }) => List.generate(count, (index) => generatePlaceholder(
        width: width,
        height: height,
        index: index,
        text: 'Image ${index + 1}',
      ));
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Utility class for generating local placeholder images
class PlaceholderImages {
  static const List<Color> _colors = [
    Color(0xFFFF6B6B), // Red
    Color(0xFF4ECDC4), // Teal
    Color(0xFF45B7D1), // Blue
    Color(0xFF96CEB4), // Green
    Color(0xFFFCEA2B), // Yellow
    Color(0xFFFF8B94), // Pink
    Color(0xFF95E1D3), // Mint
    Color(0xFFFF677D), // Coral
  ];

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
  static Widget generateWidget(
    int width,
    int height, {
    int index = 0,
    Key? key,
  }) {
    final colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
    ];

    final color = colors[index % colors.length];
    final text = _texts[index % _texts.length];

    return Container(
      key: key,
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
}

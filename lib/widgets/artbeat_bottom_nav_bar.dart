import 'package:flutter/material.dart';

class ArtbeatBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final VoidCallback onCapture;

  const ArtbeatBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(currentIndex == 0 ? Icons.home : Icons.home_outlined),
              onPressed: () => onTap(0),
              tooltip: 'Home',
            ),
            IconButton(
              icon: Icon(currentIndex == 1 ? Icons.map : Icons.map_outlined),
              onPressed: () => onTap(1),
              tooltip: 'Art Walk',
            ),
            // Capture camera button in the center
            SizedBox(
              width: 40,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.add_a_photo, size: 28),
                  onPressed: onCapture,
                  tooltip: 'Capture',
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                currentIndex == 2 ? Icons.people : Icons.people_outline,
              ),
              onPressed: () => onTap(2),
              tooltip: 'Community',
            ),
            IconButton(
              icon: Icon(
                currentIndex == 4
                    ? Icons.chat_bubble
                    : Icons.chat_bubble_outline,
              ),
              onPressed: () => onTap(4),
              tooltip: 'Chat',
            ),
          ],
        ),
      ),
    );
  }
}

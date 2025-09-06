import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/src/widgets/enhanced_bottom_nav.dart';

void main() {
  group('EnhancedBottomNav', () {
    Widget createTestWidget({
      required int currentIndex,
      required void Function(int) onTap,
      List<BottomNavItem>? items,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Container(),
          bottomNavigationBar: EnhancedBottomNav(
            currentIndex: currentIndex,
            onTap: onTap,
            items:
                items ??
                [
                  const BottomNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                  ),
                  const BottomNavItem(
                    icon: Icons.map_outlined,
                    activeIcon: Icons.map_rounded,
                    label: 'Art Walk',
                  ),
                  const BottomNavItem(
                    icon: Icons.camera_alt_outlined,
                    activeIcon: Icons.camera_alt_rounded,
                    label: 'Capture',
                    isSpecial: true,
                  ),
                  const BottomNavItem(
                    icon: Icons.people_outline_rounded,
                    activeIcon: Icons.people_rounded,
                    label: 'Community',
                  ),
                  const BottomNavItem(
                    icon: Icons.event_outlined,
                    activeIcon: Icons.event_rounded,
                    label: 'Events',
                  ),
                ],
          ),
        ),
      );
    }

    testWidgets('should display correct number of navigation items', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(currentIndex: 0, onTap: (index) {}),
      );

      // Should have 5 navigation items - check for icons
      // When currentIndex is 0, home shows active icon, others show outlined
      expect(
        find.byIcon(Icons.home_rounded),
        findsOneWidget,
      ); // Active home icon
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.people_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.event_outlined), findsOneWidget);
    });

    testWidgets('should handle tap on capture button', (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        createTestWidget(
          currentIndex: 0,
          onTap: (index) {
            tappedIndex = index;
          },
        ),
      );

      // Tap on capture button (should be at index 2)
      await tester.tap(find.byIcon(Icons.camera_alt_outlined));
      await tester.pumpAndSettle();

      expect(tappedIndex, 2);
    });

    testWidgets('should handle tap on navigation items', (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        createTestWidget(
          currentIndex: 0,
          onTap: (index) {
            tappedIndex = index;
          },
        ),
      );

      // Tap on Art Walk (should be at index 1)
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();

      expect(tappedIndex, 1);
    });

    testWidgets('should not trigger tap for already selected item', (
      tester,
    ) async {
      int tapCount = 0;

      await tester.pumpWidget(
        createTestWidget(
          currentIndex: 0,
          onTap: (index) {
            tapCount++;
          },
        ),
      );

      // Find the Home icon - when selected it should show the active icon
      final homeIcon = find.byIcon(Icons.home_rounded);
      if (homeIcon.evaluate().isNotEmpty) {
        await tester.tap(homeIcon);
      } else {
        // Fallback to outlined icon if active icon not found
        await tester.tap(find.byIcon(Icons.home_outlined));
      }
      await tester.pumpAndSettle();

      expect(tapCount, 0);
    });

    testWidgets('should show labels when showLabels is true', (tester) async {
      await tester.pumpWidget(
        createTestWidget(currentIndex: 0, onTap: (index) {}),
      );

      // Should show text labels
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Art Walk'), findsOneWidget);
      expect(find.text('Capture'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
    });

    testWidgets('should hide labels when showLabels is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            bottomNavigationBar: EnhancedBottomNav(
              currentIndex: 0,
              onTap: (index) {},
              showLabels: false,
              items: const [
                BottomNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                ),
                BottomNavItem(
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map_rounded,
                  label: 'Art Walk',
                ),
              ],
            ),
          ),
        ),
      );

      // Should not show text labels
      expect(find.text('Home'), findsNothing);
      expect(find.text('Art Walk'), findsNothing);
    });
  });
}

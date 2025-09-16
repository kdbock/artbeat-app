import 'package:flutter/material.dart';
import 'artbeat_colors.dart';

class ArtbeatComponents {
  // Button Styles
  static ButtonStyle primaryButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((
      Set<WidgetState> states,
    ) {
      if (states.contains(WidgetState.disabled)) {
        return ArtbeatColors.buttonDisabled;
      }
      return ArtbeatColors.buttonPrimary;
    }),
    foregroundColor: WidgetStateProperty.all<Color>(ArtbeatColors.white),
    padding: WidgetStateProperty.all<EdgeInsets>(
      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  static ButtonStyle secondaryButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((
      Set<WidgetState> states,
    ) {
      if (states.contains(WidgetState.disabled)) {
        return ArtbeatColors.buttonDisabled;
      }
      return ArtbeatColors.buttonSecondary;
    }),
    foregroundColor: WidgetStateProperty.all<Color>(ArtbeatColors.white),
    padding: WidgetStateProperty.all<EdgeInsets>(
      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  static ButtonStyle elevatedButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.all<Color>(
      ArtbeatColors.primaryPurple,
    ),
    foregroundColor: WidgetStateProperty.all<Color>(ArtbeatColors.white),
    padding: WidgetStateProperty.all<EdgeInsets>(
      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  static ButtonStyle outlinedButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.all<Color>(
      Colors.white.withAlpha((0.8 * 255).round()),
    ),
    foregroundColor: WidgetStateProperty.all<Color>(
      ArtbeatColors.primaryPurple,
    ),
    padding: WidgetStateProperty.all<EdgeInsets>(
      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: ArtbeatColors.primaryPurple, width: 1.5),
      ),
    ),
  );

  // Input Decoration
  static InputDecoration inputDecoration({
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withAlpha((0.95 * 255).round()),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: ArtbeatColors.primaryPurple.withAlpha((0.3 * 255).round()),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: ArtbeatColors.primaryPurple,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: ArtbeatColors.error.withAlpha((0.7 * 255).round()),
        ),
      ),
    );
  }

  // Card Style
  static BoxDecoration cardDecoration = BoxDecoration(
    color: ArtbeatColors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: ArtbeatColors.black.withAlpha(26), // 0.1 opacity
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // App Bar Style
  static AppBarTheme appBarTheme = const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: ArtbeatColors.headerText),
    titleTextStyle: TextStyle(
      color: ArtbeatColors.headerText,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      fontFamily: 'Roboto',
    ),
  );

  // Bottom Navigation Bar Style
  static BottomNavigationBarThemeData bottomNavTheme =
      const BottomNavigationBarThemeData(
        backgroundColor: ArtbeatColors.white,
        selectedItemColor: ArtbeatColors.primaryPurple,
        unselectedItemColor: ArtbeatColors.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      );
}

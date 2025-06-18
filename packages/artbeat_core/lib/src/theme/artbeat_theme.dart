import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'artbeat_colors.dart';
import 'artbeat_typography.dart';
import 'artbeat_components.dart';

class ArtbeatTheme {
  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light();
    return baseTheme.copyWith(
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF8C52FF),
        secondary: const Color(0xFF6C63FF),
        surface: const Color(0xFFF5F5F5),
        onSurface: const Color(0xFF1D1D1D),
        error: const Color(0xFFB00020),
      ),
      scaffoldBackgroundColor: Colors.white,
      shadowColor: const Color(0xFF000000).withAlpha(51), // 0.2 * 255 = 51
      textTheme: ArtbeatTypography.textTheme,
      appBarTheme: ArtbeatComponents.appBarTheme,
      bottomNavigationBarTheme: ArtbeatComponents.bottomNavTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ArtbeatComponents.primaryButtonStyle,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ArtbeatComponents.outlinedButtonStyle,
      ),
      textButtonTheme: TextButtonThemeData(
        style: ArtbeatComponents.secondaryButtonStyle,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ArtbeatColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: ArtbeatColors.textSecondary.withAlpha(77), // 0.3 opacity
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ArtbeatColors.primaryPurple),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ArtbeatColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        margin: const EdgeInsets.all(8),
        shadowColor: const Color(0xFF000000).withAlpha(33), // 0.128 opacity
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        space: 1.0,
        thickness: 1.0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: ArtbeatColors.primaryPurple,
      scaffoldBackgroundColor: ArtbeatColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: ArtbeatColors.primaryPurple,
        secondary: ArtbeatColors.primaryGreen,
        error: ArtbeatColors.error,
        surface: ArtbeatColors.backgroundDark,
      ),
      textTheme: ArtbeatTypography.textTheme.apply(
        bodyColor: ArtbeatColors.white,
        displayColor: ArtbeatColors.white,
      ),
      appBarTheme: ArtbeatComponents.appBarTheme.copyWith(
        iconTheme: const IconThemeData(color: ArtbeatColors.white),
        titleTextStyle: const TextStyle(
          color: ArtbeatColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'FallingSky',
        ),
      ),
      bottomNavigationBarTheme: ArtbeatComponents.bottomNavTheme.copyWith(
        backgroundColor: ArtbeatColors.backgroundDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ArtbeatComponents.primaryButtonStyle,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ArtbeatComponents.outlinedButtonStyle,
      ),
      textButtonTheme: TextButtonThemeData(
        style: ArtbeatComponents.secondaryButtonStyle,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ArtbeatColors.backgroundDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: ArtbeatColors.white.withAlpha(77),
          ), // 0.3 opacity
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ArtbeatColors.primaryPurple),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ArtbeatColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        color: ArtbeatColors.backgroundDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static SystemUiOverlayStyle get systemUILight =>
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: ArtbeatColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      );

  static SystemUiOverlayStyle get systemUIDark =>
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: ArtbeatColors.backgroundDark,
        systemNavigationBarIconBrightness: Brightness.light,
      );
}

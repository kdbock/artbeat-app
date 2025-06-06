import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'artbeat_colors.dart';
import 'artbeat_typography.dart';
import 'artbeat_components.dart';

class ArtbeatTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: ArtbeatColors.primaryPurple,
      scaffoldBackgroundColor: ArtbeatColors.backgroundPrimary,
      colorScheme: const ColorScheme.light(
        primary: ArtbeatColors.primaryPurple,
        secondary: ArtbeatColors.primaryGreen,
        error: ArtbeatColors.error,
        surface: ArtbeatColors.backgroundPrimary,
      ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: ArtbeatColors.textSecondary.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: ArtbeatColors.primaryPurple,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: ArtbeatColors.error,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: ArtbeatColors.white.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: ArtbeatColors.primaryPurple,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: ArtbeatColors.error,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        color: ArtbeatColors.backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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

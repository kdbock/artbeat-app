import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    colorScheme: const ColorScheme.light(
      secondary: Colors.orange,
    ),
    fontFamily: 'Oswald',
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black),
      bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black87),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Colors.blue,
      textTheme: ButtonTextTheme.primary,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blueGrey,
    colorScheme: const ColorScheme.dark(
      secondary: Colors.deepOrange,
    ),
    fontFamily: 'Oswald',
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16.0, color: Colors.white70),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Colors.blueGrey,
      textTheme: ButtonTextTheme.primary,
    ),
  );
}

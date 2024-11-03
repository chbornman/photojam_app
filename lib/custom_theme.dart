import 'package:flutter/material.dart';
import 'package:photojam_app/constants/constants.dart';

ThemeData getLightTheme() {
  return ThemeData(
    colorScheme: ColorScheme.light(
      primary: PHOTOJAM_YELLOW,
      secondary: PHOTOJAM_PINK,
      surface: Colors.white,
      onPrimary: Colors.black,
      onSurface: Colors.black,
      // more colors
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontSize: 14, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 12, color: Colors.black87),
        bodySmall: TextStyle(fontSize: 10, color: Colors.black87),
      ));
}

ThemeData getDarkTheme() {
  return ThemeData(
      colorScheme: ColorScheme.dark(
        primary: PHOTOJAM_DARK_YELLOW,
        secondary: PHOTOJAM_DARK_PINK,
        surface: Colors.black,
        onPrimary: Colors.black,
        onSurface: Colors.white,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontSize: 14, color: Colors.white10),
        bodyMedium: TextStyle(fontSize: 12, color: Colors.white10),
        bodySmall: TextStyle(fontSize: 10, color: Colors.white10),
      ));
}
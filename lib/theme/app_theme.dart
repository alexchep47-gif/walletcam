import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkGlass {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B1426),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00C9A7),
        secondary: Color(0xFF00B4D8),
        surface: Color(0xFF0F1C3F),
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF00C9A7),
        foregroundColor: Colors.white,
      ),
    );
  }
}

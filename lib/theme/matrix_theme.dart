import 'package:flutter/material.dart';

class MatrixTheme {
  // Cores Matrix
  static const Color matrixBlack = Color(0xFF0D0208);
  static const Color matrixDarkGreen = Color(0xFF003B00);
  static const Color matrixGreen = Color(0xFF00FF41);
  static const Color matrixLightGreen = Color(0xFF39FF14);
  static const Color matrixGray = Color(0xFF1A1A1A);
  static const Color matrixTextGreen = Color(0xFF00FF41);
  static const Color matrixDimGreen = Color(0xFF008F11);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: matrixGreen,
      scaffoldBackgroundColor: matrixBlack,
      fontFamily: 'Courier',
      
      colorScheme: const ColorScheme.dark(
        primary: matrixGreen,
        secondary: matrixLightGreen,
        surface: matrixGray,
        background: matrixBlack,
        onPrimary: matrixBlack,
        onSecondary: matrixBlack,
        onSurface: matrixGreen,
        onBackground: matrixGreen,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: matrixBlack,
        foregroundColor: matrixGreen,
        elevation: 0,
        iconTheme: IconThemeData(color: matrixGreen),
        titleTextStyle: TextStyle(
          color: matrixGreen,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Courier',
        ),
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: matrixGreen, fontFamily: 'Courier'),
        displayMedium: TextStyle(color: matrixGreen, fontFamily: 'Courier'),
        displaySmall: TextStyle(color: matrixGreen, fontFamily: 'Courier'),
        headlineLarge: TextStyle(color: matrixGreen, fontFamily: 'Courier'),
        headlineMedium: TextStyle(color: matrixGreen, fontFamily: 'Courier'),
        headlineSmall: TextStyle(color: matrixGreen, fontFamily: 'Courier'),
        titleLarge: TextStyle(color: matrixGreen, fontFamily: 'Courier', fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: matrixGreen, fontFamily: 'Courier'),
        titleSmall: TextStyle(color: matrixGreen, fontFamily: 'Courier'),
        bodyLarge: TextStyle(color: matrixGreen, fontFamily: 'Courier'),
        bodyMedium: TextStyle(color: matrixGreen, fontFamily: 'Courier'),
        bodySmall: TextStyle(color: matrixDimGreen, fontFamily: 'Courier'),
        labelLarge: TextStyle(color: matrixGreen, fontFamily: 'Courier'),
        labelMedium: TextStyle(color: matrixDimGreen, fontFamily: 'Courier'),
        labelSmall: TextStyle(color: matrixDimGreen, fontFamily: 'Courier'),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: matrixGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: matrixGreen, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: matrixDimGreen, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: matrixGreen, width: 2),
        ),
        hintStyle: const TextStyle(color: matrixDimGreen, fontFamily: 'Courier'),
        labelStyle: const TextStyle(color: matrixGreen, fontFamily: 'Courier'),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: matrixGreen,
          foregroundColor: matrixBlack,
          textStyle: const TextStyle(
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: matrixGreen,
        foregroundColor: matrixBlack,
      ),
      
      cardTheme: CardTheme(
        color: matrixGray,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: matrixGreen, width: 1),
        ),
      ),
    );
  }
}


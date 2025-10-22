import 'package:flutter/material.dart';

class MatrixTheme {
  // Cores principais - Design moderno
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color darkPurple = Color(0xFF6D28D9);
  static const Color lightPurple = Color(0xFFA78BFA);
  static const Color darkBackground = Color(0xFF1F2937);
  static const Color darkerBackground = Color(0xFF111827);
  static const Color cardBackground = Color(0xFF374151);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textTertiary = Color(0xFF6B7280);
  
  // Cores antigas mantidas para compatibilidade
  static const Color matrixBlack = Color(0xFF111827);
  static const Color matrixDarkGreen = Color(0xFF6D28D9);
  static const Color matrixGreen = Color(0xFF8B5CF6);
  static const Color matrixLightGreen = Color(0xFFA78BFA);
  static const Color matrixGray = Color(0xFF374151);
  static const Color matrixTextGreen = Color(0xFF8B5CF6);
  static const Color matrixDimGreen = Color(0xFF6B7280);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: darkBackground,
      
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: lightPurple,
        surface: cardBackground,
        background: darkBackground,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary, size: 24),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: textTertiary, fontSize: 12),
        labelLarge: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: textSecondary, fontSize: 12),
        labelSmall: TextStyle(color: textTertiary, fontSize: 10),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
        hintStyle: const TextStyle(color: textTertiary),
        labelStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: textPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryPurple,
        foregroundColor: textPrimary,
        elevation: 4,
      ),
      
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: cardBackground,
        thickness: 1,
      ),
    );
  }
}


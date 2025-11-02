import 'package:flutter/material.dart';

class AppTheme {

  static const Color navyDark = Color(0xFF1A1F35);
  static const Color green = Color(0xFF4CAF50);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color navyLight = Color(0xFF2A3F5F);
  static const Color greyDark = Color(0xFF3A3A3A);
  static const Color greyLight = Color(0xFFF5F5F5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      

      colorScheme: const ColorScheme.light(
        primary: green,
        secondary: navyDark,
        surface: white,
        background: greyLight,
        error: Colors.red,
        onPrimary: white,
        onSecondary: white,
        onSurface: navyDark,
        onBackground: navyDark,
        onError: white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: navyDark,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
      ),

      scaffoldBackgroundColor: navyDark,

      cardTheme: CardThemeData(
        color: white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadowColor: black.withOpacity(0.1),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: green,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: greyDark.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: greyDark.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: green, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: white.withOpacity(0.9),
        selectedColor: green,
        labelStyle: const TextStyle(color: black, fontWeight: FontWeight.w500, fontSize: 12),
        secondaryLabelStyle: const TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: navyDark,
        selectedItemColor: green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
        ),
      ),
    );
  }
}


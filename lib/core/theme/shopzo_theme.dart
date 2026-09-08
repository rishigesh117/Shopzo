import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shopzo_colors.dart';

class ShopzoTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: ShopzoColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: ShopzoColors.primaryNavy,
        onPrimary: Colors.white,
        secondary: ShopzoColors.secondaryGreen,
        onSecondary: Colors.white,
        surface: ShopzoColors.lightSurface,
        onSurface: ShopzoColors.lightTextPrimary,
        error: ShopzoColors.danger,
        outline: ShopzoColors.lightBorder,
      ),
      cardTheme: CardThemeData(
        color: ShopzoColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ShopzoColors.lightBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ShopzoColors.lightSurface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: ShopzoColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: ShopzoColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ShopzoColors.lightSurfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ShopzoColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ShopzoColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ShopzoColors.primaryNavy, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ShopzoColors.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ShopzoColors.primaryNavy,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: ShopzoColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: ShopzoColors.secondaryGreen,
        onPrimary: ShopzoColors.darkBackground,
        secondary: ShopzoColors.accentBlue,
        onSecondary: Colors.white,
        surface: ShopzoColors.darkSurface,
        onSurface: ShopzoColors.darkTextPrimary,
        error: ShopzoColors.danger,
        outline: ShopzoColors.darkBorder,
      ),
      cardTheme: CardThemeData(
        color: ShopzoColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ShopzoColors.darkBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ShopzoColors.darkSurface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: ShopzoColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: ShopzoColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ShopzoColors.darkSurfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ShopzoColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ShopzoColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ShopzoColors.secondaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ShopzoColors.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ShopzoColors.secondaryGreen,
          foregroundColor: ShopzoColors.darkBackground,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
    );
  }
}

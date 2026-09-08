import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shopzo_colors.dart';

class ShopzoTypography {
  static TextStyle displayLarge(BuildContext context, {bool isDark = false}) => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: isDark ? ShopzoColors.darkTextPrimary : ShopzoColors.lightTextPrimary,
        height: 1.2,
      );

  static TextStyle headingLarge(BuildContext context, {bool isDark = false}) => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: isDark ? ShopzoColors.darkTextPrimary : ShopzoColors.lightTextPrimary,
        height: 1.25,
      );

  static TextStyle headingMedium(BuildContext context, {bool isDark = false}) => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: isDark ? ShopzoColors.darkTextPrimary : ShopzoColors.lightTextPrimary,
        height: 1.3,
      );

  static TextStyle headingSmall(BuildContext context, {bool isDark = false}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? ShopzoColors.darkTextPrimary : ShopzoColors.lightTextPrimary,
        height: 1.35,
      );

  static TextStyle moneyText(BuildContext context, {double fontSize = 22, bool isDark = false, Color? color}) => GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color ?? (isDark ? ShopzoColors.darkTextPrimary : ShopzoColors.lightTextPrimary),
        height: 1.2,
      );

  static TextStyle bodyLarge(BuildContext context, {bool isDark = false}) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: isDark ? ShopzoColors.darkTextPrimary : ShopzoColors.lightTextPrimary,
        height: 1.4,
      );

  static TextStyle bodyMedium(BuildContext context, {bool isDark = false}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: isDark ? ShopzoColors.darkTextSecondary : ShopzoColors.lightTextSecondary,
        height: 1.4,
      );

  static TextStyle bodySmall(BuildContext context, {bool isDark = false}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: isDark ? ShopzoColors.darkTextMuted : ShopzoColors.lightTextMuted,
        height: 1.4,
      );

  static TextStyle buttonText({Color color = Colors.white, double fontSize = 15}) => GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
      );
}

import 'package:flutter/material.dart';
import '../theme/shopzo_colors.dart';
import '../theme/shopzo_typography.dart';

class ShopzoButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const ShopzoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isSecondary = false,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDisabled
        ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
        : (backgroundColor ??
            (isSecondary
                ? (isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary)
                : ShopzoColors.primaryNavy));

    final fg = isDisabled
        ? (isDark ? Colors.grey.shade500 : Colors.grey.shade600)
        : (textColor ??
            (isSecondary
                ? (isDark ? ShopzoColors.darkTextPrimary : ShopzoColors.lightTextPrimary)
                : Colors.white));

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: isSecondary
                ? BorderSide(
                    color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder,
                  )
                : BorderSide.none,
          ),
        ),
        onPressed: (isLoading || isDisabled) ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: ShopzoTypography.buttonText(color: fg),
                  ),
                ],
              ),
      ),
    );
  }
}

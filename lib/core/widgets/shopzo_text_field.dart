import 'package:flutter/material.dart';
import '../theme/shopzo_colors.dart';
import '../theme/shopzo_typography.dart';

class ShopzoTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType keyboardType;
  final bool isPhone;
  final bool autofocus;
  final int maxLines;
  final String? errorText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const ShopzoTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.isPhone = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          autofocus: autofocus,
          maxLines: maxLines,
          keyboardType: isPhone ? TextInputType.phone : keyboardType,
          style: ShopzoTypography.bodyLarge(context, isDark: isDark),
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            hintStyle: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(
              color: isDark ? ShopzoColors.darkTextMuted : ShopzoColors.lightTextMuted,
            ),
            prefixIcon: isPhone
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🇮🇳 +91',
                          style: ShopzoTypography.bodyLarge(context, isDark: isDark).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 20,
                          color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder,
                        ),
                      ],
                    ),
                  )
                : (prefixIcon != null
                    ? Icon(
                        prefixIcon,
                        color: isDark ? ShopzoColors.darkTextSecondary : ShopzoColors.lightTextSecondary,
                      )
                    : null),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

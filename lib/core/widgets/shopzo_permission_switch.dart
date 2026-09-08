import 'package:flutter/material.dart';
import '../theme/shopzo_colors.dart';
import '../theme/shopzo_typography.dart';

class ShopzoPermissionSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  const ShopzoPermissionSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: value
                    ? ShopzoColors.secondaryGreen.withOpacity(0.15)
                    : (isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: value
                    ? ShopzoColors.secondaryGreen
                    : (isDark ? ShopzoColors.darkTextMuted : ShopzoColors.lightTextMuted),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ShopzoTypography.headingSmall(context, isDark: isDark).copyWith(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: ShopzoTypography.bodySmall(context, isDark: isDark),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ShopzoColors.secondaryGreen,
          ),
        ],
      ),
    );
  }
}

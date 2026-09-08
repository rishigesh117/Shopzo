import 'package:flutter/material.dart';
import '../theme/shopzo_colors.dart';
import '../theme/shopzo_typography.dart';

enum ShopzoBadgeType { success, warning, danger, info, navy, neutral }

typedef BadgeType = ShopzoBadgeType;

class ShopzoBadge extends StatelessWidget {
  final String? label;
  final String? text;
  final dynamic type; // ShopzoBadgeType, BadgeType, or String
  final IconData? icon;

  const ShopzoBadge({
    super.key,
    this.label,
    this.text,
    this.type = ShopzoBadgeType.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = label ?? text ?? '';
    Color bg;
    Color fg;

    ShopzoBadgeType badgeType = ShopzoBadgeType.neutral;
    if (type is ShopzoBadgeType) {
      badgeType = type as ShopzoBadgeType;
    } else if (type is String) {
      final t = (type as String).toLowerCase();
      if (t == 'success' || t == 'paid') badgeType = ShopzoBadgeType.success;
      else if (t == 'warning' || t == 'partially paid' || t == 'partial') badgeType = ShopzoBadgeType.warning;
      else if (t == 'danger' || t == 'unpaid') badgeType = ShopzoBadgeType.danger;
      else if (t == 'info') badgeType = ShopzoBadgeType.info;
      else if (t == 'navy') badgeType = ShopzoBadgeType.navy;
    }

    switch (badgeType) {
      case ShopzoBadgeType.success:
        bg = ShopzoColors.success.withOpacity(0.15);
        fg = ShopzoColors.success;
        break;
      case ShopzoBadgeType.warning:
        bg = ShopzoColors.warning.withOpacity(0.15);
        fg = ShopzoColors.warning;
        break;
      case ShopzoBadgeType.danger:
        bg = ShopzoColors.danger.withOpacity(0.15);
        fg = ShopzoColors.danger;
        break;
      case ShopzoBadgeType.info:
        bg = ShopzoColors.info.withOpacity(0.15);
        fg = ShopzoColors.info;
        break;
      case ShopzoBadgeType.navy:
        bg = ShopzoColors.primaryNavy.withOpacity(0.15);
        fg = ShopzoColors.primaryNavy;
        break;
      case ShopzoBadgeType.neutral:
        bg = Colors.grey.withOpacity(0.15);
        fg = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            displayText,
            style: ShopzoTypography.bodySmall(context).copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

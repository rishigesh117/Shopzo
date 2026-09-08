import 'package:flutter/material.dart';
import '../theme/shopzo_colors.dart';
import '../theme/shopzo_typography.dart';

class ShopzoLogo extends StatelessWidget {
  final double iconSize;
  final bool showTagline;
  final bool isDark;

  const ShopzoLogo({
    super.key,
    this.iconSize = 36,
    this.showTagline = true,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(iconSize * 0.28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ShopzoColors.primaryNavy, ShopzoColors.secondaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(iconSize * 0.35),
                boxShadow: [
                  BoxShadow(
                    color: ShopzoColors.secondaryGreen.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.shopping_bag_rounded,
                size: iconSize,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'SHOP',
                    style: ShopzoTypography.displayLarge(context, isDark: isDark).copyWith(
                      fontSize: iconSize * 0.85,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: 'ZO',
                    style: ShopzoTypography.displayLarge(context, isDark: isDark).copyWith(
                      fontSize: iconSize * 0.85,
                      fontWeight: FontWeight.w900,
                      color: ShopzoColors.secondaryGreen,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            'Simple. Smart. Sell.',
            style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
              color: isDark ? ShopzoColors.darkTextSecondary : ShopzoColors.lightTextSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_header.dart';

class ReportsPlaceholderScreen extends StatelessWidget {
  const ReportsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          ShopzoHeader(
            title: 'Reports & Analytics',
            subtitle: 'Sales summaries, category breakdown, and profit analytics',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ShopzoCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Weekly Sales', style: ShopzoTypography.bodyMedium(context, isDark: isDark)),
                              const SizedBox(height: 6),
                              Text('₹87,420', style: ShopzoTypography.moneyText(context, fontSize: 24, isDark: isDark)),
                              const SizedBox(height: 4),
                              Text('+18% vs last week', style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(color: ShopzoColors.secondaryGreen)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ShopzoCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Estimated Margin', style: ShopzoTypography.bodyMedium(context, isDark: isDark)),
                              const SizedBox(height: 6),
                              Text('14.2%', style: ShopzoTypography.moneyText(context, fontSize: 24, isDark: isDark, color: ShopzoColors.secondaryGreen)),
                              const SizedBox(height: 4),
                              Text('Gross profit overview', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ShopzoCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sales Performance Chart', style: ShopzoTypography.headingMedium(context, isDark: isDark)),
                        const SizedBox(height: 16),
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.bar_chart_rounded, size: 48, color: ShopzoColors.secondaryGreen),
                                const SizedBox(height: 8),
                                Text('Interactive Analytics coming in Phase 2', style: ShopzoTypography.bodyMedium(context, isDark: isDark)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

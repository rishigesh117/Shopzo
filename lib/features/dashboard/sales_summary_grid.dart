import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/bill_repository.dart';
import '../../core/providers/product_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_card.dart';

class SalesSummaryGrid extends StatefulWidget {
  const SalesSummaryGrid({super.key});

  @override
  State<SalesSummaryGrid> createState() => _SalesSummaryGridState();
}

class _SalesSummaryGridState extends State<SalesSummaryGrid> {
  final BillRepository _billRepository = BillRepository();

  int _todaySalesPaise = 0;
  int _todayBillsCount = 0;
  double _todayProductsSoldCount = 0.0;
  int _pendingPaymentsPaise = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    try {
      final sales = await _billRepository.getTodaySalesPaise();
      final bills = await _billRepository.getTodayBillsCount();
      final itemsSold = await _billRepository.getTodayProductsSoldCount();
      final pending = await _billRepository.getPendingPaymentsTotalPaise();

      if (mounted) {
        setState(() {
          _todaySalesPaise = sales;
          _todayBillsCount = bills;
          _todayProductsSoldCount = itemsSold;
          _pendingPaymentsPaise = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard metrics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 840;
    final productProvider = Provider.of<ProductProvider>(context);

    final todaySalesDouble = _todaySalesPaise / 100.0;
    final pendingDouble = _pendingPaymentsPaise / 100.0;
    final lowStockCount = productProvider.lowStockProducts.length;

    final items = [
      _MetricData(
        title: "Today's Sales",
        value: _isLoading ? '...' : '₹${todaySalesDouble.toStringAsFixed(2)}',
        subtitle: 'Offline sales completed',
        icon: Icons.trending_up_rounded,
        color: ShopzoColors.secondaryGreen,
      ),
      _MetricData(
        title: 'Bills',
        value: _isLoading ? '...' : '$_todayBillsCount',
        subtitle: 'Created today',
        icon: Icons.receipt_long_rounded,
        color: ShopzoColors.primaryNavy,
      ),
      _MetricData(
        title: 'Products Sold',
        value: _isLoading ? '...' : (_todayProductsSoldCount % 1 == 0 ? _todayProductsSoldCount.toInt().toString() : _todayProductsSoldCount.toStringAsFixed(1)),
        subtitle: 'Units sold today',
        icon: Icons.shopping_cart_rounded,
        color: ShopzoColors.accentBlue,
      ),
      _MetricData(
        title: 'Pending Dues',
        value: _isLoading ? '...' : '₹${pendingDouble.toStringAsFixed(2)}',
        subtitle: 'Customer balance due',
        icon: Icons.pending_actions_rounded,
        color: ShopzoColors.warning,
      ),
      _MetricData(
        title: 'Low Stock',
        value: '$lowStockCount Items',
        subtitle: 'Needs restocking',
        icon: Icons.warning_amber_rounded,
        color: ShopzoColors.danger,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 5 : (MediaQuery.of(context).size.width > 500 ? 3 : 2),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isWide ? 1.35 : 1.25,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ShopzoCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.title,
                    style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, size: 16, color: item.color),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: ShopzoTypography.moneyText(
                  context,
                  fontSize: 20,
                  isDark: isDark,
                  color: item.color == ShopzoColors.danger ? ShopzoColors.danger : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  _MetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/bill_repository.dart';
import '../../core/models/bill_model.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_header.dart';
import '../../core/widgets/shopzo_text_field.dart';
import '../billing/new_bill_screen.dart';
import 'bill_details_screen.dart';

class BillsScreen extends StatefulWidget {
  final String? initialStatusFilter;

  const BillsScreen({super.key, this.initialStatusFilter});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final BillRepository _repository = BillRepository();
  List<Bill> _bills = [];
  bool _isLoading = true;
  String _searchQuery = '';
  late String _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _selectedStatusFilter = widget.initialStatusFilter ?? 'all';
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repository.getBills(
        searchQuery: _searchQuery,
        statusFilter: _selectedStatusFilter,
      );
      setState(() => _bills = list);
    } catch (e) {
      debugPrint('Error loading bills: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShopzoHeader(
                title: 'Bills & Sales',
                subtitle: 'Offline sales transactions, payment history & receipts',
                actions: [
                  ShopzoButton(
                    text: '+ New Bill',
                    icon: Icons.add_rounded,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NewBillScreen()),
                      ).then((_) => _loadBills());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search & Filter Bar
              Row(
                children: [
                  Expanded(
                    child: ShopzoTextField(
                      label: 'Search Bills',
                      hint: 'Search by bill #, customer name or phone...',
                      prefixIcon: Icons.search_rounded,
                      onChanged: (val) {
                        _searchQuery = val;
                        _loadBills();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Bills', 'all', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('Paid', 'paid', isDark, badgeColor: ShopzoColors.secondaryGreen),
                    const SizedBox(width: 8),
                    _buildFilterChip('Partially Paid', 'partially_paid', isDark, badgeColor: ShopzoColors.warning),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', 'pending', isDark, badgeColor: ShopzoColors.danger),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bills List
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_bills.isEmpty)
                ShopzoCard(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: isDark ? ShopzoColors.darkTextMuted : ShopzoColors.lightTextMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No bills found',
                          style: ShopzoTypography.headingMedium(context, isDark: isDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try adjusting your search query or status filters, or create a new bill.',
                          style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final bill = _bills[i];
                    final dateStr = dateFormat.format(bill.createdAt);

                    return ShopzoCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BillDetailsScreen(billId: bill.id)),
                        ).then((_) => _loadBills());
                      },
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: ShopzoColors.primaryNavy.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.receipt_rounded, color: ShopzoColors.primaryNavy, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bill ${bill.billNumber}',
                                        style: ShopzoTypography.headingMedium(context, isDark: isDark).copyWith(fontSize: 16),
                                      ),
                                      Text(
                                        '${bill.customerNameSnapshot ?? "Walk-in Customer"} • $dateStr',
                                        style: ShopzoTypography.bodySmall(context, isDark: isDark),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ShopzoBadge(
                                text: bill.paymentStatus,
                                type: bill.paymentStatus == 'Paid'
                                    ? BadgeType.success
                                    : (bill.paymentStatus == 'Partially Paid' ? BadgeType.warning : BadgeType.danger),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${bill.items.length} items',
                                style: ShopzoTypography.bodySmall(context, isDark: isDark),
                              ),
                              Row(
                                children: [
                                  if (bill.pendingAmount > 0) ...[
                                    Text(
                                      'Due: ₹${bill.pendingAmount.toStringAsFixed(2)}  •  ',
                                      style: const TextStyle(color: ShopzoColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                  Text(
                                    'Total: ₹${bill.totalAmount.toStringAsFixed(2)}',
                                    style: ShopzoTypography.moneyText(context, fontSize: 18, isDark: isDark, color: ShopzoColors.secondaryGreen),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark, {Color? badgeColor}) {
    final isSelected = _selectedStatusFilter == value;

    return InkWell(
      onTap: () {
        setState(() => _selectedStatusFilter = value);
        _loadBills();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ShopzoColors.primaryNavy : (isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? ShopzoColors.primaryNavy : (isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder),
          ),
        ),
        child: Row(
          children: [
            if (badgeColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(
                color: isSelected ? Colors.white : (isDark ? ShopzoColors.darkTextPrimary : ShopzoColors.lightTextPrimary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

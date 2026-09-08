import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/bill_repository.dart';
import '../../core/models/bill_model.dart';
import '../../core/models/customer_model.dart';
import '../../core/models/payment_model.dart';
import '../../core/models/return_model.dart';
import '../../core/providers/customer_provider.dart';
import '../../core/providers/payment_provider.dart';
import '../../core/providers/return_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_header.dart';
import '../bills/bill_details_screen.dart';
import '../payments/record_payment_dialog.dart';
import 'add_edit_customer_dialog.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailsScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> with SingleTickerProviderStateMixin {
  final BillRepository _billRepository = BillRepository();
  late TabController _tabController;
  List<Bill> _customerBills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCustomerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerData() async {
    setState(() => _isLoading = true);
    try {
      final bills = await _billRepository.getBills(customerId: widget.customerId);
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      final returnProvider = Provider.of<ReturnProvider>(context, listen: false);

      await customerProvider.loadCustomers();
      await paymentProvider.loadPayments(customerId: widget.customerId);
      await returnProvider.loadReturns(customerId: widget.customerId);

      setState(() {
        _customerBills = bills;
      });
    } catch (e) {
      debugPrint('Error loading customer details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customerProvider = Provider.of<CustomerProvider>(context);
    final paymentProvider = Provider.of<PaymentProvider>(context);
    final returnProvider = Provider.of<ReturnProvider>(context);

    final customer = customerProvider.customers.firstWhere(
      (c) => c.id == widget.customerId,
      orElse: () => Customer(
        id: widget.customerId,
        name: 'Unknown Customer',
        phone: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final duePaise = customerProvider.getCustomerDuePaise(customer.id);
    final dueDouble = duePaise / 100.0;
    final totalPurchases = customerProvider.getCustomerTotalPurchases(customer.id);
    final customerPayments = paymentProvider.payments.where((p) => p.customerId == customer.id).toList();
    final customerReturns = returnProvider.returns.where((r) => r.customerId == customer.id).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ShopzoHeader(
              title: customer.name,
              subtitle: 'Customer Profile & Ledger History',
              actions: [
                ShopzoButton(
                  text: 'Edit Customer',
                  icon: Icons.edit_rounded,
                  isSecondary: true,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AddEditCustomerDialog(customer: customer),
                    ).then((_) => _loadCustomerData());
                  },
                ),
                if (duePaise > 0) ...[
                  const SizedBox(width: 8),
                  ShopzoButton(
                    text: 'Record Payment',
                    icon: Icons.payment_rounded,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => RecordPaymentDialog(
                          customerId: customer.id,
                          pendingAmountPaise: duePaise,
                          onPaymentRecorded: () => _loadCustomerData(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards Grid
                    Row(
                      children: [
                        Expanded(
                          child: ShopzoCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Purchases', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${totalPurchases.toStringAsFixed(2)}',
                                  style: ShopzoTypography.moneyText(context, fontSize: 22, isDark: isDark, color: ShopzoColors.primaryNavy),
                                ),
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
                                Text('Outstanding Due', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${dueDouble.toStringAsFixed(2)}',
                                  style: ShopzoTypography.moneyText(
                                    context,
                                    fontSize: 22,
                                    isDark: isDark,
                                    color: duePaise > 0 ? ShopzoColors.danger : ShopzoColors.secondaryGreen,
                                  ),
                                ),
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
                                Text('Total Bills', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                                const SizedBox(height: 4),
                                Text(
                                  '${_customerBills.length}',
                                  style: ShopzoTypography.moneyText(context, fontSize: 22, isDark: isDark, color: ShopzoColors.accentBlue),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Contact Details Box
                    ShopzoCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_rounded, color: ShopzoColors.primaryNavy),
                          const SizedBox(width: 12),
                          Text('Phone: ${customer.phone}', style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 24),
                          if (customer.address != null && customer.address!.isNotEmpty) ...[
                            const Icon(Icons.location_on_rounded, color: ShopzoColors.primaryNavy),
                            const SizedBox(width: 8),
                            Text('Address: ${customer.address}', style: ShopzoTypography.bodyMedium(context, isDark: isDark)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tabs Header
                    TabBar(
                      controller: _tabController,
                      labelColor: ShopzoColors.primaryNavy,
                      unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                      indicatorColor: ShopzoColors.primaryNavy,
                      tabs: [
                        Tab(text: 'Bill History (${_customerBills.length})'),
                        Tab(text: 'Payment History (${customerPayments.length})'),
                        Tab(text: 'Return History (${customerReturns.length})'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 400,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Bills
                          _customerBills.isEmpty
                              ? const Center(child: Text('No bills recorded for this customer.'))
                              : ListView.separated(
                                  itemCount: _customerBills.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (ctx, i) {
                                    final bill = _customerBills[i];
                                    return ShopzoCard(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => BillDetailsScreen(billId: bill.id)),
                                        ).then((_) => _loadCustomerData());
                                      },
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Bill ${bill.billNumber}', style: ShopzoTypography.bodyLarge(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold)),
                                              Text('${bill.items.length} items', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              ShopzoBadge(
                                                text: bill.paymentStatus,
                                                type: bill.paymentStatus == 'Paid'
                                                    ? BadgeType.success
                                                    : (bill.paymentStatus == 'Partially Paid' ? BadgeType.warning : BadgeType.danger),
                                              ),
                                              const SizedBox(width: 12),
                                              Text('₹${bill.totalAmount.toStringAsFixed(2)}', style: ShopzoTypography.moneyText(context, fontSize: 16, isDark: isDark)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                          // Tab 2: Payments
                          customerPayments.isEmpty
                              ? const Center(child: Text('No payment entries recorded.'))
                              : ListView.separated(
                                  itemCount: customerPayments.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (ctx, i) {
                                    final pay = customerPayments[i];
                                    return ShopzoCard(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Payment via ${pay.paymentMethod}', style: ShopzoTypography.bodyLarge(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold)),
                                              if (pay.notes != null) Text(pay.notes!, style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                                            ],
                                          ),
                                          Text(
                                            '+₹${pay.amount.toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ShopzoColors.secondaryGreen),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                          // Tab 3: Returns
                          customerReturns.isEmpty
                              ? const Center(child: Text('No product returns recorded.'))
                              : ListView.separated(
                                  itemCount: customerReturns.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (ctx, i) {
                                    final ret = customerReturns[i];
                                    return ShopzoCard(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(ret.productNameSnapshot, style: ShopzoTypography.bodyLarge(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold)),
                                              Text('Reason: ${ret.reason}', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                                            ],
                                          ),
                                          Text(
                                            '-₹${ret.refundAmount.toStringAsFixed(2)} (${ret.quantity} ${ret.unit})',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ShopzoColors.danger),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
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
      ),
    );
  }
}

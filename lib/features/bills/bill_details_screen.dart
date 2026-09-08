import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/bill_repository.dart';
import '../../core/models/bill_model.dart';
import '../../core/models/payment_model.dart';
import '../../core/models/return_model.dart';
import '../../core/providers/customer_provider.dart';
import '../../core/providers/payment_provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/providers/return_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_header.dart';
import '../billing/receipt_pdf_helper.dart';
import '../billing/receipt_widget.dart';
import '../payments/record_payment_dialog.dart';
import '../returns/process_return_dialog.dart';

class BillDetailsScreen extends StatefulWidget {
  final String billId;

  const BillDetailsScreen({super.key, required this.billId});

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  final BillRepository _billRepository = BillRepository();
  Bill? _bill;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  Future<void> _loadBill() async {
    setState(() => _isLoading = true);
    try {
      final b = await _billRepository.getBillById(widget.billId);
      setState(() => _bill = b);
    } catch (e) {
      debugPrint('Error loading bill details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paymentProvider = Provider.of<PaymentProvider>(context);
    final returnProvider = Provider.of<ReturnProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final customerProvider = Provider.of<CustomerProvider>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bill Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_bill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bill Details')),
        body: const Center(child: Text('Bill not found.')),
      );
    }

    final bill = _bill!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ShopzoHeader(
              title: 'Bill ${bill.billNumber}',
              subtitle: 'Transaction details & offline receipt',
              actions: [
                ShopzoButton(
                  text: 'Print / Export PDF',
                  icon: Icons.print_rounded,
                  isSecondary: true,
                  onPressed: () => ReceiptPdfHelper.printOrShareReceipt(bill),
                ),
                if (bill.pendingAmount > 0) ...[
                  const SizedBox(width: 8),
                  ShopzoButton(
                    text: 'Record Payment',
                    icon: Icons.payments_rounded,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => RecordPaymentDialog(
                          billId: bill.id,
                          customerId: bill.customerId,
                          pendingAmountPaise: bill.pendingAmountPaise,
                          onPaymentRecorded: () {
                            _loadBill();
                          },
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Bill Breakdown & Payments/Returns
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status & Customer Summary Card
                          ShopzoCard(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Payment Status', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                                    const SizedBox(height: 4),
                                    ShopzoBadge(
                                      text: bill.paymentStatus,
                                      type: bill.paymentStatus == 'Paid'
                                          ? BadgeType.success
                                          : (bill.paymentStatus == 'Partially Paid' ? BadgeType.warning : BadgeType.danger),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Customer', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                                    const SizedBox(height: 4),
                                    Text(
                                      bill.customerNameSnapshot ?? 'Walk-in Customer',
                                      style: ShopzoTypography.bodyLarge(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    if (bill.customerPhoneSnapshot != null)
                                      Text(bill.customerPhoneSnapshot!, style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Itemized Items Table
                          Text('Purchased Items (${bill.items.length})', style: ShopzoTypography.headingMedium(context, isDark: isDark)),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: bill.items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final item = bill.items[i];
                              final qtyStr = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();

                              return ShopzoCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productNameSnapshot,
                                            style: ShopzoTypography.bodyLarge(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '₹${item.sellingPrice.toStringAsFixed(2)} / ${item.unit}',
                                            style: ShopzoTypography.bodySmall(context, isDark: isDark),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '$qtyStr ${item.unit}',
                                        textAlign: TextAlign.center,
                                        style: ShopzoTypography.bodyMedium(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '₹${item.lineTotal.toStringAsFixed(2)}',
                                        textAlign: TextAlign.right,
                                        style: ShopzoTypography.moneyText(context, fontSize: 16, isDark: isDark, color: ShopzoColors.secondaryGreen),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Process Return Action
                                    IconButton(
                                      tooltip: 'Return Product',
                                      icon: const Icon(Icons.assignment_return_rounded, color: ShopzoColors.accentBlue, size: 20),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => ProcessReturnDialog(
                                            billId: bill.id,
                                            customerId: bill.customerId,
                                            productId: item.productId,
                                            productNameSnapshot: item.productNameSnapshot,
                                            purchasedQuantity: item.quantity,
                                            unit: item.unit,
                                            sellingPricePaise: item.sellingPricePaise,
                                            onReturnProcessed: () {
                                              _loadBill();
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Linked Returns Section
                          FutureBuilder<List<ProductReturn>>(
                            future: returnProvider.returns.where((r) => r.billId == bill.id).toList().isNotEmpty
                                ? Future.value(returnProvider.returns.where((r) => r.billId == bill.id).toList())
                                : returnProvider.returns.isEmpty
                                    ? Future.value([])
                                    : Future.value([]),
                            builder: (context, snapshot) {
                              final returns = returnProvider.returns.where((r) => r.billId == bill.id).toList();
                              if (returns.isEmpty) return const SizedBox.shrink();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Returned Products (${returns.length})', style: ShopzoTypography.headingMedium(context, isDark: isDark)),
                                  const SizedBox(height: 12),
                                  ...returns.map((ret) => ShopzoCard(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(ret.productNameSnapshot, style: ShopzoTypography.bodyLarge(context, isDark: isDark).copyWith(fontWeight: FontWeight.bold)),
                                                Text('Reason: ${ret.reason} • Action: ${ret.stockAction}', style: ShopzoTypography.bodySmall(context, isDark: isDark)),
                                              ],
                                            ),
                                            Text(
                                              'Returned ${ret.quantity} ${ret.unit} (Refund: ₹${ret.refundAmount.toStringAsFixed(2)})',
                                              style: const TextStyle(color: ShopzoColors.danger, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      )),
                                  const SizedBox(height: 24),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Right Column: Printable Receipt Preview Card
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Text('Receipt Preview', style: ShopzoTypography.headingMedium(context, isDark: isDark)),
                          const SizedBox(height: 12),
                          ReceiptWidget(bill: bill),
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

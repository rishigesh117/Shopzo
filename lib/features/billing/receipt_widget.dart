import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/bill_model.dart';
import '../../core/theme/shopzo_colors.dart';

class ReceiptWidget extends StatelessWidget {
  final Bill bill;
  final String shopName;

  const ReceiptWidget({
    super.key,
    required this.bill,
    this.shopName = 'SuperMart Supermarket',
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final formattedDate = dateFormat.format(bill.createdAt);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Text(
            shopName.toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ShopzoColors.primaryNavy,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Simple. Smart. Sell.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(thickness: 1, color: Colors.black26),
          const SizedBox(height: 8),

          // Bill Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bill ${bill.billNumber}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
          if (bill.customerNameSnapshot != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  'Customer: ${bill.customerNameSnapshot} (${bill.customerPhoneSnapshot ?? ""})',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.black54),
                SizedBox(width: 4),
                Text(
                  'Customer: Walk-in Customer',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(thickness: 1, color: Colors.black26),
          const SizedBox(height: 8),

          // Items Header
          const Row(
            children: [
              Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 8),

          // Items List
          ...bill.items.map((item) {
            final qtyStr = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.productNameSnapshot,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '$qtyStr ${item.unit}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${item.sellingPrice.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${item.lineTotal.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
          const Divider(thickness: 1, color: Colors.black26),
          const SizedBox(height: 8),

          // Totals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text('₹${bill.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ShopzoColors.secondaryGreen)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount Received:', style: TextStyle(fontSize: 12, color: Colors.black87)),
              Text('₹${bill.amountReceived.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          ),
          if (bill.changeAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Change Returned:', style: TextStyle(fontSize: 12, color: Colors.black87)),
                Text('₹${bill.changeAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: ShopzoColors.accentBlue)),
              ],
            ),
          ],
          if (bill.pendingAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pending Due:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ShopzoColors.danger)),
                Text('₹${bill.pendingAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ShopzoColors.danger)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Payment Status:', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: bill.paymentStatus == 'Paid'
                      ? ShopzoColors.secondaryGreen.withOpacity(0.15)
                      : (bill.paymentStatus == 'Partially Paid' ? ShopzoColors.warning.withOpacity(0.15) : ShopzoColors.danger.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  bill.paymentStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: bill.paymentStatus == 'Paid'
                        ? ShopzoColors.secondaryGreen
                        : (bill.paymentStatus == 'Partially Paid' ? ShopzoColors.warning : ShopzoColors.danger),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(thickness: 1, color: Colors.black26),
          const SizedBox(height: 8),
          const Text(
            'Thank you for shopping with us!',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

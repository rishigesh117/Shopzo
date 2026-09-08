import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/report_provider.dart';

class PendingPaymentsReportTab extends StatelessWidget {
  const PendingPaymentsReportTab({super.key});

  String _formatRupees(int paise) {
    return '₹${(paise / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final pending = provider.pendingReport;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pending == null || pending.pendingBills.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
              SizedBox(height: 12),
              Text('All customer payments are clear!', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Outstanding Dues Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Outstanding Dues', style: TextStyle(fontSize: 12, color: Colors.red.shade800)),
                  const SizedBox(height: 4),
                  Text(
                    _formatRupees(pending.totalOutstandingPaise),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                  ),
                ],
              ),
              Chip(
                backgroundColor: Colors.red.shade100,
                label: Text(
                  '${pending.pendingCustomerCount} Customers',
                  style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Pending Bills Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        ...pending.pendingBills.map((bill) {
          final custName = bill['customer_name'] ?? bill['customer_name_snapshot'] ?? 'Walk-in Customer';
          final custPhone = bill['customer_phone'] ?? bill['customer_phone_snapshot'] ?? '';
          final total = (bill['total_amount_paise'] as num).toInt();
          final paid = (bill['amount_received_paise'] as num).toInt();
          final due = (bill['pending_amount_paise'] as num).toInt();

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.person_outline, color: Colors.white),
              ),
              title: Text(custName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Bill: ${bill['bill_number']} | Phone: ${custPhone.isNotEmpty ? custPhone : 'N/A'}\nTotal: ${_formatRupees(total)} | Paid: ${_formatRupees(paid)}'),
              isThreeLine: true,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatRupees(due), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                  const Text('DUE', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

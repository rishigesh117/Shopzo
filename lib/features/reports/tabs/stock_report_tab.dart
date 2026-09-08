import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/report_provider.dart';

class StockReportTab extends StatelessWidget {
  const StockReportTab({super.key});

  String _formatRupees(int paise) {
    return '₹${(paise / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final stock = provider.stockReport;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (stock == null) {
      return const Center(child: Text('No stock data available.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Stock Valuation Cards
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Stock Inventory Valuation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildValuationItem(context, 'Cost Value', _formatRupees(stock.totalStockValueBuyingPaise), Colors.blue),
                    _buildValuationItem(context, 'Retail Value', _formatRupees(stock.totalStockValueSellingPaise), Colors.purple),
                    _buildValuationItem(context, 'Potential Profit', _formatRupees(stock.potentialProfitPaise), Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Status Counts
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: [
            _buildCountCard(context, 'Total Products', '${stock.totalProducts}', Icons.inventory_2, Colors.blue),
            _buildCountCard(context, 'Low Stock', '${stock.lowStockCount}', Icons.warning_amber, Colors.orange),
            _buildCountCard(context, 'Out of Stock', '${stock.outOfStockCount}', Icons.error_outline, Colors.red),
          ],
        ),
        const SizedBox(height: 16),

        // Recently Restocked List
        if (stock.recentlyRestocked.isNotEmpty) ...[
          const Text('Recently Restocked Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...stock.recentlyRestocked.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.add_shopping_cart, color: Colors.green),
                  title: Text(item['product_name'] ?? 'Product'),
                  subtitle: Text('Qty Changed: +${item['quantity_change']} (${item['created_at'].toString().split('T').first})'),
                  trailing: Text(
                    _formatRupees((item['purchase_price_paise'] as num? ?? 0).toInt()),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildValuationItem(BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildCountCard(BuildContext context, String label, String count, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/models/bill_model.dart';

class ReceiptPdfHelper {
  static Future<void> printOrShareReceipt(Bill bill, {String shopName = 'SuperMart Supermarket'}) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final formattedDate = dateFormat.format(bill.createdAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                shopName.toUpperCase(),
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Simple. Smart. Sell.',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill ${bill.billNumber}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(formattedDate, style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Text(
                    'Customer: ${bill.customerNameSnapshot ?? "Walk-in Customer"}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.5),
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.Divider(thickness: 0.2),
              ...bill.items.map((item) {
                final qtyStr = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(item.productNameSnapshot, style: const pw.TextStyle(fontSize: 7))),
                      pw.Expanded(flex: 2, child: pw.Text('$qtyStr ${item.unit}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7))),
                      pw.Expanded(flex: 2, child: pw.Text('Rs.${item.sellingPrice.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7))),
                      pw.Expanded(flex: 2, child: pw.Text('Rs.${item.lineTotal.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                );
              }),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs.${bill.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Received:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Rs.${bill.amountReceived.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (bill.changeAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Change:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Rs.${bill.changeAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              if (bill.pendingAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Pending:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rs.${bill.pendingAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              pw.SizedBox(height: 4),
              pw.Text('Status: ${bill.paymentStatus.toUpperCase()}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 0.5),
              pw.Text('Thank you for shopping!', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${bill.billNumber}',
    );
  }
}

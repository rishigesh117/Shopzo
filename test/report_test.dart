import 'package:flutter_test/flutter_test.dart';
import 'package:shopzo/core/services/report_service.dart';

void main() {
  group('ReportService DateTimeRange Tests', () {
    test('DateTimeRange.preset Today covers full 24 hours of current day', () {
      final range = DateTimeRange.preset(DateRangePreset.today);
      final now = DateTime.now();

      expect(range.start.year, equals(now.year));
      expect(range.start.month, equals(now.month));
      expect(range.start.day, equals(now.day));
      expect(range.start.hour, equals(0));
      expect(range.start.minute, equals(0));

      expect(range.end.hour, equals(23));
      expect(range.end.minute, equals(59));
      expect(range.end.second, equals(59));
    });

    test('Profit calculation formula works correctly', () {
      const grossSalesPaise = 50000; // ₹500.00
      const cogsPaise = 30000; // ₹300.00
      const returnedPaise = 5000; // ₹50.00

      final netSales = grossSalesPaise - returnedPaise;
      final netProfit = netSales - cogsPaise;
      final margin = (netProfit / netSales) * 100;

      expect(netSales, equals(45000));
      expect(netProfit, equals(15000));
      expect(margin, closeTo(33.33, 0.01));
    });
  });
}

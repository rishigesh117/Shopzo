import 'package:flutter/foundation.dart';
import '../services/report_service.dart';

class ReportProvider with ChangeNotifier {
  final ReportService _reportService = ReportService();

  DateRangePreset _selectedPreset = DateRangePreset.today;
  DateTimeRange _currentRange = DateTimeRange.preset(DateRangePreset.today);

  bool _isLoading = false;
  String? _error;

  SalesReportData? _salesReport;
  ProfitReportData? _profitReport;
  StockReportData? _stockReport;
  ReturnReportData? _returnReport;
  PendingPaymentReportData? _pendingReport;
  List<BestSellerItem> _bestSellers = [];
  List<SalesTrendPoint> _salesTrends = [];
  List<BusinessInsight> _insights = [];

  DateRangePreset get selectedPreset => _selectedPreset;
  DateTimeRange get currentRange => _currentRange;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SalesReportData? get salesReport => _salesReport;
  ProfitReportData? get profitReport => _profitReport;
  StockReportData? get stockReport => _stockReport;
  ReturnReportData? get returnReport => _returnReport;
  PendingPaymentReportData? get pendingReport => _pendingReport;
  List<BestSellerItem> get bestSellers => _bestSellers;
  List<SalesTrendPoint> get salesTrends => _salesTrends;
  List<BusinessInsight> get insights => _insights;

  ReportProvider() {
    loadAllReports();
  }

  void setPreset(DateRangePreset preset, {DateTime? customStart, DateTime? customEnd}) {
    _selectedPreset = preset;
    _currentRange = DateTimeRange.preset(preset, customStart: customStart, customEnd: customEnd);
    loadAllReports();
  }

  Future<void> loadAllReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final sales = await _reportService.getSalesReport(_currentRange);
      final profit = await _reportService.getProfitReport(_currentRange);
      final stock = await _reportService.getStockReport();
      final returns = await _reportService.getReturnReport(_currentRange);
      final pending = await _reportService.getPendingPaymentsReport();
      final best = await _reportService.getBestSellers(_currentRange, limit: 10);
      final trends = await _reportService.getSalesTrends(_currentRange);
      final ins = await _reportService.getBusinessInsights(_currentRange);

      _salesReport = sales;
      _profitReport = profit;
      _stockReport = stock;
      _returnReport = returns;
      _pendingReport = pending;
      _bestSellers = best;
      _salesTrends = trends;
      _insights = ins;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

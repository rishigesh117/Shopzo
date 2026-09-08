import 'package:flutter/material.dart';
import '../database/return_repository.dart';
import '../models/return_model.dart';
import 'product_provider.dart';

class ReturnProvider extends ChangeNotifier {
  final ReturnRepository _repository = ReturnRepository();

  List<ProductReturn> _returns = [];
  bool _isLoading = false;

  List<ProductReturn> get returns => _returns;
  bool get isLoading => _isLoading;

  ReturnProvider() {
    loadReturns();
  }

  Future<void> loadReturns({String? billId, String? customerId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _returns = await _repository.getReturns(billId: billId, customerId: customerId);
    } catch (e) {
      debugPrint('Error loading returns: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<double> getAlreadyReturnedQuantity(String billId, String productId) {
    return _repository.getAlreadyReturnedQuantity(billId, productId);
  }

  Future<ProductReturn> processReturn({
    required String billId,
    required String? customerId,
    required String productId,
    required String productNameSnapshot,
    required double returnQuantity,
    required String unit,
    required String reason,
    required String stockAction,
    required ProductProvider productProvider,
  }) async {
    final ret = await _repository.processReturn(
      billId: billId,
      customerId: customerId,
      productId: productId,
      productNameSnapshot: productNameSnapshot,
      returnQuantity: returnQuantity,
      unit: unit,
      reason: reason,
      stockAction: stockAction,
    );

    // Refresh returns list
    await loadReturns(billId: billId);

    // Refresh products in product provider if stock was restored
    if (stockAction == 'Restocked') {
      await productProvider.loadProducts();
    }

    return ret;
  }
}

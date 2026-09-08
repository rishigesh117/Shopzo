import 'package:flutter/material.dart';
import '../database/bill_repository.dart';
import '../models/bill_model.dart';
import '../models/customer_model.dart';
import '../models/product_model.dart';
import 'product_provider.dart';

class CartItem {
  final Product product;
  double quantity;

  CartItem({
    required this.product,
    this.quantity = 1.0,
  });

  int get sellingPricePaise => product.sellingPricePaise;
  int get buyingPricePaise => product.buyingPricePaise;
  
  double get sellingPrice => product.sellingPrice;
  double get buyingPrice => product.buyingPrice;

  int get lineTotalPaise => (sellingPricePaise * quantity).round();
  double get lineTotal => lineTotalPaise / 100.0;

  int get profitPaise => ((sellingPricePaise - buyingPricePaise) * quantity).round();
  double get profit => profitPaise / 100.0;
}

class BillingProvider extends ChangeNotifier {
  final BillRepository _billRepository = BillRepository();

  final List<CartItem> _cart = [];
  Customer? _selectedCustomer;
  double _amountReceived = 0.0;
  String _paymentMethod = 'Cash';
  String _productSearchQuery = '';
  bool _isProcessing = false;
  String? _errorMessage;

  List<CartItem> get cart => _cart;
  Customer? get selectedCustomer => _selectedCustomer;
  double get amountReceived => _amountReceived;
  String get paymentMethod => _paymentMethod;
  String get productSearchQuery => _productSearchQuery;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  // Calculates subtotal & total in paise to ensure exact precision
  int get subtotalPaise => _cart.fold(0, (sum, item) => sum + item.lineTotalPaise);
  double get subtotal => subtotalPaise / 100.0;

  int get totalAmountPaise => subtotalPaise;
  double get totalAmount => totalAmountPaise / 100.0;

  int get amountReceivedPaise => (_amountReceived * 100).round();

  int get changeAmountPaise {
    if (amountReceivedPaise >= totalAmountPaise) {
      return amountReceivedPaise - totalAmountPaise;
    }
    return 0;
  }
  double get changeAmount => changeAmountPaise / 100.0;

  int get pendingAmountPaise {
    if (amountReceivedPaise < totalAmountPaise) {
      return totalAmountPaise - amountReceivedPaise;
    }
    return 0;
  }
  double get pendingAmount => pendingAmountPaise / 100.0;

  String get paymentStatus {
    if (amountReceivedPaise >= totalAmountPaise) return 'Paid';
    if (amountReceivedPaise > 0) return 'Partially Paid';
    return 'Pending';
  }

  void setProductSearchQuery(String query) {
    _productSearchQuery = query;
    notifyListeners();
  }

  void setSelectedCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setAmountReceived(double amount) {
    _amountReceived = amount < 0 ? 0.0 : amount;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  /// Add product to cart with stock validation
  void addToCart(Product product, {double quantity = 1.0}) {
    _errorMessage = null;

    final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
    final currentInCart = existingIndex != -1 ? _cart[existingIndex].quantity : 0.0;
    final totalRequested = currentInCart + quantity;

    if (totalRequested > product.quantity) {
      _errorMessage = 'Only ${product.quantity} ${product.unit} of "${product.name}" available in stock.';
      notifyListeners();
      return;
    }

    if (existingIndex != -1) {
      _cart[existingIndex].quantity = totalRequested;
    } else {
      _cart.add(CartItem(product: product, quantity: quantity));
    }

    notifyListeners();
  }

  /// Increment quantity (+ button)
  void incrementQuantity(int index) {
    if (index < 0 || index >= _cart.length) return;
    _errorMessage = null;

    final item = _cart[index];
    final step = (item.product.unit.toLowerCase() == 'kg' || item.product.unit.toLowerCase() == 'litre') ? 0.5 : 1.0;
    final newQty = item.quantity + step;

    if (newQty > item.product.quantity) {
      _errorMessage = 'Cannot exceed available stock (${item.product.quantity} ${item.product.unit}).';
      notifyListeners();
      return;
    }

    item.quantity = newQty;
    notifyListeners();
  }

  /// Decrement quantity (- button)
  void decrementQuantity(int index) {
    if (index < 0 || index >= _cart.length) return;
    _errorMessage = null;

    final item = _cart[index];
    final step = (item.product.unit.toLowerCase() == 'kg' || item.product.unit.toLowerCase() == 'litre') ? 0.5 : 1.0;
    final newQty = item.quantity - step;

    if (newQty <= 0) {
      _cart.removeAt(index);
    } else {
      item.quantity = newQty;
    }

    notifyListeners();
  }

  /// Direct quantity typing setter
  void setQuantity(int index, double newQuantity) {
    if (index < 0 || index >= _cart.length) return;
    _errorMessage = null;

    final item = _cart[index];
    if (newQuantity <= 0) {
      _cart.removeAt(index);
      notifyListeners();
      return;
    }

    if (newQuantity > item.product.quantity) {
      _errorMessage = 'Only ${item.product.quantity} ${item.product.unit} available in stock.';
      notifyListeners();
      return;
    }

    item.quantity = newQuantity;
    notifyListeners();
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cart.length) {
      _cart.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    _selectedCustomer = null;
    _amountReceived = 0.0;
    _paymentMethod = 'Cash';
    _errorMessage = null;
    notifyListeners();
  }

  /// Complete Bill in SQLite database transaction
  Future<Bill?> checkout(ProductProvider productProvider) async {
    if (_cart.isEmpty) {
      _errorMessage = 'Cart is empty. Add products to create a bill.';
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<BillItem> billItems = _cart.map((item) {
        return BillItem(
          id: '',
          billId: '',
          productId: item.product.id,
          productNameSnapshot: item.product.name,
          quantity: item.quantity,
          unit: item.product.unit,
          sellingPricePaise: item.sellingPricePaise,
          buyingPricePaise: item.buyingPricePaise,
          lineTotalPaise: item.lineTotalPaise,
          profitPaise: item.profitPaise,
        );
      }).toList();

      final bill = await _billRepository.saveBill(
        customerId: _selectedCustomer?.id,
        customerNameSnapshot: _selectedCustomer?.name,
        customerPhoneSnapshot: _selectedCustomer?.phone,
        cartItems: billItems,
        amountReceivedPaise: amountReceivedPaise,
        paymentMethod: _paymentMethod,
      );

      // Refresh products state in UI to reflect new stock levels
      await productProvider.loadProducts();

      clearCart();
      return bill;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}

import 'package:flutter/material.dart';
import '../database/customer_repository.dart';
import '../models/customer_model.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repository = CustomerRepository();

  List<Customer> _customers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Map<String, int> _customerDues = {};
  Map<String, int> _customerTotalPurchases = {};

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  CustomerProvider() {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _customers = await _repository.getCustomers(searchQuery: _searchQuery);
      
      // Load due balances and total purchases for loaded customers
      _customerDues = {};
      _customerTotalPurchases = {};
      for (final cust in _customers) {
        final due = await _repository.getCustomerPendingDuePaise(cust.id);
        final purchases = await _repository.getCustomerTotalPurchasesPaise(cust.id);
        _customerDues[cust.id] = due;
        _customerTotalPurchases[cust.id] = purchases;
      }
    } catch (e) {
      debugPrint('Error loading customers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadCustomers();
  }

  int getCustomerDuePaise(String customerId) => _customerDues[customerId] ?? 0;
  double getCustomerDue(String customerId) => getCustomerDuePaise(customerId) / 100.0;

  int getCustomerTotalPurchasesPaise(String customerId) => _customerTotalPurchases[customerId] ?? 0;
  double getCustomerTotalPurchases(String customerId) => getCustomerTotalPurchasesPaise(customerId) / 100.0;

  Future<Customer> addCustomer({
    required String name,
    required String phone,
    String? address,
  }) async {
    final now = DateTime.now();
    final newCust = Customer(
      id: 'cust_${now.millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      address: address,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.addCustomer(newCust);
    await loadCustomers();
    return newCust;
  }

  Future<void> updateCustomer(Customer customer) async {
    final updated = customer.copyWith(updatedAt: DateTime.now());
    await _repository.updateCustomer(updated);
    await loadCustomers();
  }

  Future<void> softDeleteCustomer(String customerId) async {
    await _repository.softDeleteCustomer(customerId);
    await loadCustomers();
  }
}

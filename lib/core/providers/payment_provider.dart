import 'package:flutter/material.dart';
import '../database/payment_repository.dart';
import '../models/payment_model.dart';
import 'customer_provider.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentRepository _repository = PaymentRepository();

  List<Payment> _payments = [];
  bool _isLoading = false;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;

  PaymentProvider() {
    loadPayments();
  }

  Future<void> loadPayments({String? customerId, String? billId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _payments = await _repository.getPayments(customerId: customerId, billId: billId);
    } catch (e) {
      debugPrint('Error loading payments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Payment> recordPayment({
    required String? customerId,
    required String? billId,
    required double amount,
    required String paymentMethod,
    String? notes,
    CustomerProvider? customerProvider,
  }) async {
    final amountPaise = (amount * 100).round();
    final payment = await _repository.recordPayment(
      customerId: customerId,
      billId: billId,
      amountPaise: amountPaise,
      paymentMethod: paymentMethod,
      notes: notes,
    );

    await loadPayments(customerId: customerId, billId: billId);

    if (customerProvider != null) {
      await customerProvider.loadCustomers();
    }

    return payment;
  }
}

class Payment {
  final String id;
  final String? customerId;
  final String? billId;
  final int amountPaise;
  final String paymentMethod; // 'Cash', 'UPI', 'Card', 'Other'
  final String? notes;
  final DateTime createdAt;

  Payment({
    required this.id,
    this.customerId,
    this.billId,
    required this.amountPaise,
    required this.paymentMethod,
    this.notes,
    required this.createdAt,
  });

  double get amount => amountPaise / 100.0;

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      customerId: map['customer_id'] as String?,
      billId: map['bill_id'] as String?,
      amountPaise: map['amount_paise'] as int,
      paymentMethod: map['payment_method'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'bill_id': billId,
      'amount_paise': amountPaise,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

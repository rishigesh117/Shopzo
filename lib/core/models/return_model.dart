class ProductReturn {
  final String id;
  final String billId;
  final String? customerId;
  final String productId;
  final String productNameSnapshot;
  final double quantity;
  final String unit;
  final int refundAmountPaise;
  final String reason; // 'Damaged', 'Customer Return', 'Expired', 'Other'
  final String status; // 'Completed', 'Cancelled'
  final String stockAction; // 'Restocked', 'Scrapped'
  final DateTime createdAt;

  ProductReturn({
    required this.id,
    required this.billId,
    this.customerId,
    required this.productId,
    required this.productNameSnapshot,
    required this.quantity,
    required this.unit,
    required this.refundAmountPaise,
    required this.reason,
    required this.status,
    required this.stockAction,
    required this.createdAt,
  });

  double get refundAmount => refundAmountPaise / 100.0;

  factory ProductReturn.fromMap(Map<String, dynamic> map) {
    return ProductReturn(
      id: map['id'] as String,
      billId: map['bill_id'] as String,
      customerId: map['customer_id'] as String?,
      productId: map['product_id'] as String,
      productNameSnapshot: map['product_name_snapshot'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      refundAmountPaise: map['refund_amount_paise'] as int,
      reason: map['reason'] as String,
      status: map['status'] as String,
      stockAction: map['stock_action'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_id': billId,
      'customer_id': customerId,
      'product_id': productId,
      'product_name_snapshot': productNameSnapshot,
      'quantity': quantity,
      'unit': unit,
      'refund_amount_paise': refundAmountPaise,
      'reason': reason,
      'status': status,
      'stock_action': stockAction,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

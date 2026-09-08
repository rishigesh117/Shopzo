class BillItem {
  final String id;
  final String billId;
  final String productId;
  final String productNameSnapshot;
  final double quantity;
  final String unit;
  final int sellingPricePaise;
  final int buyingPricePaise;
  final int lineTotalPaise;
  final int profitPaise;

  BillItem({
    required this.id,
    required this.billId,
    required this.productId,
    required this.productNameSnapshot,
    required this.quantity,
    required this.unit,
    required this.sellingPricePaise,
    required this.buyingPricePaise,
    required this.lineTotalPaise,
    required this.profitPaise,
  });

  double get sellingPrice => sellingPricePaise / 100.0;
  double get buyingPrice => buyingPricePaise / 100.0;
  double get lineTotal => lineTotalPaise / 100.0;
  double get profit => profitPaise / 100.0;

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'] as String,
      billId: map['bill_id'] as String,
      productId: map['product_id'] as String,
      productNameSnapshot: map['product_name_snapshot'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      sellingPricePaise: map['selling_price_paise'] as int,
      buyingPricePaise: map['buying_price_paise'] as int,
      lineTotalPaise: map['line_total_paise'] as int,
      profitPaise: map['profit_paise'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_id': billId,
      'product_id': productId,
      'product_name_snapshot': productNameSnapshot,
      'quantity': quantity,
      'unit': unit,
      'selling_price_paise': sellingPricePaise,
      'buying_price_paise': buyingPricePaise,
      'line_total_paise': lineTotalPaise,
      'profit_paise': profitPaise,
    };
  }
}

class Bill {
  final String id;
  final String billNumber;
  final String? customerId;
  final String? customerNameSnapshot;
  final String? customerPhoneSnapshot;
  final int subtotalPaise;
  final int totalAmountPaise;
  final int amountReceivedPaise;
  final int changeAmountPaise;
  final int pendingAmountPaise;
  final String paymentStatus; // 'Paid', 'Partially Paid', 'Pending'
  final bool isCancelled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BillItem> items;

  Bill({
    required this.id,
    required this.billNumber,
    this.customerId,
    this.customerNameSnapshot,
    this.customerPhoneSnapshot,
    required this.subtotalPaise,
    required this.totalAmountPaise,
    required this.amountReceivedPaise,
    required this.changeAmountPaise,
    required this.pendingAmountPaise,
    required this.paymentStatus,
    this.isCancelled = false,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  double get subtotal => subtotalPaise / 100.0;
  double get totalAmount => totalAmountPaise / 100.0;
  double get amountReceived => amountReceivedPaise / 100.0;
  double get changeAmount => changeAmountPaise / 100.0;
  double get pendingAmount => pendingAmountPaise / 100.0;
  double get totalProfit => items.fold(0.0, (sum, item) => sum + item.profit);

  factory Bill.fromMap(Map<String, dynamic> map, {List<BillItem> items = const []}) {
    return Bill(
      id: map['id'] as String,
      billNumber: map['bill_number'] as String,
      customerId: map['customer_id'] as String?,
      customerNameSnapshot: map['customer_name_snapshot'] as String?,
      customerPhoneSnapshot: map['customer_phone_snapshot'] as String?,
      subtotalPaise: map['subtotal_paise'] as int,
      totalAmountPaise: map['total_amount_paise'] as int,
      amountReceivedPaise: map['amount_received_paise'] as int,
      changeAmountPaise: map['change_amount_paise'] as int,
      pendingAmountPaise: map['pending_amount_paise'] as int,
      paymentStatus: map['payment_status'] as String,
      isCancelled: (map['is_cancelled'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      items: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_number': billNumber,
      'customer_id': customerId,
      'customer_name_snapshot': customerNameSnapshot,
      'customer_phone_snapshot': customerPhoneSnapshot,
      'subtotal_paise': subtotalPaise,
      'total_amount_paise': totalAmountPaise,
      'amount_received_paise': amountReceivedPaise,
      'change_amount_paise': changeAmountPaise,
      'pending_amount_paise': pendingAmountPaise,
      'payment_status': paymentStatus,
      'is_cancelled': isCancelled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Bill copyWith({
    String? id,
    String? billNumber,
    String? customerId,
    String? customerNameSnapshot,
    String? customerPhoneSnapshot,
    int? subtotalPaise,
    int? totalAmountPaise,
    int? amountReceivedPaise,
    int? changeAmountPaise,
    int? pendingAmountPaise,
    String? paymentStatus,
    bool? isCancelled,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<BillItem>? items,
  }) {
    return Bill(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      customerId: customerId ?? this.customerId,
      customerNameSnapshot: customerNameSnapshot ?? this.customerNameSnapshot,
      customerPhoneSnapshot: customerPhoneSnapshot ?? this.customerPhoneSnapshot,
      subtotalPaise: subtotalPaise ?? this.subtotalPaise,
      totalAmountPaise: totalAmountPaise ?? this.totalAmountPaise,
      amountReceivedPaise: amountReceivedPaise ?? this.amountReceivedPaise,
      changeAmountPaise: changeAmountPaise ?? this.changeAmountPaise,
      pendingAmountPaise: pendingAmountPaise ?? this.pendingAmountPaise,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isCancelled: isCancelled ?? this.isCancelled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}

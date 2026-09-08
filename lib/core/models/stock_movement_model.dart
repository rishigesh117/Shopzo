enum StockMovementType {
  restock,
  adjustment,
  sale,
  returnStock,
  returnItem,
}

class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final double previousQuantity;
  final double quantityChange;
  final double newQuantity;
  final int purchasePricePaise;
  final StockMovementType movementType;
  final String? reason;
  final String? supplier;
  final String? notes;
  final DateTime createdAt;

  StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.previousQuantity,
    required this.quantityChange,
    required this.newQuantity,
    this.purchasePricePaise = 0,
    required this.movementType,
    this.reason,
    this.supplier,
    this.notes,
    required this.createdAt,
  });

  double get purchasePrice => purchasePricePaise / 100.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'previous_quantity': previousQuantity,
      'quantity_change': quantityChange,
      'new_quantity': newQuantity,
      'purchase_price_paise': purchasePricePaise,
      'movement_type': movementType.name.toUpperCase(),
      'reason': reason,
      'supplier': supplier,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    final typeStr = (map['movement_type'] as String? ?? 'RESTOCK').toLowerCase();
    StockMovementType type;
    if (typeStr == 'adjustment') {
      type = StockMovementType.adjustment;
    } else if (typeStr == 'sale') {
      type = StockMovementType.sale;
    } else if (typeStr == 'returnstock' || typeStr == 'return') {
      type = StockMovementType.returnStock;
    } else if (typeStr == 'returnitem') {
      type = StockMovementType.returnItem;
    } else {
      type = StockMovementType.restock;
    }

    return StockMovement(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      previousQuantity: (map['previous_quantity'] as num).toDouble(),
      quantityChange: (map['quantity_change'] as num).toDouble(),
      newQuantity: (map['new_quantity'] as num).toDouble(),
      purchasePricePaise: map['purchase_price_paise'] as int? ?? 0,
      movementType: type,
      reason: map['reason'] as String?,
      supplier: map['supplier'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

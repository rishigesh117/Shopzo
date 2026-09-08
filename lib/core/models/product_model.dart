class Product {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final String? brand;
  final int buyingPricePaise;
  final int sellingPricePaise;
  final double quantity;
  final String unit;
  final double minStockLevel;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    this.brand,
    required this.buyingPricePaise,
    required this.sellingPricePaise,
    required this.quantity,
    required this.unit,
    required this.minStockLevel,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  double get buyingPrice => buyingPricePaise / 100.0;
  double get sellingPrice => sellingPricePaise / 100.0;

  bool get isInStock => quantity > minStockLevel;
  bool get isLowStock => quantity > 0 && quantity <= minStockLevel;
  bool get isOutOfStock => quantity <= 0;

  String get stockStatusText {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  String get stockStatusBadgeType {
    if (isOutOfStock) return 'danger';
    if (isLowStock) return 'warning';
    return 'success';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'category_name': categoryName,
      'brand': brand,
      'buying_price_paise': buyingPricePaise,
      'selling_price_paise': sellingPricePaise,
      'quantity': quantity,
      'unit': unit,
      'min_stock_level': minStockLevel,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      categoryId: map['category_id'] as String,
      categoryName: map['category_name'] as String,
      brand: map['brand'] as String?,
      buyingPricePaise: map['buying_price_paise'] as int,
      sellingPricePaise: map['selling_price_paise'] as int,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      minStockLevel: (map['min_stock_level'] as num).toDouble(),
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? categoryName,
    String? brand,
    int? buyingPricePaise,
    int? sellingPricePaise,
    double? quantity,
    String? unit,
    double? minStockLevel,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      brand: brand ?? this.brand,
      buyingPricePaise: buyingPricePaise ?? this.buyingPricePaise,
      sellingPricePaise: sellingPricePaise ?? this.sellingPricePaise,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

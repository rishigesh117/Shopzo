class Shop {
  final String id;
  final String name;
  final String ownerName;
  final String phone;
  final String address;
  final String shopCode;
  final String? logoUrl;
  final DateTime createdAt;

  Shop({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.phone,
    required this.address,
    required this.shopCode,
    this.logoUrl,
    required this.createdAt,
  });

  Shop copyWith({
    String? id,
    String? name,
    String? ownerName,
    String? phone,
    String? address,
    String? shopCode,
    String? logoUrl,
    DateTime? createdAt,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      shopCode: shopCode ?? this.shopCode,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

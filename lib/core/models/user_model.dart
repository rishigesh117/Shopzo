enum UserRole { owner, member }

class User {
  final String id;
  final String name;
  final String phone;
  final String? shopId;
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required this.phone,
    this.shopId,
    required this.role,
  });

  User copyWith({
    String? id,
    String? name,
    String? phone,
    String? shopId,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      shopId: shopId ?? this.shopId,
      role: role ?? this.role,
    );
  }
}

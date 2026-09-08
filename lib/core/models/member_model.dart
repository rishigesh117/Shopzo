import 'permission_model.dart';

enum MemberStatus { active, pending, invited, rejected }
enum MemberRole { owner, manager, staff }

class ShopMember {
  final String id;
  final String name;
  final String phone;
  final MemberRole role;
  final MemberStatus status;
  final ShopzoPermissions permissions;
  final DateTime joinedDate;

  ShopMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.status,
    required this.permissions,
    required this.joinedDate,
  });

  ShopMember copyWith({
    String? id,
    String? name,
    String? phone,
    MemberRole? role,
    MemberStatus? status,
    ShopzoPermissions? permissions,
    DateTime? joinedDate,
  }) {
    return ShopMember(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }

  String get maskedPhone {
    if (phone.length >= 10) {
      return '${phone.substring(0, 3)}****${phone.substring(phone.length - 3)}';
    }
    return phone;
  }
}

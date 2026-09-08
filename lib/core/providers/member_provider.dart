import 'package:flutter/material.dart';
import '../models/member_model.dart';
import '../models/permission_model.dart';

class MemberProvider extends ChangeNotifier {
  final List<ShopMember> _members = [
    ShopMember(
      id: 'mem_001',
      name: 'Arun Kumar',
      phone: '+91 98765 12345',
      role: MemberRole.staff,
      status: MemberStatus.active,
      permissions: ShopzoPermissions.standardStaff(),
      joinedDate: DateTime.now().subtract(const Duration(days: 45)),
    ),
    ShopMember(
      id: 'mem_002',
      name: 'Priya Sundaram',
      phone: '+91 98765 67890',
      role: MemberRole.staff,
      status: MemberStatus.pending,
      permissions: ShopzoPermissions.standardStaff(),
      joinedDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ShopMember(
      id: 'mem_003',
      name: 'Rahul Verma',
      phone: '+91 98765 99999',
      role: MemberRole.staff,
      status: MemberStatus.active,
      permissions: ShopzoPermissions.fullAccess(),
      joinedDate: DateTime.now().subtract(const Duration(days: 120)),
    ),
  ];

  // Invitations sent to current logged-in employee (Flow B)
  bool _hasPendingInvitation = true;
  String _invitingShopName = 'SuperMart Central';

  List<ShopMember> get members => List.unmodifiable(_members);
  List<ShopMember> get activeMembers => _members.where((m) => m.status == MemberStatus.active).toList();
  List<ShopMember> get pendingRequests => _members.where((m) => m.status == MemberStatus.pending).toList();

  bool get hasPendingInvitation => _hasPendingInvitation;
  String get invitingShopName => _invitingShopName;

  void addMemberInvitation({
    required String name,
    required String phone,
    required ShopzoPermissions permissions,
  }) {
    final newMember = ShopMember(
      id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      role: MemberRole.staff,
      status: MemberStatus.pending,
      permissions: permissions,
      joinedDate: DateTime.now(),
    );
    _members.insert(0, newMember);
    notifyListeners();
  }

  void updateMemberPermissions(String memberId, ShopzoPermissions newPermissions) {
    final index = _members.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      _members[index] = _members[index].copyWith(permissions: newPermissions);
      notifyListeners();
    }
  }

  void acceptMemberRequest(String memberId) {
    final index = _members.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      _members[index] = _members[index].copyWith(status: MemberStatus.active);
      notifyListeners();
    }
  }

  void rejectMemberRequest(String memberId) {
    _members.removeWhere((m) => m.id == memberId);
    notifyListeners();
  }

  void removeMember(String memberId) {
    _members.removeWhere((m) => m.id == memberId);
    notifyListeners();
  }

  void respondToInvitation(bool accept) {
    _hasPendingInvitation = false;
    notifyListeners();
  }
}

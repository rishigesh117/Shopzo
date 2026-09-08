import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class MemberManagementScreen extends StatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _members = [];
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMemberData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberData() async {
    setState(() => _isLoading = true);

    final membersRes = await ApiService.instance.get('/members');
    final reqsRes = await ApiService.instance.get('/members/requests');

    setState(() {
      _isLoading = false;
      if (membersRes.success && membersRes.data is List) {
        _members = membersRes.data;
      }
      if (reqsRes.success && reqsRes.data is List) {
        _requests = reqsRes.data;
      }
    });
  }

  Future<void> _inviteEmployeeDialog() async {
    final phoneController = TextEditingController();
    bool canCreateBills = true;
    bool canManageProducts = true;
    bool canViewReports = true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Invite Employee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Employee Phone Number',
                    hintText: '9876543210',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Assign Permissions:', style: TextStyle(fontWeight: FontWeight.bold)),
                CheckboxListTile(
                  title: const Text('Create & View Bills'),
                  value: canCreateBills,
                  onChanged: (v) => setDlgState(() => canCreateBills = v ?? true),
                ),
                CheckboxListTile(
                  title: const Text('Add & Edit Products'),
                  value: canManageProducts,
                  onChanged: (v) => setDlgState(() => canManageProducts = v ?? true),
                ),
                CheckboxListTile(
                  title: const Text('View Financial Reports'),
                  value: canViewReports,
                  onChanged: (v) => setDlgState(() => canViewReports = v ?? true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send Invitation'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && phoneController.text.trim().isNotEmpty) {
      final res = await ApiService.instance.post(
        '/members/invite',
        body: {
          'phone': phoneController.text.trim(),
          'permissions': {
            'is_full_access': false,
            'can_create_bills': canCreateBills,
            'can_view_bills': canCreateBills,
            'can_add_products': canManageProducts,
            'can_edit_products': canManageProducts,
            'can_view_reports': canViewReports,
          },
        },
      );

      if (res.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invitation sent successfully!'), backgroundColor: Colors.green),
          );
        }
        _loadMemberData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.error ?? 'Failed to send invitation'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    final res = await ApiService.instance.post('/members/requests/$requestId/accept');
    if (res.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Join request accepted! Employee added to shop.'), backgroundColor: Colors.green),
        );
      }
      _loadMemberData();
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final res = await ApiService.instance.post('/members/requests/$requestId/reject');
    if (res.success) {
      _loadMemberData();
    }
  }

  Future<void> _removeMember(String userId, String name, String role) async {
    if (role == 'OWNER') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owner cannot be removed from the shop!'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove "$name" from this shop?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.instance.delete('/members/$userId');
      if (res.success) {
        _loadMemberData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.error ?? 'Failed to remove member'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Members & Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Members (${_members.length})'),
            Tab(text: 'Join Requests (${_requests.where((r) => r['status'] == 'PENDING').length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _inviteEmployeeDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Invite Employee'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Active Members List
                RefreshIndicator(
                  onRefresh: _loadMemberData,
                  child: _members.isEmpty
                      ? const Center(child: Text('No active members found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _members.length,
                          itemBuilder: (ctx, idx) {
                            final m = _members[idx];
                            final role = m['role'] ?? 'EMPLOYEE';
                            final isOwner = role == 'OWNER';
                            final name = m['user_name'] ?? 'User';
                            final phone = m['user_phone'] ?? '';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isOwner ? Colors.amber.shade100 : Colors.blue.shade100,
                                  child: Icon(
                                    isOwner ? Icons.star : Icons.person,
                                    color: isOwner ? Colors.amber.shade900 : Colors.blue.shade900,
                                  ),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('$phone • Role: $role'),
                                trailing: isOwner
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'OWNER',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _removeMember(m['user_id'], name, role),
                                      ),
                              ),
                            );
                          },
                        ),
                ),

                // Join Requests List
                RefreshIndicator(
                  onRefresh: _loadMemberData,
                  child: _requests.where((r) => r['status'] == 'PENDING').isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('No pending join requests.')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _requests.length,
                          itemBuilder: (ctx, idx) {
                            final r = _requests[idx];
                            if (r['status'] != 'PENDING') return const SizedBox.shrink();

                            final name = r['user_name'] ?? 'Applicant';
                            final phone = r['user_phone'] ?? '';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.orange,
                                  child: Icon(Icons.person_add, color: Colors.white),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Phone: $phone\nStatus: Pending Approval'),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _acceptRequest(r['id']),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                      child: const Text('Accept'),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () => _rejectRequest(r['id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ],
            ),
    );
  }
}

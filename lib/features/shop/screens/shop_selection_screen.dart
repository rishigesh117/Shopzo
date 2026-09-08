import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/sync_status_badge.dart';
import '../../dashboard/dashboard_screen.dart';

class ShopSelectionScreen extends StatefulWidget {
  const ShopSelectionScreen({super.key});

  @override
  State<ShopSelectionScreen> createState() => _ShopSelectionScreenState();
}

class _ShopSelectionScreenState extends State<ShopSelectionScreen> {
  List<dynamic> _myShops = [];
  List<dynamic> _invitations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShopsAndInvitations();
  }

  Future<void> _loadShopsAndInvitations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final shopsRes = await ApiService.instance.get('/shops/my-shops');
    final invRes = await ApiService.instance.get('/members/my-invitations');

    setState(() {
      _isLoading = false;
      if (shopsRes.success && shopsRes.data is List) {
        _myShops = shopsRes.data;
      }
      if (invRes.success && invRes.data is List) {
        _invitations = invRes.data;
      }
    });
  }

  Future<void> _handleCreateShop() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Shop'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Shop Name',
            hintText: 'e.g. SuperMart Chennai',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final res = await ApiService.instance.post('/shops/create', body: {'name': result});
      if (res.success && res.data != null) {
        final shop = res.data;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Shop "${shop['name']}" created! Shop Code: ${shop['shop_code']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadShopsAndInvitations();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.error ?? 'Failed to create shop'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleJoinShop() async {
    final codeController = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Shop via Code'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Shop Code',
            hintText: 'e.g. SHOP-A1B2C3',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, codeController.text.trim()),
            child: const Text('Request to Join'),
          ),
        ],
      ),
    );

    if (code != null && code.isNotEmpty) {
      final res = await ApiService.instance.post('/members/request-join', body: {'shopCode': code});
      if (res.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Join request sent to Shop Owner! Waiting for approval.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.error ?? 'Failed to join shop'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _acceptInvitation(String invitationId) async {
    final res = await ApiService.instance.post('/members/invitations/$invitationId/accept');
    if (res.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation accepted! You are now a shop member.'), backgroundColor: Colors.green),
        );
      }
      _loadShopsAndInvitations();
    }
  }

  Future<void> _declineInvitation(String invitationId) async {
    final res = await ApiService.instance.post('/members/invitations/$invitationId/decline');
    if (res.success) {
      _loadShopsAndInvitations();
    }
  }

  void _selectShop(dynamic shop) {
    final shopId = shop['id'] as String;
    ApiService.instance.setActiveShopId(shopId);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Shop', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: SyncStatusBadge(compact: true),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadShopsAndInvitations,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pending Invitations Section
                    if (_invitations.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.mark_email_unread_rounded, color: Colors.amber),
                                SizedBox(width: 8),
                                Text(
                                  'Pending Invitations',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._invitations.map(
                              (inv) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(inv['shop_name'] ?? 'Shop', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Invited by ${inv['invited_by_name'] ?? 'Owner'} (Code: ${inv['shop_code'] ?? ''})'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle, color: Colors.green),
                                        onPressed: () => _acceptInvitation(inv['id']),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel, color: Colors.red),
                                        onPressed: () => _declineInvitation(inv['id']),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Action Buttons (Create / Join)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleCreateShop,
                            icon: const Icon(Icons.add_business_rounded),
                            label: const Text('Create Shop'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF1E88E5),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _handleJoinShop,
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                            label: const Text('Join Shop Code'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Your Shops & Memberships',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    if (_myShops.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.store_mall_directory_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No active shops found.'),
                            SizedBox(height: 4),
                            Text('Create a new shop or enter a Shop Code to join an existing shop.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _myShops.length,
                        itemBuilder: (ctx, idx) {
                          final shop = _myShops[idx];
                          final role = shop['role'] ?? 'OWNER';
                          final isOwner = role == 'OWNER';

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: isOwner ? Colors.blue.shade100 : Colors.green.shade100,
                                child: Icon(
                                  isOwner ? Icons.workspace_premium : Icons.badge,
                                  color: isOwner ? Colors.blue.shade900 : Colors.green.shade900,
                                ),
                              ),
                              title: Text(
                                shop['name'] ?? 'Shop',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Role: $role • Code: ${shop['shop_code'] ?? 'N/A'}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                              onTap: () => _selectShop(shop),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

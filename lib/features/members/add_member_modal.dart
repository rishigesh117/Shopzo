import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/permission_model.dart';
import '../../core/providers/member_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_text_field.dart';
import 'permission_selection_screen.dart';

class AddMemberModal extends StatefulWidget {
  const AddMemberModal({super.key});

  @override
  State<AddMemberModal> createState() => _AddMemberModalState();
}

class _AddMemberModalState extends State<AddMemberModal> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  ShopzoPermissions _selectedPermissions = ShopzoPermissions.standardStaff();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSendInvitation() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid employee details')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final memberProvider = Provider.of<MemberProvider>(context, listen: false);
        memberProvider.addMemberInvitation(
          name: name,
          phone: phone,
          permissions: _selectedPermissions,
        );

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to $name!'),
            backgroundColor: ShopzoColors.secondaryGreen,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Invite Employee',
                style: ShopzoTypography.headingMedium(context, isDark: isDark),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ShopzoTextField(
            label: 'Employee Name',
            hint: 'e.g. Suresh Kumar',
            controller: _nameController,
            prefixIcon: Icons.person_rounded,
          ),
          const SizedBox(height: 16),
          ShopzoTextField(
            label: 'Employee Phone Number',
            hint: '98765 12345',
            controller: _phoneController,
            isPhone: true,
          ),
          const SizedBox(height: 20),
          // Permission Summary & Configure Link
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? ShopzoColors.darkBorder : ShopzoColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permissions',
                        style: ShopzoTypography.headingSmall(context, isDark: isDark).copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedPermissions.isFullAccess
                            ? 'Full Access (All 15 Permissions)'
                            : '${_selectedPermissions.enabledCount} of 15 Permissions Enabled',
                        style: ShopzoTypography.bodySmall(context, isDark: isDark),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PermissionSelectionScreen(
                          initialPermissions: _selectedPermissions,
                          memberName: _nameController.text.isEmpty ? 'Employee' : _nameController.text,
                          onSave: (newPerms) {
                            setState(() {
                              _selectedPermissions = newPerms;
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text('Configure'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ShopzoButton(
            text: 'Send Invitation',
            isLoading: _isLoading,
            onPressed: _handleSendInvitation,
          ),
        ],
      ),
    );
  }
}

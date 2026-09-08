import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/member_model.dart';
import '../../core/providers/member_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_badge.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_card.dart';
import '../../core/widgets/shopzo_dialog.dart';
import '../../core/widgets/shopzo_header.dart';
import 'add_member_modal.dart';
import 'member_invitation_view.dart';
import 'permission_selection_screen.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  void _showAddMemberModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddMemberModal(),
    );
  }

  void _showMemberDetails(BuildContext context, ShopMember member) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? ShopzoColors.darkSurface : ShopzoColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(member.name, style: ShopzoTypography.headingMedium(ctx, isDark: isDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${member.phone}', style: ShopzoTypography.bodyMedium(ctx, isDark: isDark)),
            const SizedBox(height: 6),
            Text('Role: ${member.role.name.toUpperCase()}', style: ShopzoTypography.bodyMedium(ctx, isDark: isDark)),
            const SizedBox(height: 6),
            Text('Status: ${member.status.name.toUpperCase()}', style: ShopzoTypography.bodyMedium(ctx, isDark: isDark)),
            const SizedBox(height: 12),
            Text(
              member.permissions.isFullAccess
                  ? 'Access: Full Access'
                  : 'Enabled Permissions: ${member.permissions.enabledCount} of 15',
              style: ShopzoTypography.bodyMedium(ctx, isDark: isDark).copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final memberProvider = Provider.of<MemberProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          ShopzoHeader(
            title: 'Shop Members',
            subtitle: 'Manage team access and permissions',
            trailing: SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShopzoColors.secondaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Add Member'),
                onPressed: () => _showAddMemberModal(context),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MemberInvitationView(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Team Members (${memberProvider.members.length})',
                        style: ShopzoTypography.headingMedium(context, isDark: isDark),
                      ),
                      ShopzoBadge(
                        label: '${memberProvider.activeMembers.length} Active',
                        type: ShopzoBadgeType.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: memberProvider.members.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final member = memberProvider.members[index];
                      final isPending = member.status == MemberStatus.pending;

                      return ShopzoCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: isPending
                                      ? ShopzoColors.warning.withOpacity(0.2)
                                      : ShopzoColors.primaryNavy.withOpacity(0.12),
                                  child: Text(
                                    member.name.substring(0, 1),
                                    style: ShopzoTypography.headingSmall(context, isDark: isDark).copyWith(
                                      color: isPending ? ShopzoColors.warning : ShopzoColors.primaryNavy,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            member.name,
                                            style: ShopzoTypography.headingSmall(context, isDark: isDark),
                                          ),
                                          const SizedBox(width: 8),
                                          ShopzoBadge(
                                            label: isPending ? 'Pending' : 'Active',
                                            type: isPending ? ShopzoBadgeType.warning : ShopzoBadgeType.success,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Phone: ${member.maskedPhone} • Staff',
                                        style: ShopzoTypography.bodySmall(context, isDark: isDark),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? ShopzoColors.darkSurfaceSecondary : ShopzoColors.lightSurfaceSecondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    member.permissions.isFullAccess
                                        ? 'Full Access'
                                        : '${member.permissions.enabledCount}/15 Perms',
                                    style: ShopzoTypography.bodySmall(context, isDark: isDark).copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isPending) ...[
                                  TextButton.icon(
                                    icon: const Icon(Icons.check_rounded, size: 16, color: ShopzoColors.success),
                                    label: const Text('Accept', style: TextStyle(color: ShopzoColors.success)),
                                    onPressed: () => memberProvider.acceptMemberRequest(member.id),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.close_rounded, size: 16, color: ShopzoColors.danger),
                                    label: const Text('Reject', style: TextStyle(color: ShopzoColors.danger)),
                                    onPressed: () => memberProvider.rejectMemberRequest(member.id),
                                  ),
                                ],
                                TextButton.icon(
                                  icon: const Icon(Icons.visibility_rounded, size: 16),
                                  label: const Text('View'),
                                  onPressed: () => _showMemberDetails(context, member),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.tune_rounded, size: 16),
                                  label: const Text('Edit Permissions'),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => PermissionSelectionScreen(
                                          initialPermissions: member.permissions,
                                          memberName: member.name,
                                          onSave: (newPerms) {
                                            memberProvider.updateMemberPermissions(member.id, newPerms);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: ShopzoColors.danger),
                                  tooltip: 'Remove Member',
                                  onPressed: () {
                                    ShopzoDialog.show(
                                      context,
                                      title: 'Remove Member',
                                      message: 'Are you sure you want to remove ${member.name} from your shop?',
                                      confirmText: 'Remove',
                                      isDestructive: true,
                                      icon: Icons.person_remove_rounded,
                                    ).then((confirmed) {
                                      if (confirmed == true) {
                                        memberProvider.removeMember(member.id);
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

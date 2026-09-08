import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/member_provider.dart';
import '../../core/theme/shopzo_colors.dart';
import '../../core/theme/shopzo_typography.dart';
import '../../core/widgets/shopzo_button.dart';
import '../../core/widgets/shopzo_card.dart';

class MemberInvitationView extends StatelessWidget {
  const MemberInvitationView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final memberProvider = Provider.of<MemberProvider>(context);

    if (!memberProvider.hasPendingInvitation) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ShopzoCard(
        backgroundColor: ShopzoColors.secondaryGreen.withOpacity(0.08),
        borderColor: ShopzoColors.secondaryGreen.withOpacity(0.4),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: ShopzoColors.secondaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shop Invitation Received',
                        style: ShopzoTypography.headingSmall(context, isDark: isDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${memberProvider.invitingShopName} wants you to join their shop.',
                        style: ShopzoTypography.bodyMedium(context, isDark: isDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ShopzoButton(
                    text: 'Decline',
                    isSecondary: true,
                    onPressed: () {
                      memberProvider.respondToInvitation(false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invitation declined')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShopzoButton(
                    text: 'Accept',
                    backgroundColor: ShopzoColors.secondaryGreen,
                    onPressed: () {
                      memberProvider.respondToInvitation(true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully joined shop!'),
                          backgroundColor: ShopzoColors.secondaryGreen,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

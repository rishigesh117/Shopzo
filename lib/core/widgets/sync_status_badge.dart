import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import '../services/connectivity_service.dart';

class SyncStatusBadge extends StatelessWidget {
  final bool compact;

  const SyncStatusBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProv, child) {
        final state = syncProv.statusState;
        final isOnline = syncProv.isOnline;

        Color bgColor;
        Color textColor;
        IconData iconData;
        String text;

        if (syncProv.isSyncing) {
          bgColor = Colors.amber.shade100;
          textColor = Colors.amber.shade900;
          iconData = Icons.sync;
          text = 'Syncing...';
        } else if (!isOnline || state == SyncStatusState.offline) {
          bgColor = Colors.grey.shade200;
          textColor = Colors.grey.shade800;
          iconData = Icons.cloud_off;
          text = 'Offline Mode';
        } else if (state == SyncStatusState.error) {
          bgColor = Colors.red.shade100;
          textColor = Colors.red.shade900;
          iconData = Icons.warning_amber_rounded;
          text = 'Sync Error';
        } else {
          bgColor = Colors.green.shade100;
          textColor = Colors.green.shade900;
          iconData = Icons.cloud_done;
          text = 'Synced';
        }

        if (compact) {
          return InkWell(
            onTap: () => syncProv.triggerSync(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (syncProv.isSyncing)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  else
                    Icon(iconData, size: 14, color: textColor),
                  const SizedBox(width: 4),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: textColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (syncProv.isSyncing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              else
                Icon(iconData, size: 18, color: textColor),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.refresh, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: textColor,
                tooltip: 'Sync Now',
                onPressed: () => syncProv.triggerSync(),
              ),
            ],
          ),
        );
      },
    );
  }
}

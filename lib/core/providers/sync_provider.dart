import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

class SyncProvider extends ChangeNotifier {
  ConnectivityService get connectivity => ConnectivityService.instance;
  SyncService get syncService => SyncService.instance;

  SyncProvider() {
    connectivity.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    notifyListeners();
  }

  bool get isOnline => connectivity.isOnline;
  SyncStatusState get statusState => connectivity.statusState;
  String? get lastError => connectivity.lastError;
  bool get isSyncing => syncService.isSyncing;

  Future<bool> triggerSync() async {
    final success = await syncService.syncNow();
    notifyListeners();
    return success;
  }

  @override
  void dispose() {
    connectivity.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

enum SyncStatusState {
  offline,
  syncing,
  synced,
  error,
}

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService instance = ConnectivityService._internal();

  bool _isOnline = false;
  SyncStatusState _statusState = SyncStatusState.offline;
  String? _lastError;
  Timer? _pingTimer;

  ConnectivityService._internal() {
    _startPingTimer();
  }

  bool get isOnline => _isOnline;
  SyncStatusState get statusState => _statusState;
  String? get lastError => _lastError;

  void _startPingTimer() {
    checkConnectivity();
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) => checkConnectivity());
  }

  Future<bool> checkConnectivity() async {
    try {
      final res = await ApiService.instance.get('/health');
      final reachable = res.success;

      if (_isOnline != reachable) {
        _isOnline = reachable;
        if (_isOnline) {
          _statusState = SyncStatusState.synced;
          _lastError = null;
        } else {
          _statusState = SyncStatusState.offline;
        }
        notifyListeners();
      }
      return _isOnline;
    } catch (_) {
      if (_isOnline) {
        _isOnline = false;
        _statusState = SyncStatusState.offline;
        notifyListeners();
      }
      return false;
    }
  }

  void setStatusState(SyncStatusState state, {String? error}) {
    _statusState = state;
    _lastError = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }
}

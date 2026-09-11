package com.shopzo.app.core.sync

import com.shopzo.app.core.network.NetworkResult
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.concurrent.atomic.AtomicBoolean

enum class SyncState {
    SYNCED,
    SYNCING,
    OFFLINE,
    ERROR
}

data class SyncStatusInfo(
    val state: SyncState = SyncState.SYNCED,
    val pendingCount: Int = 0,
    val lastSyncedAt: Long = 0L,
    val message: String = "All data synced"
)

class SyncManager(
    private val syncRepository: SyncRepository,
    private val getCurrentShopId: () -> String?,
    private val isNetworkAvailable: () -> Boolean
) {
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val isSyncing = AtomicBoolean(false)

    private val _syncStatus = MutableStateFlow(SyncStatusInfo())
    val syncStatus: StateFlow<SyncStatusInfo> = _syncStatus.asStateFlow()

    fun syncNow() {
        val shopId = getCurrentShopId() ?: return
        if (!isNetworkAvailable()) {
            _syncStatus.value = _syncStatus.value.copy(
                state = SyncState.OFFLINE,
                message = "Offline — Changes saved locally"
            )
            return
        }

        if (isSyncing.compareAndSet(false, true)) {
            scope.launch {
                try {
                    _syncStatus.value = _syncStatus.value.copy(
                        state = SyncState.SYNCING,
                        message = "Syncing with cloud..."
                    )

                    // 1. Push local pending changes to backend
                    val pushResult = syncRepository.pushPendingOperations(shopId)

                    // 2. Pull cloud delta updates
                    val lastSynced = _syncStatus.value.lastSyncedAt
                    val pullResult = syncRepository.pullDeltaUpdates(shopId, lastSynced)

                    val newServerTime = if (pullResult is NetworkResult.Success) pullResult.data else System.currentTimeMillis()

                    _syncStatus.value = SyncStatusInfo(
                        state = SyncState.SYNCED,
                        pendingCount = 0,
                        lastSyncedAt = newServerTime,
                        message = "All data synced"
                    )
                } catch (e: Exception) {
                    _syncStatus.value = _syncStatus.value.copy(
                        state = SyncState.ERROR,
                        message = "Sync failed — Will retry"
                    )
                } finally {
                    isSyncing.set(false)
                }
            }
        }
    }
}

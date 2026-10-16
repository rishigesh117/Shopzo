package com.shopzo.app.core.sync

/**
 * Global event trigger to request immediate synchronization when local data changes.
 */
object SyncTrigger {
    @Volatile
    var onSyncNeeded: (() -> Unit)? = null

    fun trigger() {
        onSyncNeeded?.invoke()
    }
}

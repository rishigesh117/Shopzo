package com.shopzo.app.core.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.shopzo.app.core.database.entity.SyncQueueEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface SyncDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(queueItem: SyncQueueEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(queueItems: List<SyncQueueEntity>)

    @Query("SELECT * FROM sync_queue WHERE shopId = :shopId AND status = 'PENDING' ORDER BY createdAt ASC LIMIT :limit")
    suspend fun getPendingItems(shopId: String, limit: Int = 50): List<SyncQueueEntity>

    @Query("SELECT * FROM sync_queue WHERE shopId = :shopId AND status = 'PENDING' ORDER BY createdAt ASC")
    fun observePendingItems(shopId: String): Flow<List<SyncQueueEntity>>

    @Query("SELECT COUNT(*) FROM sync_queue WHERE shopId = :shopId AND status = 'PENDING'")
    fun observePendingCount(shopId: String): Flow<Int>

    @Query("SELECT COUNT(*) FROM sync_queue WHERE shopId = :shopId AND status = 'FAILED'")
    fun observeFailedCount(shopId: String): Flow<Int>

    @Query("UPDATE sync_queue SET status = 'SYNCED', lastAttemptAt = :timestamp WHERE id IN (:ids)")
    suspend fun markSynced(ids: List<Long>, timestamp: Long = System.currentTimeMillis())

    @Query("UPDATE sync_queue SET status = :status, retryCount = :retryCount, lastAttemptAt = :timestamp, errorMessage = :errorMessage WHERE id = :id")
    suspend fun updateItemStatus(id: Long, status: String, retryCount: Int, timestamp: Long = System.currentTimeMillis(), errorMessage: String?)

    @Query("DELETE FROM sync_queue WHERE status = 'SYNCED' AND createdAt < :beforeTimestamp")
    suspend fun purgeOldSyncedItems(beforeTimestamp: Long)
}

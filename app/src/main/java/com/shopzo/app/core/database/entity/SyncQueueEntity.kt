package com.shopzo.app.core.database.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * Room Entity for storing local offline mutation queue items.
 *
 * Each record represents a local change that needs to be synchronized with PostgreSQL when online.
 */
@Entity(
    tableName = "sync_queue",
    indices = [
        Index("shopId"),
        Index("status"),
        Index(value = ["shopId", "status"])
    ]
)
data class SyncQueueEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val entityType: String,      // CATEGORY, PRODUCT, STOCK_MOVEMENT, CUSTOMER, BILL, BILL_ITEM, PAYMENT, RETURN
    val entityId: String,        // Client-side UUID
    val operationType: String,   // CREATE, UPDATE, DELETE
    val payloadJson: String,     // JSON string payload
    val shopId: String,
    val createdAt: Long = System.currentTimeMillis(),
    val retryCount: Int = 0,
    val lastAttemptAt: Long? = null,
    val status: String = "PENDING", // PENDING, SYNCED, FAILED
    val errorMessage: String? = null
)

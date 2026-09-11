package com.shopzo.app.core.database.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * Represents a product return transaction linked to a specific bill item.
 */
@Entity(
    tableName = "returns",
    indices = [
        Index("billId"),
        Index("billItemId"),
        Index("productId"),
        Index("shopId")
    ]
)
data class ReturnEntity(
    @PrimaryKey
    val id: String,
    val billId: String,
    val billItemId: String,
    val productId: String,
    val quantityReturned: Double,
    val refundAmountPaise: Long,
    val stockRestored: Boolean,
    val reason: String = "",
    val createdAt: Long = System.currentTimeMillis(),
    val shopId: String
)

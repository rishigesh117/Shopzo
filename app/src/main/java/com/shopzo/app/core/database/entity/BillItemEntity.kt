package com.shopzo.app.core.database.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * Represents a single line item within a bill.
 * Stores historical buyingPricePaise at time of sale for accurate profit calculations.
 */
@Entity(
    tableName = "bill_items",
    indices = [
        Index("billId"),
        Index("productId"),
        Index("shopId")
    ]
)
data class BillItemEntity(
    @PrimaryKey
    val id: String,
    val billId: String,
    val productId: String,
    val productNameSnapshot: String,
    val quantity: Double,
    val unit: String,
    val sellingPricePaise: Long,
    val buyingPricePaise: Long, // Historical buying price snapshot!
    val subtotalPaise: Long,
    val shopId: String
)

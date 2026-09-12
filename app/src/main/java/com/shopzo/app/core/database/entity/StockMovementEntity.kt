package com.shopzo.app.core.database.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.Serializable

/**
 * Records every stock change — restock or adjustment — for full audit trail.
 */
@Serializable
@Entity(tableName = "stock_movements")
data class StockMovementEntity(
    @PrimaryKey
    val id: String,                    // UUID
    val productId: String,             // references ProductEntity.id
    val type: String,                  // StockMovementType enum name (RESTOCK / ADJUSTMENT / SALE / RETURN)
    val quantityChange: Double,        // positive for restock/return, negative for sale/loss
    val previousQuantity: Double,
    val newQuantity: Double,
    val buyingPricePaise: Long?,       // only for RESTOCK
    val supplier: String?,             // optional supplier name
    val reason: String?,               // AdjustmentReason enum name (only for ADJUSTMENT)
    val notes: String?,                // optional
    val shopId: String,                // references ShopEntity.id
    val createdAt: Long                // epoch millis
)

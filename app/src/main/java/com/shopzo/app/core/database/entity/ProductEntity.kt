package com.shopzo.app.core.database.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Represents a product in a shop.
 *
 * - Prices stored as integer paise (₹100.50 = 10050)
 * - Quantity stored as Double to support fractional units (Kg, Litre, etc.)
 */
@Entity(tableName = "products")
data class ProductEntity(
    @PrimaryKey
    val id: String,                    // UUID
    val name: String,
    val categoryId: String,            // references CategoryEntity.id
    val brand: String?,                // optional
    val buyingPricePaise: Long,        // in paise
    val sellingPricePaise: Long,       // in paise
    val quantity: Double,              // current stock quantity
    val unit: String,                  // ProductUnit enum name
    val minStockLevel: Double,         // minimum stock threshold
    val shopId: String,                // references ShopEntity.id
    val createdAt: Long,               // epoch millis
    val updatedAt: Long                // epoch millis
)

val ProductEntity.stockQuantity: Double get() = quantity
val ProductEntity.lowStockThreshold: Double get() = minStockLevel

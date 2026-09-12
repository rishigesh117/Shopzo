package com.shopzo.app.core.database.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.Serializable

/**
 * Represents a product category within a shop.
 */
@Serializable
@Entity(tableName = "categories")
data class CategoryEntity(
    @PrimaryKey
    val id: String,                // UUID
    val name: String,
    val shopId: String,            // references ShopEntity.id
    val createdAt: Long            // epoch millis
)

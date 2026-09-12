package com.shopzo.app.core.database.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import kotlinx.serialization.Serializable

/**
 * Represents a shop in the SHOPZO system.
 */
@Serializable
@Entity(
    tableName = "shops",
    indices = [Index(value = ["shopCode"], unique = true)]
)
data class ShopEntity(
    @PrimaryKey
    val id: String,                // UUID
    val shopName: String,
    val ownerName: String,
    val mobileNumber: String,
    val address: String?,          // optional
    val shopCode: String,          // SZ-XXXXXX format
    val ownerId: String,           // references UserEntity.id
    val createdAt: Long            // epoch millis
)

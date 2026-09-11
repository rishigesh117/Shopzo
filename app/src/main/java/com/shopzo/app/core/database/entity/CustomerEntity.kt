package com.shopzo.app.core.database.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * Represents a customer registered in a shop.
 */
@Entity(
    tableName = "customers",
    indices = [
        Index("shopId"),
        Index("mobileNumber")
    ]
)
data class CustomerEntity(
    @PrimaryKey
    val id: String,
    val name: String,
    val mobileNumber: String,
    val address: String? = null,
    val totalPurchasePaise: Long = 0L,
    val outstandingDuePaise: Long = 0L,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val shopId: String
)

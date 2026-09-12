package com.shopzo.app.core.database.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import kotlinx.serialization.Serializable

/**
 * Represents a sale transaction / bill.
 */
@Serializable
@Entity(
    tableName = "bills",
    indices = [
        Index("shopId"),
        Index("customerId"),
        Index(value = ["shopId", "billNumber"], unique = true)
    ]
)
data class BillEntity(
    @PrimaryKey
    val id: String,
    val billNumber: String,
    val customerId: String? = null,
    val customerNameSnapshot: String = "Walk-in Customer",
    val customerMobileSnapshot: String = "",
    val subtotalPaise: Long,
    val grandTotalPaise: Long,
    val paidAmountPaise: Long,
    val pendingAmountPaise: Long,
    val paymentStatus: String, // PAID, PARTIALLY_PAID, PENDING
    val createdAt: Long = System.currentTimeMillis(),
    val shopId: String
)

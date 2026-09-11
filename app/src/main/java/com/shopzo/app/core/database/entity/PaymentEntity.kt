package com.shopzo.app.core.database.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * Represents a payment transaction made by a customer for a bill or outstanding due.
 */
@Entity(
    tableName = "payments",
    indices = [
        Index("billId"),
        Index("customerId"),
        Index("shopId")
    ]
)
data class PaymentEntity(
    @PrimaryKey
    val id: String,
    val billId: String? = null,
    val customerId: String,
    val amountPaise: Long,
    val paymentMethod: String, // CASH, UPI, CARD, CREDIT
    val createdAt: Long = System.currentTimeMillis(),
    val shopId: String
)

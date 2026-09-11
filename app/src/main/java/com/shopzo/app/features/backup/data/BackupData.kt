package com.shopzo.app.features.backup.data

import com.shopzo.app.core.database.entity.*
import kotlinx.serialization.Serializable

/**
 * Serializable data container for complete Shopzo shop database backups.
 */
@Serializable
data class ShopzoBackup(
    val version: Int = 1,
    val exportedAt: Long = System.currentTimeMillis(),
    val shopId: String,
    val categories: List<CategoryBackupDto> = emptyList(),
    val products: List<ProductBackupDto> = emptyList(),
    val stockMovements: List<StockMovementBackupDto> = emptyList(),
    val customers: List<CustomerBackupDto> = emptyList(),
    val bills: List<BillBackupDto> = emptyList(),
    val billItems: List<BillItemBackupDto> = emptyList(),
    val payments: List<PaymentBackupDto> = emptyList(),
    val returns: List<ReturnBackupDto> = emptyList()
)

@Serializable
data class CategoryBackupDto(
    val id: String,
    val name: String,
    val shopId: String,
    val createdAt: Long
)

@Serializable
data class ProductBackupDto(
    val id: String,
    val name: String,
    val categoryId: String,
    val brand: String? = null,
    val buyingPricePaise: Long,
    val sellingPricePaise: Long,
    val quantity: Double,
    val unit: String,
    val minStockLevel: Double,
    val shopId: String,
    val createdAt: Long,
    val updatedAt: Long
)

@Serializable
data class StockMovementBackupDto(
    val id: String,
    val productId: String,
    val type: String,
    val quantityChange: Double,
    val previousQuantity: Double,
    val newQuantity: Double,
    val buyingPricePaise: Long? = null,
    val supplier: String? = null,
    val reason: String? = null,
    val notes: String? = null,
    val shopId: String,
    val createdAt: Long
)

@Serializable
data class CustomerBackupDto(
    val id: String,
    val name: String,
    val mobileNumber: String,
    val address: String? = null,
    val totalPurchasePaise: Long,
    val outstandingDuePaise: Long,
    val createdAt: Long,
    val updatedAt: Long,
    val shopId: String
)

@Serializable
data class BillBackupDto(
    val id: String,
    val billNumber: String,
    val customerId: String? = null,
    val customerNameSnapshot: String,
    val customerMobileSnapshot: String,
    val subtotalPaise: Long,
    val grandTotalPaise: Long,
    val paidAmountPaise: Long,
    val pendingAmountPaise: Long,
    val paymentStatus: String,
    val createdAt: Long,
    val shopId: String
)

@Serializable
data class BillItemBackupDto(
    val id: String,
    val billId: String,
    val productId: String,
    val productNameSnapshot: String,
    val quantity: Double,
    val unit: String,
    val sellingPricePaise: Long,
    val buyingPricePaise: Long,
    val subtotalPaise: Long,
    val shopId: String
)

@Serializable
data class PaymentBackupDto(
    val id: String,
    val billId: String? = null,
    val customerId: String,
    val amountPaise: Long,
    val paymentMethod: String,
    val createdAt: Long,
    val shopId: String
)

@Serializable
data class ReturnBackupDto(
    val id: String,
    val billId: String,
    val billItemId: String,
    val productId: String,
    val quantityReturned: Double,
    val refundAmountPaise: Long,
    val stockRestored: Boolean,
    val reason: String,
    val createdAt: Long,
    val shopId: String
)

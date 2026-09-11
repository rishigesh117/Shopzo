package com.shopzo.app.core.network.dto

import kotlinx.serialization.Serializable

@Serializable
data class RegisterRequest(
    val name: String,
    val mobileNumber: String,
    val password: String
)

@Serializable
data class LoginRequest(
    val mobileNumber: String,
    val password: String
)

@Serializable
data class UserDto(
    val id: String,
    val mobileNumber: String,
    val name: String
)

@Serializable
data class ShopDto(
    val id: String,
    val shopCode: String,
    val name: String,
    val ownerId: String,
    val address: String? = null,
    val role: String? = null,
    val createdAt: Long? = null,
    val updatedAt: Long? = null
)

@Serializable
data class AuthResponse(
    val token: String,
    val user: UserDto,
    val shops: List<ShopDto> = emptyList()
)

@Serializable
data class CreateShopRequest(
    val name: String,
    val address: String? = null
)

@Serializable
data class ShopResponse(
    val shop: ShopDto
)

@Serializable
data class MyShopsResponse(
    val shops: List<ShopDto>
)

@Serializable
data class AddStaffRequest(
    val name: String,
    val mobileNumber: String,
    val password: String,
    val permissions: List<String>
)

@Serializable
data class StaffDto(
    val staffId: String,
    val userId: String,
    val name: String,
    val mobileNumber: String,
    val role: String,
    val permissions: List<String>
)

@Serializable
data class StaffListResponse(
    val staff: List<StaffDto>
)

@Serializable
data class StaffResponse(
    val staff: StaffDto
)

@Serializable
data class UpdatePermissionsRequest(
    val permissions: List<String>
)

@Serializable
data class SyncOperationDto(
    val id: String,
    val entityType: String,
    val entityId: String,
    val operationType: String,
    val payload: String, // JSON payload string
    val shopId: String,
    val createdAt: Long
)

@Serializable
data class SyncPushRequest(
    val shopId: String,
    val operations: List<SyncOperationDto>
)

@Serializable
data class SyncPushResponse(
    val syncedIds: List<String>,
    val serverTime: Long
)

@Serializable
data class CategoryDto(
    val id: String,
    val shopId: String,
    val name: String,
    val createdAt: Long,
    val updatedAt: Long,
    val deleted: Boolean = false
)

@Serializable
data class ProductDto(
    val id: String,
    val shopId: String,
    val categoryId: String,
    val name: String,
    val brand: String? = null,
    val buyingPricePaise: Long,
    val sellingPricePaise: Long,
    val quantity: Double,
    val unit: String,
    val minStockLevel: Double,
    val createdAt: Long,
    val updatedAt: Long,
    val deleted: Boolean = false
)

@Serializable
data class StockMovementDto(
    val id: String,
    val shopId: String,
    val productId: String,
    val type: String,
    val quantity: Double,
    val reason: String? = null,
    val createdAt: Long
)

@Serializable
data class CustomerDto(
    val id: String,
    val shopId: String,
    val name: String,
    val mobileNumber: String,
    val address: String? = null,
    val totalPurchasePaise: Long,
    val outstandingDuePaise: Long,
    val createdAt: Long,
    val updatedAt: Long,
    val deleted: Boolean = false
)

@Serializable
data class BillDto(
    val id: String,
    val shopId: String,
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
    val updatedAt: Long
)

@Serializable
data class BillItemDto(
    val id: String,
    val shopId: String,
    val billId: String,
    val productId: String,
    val productNameSnapshot: String,
    val quantity: Double,
    val unit: String,
    val sellingPricePaise: Long,
    val buyingPricePaise: Long,
    val subtotalPaise: Long
)

@Serializable
data class PaymentDto(
    val id: String,
    val shopId: String,
    val billId: String? = null,
    val customerId: String? = null,
    val amountPaise: Long,
    val paymentMethod: String,
    val createdAt: Long
)

@Serializable
data class ReturnDto(
    val id: String,
    val shopId: String,
    val billId: String,
    val billItemId: String,
    val productId: String,
    val quantityReturned: Double,
    val refundAmountPaise: Long,
    val stockRestored: Boolean,
    val reason: String? = null,
    val createdAt: Long
)

@Serializable
data class SyncDeltaDto(
    val categories: List<CategoryDto> = emptyList(),
    val products: List<ProductDto> = emptyList(),
    val stockMovements: List<StockMovementDto> = emptyList(),
    val customers: List<CustomerDto> = emptyList(),
    val bills: List<BillDto> = emptyList(),
    val billItems: List<BillItemDto> = emptyList(),
    val payments: List<PaymentDto> = emptyList(),
    val returns: List<ReturnDto> = emptyList()
)

@Serializable
data class SyncPullResponse(
    val serverTime: Long,
    val delta: SyncDeltaDto
)

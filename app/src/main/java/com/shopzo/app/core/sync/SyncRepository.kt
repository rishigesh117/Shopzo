package com.shopzo.app.core.sync

import com.shopzo.app.core.database.ShopzoDatabase
import com.shopzo.app.core.database.entity.*
import com.shopzo.app.core.network.NetworkResult
import com.shopzo.app.core.network.ShopzoApiService
import com.shopzo.app.core.network.dto.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class SyncRepository(
    private val database: ShopzoDatabase,
    private val apiService: ShopzoApiService
) {
    private val syncDao = database.syncDao()
    private val json = Json { ignoreUnknownKeys = true }

    fun observePendingCount(shopId: String): Flow<Int> = syncDao.observePendingCount(shopId)
    fun observeFailedCount(shopId: String): Flow<Int> = syncDao.observeFailedCount(shopId)

    suspend fun enqueueOperation(
        entityType: String,
        entityId: String,
        operationType: String,
        payloadJson: String,
        shopId: String
    ) = withContext(Dispatchers.IO) {
        val item = SyncQueueEntity(
            entityType = entityType,
            entityId = entityId,
            operationType = operationType,
            payloadJson = payloadJson,
            shopId = shopId,
            createdAt = System.currentTimeMillis(),
            status = "PENDING"
        )
        syncDao.insert(item)
    }

    suspend fun pushPendingOperations(shopId: String): NetworkResult<Int> = withContext(Dispatchers.IO) {
        val pendingItems = syncDao.getPendingItems(shopId, limit = 100)
        if (pendingItems.isEmpty()) {
            return@withContext NetworkResult.Success(0)
        }

        val opDtos = pendingItems.map { item ->
            SyncOperationDto(
                id = item.id.toString(),
                entityType = item.entityType,
                entityId = item.entityId,
                operationType = item.operationType,
                payload = item.payloadJson,
                shopId = item.shopId,
                createdAt = item.createdAt
            )
        }

        try {
            val response = apiService.pushSync(shopId, SyncPushRequest(shopId, opDtos))
            if (response.isSuccessful && response.body() != null) {
                val body = response.body()!!
                val syncedIds = body.syncedIds.mapNotNull { it.toLongOrNull() }
                if (syncedIds.isNotEmpty()) {
                    syncDao.markSynced(syncedIds)
                }
                NetworkResult.Success(syncedIds.size)
            } else {
                NetworkResult.Error(response.code(), response.message())
            }
        } catch (e: Exception) {
            NetworkResult.Exception(e)
        }
    }

    suspend fun pullDeltaUpdates(shopId: String, since: Long): NetworkResult<Long> = withContext(Dispatchers.IO) {
        try {
            val response = apiService.pullSync(shopId, since)
            if (response.isSuccessful && response.body() != null) {
                val body = response.body()!!
                val delta = body.delta

                // Process categories
                delta.categories.forEach { c ->
                    val entity = CategoryEntity(
                        id = c.id,
                        name = c.name,
                        shopId = c.shopId,
                        createdAt = c.createdAt
                    )
                    database.categoryDao().insert(entity)
                }

                // Process products
                delta.products.forEach { p ->
                    val entity = ProductEntity(
                        id = p.id,
                        name = p.name,
                        categoryId = p.categoryId,
                        brand = p.brand,
                        buyingPricePaise = p.buyingPricePaise,
                        sellingPricePaise = p.sellingPricePaise,
                        quantity = p.quantity,
                        unit = p.unit,
                        minStockLevel = p.minStockLevel,
                        shopId = p.shopId,
                        createdAt = p.createdAt,
                        updatedAt = p.updatedAt
                    )
                    database.productDao().insert(entity)
                }

                // Process customers
                delta.customers.forEach { cust ->
                    val entity = CustomerEntity(
                        id = cust.id,
                        name = cust.name,
                        mobileNumber = cust.mobileNumber,
                        address = cust.address,
                        totalPurchasePaise = cust.totalPurchasePaise,
                        outstandingDuePaise = cust.outstandingDuePaise,
                        createdAt = cust.createdAt,
                        updatedAt = cust.updatedAt,
                        shopId = cust.shopId
                    )
                    database.customerDao().insertCustomer(entity)
                }

                // Process bills
                delta.bills.forEach { b ->
                    val entity = BillEntity(
                        id = b.id,
                        billNumber = b.billNumber,
                        customerId = b.customerId,
                        customerNameSnapshot = b.customerNameSnapshot,
                        customerMobileSnapshot = b.customerMobileSnapshot,
                        subtotalPaise = b.subtotalPaise,
                        grandTotalPaise = b.grandTotalPaise,
                        paidAmountPaise = b.paidAmountPaise,
                        pendingAmountPaise = b.pendingAmountPaise,
                        paymentStatus = b.paymentStatus,
                        createdAt = b.createdAt,
                        shopId = b.shopId
                    )
                    database.billDao().insertBill(entity)
                }

                // Process bill items
                delta.billItems.forEach { bi ->
                    val entity = BillItemEntity(
                        id = bi.id,
                        billId = bi.billId,
                        productId = bi.productId,
                        productNameSnapshot = bi.productNameSnapshot,
                        quantity = bi.quantity,
                        unit = bi.unit,
                        sellingPricePaise = bi.sellingPricePaise,
                        buyingPricePaise = bi.buyingPricePaise,
                        subtotalPaise = bi.subtotalPaise,
                        shopId = bi.shopId
                    )
                    database.billItemDao().insertBillItem(entity)
                }

                // Process payments
                delta.payments.forEach { pay ->
                    val entity = PaymentEntity(
                        id = pay.id,
                        billId = pay.billId,
                        customerId = pay.customerId ?: "",
                        amountPaise = pay.amountPaise,
                        paymentMethod = pay.paymentMethod,
                        createdAt = pay.createdAt,
                        shopId = pay.shopId
                    )
                    database.paymentDao().insertPayment(entity)
                }

                // Process returns
                delta.returns.forEach { ret ->
                    val entity = ReturnEntity(
                        id = ret.id,
                        billId = ret.billId,
                        billItemId = ret.billItemId,
                        productId = ret.productId,
                        quantityReturned = ret.quantityReturned,
                        refundAmountPaise = ret.refundAmountPaise,
                        stockRestored = ret.stockRestored,
                        reason = ret.reason ?: "",
                        createdAt = ret.createdAt,
                        shopId = ret.shopId
                    )
                    database.returnDao().insertReturn(entity)
                }

                // Process stock movements
                delta.stockMovements.forEach { sm ->
                    val entity = StockMovementEntity(
                        id = sm.id,
                        productId = sm.productId,
                        type = sm.type,
                        quantityChange = sm.quantity,
                        previousQuantity = 0.0,
                        newQuantity = sm.quantity,
                        buyingPricePaise = null,
                        supplier = null,
                        reason = sm.reason ?: "",
                        notes = "Cloud Sync Movement",
                        shopId = sm.shopId,
                        createdAt = sm.createdAt
                    )
                    database.stockMovementDao().insert(entity)
                }

                NetworkResult.Success(body.serverTime)
            } else {
                NetworkResult.Error(response.code(), response.message())
            }
        } catch (e: Exception) {
            NetworkResult.Exception(e)
        }
    }
}

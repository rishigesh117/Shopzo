package com.shopzo.app.features.returns.data

import androidx.room.withTransaction
import com.shopzo.app.core.database.ShopzoDatabase
import com.shopzo.app.core.database.entity.ReturnEntity
import com.shopzo.app.core.database.entity.StockMovementEntity
import com.shopzo.app.core.database.entity.SyncQueueEntity
import com.shopzo.app.core.database.entity.stockQuantity
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.UUID

class ReturnRepository(
    private val database: ShopzoDatabase
) {
    private val returnDao = database.returnDao()
    private val billDao = database.billDao()
    private val billItemDao = database.billItemDao()
    private val productDao = database.productDao()
    private val stockMovementDao = database.stockMovementDao()
    private val syncDao = database.syncDao()
    private val json = Json { ignoreUnknownKeys = true }

    fun getReturnsByShop(shopId: String): Flow<List<ReturnEntity>> {
        return returnDao.getReturnsByShop(shopId)
    }

    fun getReturnsByBill(billId: String): Flow<List<ReturnEntity>> {
        return returnDao.getReturnsByBillFlow(billId)
    }

    suspend fun getPreviouslyReturnedQuantity(billItemId: String): Double {
        return returnDao.getTotalQuantityReturnedForBillItem(billItemId) ?: 0.0
    }

    suspend fun processReturn(
        shopId: String,
        billId: String,
        billItemId: String,
        quantityToReturn: Double,
        stockRestored: Boolean,
        reason: String
    ): Result<ReturnEntity> {
        if (quantityToReturn <= 0.0) {
            return Result.failure(IllegalArgumentException("Return quantity must be greater than zero."))
        }

        return try {
            val returnRecord = database.withTransaction {
                val bill = billDao.getBillById(billId)
                    ?: throw IllegalArgumentException("Bill not found.")

                val items = billItemDao.getItemsForBill(billId)
                val billItem = items.find { it.id == billItemId }
                    ?: throw IllegalArgumentException("Bill item not found.")

                val prevReturned = returnDao.getTotalQuantityReturnedForBillItem(billItemId) ?: 0.0
                val availableForReturn = billItem.quantity - prevReturned

                if (quantityToReturn > availableForReturn) {
                    throw IllegalArgumentException(
                        "Return quantity exceeds available return quantity ($availableForReturn ${billItem.unit})."
                    )
                }

                val refundAmountPaise = (billItem.sellingPricePaise * quantityToReturn).toLong()
                val now = System.currentTimeMillis()

                val returnEntity = ReturnEntity(
                    id = UUID.randomUUID().toString(),
                    billId = billId,
                    billItemId = billItemId,
                    productId = billItem.productId,
                    quantityReturned = quantityToReturn,
                    refundAmountPaise = refundAmountPaise,
                    stockRestored = stockRestored,
                    reason = reason.trim(),
                    createdAt = now,
                    shopId = shopId
                )
                returnDao.insertReturn(returnEntity)
                enqueueSync("RETURN", returnEntity.id, "CREATE", json.encodeToString(returnEntity), shopId)

                // Restore stock if requested
                if (stockRestored) {
                    val product = productDao.getProductById(billItem.productId)
                    if (product != null) {
                        val prevStock = product.stockQuantity
                        val newStock = prevStock + quantityToReturn
                        productDao.updateStock(billItem.productId, newStock, now)

                        val updatedProd = product.copy(quantity = newStock, updatedAt = now)
                        enqueueSync("PRODUCT", billItem.productId, "UPDATE", json.encodeToString(updatedProd), shopId)

                        val movement = StockMovementEntity(
                            id = UUID.randomUUID().toString(),
                            productId = billItem.productId,
                            type = "RETURN",
                            quantityChange = quantityToReturn,
                            previousQuantity = prevStock,
                            newQuantity = newStock,
                            buyingPricePaise = null,
                            supplier = null,
                            reason = reason.ifEmpty { null },
                            notes = "Return for Bill ${bill.billNumber}: ${reason.ifEmpty { "Customer Return" }}",
                            shopId = shopId,
                            createdAt = now
                        )
                        stockMovementDao.insertStockMovement(movement)
                        enqueueSync("STOCK_MOVEMENT", movement.id, "CREATE", json.encodeToString(movement), shopId)
                    }
                }

                returnEntity
            }
            Result.success(returnRecord)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private suspend fun enqueueSync(entityType: String, entityId: String, operationType: String, payloadJson: String, shopId: String) {
        try {
            syncDao.insert(
                SyncQueueEntity(
                    entityType = entityType,
                    entityId = entityId,
                    operationType = operationType,
                    payloadJson = payloadJson,
                    shopId = shopId,
                    createdAt = System.currentTimeMillis()
                )
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}

package com.shopzo.app.features.stock.data

import com.shopzo.app.core.database.ShopzoDatabase
import com.shopzo.app.core.database.entity.StockMovementEntity
import com.shopzo.app.core.database.entity.SyncQueueEntity
import com.shopzo.app.core.model.AdjustmentReason
import com.shopzo.app.core.model.StockMovementType
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.UUID

class StockRepository(
    private val database: ShopzoDatabase
) {
    private val productDao = database.productDao()
    private val stockMovementDao = database.stockMovementDao()
    private val syncDao = database.syncDao()
    private val json = Json { ignoreUnknownKeys = true }

    suspend fun restock(
        productId: String,
        quantity: Double,
        buyingPricePaise: Long?,
        supplier: String?,
        notes: String?,
        shopId: String
    ): Boolean {
        val product = productDao.getProductById(productId) ?: return false
        val newQuantity = product.quantity + quantity
        val now = System.currentTimeMillis()

        // Update product quantity and optionally buying price
        val updatedProduct = product.copy(
            quantity = newQuantity,
            buyingPricePaise = buyingPricePaise ?: product.buyingPricePaise,
            updatedAt = now
        )
        productDao.update(updatedProduct)
        enqueueSync("PRODUCT", productId, "UPDATE", json.encodeToString(updatedProduct), shopId)

        // Record movement
        val movement = StockMovementEntity(
            id = UUID.randomUUID().toString(),
            productId = productId,
            type = StockMovementType.RESTOCK.name,
            quantityChange = quantity,
            previousQuantity = product.quantity,
            newQuantity = newQuantity,
            buyingPricePaise = buyingPricePaise,
            supplier = supplier?.trim()?.ifEmpty { null },
            reason = null,
            notes = notes?.trim()?.ifEmpty { null },
            shopId = shopId,
            createdAt = now
        )
        stockMovementDao.insert(movement)
        enqueueSync("STOCK_MOVEMENT", movement.id, "CREATE", json.encodeToString(movement), shopId)
        return true
    }

    suspend fun adjustStock(
        productId: String,
        quantityChange: Double,
        reason: AdjustmentReason,
        notes: String?,
        shopId: String
    ): Boolean {
        val product = productDao.getProductById(productId) ?: return false
        val newQuantity = (product.quantity + quantityChange).coerceAtLeast(0.0)
        val now = System.currentTimeMillis()

        val updatedProduct = product.copy(
            quantity = newQuantity,
            updatedAt = now
        )
        productDao.update(updatedProduct)
        enqueueSync("PRODUCT", productId, "UPDATE", json.encodeToString(updatedProduct), shopId)

        val movement = StockMovementEntity(
            id = UUID.randomUUID().toString(),
            productId = productId,
            type = StockMovementType.ADJUSTMENT.name,
            quantityChange = quantityChange,
            previousQuantity = product.quantity,
            newQuantity = newQuantity,
            buyingPricePaise = null,
            supplier = null,
            reason = reason.name,
            notes = notes?.trim()?.ifEmpty { null },
            shopId = shopId,
            createdAt = now
        )
        stockMovementDao.insert(movement)
        enqueueSync("STOCK_MOVEMENT", movement.id, "CREATE", json.encodeToString(movement), shopId)
        return true
    }

    fun getMovementsForProduct(productId: String): Flow<List<StockMovementEntity>> =
        stockMovementDao.getMovementsForProduct(productId)

    private suspend fun enqueueSync(entityType: String, entityId: String, operationType: String, payloadJson: String, shopId: String) {
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
    }
}

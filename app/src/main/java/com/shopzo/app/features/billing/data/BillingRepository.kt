package com.shopzo.app.features.billing.data

import androidx.room.withTransaction
import com.shopzo.app.core.database.ShopzoDatabase
import com.shopzo.app.core.database.entity.BillEntity
import com.shopzo.app.core.database.entity.BillItemEntity
import com.shopzo.app.core.database.entity.PaymentEntity
import com.shopzo.app.core.database.entity.StockMovementEntity
import com.shopzo.app.core.database.entity.SyncQueueEntity
import com.shopzo.app.core.database.entity.stockQuantity
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.UUID

data class CartItem(
    val productId: String,
    val productName: String,
    val quantity: Double,
    val unit: String,
    val sellingPricePaise: Long,
    val buyingPricePaise: Long
) {
    val subtotalPaise: Long get() = (sellingPricePaise * quantity).toLong()
}

class BillingRepository(
    private val database: ShopzoDatabase
) {
    private val billDao = database.billDao()
    private val billItemDao = database.billItemDao()
    private val productDao = database.productDao()
    private val customerDao = database.customerDao()
    private val paymentDao = database.paymentDao()
    private val stockMovementDao = database.stockMovementDao()
    private val syncDao = database.syncDao()
    private val json = Json { ignoreUnknownKeys = true }

    fun getBillsByShop(shopId: String): Flow<List<BillEntity>> {
        return billDao.getBillsByShop(shopId)
    }

    fun getBillsByStatus(shopId: String, status: String): Flow<List<BillEntity>> {
        return billDao.getBillsByStatus(shopId, status)
    }

    fun searchBills(shopId: String, query: String): Flow<List<BillEntity>> {
        return billDao.searchBills(shopId, query)
    }

    suspend fun getBillById(id: String): BillEntity? {
        return billDao.getBillById(id)
    }

    fun getBillByIdFlow(id: String): Flow<BillEntity?> {
        return billDao.getBillByIdFlow(id)
    }

    suspend fun getBillItems(billId: String): List<BillItemEntity> {
        return billItemDao.getItemsForBill(billId)
    }

    fun getBillItemsFlow(billId: String): Flow<List<BillItemEntity>> {
        return billItemDao.getItemsForBillFlow(billId)
    }

    suspend fun createBill(
        shopId: String,
        customerId: String?,
        customerNameSnapshot: String,
        customerMobileSnapshot: String,
        cartItems: List<CartItem>,
        paidAmountPaise: Long,
        paymentMethod: String // CASH, UPI, CARD, CREDIT
    ): Result<BillEntity> {
        if (cartItems.isEmpty()) {
            return Result.failure(IllegalArgumentException("Cart is empty."))
        }

        return try {
            val createdBill = database.withTransaction {
                // 1. Calculate totals
                val grandTotalPaise = cartItems.sumOf { (it.sellingPricePaise * it.quantity).toLong() }

                if (paidAmountPaise > grandTotalPaise) {
                    throw IllegalArgumentException("Paid amount cannot exceed total bill amount of ₹${grandTotalPaise / 100.0}.")
                }
                if (paidAmountPaise < 0) {
                    throw IllegalArgumentException("Paid amount cannot be negative.")
                }

                val pendingAmountPaise = grandTotalPaise - paidAmountPaise
                val paymentStatus = when {
                    pendingAmountPaise <= 0L -> "PAID"
                    paidAmountPaise > 0L -> "PARTIALLY_PAID"
                    else -> "PENDING"
                }

                // 2. Generate unique Bill Number (#1001, #1002, ...)
                val maxNum = billDao.getMaxBillNumberNumeric(shopId) ?: 1000
                val nextNum = maxNum + 1
                val billNumber = "#$nextNum"
                val billId = UUID.randomUUID().toString()
                val now = System.currentTimeMillis()

                // 3. Create Bill Entity
                val bill = BillEntity(
                    id = billId,
                    billNumber = billNumber,
                    customerId = customerId,
                    customerNameSnapshot = customerNameSnapshot.ifEmpty { "Walk-in Customer" },
                    customerMobileSnapshot = customerMobileSnapshot,
                    subtotalPaise = grandTotalPaise,
                    grandTotalPaise = grandTotalPaise,
                    paidAmountPaise = paidAmountPaise,
                    pendingAmountPaise = pendingAmountPaise,
                    paymentStatus = paymentStatus,
                    createdAt = now,
                    shopId = shopId
                )
                billDao.insertBill(bill)
                enqueueSync("BILL", bill.id, "CREATE", json.encodeToString(bill), shopId)

                // 4. Create Bill Items & Reduce Product Stock & Record Stock Movements
                val billItemEntities = ArrayList<BillItemEntity>()
                for (item in cartItems) {
                    val product = productDao.getProductById(item.productId)
                        ?: throw IllegalStateException("Product ${item.productName} not found.")

                    if (product.stockQuantity < item.quantity) {
                        throw IllegalArgumentException("Only ${product.stockQuantity} ${product.unit} available for ${product.name}.")
                    }

                    val subtotal = (item.sellingPricePaise * item.quantity).toLong()
                    val billItem = BillItemEntity(
                        id = UUID.randomUUID().toString(),
                        billId = billId,
                        productId = item.productId,
                        productNameSnapshot = item.productName,
                        quantity = item.quantity,
                        unit = item.unit,
                        sellingPricePaise = item.sellingPricePaise,
                        buyingPricePaise = item.buyingPricePaise,
                        subtotalPaise = subtotal,
                        shopId = shopId
                    )
                    billItemEntities.add(billItem)
                    enqueueSync("BILL_ITEM", billItem.id, "CREATE", json.encodeToString(billItem), shopId)

                    // Stock reduction
                    val previousStock = product.stockQuantity
                    val newStock = previousStock - item.quantity
                    productDao.updateStock(item.productId, newStock, now)

                    val updatedProduct = product.copy(quantity = newStock, updatedAt = now)
                    enqueueSync("PRODUCT", item.productId, "UPDATE", json.encodeToString(updatedProduct), shopId)

                    // Stock Movement record
                    val movement = StockMovementEntity(
                        id = UUID.randomUUID().toString(),
                        productId = item.productId,
                        type = "SALE",
                        quantityChange = -item.quantity,
                        previousQuantity = previousStock,
                        newQuantity = newStock,
                        buyingPricePaise = null,
                        supplier = null,
                        reason = null,
                        notes = "Bill $billNumber",
                        shopId = shopId,
                        createdAt = now
                    )
                    stockMovementDao.insertStockMovement(movement)
                    enqueueSync("STOCK_MOVEMENT", movement.id, "CREATE", json.encodeToString(movement), shopId)
                }
                billItemDao.insertBillItems(billItemEntities)

                // 5. Payment Record if paid > 0
                if (paidAmountPaise > 0L) {
                    val payment = PaymentEntity(
                        id = UUID.randomUUID().toString(),
                        billId = billId,
                        customerId = customerId ?: "WALK_IN",
                        amountPaise = paidAmountPaise,
                        paymentMethod = paymentMethod,
                        createdAt = now,
                        shopId = shopId
                    )
                    paymentDao.insertPayment(payment)
                    enqueueSync("PAYMENT", payment.id, "CREATE", json.encodeToString(payment), shopId)
                }

                // 6. Update Customer Dues & Total Purchase if registered customer
                if (customerId != null) {
                    customerDao.updateDuesAndPurchase(
                        id = customerId,
                        addPurchasePaise = grandTotalPaise,
                        addDuePaise = pendingAmountPaise,
                        updatedAt = now
                    )
                    val updatedCust = customerDao.getCustomerById(customerId)
                    if (updatedCust != null) {
                        enqueueSync("CUSTOMER", customerId, "UPDATE", json.encodeToString(updatedCust), shopId)
                    }
                }

                bill
            }
            Result.success(createdBill)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

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

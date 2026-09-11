package com.shopzo.app.features.backup.data

import androidx.room.withTransaction
import com.shopzo.app.core.database.ShopzoDatabase
import com.shopzo.app.core.database.entity.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class BackupRepository(
    private val database: ShopzoDatabase
) {
    private val json = Json {
        ignoreUnknownKeys = true
        prettyPrint = true
    }

    suspend fun exportBackup(shopId: String): String = withContext(Dispatchers.IO) {
        val categories = database.categoryDao().getCategoriesByShop(shopId).first().map {
            CategoryBackupDto(it.id, it.name, it.shopId, it.createdAt)
        }
        val products = database.productDao().getProductsByShop(shopId).first().map {
            ProductBackupDto(it.id, it.name, it.categoryId, it.brand, it.buyingPricePaise, it.sellingPricePaise, it.quantity, it.unit, it.minStockLevel, it.shopId, it.createdAt, it.updatedAt)
        }
        val stockMovements = database.stockMovementDao().getRecentMovements(shopId, 1000).first().map {
            StockMovementBackupDto(it.id, it.productId, it.type, it.quantityChange, it.previousQuantity, it.newQuantity, it.buyingPricePaise, it.supplier, it.reason, it.notes, it.shopId, it.createdAt)
        }
        val customers = database.customerDao().getCustomersByShop(shopId).first().map {
            CustomerBackupDto(it.id, it.name, it.mobileNumber, it.address, it.totalPurchasePaise, it.outstandingDuePaise, it.createdAt, it.updatedAt, it.shopId)
        }
        val bills = database.billDao().getBillsByShop(shopId).first().map {
            BillBackupDto(it.id, it.billNumber, it.customerId, it.customerNameSnapshot, it.customerMobileSnapshot, it.subtotalPaise, it.grandTotalPaise, it.paidAmountPaise, it.pendingAmountPaise, it.paymentStatus, it.createdAt, it.shopId)
        }
        val billItems = mutableListOf<BillItemBackupDto>()
        bills.forEach { b ->
            val items = database.billItemDao().getItemsForBill(b.id)
            billItems.addAll(items.map { bi ->
                BillItemBackupDto(bi.id, bi.billId, bi.productId, bi.productNameSnapshot, bi.quantity, bi.unit, bi.sellingPricePaise, bi.buyingPricePaise, bi.subtotalPaise, bi.shopId)
            })
        }
        val payments = database.paymentDao().getPaymentsByShop(shopId).first().map {
            PaymentBackupDto(it.id, it.billId, it.customerId, it.amountPaise, it.paymentMethod, it.createdAt, it.shopId)
        }
        val returns = database.returnDao().getReturnsByShop(shopId).first().map {
            ReturnBackupDto(it.id, it.billId, it.billItemId, it.productId, it.quantityReturned, it.refundAmountPaise, it.stockRestored, it.reason, it.createdAt, it.shopId)
        }

        val backup = ShopzoBackup(
            version = 1,
            exportedAt = System.currentTimeMillis(),
            shopId = shopId,
            categories = categories,
            products = products,
            stockMovements = stockMovements,
            customers = customers,
            bills = bills,
            billItems = billItems,
            payments = payments,
            returns = returns
        )

        json.encodeToString(backup)
    }

    fun validateBackup(backupJson: String, targetShopId: String): Result<ShopzoBackup> {
        return try {
            val backup = json.decodeFromString<ShopzoBackup>(backupJson)
            if (backup.version != 1) {
                return Result.failure(IllegalArgumentException("Incompatible backup version ${backup.version}."))
            }
            if (backup.shopId != targetShopId) {
                return Result.failure(IllegalArgumentException("Backup belongs to shop ${backup.shopId}, which does not match current shop."))
            }
            Result.success(backup)
        } catch (e: Exception) {
            Result.failure(IllegalArgumentException("Invalid or corrupted backup file format."))
        }
    }

    suspend fun restoreBackup(backup: ShopzoBackup): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            database.withTransaction {
                // Restore Categories
                backup.categories.forEach { c ->
                    database.categoryDao().insert(CategoryEntity(c.id, c.name, c.shopId, c.createdAt))
                }

                // Restore Products
                backup.products.forEach { p ->
                    database.productDao().insert(ProductEntity(p.id, p.name, p.categoryId, p.brand, p.buyingPricePaise, p.sellingPricePaise, p.quantity, p.unit, p.minStockLevel, p.shopId, p.createdAt, p.updatedAt))
                }

                // Restore Stock Movements
                backup.stockMovements.forEach { sm ->
                    database.stockMovementDao().insert(StockMovementEntity(sm.id, sm.productId, sm.type, sm.quantityChange, sm.previousQuantity, sm.newQuantity, sm.buyingPricePaise, sm.supplier, sm.reason, sm.notes, sm.shopId, sm.createdAt))
                }

                // Restore Customers
                backup.customers.forEach { cust ->
                    database.customerDao().insertCustomer(CustomerEntity(cust.id, cust.name, cust.mobileNumber, cust.address, cust.totalPurchasePaise, cust.outstandingDuePaise, cust.createdAt, cust.updatedAt, cust.shopId))
                }

                // Restore Bills
                backup.bills.forEach { b ->
                    database.billDao().insertBill(BillEntity(b.id, b.billNumber, b.customerId, b.customerNameSnapshot, b.customerMobileSnapshot, b.subtotalPaise, b.grandTotalPaise, b.paidAmountPaise, b.pendingAmountPaise, b.paymentStatus, b.createdAt, b.shopId))
                }

                // Restore Bill Items
                backup.billItems.forEach { bi ->
                    database.billItemDao().insertBillItem(BillItemEntity(bi.id, bi.billId, bi.productId, bi.productNameSnapshot, bi.quantity, bi.unit, bi.sellingPricePaise, bi.buyingPricePaise, bi.subtotalPaise, bi.shopId))
                }

                // Restore Payments
                backup.payments.forEach { pay ->
                    database.paymentDao().insertPayment(PaymentEntity(pay.id, pay.billId, pay.customerId, pay.amountPaise, pay.paymentMethod, pay.createdAt, pay.shopId))
                }

                // Restore Returns
                backup.returns.forEach { ret ->
                    database.returnDao().insertReturn(ReturnEntity(ret.id, ret.billId, ret.billItemId, ret.productId, ret.quantityReturned, ret.refundAmountPaise, ret.stockRestored, ret.reason, ret.createdAt, ret.shopId))
                }
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

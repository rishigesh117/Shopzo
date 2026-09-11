package com.shopzo.app.features.payments.data

import androidx.room.withTransaction
import com.shopzo.app.core.database.ShopzoDatabase
import com.shopzo.app.core.database.entity.PaymentEntity
import com.shopzo.app.core.database.entity.SyncQueueEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.UUID

class PaymentRepository(
    private val database: ShopzoDatabase
) {
    private val paymentDao = database.paymentDao()
    private val billDao = database.billDao()
    private val customerDao = database.customerDao()
    private val syncDao = database.syncDao()
    private val json = Json { ignoreUnknownKeys = true }

    fun getPaymentsByShop(shopId: String): Flow<List<PaymentEntity>> {
        return paymentDao.getPaymentsByShop(shopId)
    }

    fun getPaymentsByBill(billId: String): Flow<List<PaymentEntity>> {
        return paymentDao.getPaymentsByBillFlow(billId)
    }

    fun getPaymentsByCustomer(customerId: String): Flow<List<PaymentEntity>> {
        return paymentDao.getPaymentsByCustomer(customerId)
    }

    suspend fun recordPayment(
        shopId: String,
        customerId: String,
        billId: String?,
        amountPaise: Long,
        paymentMethod: String // CASH, UPI, CARD, CREDIT
    ): Result<PaymentEntity> {
        if (amountPaise <= 0L) {
            return Result.failure(IllegalArgumentException("Payment amount must be greater than zero."))
        }

        return try {
            val payment = database.withTransaction {
                val now = System.currentTimeMillis()
                val paymentRecord = PaymentEntity(
                    id = UUID.randomUUID().toString(),
                    billId = billId,
                    customerId = customerId,
                    amountPaise = amountPaise,
                    paymentMethod = paymentMethod,
                    createdAt = now,
                    shopId = shopId
                )
                paymentDao.insertPayment(paymentRecord)
                enqueueSync("PAYMENT", paymentRecord.id, "CREATE", json.encodeToString(paymentRecord), shopId)

                if (billId != null) {
                    val bill = billDao.getBillById(billId)
                        ?: throw IllegalArgumentException("Bill not found.")

                    if (amountPaise > bill.pendingAmountPaise) {
                        throw IllegalArgumentException("Payment amount ₹${amountPaise / 100.0} exceeds bill pending amount ₹${bill.pendingAmountPaise / 100.0}.")
                    }

                    val newPending = bill.pendingAmountPaise - amountPaise
                    val newStatus = if (newPending <= 0L) "PAID" else "PARTIALLY_PAID"

                    billDao.applyPaymentToBill(billId, amountPaise, newStatus)
                    val updatedBill = billDao.getBillById(billId)
                    if (updatedBill != null) {
                        enqueueSync("BILL", billId, "UPDATE", json.encodeToString(updatedBill), shopId)
                    }

                    if (!bill.customerId.isNullOrEmpty()) {
                        customerDao.reduceOutstandingDue(bill.customerId, amountPaise, now)
                        val updatedCust = customerDao.getCustomerById(bill.customerId)
                        if (updatedCust != null) {
                            enqueueSync("CUSTOMER", bill.customerId, "UPDATE", json.encodeToString(updatedCust), shopId)
                        }
                    }
                } else {
                    // Overall customer payment (applied to customer due)
                    val customer = customerDao.getCustomerById(customerId)
                        ?: throw IllegalArgumentException("Customer not found.")

                    if (amountPaise > customer.outstandingDuePaise) {
                        throw IllegalArgumentException("Payment amount ₹${amountPaise / 100.0} exceeds customer outstanding due ₹${customer.outstandingDuePaise / 100.0}.")
                    }

                    customerDao.reduceOutstandingDue(customerId, amountPaise, now)
                    val updatedCust = customerDao.getCustomerById(customerId)
                    if (updatedCust != null) {
                        enqueueSync("CUSTOMER", customerId, "UPDATE", json.encodeToString(updatedCust), shopId)
                    }
                }

                paymentRecord
            }
            Result.success(payment)
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

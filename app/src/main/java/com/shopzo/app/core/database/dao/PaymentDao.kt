package com.shopzo.app.core.database.dao

import androidx.room.*
import com.shopzo.app.core.database.entity.PaymentEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface PaymentDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPayment(payment: PaymentEntity)

    @Query("SELECT * FROM payments WHERE billId = :billId ORDER BY createdAt DESC")
    suspend fun getPaymentsByBill(billId: String): List<PaymentEntity>

    @Query("SELECT * FROM payments WHERE billId = :billId ORDER BY createdAt DESC")
    fun getPaymentsByBillFlow(billId: String): Flow<List<PaymentEntity>>

    @Query("SELECT * FROM payments WHERE customerId = :customerId ORDER BY createdAt DESC")
    fun getPaymentsByCustomer(customerId: String): Flow<List<PaymentEntity>>

    @Query("SELECT * FROM payments WHERE shopId = :shopId ORDER BY createdAt DESC")
    fun getPaymentsByShop(shopId: String): Flow<List<PaymentEntity>>

    @Query("SELECT SUM(amountPaise) FROM payments WHERE shopId = :shopId AND createdAt >= :startTime AND createdAt <= :endTime")
    fun getTotalPaymentsInPeriod(shopId: String, startTime: Long, endTime: Long): Flow<Long?>
}

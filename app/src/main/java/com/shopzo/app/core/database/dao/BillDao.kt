package com.shopzo.app.core.database.dao

import androidx.room.*
import com.shopzo.app.core.database.entity.BillEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface BillDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBill(bill: BillEntity)

    @Update
    suspend fun updateBill(bill: BillEntity)

    @Query("SELECT * FROM bills WHERE id = :id")
    suspend fun getBillById(id: String): BillEntity?

    @Query("SELECT * FROM bills WHERE id = :id")
    fun getBillByIdFlow(id: String): Flow<BillEntity?>

    @Query("SELECT * FROM bills WHERE shopId = :shopId ORDER BY createdAt DESC")
    fun getBillsByShop(shopId: String): Flow<List<BillEntity>>

    @Query("SELECT * FROM bills WHERE shopId = :shopId AND paymentStatus = :status ORDER BY createdAt DESC")
    fun getBillsByStatus(shopId: String, status: String): Flow<List<BillEntity>>

    @Query("SELECT * FROM bills WHERE shopId = :shopId AND customerId = :customerId ORDER BY createdAt DESC")
    fun getBillsByCustomer(shopId: String, customerId: String): Flow<List<BillEntity>>

    @Query("SELECT * FROM bills WHERE shopId = :shopId AND (billNumber LIKE '%' || :query || '%' OR customerNameSnapshot LIKE '%' || :query || '%' OR customerMobileSnapshot LIKE '%' || :query || '%') ORDER BY createdAt DESC")
    fun searchBills(shopId: String, query: String): Flow<List<BillEntity>>

    @Query("SELECT COUNT(*) FROM bills WHERE shopId = :shopId AND createdAt >= :startTime AND createdAt <= :endTime")
    fun countBillsInPeriod(shopId: String, startTime: Long, endTime: Long): Flow<Int>

    @Query("SELECT SUM(grandTotalPaise) FROM bills WHERE shopId = :shopId AND createdAt >= :startTime AND createdAt <= :endTime")
    fun getTotalSalesInPeriod(shopId: String, startTime: Long, endTime: Long): Flow<Long?>

    @Query("SELECT SUM(paidAmountPaise) FROM bills WHERE shopId = :shopId AND createdAt >= :startTime AND createdAt <= :endTime")
    fun getTotalPaidInPeriod(shopId: String, startTime: Long, endTime: Long): Flow<Long?>

    @Query("SELECT SUM(pendingAmountPaise) FROM bills WHERE shopId = :shopId AND createdAt >= :startTime AND createdAt <= :endTime")
    fun getTotalPendingInPeriod(shopId: String, startTime: Long, endTime: Long): Flow<Long?>

    @Query("SELECT SUM(pendingAmountPaise) FROM bills WHERE shopId = :shopId")
    fun getTotalPendingDues(shopId: String): Flow<Long?>

    @Query("SELECT * FROM bills WHERE shopId = :shopId AND createdAt >= :startTime AND createdAt <= :endTime ORDER BY createdAt DESC")
    fun getBillsInPeriod(shopId: String, startTime: Long, endTime: Long): Flow<List<BillEntity>>

    @Query("SELECT MAX(CAST(SUBSTR(billNumber, 2) AS INTEGER)) FROM bills WHERE shopId = :shopId AND billNumber LIKE '#%'")
    suspend fun getMaxBillNumberNumeric(shopId: String): Int?

    @Query("UPDATE bills SET paidAmountPaise = paidAmountPaise + :additionalPaidPaise, pendingAmountPaise = pendingAmountPaise - :additionalPaidPaise, paymentStatus = :newStatus WHERE id = :billId")
    suspend fun applyPaymentToBill(billId: String, additionalPaidPaise: Long, newStatus: String)
}

package com.shopzo.app.core.database.dao

import androidx.room.*
import com.shopzo.app.core.database.entity.ReturnEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface ReturnDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertReturn(returnEntity: ReturnEntity)

    @Query("SELECT * FROM returns WHERE billId = :billId ORDER BY createdAt DESC")
    suspend fun getReturnsByBill(billId: String): List<ReturnEntity>

    @Query("SELECT * FROM returns WHERE billId = :billId ORDER BY createdAt DESC")
    fun getReturnsByBillFlow(billId: String): Flow<List<ReturnEntity>>

    @Query("SELECT * FROM returns WHERE shopId = :shopId ORDER BY createdAt DESC")
    fun getReturnsByShop(shopId: String): Flow<List<ReturnEntity>>

    @Query("SELECT SUM(quantityReturned) FROM returns WHERE billItemId = :billItemId")
    suspend fun getTotalQuantityReturnedForBillItem(billItemId: String): Double?

    @Query("SELECT SUM(refundAmountPaise) FROM returns WHERE shopId = :shopId AND createdAt >= :startTime AND createdAt <= :endTime")
    fun getTotalRefundsInPeriod(shopId: String, startTime: Long, endTime: Long): Flow<Long?>
}

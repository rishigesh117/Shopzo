package com.shopzo.app.core.database.dao

import androidx.room.*
import com.shopzo.app.core.database.entity.BillItemEntity
import kotlinx.coroutines.flow.Flow

data class BestSellerAggregate(
    val productId: String,
    val productNameSnapshot: String,
    val totalQuantitySold: Double,
    val totalRevenuePaise: Long,
    val totalProfitPaise: Long
)

@Dao
interface BillItemDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBillItems(items: List<BillItemEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBillItem(item: BillItemEntity)

    @Query("SELECT * FROM bill_items WHERE billId = :billId")
    suspend fun getItemsForBill(billId: String): List<BillItemEntity>

    @Query("SELECT * FROM bill_items WHERE billId = :billId")
    fun getItemsForBillFlow(billId: String): Flow<List<BillItemEntity>>

    @Query("""
        SELECT 
            bi.productId AS productId, 
            bi.productNameSnapshot AS productNameSnapshot, 
            SUM(bi.quantity) AS totalQuantitySold, 
            SUM(bi.subtotalPaise) AS totalRevenuePaise, 
            SUM((bi.sellingPricePaise - bi.buyingPricePaise) * bi.quantity) AS totalProfitPaise 
        FROM bill_items bi 
        INNER JOIN bills b ON bi.billId = b.id 
        WHERE bi.shopId = :shopId AND b.createdAt >= :startTime AND b.createdAt <= :endTime 
        GROUP BY bi.productId 
        ORDER BY totalQuantitySold DESC 
        LIMIT :limit
    """)
    fun getTopSellersByQuantity(shopId: String, startTime: Long, endTime: Long, limit: Int): Flow<List<BestSellerAggregate>>

    @Query("""
        SELECT 
            bi.productId AS productId, 
            bi.productNameSnapshot AS productNameSnapshot, 
            SUM(bi.quantity) AS totalQuantitySold, 
            SUM(bi.subtotalPaise) AS totalRevenuePaise, 
            SUM((bi.sellingPricePaise - bi.buyingPricePaise) * bi.quantity) AS totalProfitPaise 
        FROM bill_items bi 
        INNER JOIN bills b ON bi.billId = b.id 
        WHERE bi.shopId = :shopId AND b.createdAt >= :startTime AND b.createdAt <= :endTime 
        GROUP BY bi.productId 
        ORDER BY totalRevenuePaise DESC 
        LIMIT :limit
    """)
    fun getTopSellersByRevenue(shopId: String, startTime: Long, endTime: Long, limit: Int): Flow<List<BestSellerAggregate>>

    @Query("""
        SELECT 
            bi.productId AS productId, 
            bi.productNameSnapshot AS productNameSnapshot, 
            SUM(bi.quantity) AS totalQuantitySold, 
            SUM(bi.subtotalPaise) AS totalRevenuePaise, 
            SUM((bi.sellingPricePaise - bi.buyingPricePaise) * bi.quantity) AS totalProfitPaise 
        FROM bill_items bi 
        INNER JOIN bills b ON bi.billId = b.id 
        WHERE bi.shopId = :shopId AND b.createdAt >= :startTime AND b.createdAt <= :endTime 
        GROUP BY bi.productId 
        ORDER BY totalProfitPaise DESC 
        LIMIT :limit
    """)
    fun getTopSellersByProfit(shopId: String, startTime: Long, endTime: Long, limit: Int): Flow<List<BestSellerAggregate>>

    @Query("""
        SELECT SUM(bi.quantity) 
        FROM bill_items bi 
        INNER JOIN bills b ON bi.billId = b.id 
        WHERE bi.shopId = :shopId AND b.createdAt >= :startTime AND b.createdAt <= :endTime
    """)
    fun getTotalProductsSoldInPeriod(shopId: String, startTime: Long, endTime: Long): Flow<Double?>
}

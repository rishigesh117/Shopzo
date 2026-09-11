package com.shopzo.app.core.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import com.shopzo.app.core.database.entity.StockMovementEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface StockMovementDao {

    @Insert
    suspend fun insert(movement: StockMovementEntity)

    suspend fun insertStockMovement(movement: StockMovementEntity) = insert(movement)

    @Query("SELECT * FROM stock_movements WHERE productId = :productId ORDER BY createdAt DESC")
    fun getMovementsForProduct(productId: String): Flow<List<StockMovementEntity>>

    @Query("SELECT * FROM stock_movements WHERE shopId = :shopId ORDER BY createdAt DESC LIMIT :limit")
    fun getRecentMovements(shopId: String, limit: Int = 50): Flow<List<StockMovementEntity>>
}

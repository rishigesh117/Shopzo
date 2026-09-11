package com.shopzo.app.core.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import com.shopzo.app.core.database.entity.ShopEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface ShopDao {

    @Insert
    suspend fun insert(shop: ShopEntity)

    @Query("SELECT * FROM shops WHERE id = :shopId LIMIT 1")
    suspend fun getShopById(shopId: String): ShopEntity?

    @Query("SELECT * FROM shops WHERE ownerId = :ownerId LIMIT 1")
    suspend fun getShopByOwner(ownerId: String): ShopEntity?

    @Query("SELECT * FROM shops WHERE id = :shopId LIMIT 1")
    fun getShopFlow(shopId: String): Flow<ShopEntity?>
}

package com.shopzo.app.core.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import com.shopzo.app.core.database.entity.CategoryEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface CategoryDao {

    @Insert
    suspend fun insert(category: CategoryEntity)

    @Insert
    suspend fun insertAll(categories: List<CategoryEntity>)

    @Update
    suspend fun update(category: CategoryEntity)

    @Query("SELECT * FROM categories WHERE shopId = :shopId ORDER BY name ASC")
    fun getCategoriesByShop(shopId: String): Flow<List<CategoryEntity>>

    @Query("SELECT * FROM categories WHERE id = :categoryId LIMIT 1")
    suspend fun getCategoryById(categoryId: String): CategoryEntity?

    @Query("DELETE FROM categories WHERE id = :categoryId")
    suspend fun deleteById(categoryId: String)

    @Query("SELECT COUNT(*) FROM categories WHERE shopId = :shopId")
    suspend fun countByShop(shopId: String): Int
}

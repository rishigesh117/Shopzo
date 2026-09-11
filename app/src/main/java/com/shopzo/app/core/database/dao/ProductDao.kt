package com.shopzo.app.core.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import com.shopzo.app.core.database.entity.ProductEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface ProductDao {

    @Insert
    suspend fun insert(product: ProductEntity)

    @Update
    suspend fun update(product: ProductEntity)

    @Query("SELECT * FROM products WHERE shopId = :shopId ORDER BY name ASC")
    fun getProductsByShop(shopId: String): Flow<List<ProductEntity>>

    @Query("SELECT * FROM products WHERE shopId = :shopId AND categoryId = :categoryId ORDER BY name ASC")
    fun getProductsByCategory(shopId: String, categoryId: String): Flow<List<ProductEntity>>

    @Query("SELECT * FROM products WHERE shopId = :shopId AND (name LIKE '%' || :query || '%' OR brand LIKE '%' || :query || '%') ORDER BY name ASC")
    fun searchProducts(shopId: String, query: String): Flow<List<ProductEntity>>

    @Query("SELECT * FROM products WHERE id = :productId LIMIT 1")
    suspend fun getProductById(productId: String): ProductEntity?

    @Query("SELECT * FROM products WHERE id = :productId LIMIT 1")
    fun getProductByIdFlow(productId: String): Flow<ProductEntity?>

    @Query("UPDATE products SET quantity = :newQuantity, updatedAt = :updatedAt WHERE id = :productId")
    suspend fun updateStock(productId: String, newQuantity: Double, updatedAt: Long = System.currentTimeMillis())

    @Query("DELETE FROM products WHERE id = :productId")
    suspend fun deleteById(productId: String)

    @Query("SELECT COUNT(*) FROM products WHERE categoryId = :categoryId")
    suspend fun countByCategory(categoryId: String): Int

    @Query("SELECT COUNT(*) FROM products WHERE shopId = :shopId AND quantity <= 0")
    fun countOutOfStock(shopId: String): Flow<Int>

    @Query("SELECT COUNT(*) FROM products WHERE shopId = :shopId AND quantity > 0 AND quantity <= minStockLevel")
    fun countLowStock(shopId: String): Flow<Int>

    @Query("SELECT COUNT(*) FROM products WHERE shopId = :shopId")
    fun countProducts(shopId: String): Flow<Int>

    @Query("SELECT * FROM products WHERE shopId = :shopId AND quantity <= 0 ORDER BY name ASC")
    fun getOutOfStockProducts(shopId: String): Flow<List<ProductEntity>>

    @Query("SELECT * FROM products WHERE shopId = :shopId AND quantity > 0 AND quantity <= minStockLevel ORDER BY name ASC")
    fun getLowStockProducts(shopId: String): Flow<List<ProductEntity>>
}

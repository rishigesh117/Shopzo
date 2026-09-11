package com.shopzo.app.features.products.data

import com.shopzo.app.core.database.ShopzoDatabase
import com.shopzo.app.core.database.entity.CategoryEntity
import com.shopzo.app.core.database.entity.ProductEntity
import com.shopzo.app.core.database.entity.SyncQueueEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.UUID

class ProductRepository(
    private val database: ShopzoDatabase
) {
    private val productDao = database.productDao()
    private val categoryDao = database.categoryDao()
    private val syncDao = database.syncDao()
    private val json = Json { ignoreUnknownKeys = true }

    // Products
    suspend fun addProduct(product: ProductEntity) {
        productDao.insert(product)
        enqueueSync("PRODUCT", product.id, "CREATE", json.encodeToString(product), product.shopId)
    }

    suspend fun updateProduct(product: ProductEntity) {
        productDao.update(product)
        enqueueSync("PRODUCT", product.id, "UPDATE", json.encodeToString(product), product.shopId)
    }

    suspend fun deleteProduct(productId: String) {
        val product = productDao.getProductById(productId)
        productDao.deleteById(productId)
        if (product != null) {
            enqueueSync("PRODUCT", productId, "DELETE", json.encodeToString(product), product.shopId)
        }
    }

    fun getProductsByShop(shopId: String): Flow<List<ProductEntity>> =
        productDao.getProductsByShop(shopId)

    fun searchProducts(shopId: String, query: String): Flow<List<ProductEntity>> =
        productDao.searchProducts(shopId, query)

    fun getProductsByCategory(shopId: String, categoryId: String): Flow<List<ProductEntity>> =
        productDao.getProductsByCategory(shopId, categoryId)

    suspend fun getProductById(productId: String): ProductEntity? =
        productDao.getProductById(productId)

    fun getProductByIdFlow(productId: String): Flow<ProductEntity?> =
        productDao.getProductByIdFlow(productId)

    fun countOutOfStock(shopId: String): Flow<Int> = productDao.countOutOfStock(shopId)
    fun countLowStock(shopId: String): Flow<Int> = productDao.countLowStock(shopId)
    fun countProducts(shopId: String): Flow<Int> = productDao.countProducts(shopId)

    // Categories
    fun getCategoriesByShop(shopId: String): Flow<List<CategoryEntity>> =
        categoryDao.getCategoriesByShop(shopId)

    suspend fun getCategoryById(categoryId: String): CategoryEntity? =
        categoryDao.getCategoryById(categoryId)

    suspend fun addCategory(name: String, shopId: String): CategoryEntity {
        val category = CategoryEntity(
            id = UUID.randomUUID().toString(),
            name = name.trim(),
            shopId = shopId,
            createdAt = System.currentTimeMillis()
        )
        categoryDao.insert(category)
        enqueueSync("CATEGORY", category.id, "CREATE", json.encodeToString(category), shopId)
        return category
    }

    suspend fun updateCategory(category: CategoryEntity) {
        categoryDao.update(category)
        enqueueSync("CATEGORY", category.id, "UPDATE", json.encodeToString(category), category.shopId)
    }

    suspend fun deleteCategory(categoryId: String): Boolean {
        val productCount = productDao.countByCategory(categoryId)
        if (productCount > 0) return false
        val cat = categoryDao.getCategoryById(categoryId)
        categoryDao.deleteById(categoryId)
        if (cat != null) {
            enqueueSync("CATEGORY", categoryId, "DELETE", json.encodeToString(cat), cat.shopId)
        }
        return true
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

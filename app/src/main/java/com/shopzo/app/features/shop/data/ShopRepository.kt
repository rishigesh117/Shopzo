package com.shopzo.app.features.shop.data

import com.shopzo.app.core.database.dao.CategoryDao
import com.shopzo.app.core.database.dao.ShopDao
import com.shopzo.app.core.database.dao.UserDao
import com.shopzo.app.core.database.entity.CategoryEntity
import com.shopzo.app.core.database.entity.ShopEntity
import com.shopzo.app.core.utils.ShopCodeGenerator
import kotlinx.coroutines.flow.Flow
import java.util.UUID

class ShopRepository(
    private val shopDao: ShopDao,
    private val userDao: UserDao,
    private val categoryDao: CategoryDao
) {

    private val defaultCategories = listOf(
        "Grocery", "Beverages", "Snacks", "Dairy", "Personal Care",
        "Household", "Stationery", "Fruits & Vegetables", "Cosmetics", "Others"
    )

    suspend fun createShop(
        shopName: String,
        ownerName: String,
        mobileNumber: String,
        address: String?,
        ownerId: String
    ): ShopEntity {
        val shopId = UUID.randomUUID().toString()
        val shop = ShopEntity(
            id = shopId,
            shopName = shopName.trim(),
            ownerName = ownerName.trim(),
            mobileNumber = mobileNumber.trim(),
            address = address?.trim()?.ifEmpty { null },
            shopCode = ShopCodeGenerator.generate(),
            ownerId = ownerId,
            createdAt = System.currentTimeMillis()
        )
        shopDao.insert(shop)

        // Link owner to shop
        val owner = userDao.getUserById(ownerId)
        if (owner != null) {
            userDao.update(owner.copy(shopId = shopId))
        }

        // Seed default categories
        seedDefaultCategories(shopId)

        return shop
    }

    private suspend fun seedDefaultCategories(shopId: String) {
        if (categoryDao.countByShop(shopId) == 0) {
            val categories = defaultCategories.map { name ->
                CategoryEntity(
                    id = UUID.randomUUID().toString(),
                    name = name,
                    shopId = shopId,
                    createdAt = System.currentTimeMillis()
                )
            }
            categoryDao.insertAll(categories)
        }
    }

    suspend fun getShopByOwner(ownerId: String): ShopEntity? = shopDao.getShopByOwner(ownerId)

    suspend fun getShopById(shopId: String): ShopEntity? = shopDao.getShopById(shopId)

    fun getShopFlow(shopId: String): Flow<ShopEntity?> = shopDao.getShopFlow(shopId)
}

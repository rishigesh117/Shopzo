package com.shopzo.app.features.shop.data

import com.shopzo.app.core.database.dao.CategoryDao
import com.shopzo.app.core.database.dao.ShopDao
import com.shopzo.app.core.database.dao.UserDao
import com.shopzo.app.core.database.entity.CategoryEntity
import com.shopzo.app.core.database.entity.ShopEntity
import com.shopzo.app.core.network.ShopzoApiService
import com.shopzo.app.core.network.dto.CreateShopRequest
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.core.sync.SyncRepository
import com.shopzo.app.core.utils.ShopCodeGenerator
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.map
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.UUID

class ShopRepository(
    private val shopDao: ShopDao,
    private val userDao: UserDao,
    private val categoryDao: CategoryDao,
    private val apiService: ShopzoApiService? = null,
    private val sessionManager: SessionManager? = null,
    private val syncRepository: SyncRepository? = null
) {
    private val json = Json { ignoreUnknownKeys = true }

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
        var cloudShopId: String? = null
        var cloudShopCode: String? = null

        if (apiService != null) {
            try {
                val response = apiService.createShop(
                    CreateShopRequest(
                        name = shopName.trim(),
                        address = address?.trim()?.ifEmpty { null }
                    )
                )
                if (response.isSuccessful && response.body() != null) {
                    val s = response.body()!!.shop
                    cloudShopId = s.id
                    cloudShopCode = s.shopCode
                }
            } catch (_: Exception) {
                // Offline fallback
            }
        }

        val shopId = cloudShopId ?: UUID.randomUUID().toString()
        val shopCode = cloudShopCode ?: ShopCodeGenerator.generate()

        val shop = ShopEntity(
            id = shopId,
            shopName = shopName.trim(),
            ownerName = ownerName.trim(),
            mobileNumber = mobileNumber.trim(),
            address = address?.trim()?.ifEmpty { null },
            shopCode = shopCode,
            ownerId = ownerId,
            createdAt = System.currentTimeMillis()
        )
        shopDao.insert(shop)

        sessionManager?.updateShopId(shopId)

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

            // Queue categories for sync
            categories.forEach { cat ->
                try {
                    syncRepository?.enqueueOperation(
                        entityType = "CATEGORY",
                        entityId = cat.id,
                        operationType = "CREATE",
                        payloadJson = json.encodeToString(cat),
                        shopId = shopId
                    )
                } catch (_: Exception) {}
            }
        }
    }

    suspend fun getShopByOwner(ownerId: String): ShopEntity? {
        val shop = shopDao.getShopByOwner(ownerId) ?: return null
        return ensureOwnerDetails(shop)
    }

    suspend fun getShopById(shopId: String): ShopEntity? {
        val shop = shopDao.getShopById(shopId) ?: return null
        return ensureOwnerDetails(shop)
    }

    fun getShopFlow(shopId: String): Flow<ShopEntity?> = shopDao.getShopFlow(shopId).map { shop ->
        if (shop != null) ensureOwnerDetails(shop) else null
    }

    private suspend fun ensureOwnerDetails(shop: ShopEntity): ShopEntity {
        if (shop.ownerName.isBlank()) {
            val owner = userDao.getUserById(shop.ownerId)
            val sessionName = sessionManager?.sessionFlow?.firstOrNull()?.userName
            val resolvedName = owner?.name?.ifBlank { null } ?: sessionName?.ifBlank { null }
            if (resolvedName != null) {
                val updatedShop = shop.copy(
                    ownerName = resolvedName,
                    mobileNumber = if (shop.mobileNumber.isBlank()) (owner?.mobileNumber ?: "") else shop.mobileNumber
                )
                shopDao.insert(updatedShop)
                return updatedShop
            }
        }
        return shop
    }
}

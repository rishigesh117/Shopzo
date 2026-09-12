package com.shopzo.app.features.auth.data

import com.shopzo.app.core.database.dao.ShopDao
import com.shopzo.app.core.database.dao.UserDao
import com.shopzo.app.core.database.entity.ShopEntity
import com.shopzo.app.core.database.entity.UserEntity
import com.shopzo.app.core.model.UserRole
import com.shopzo.app.core.network.ShopzoApiService
import com.shopzo.app.core.network.dto.LoginRequest
import com.shopzo.app.core.network.dto.RegisterRequest
import com.shopzo.app.core.security.PasswordHasher
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.core.sync.SyncRepository
import java.util.UUID

class AuthRepository(
    private val userDao: UserDao,
    private val apiService: ShopzoApiService? = null,
    private val sessionManager: SessionManager? = null,
    private val shopDao: ShopDao? = null,
    private val syncRepository: SyncRepository? = null
) {

    sealed class AuthResult {
        data class Success(val user: UserEntity) : AuthResult()
        data class Error(val message: String) : AuthResult()
    }

    suspend fun register(name: String, mobileNumber: String, password: String): AuthResult {
        val cleanMobile = mobileNumber.trim()
        val cleanName = name.trim()

        if (userDao.countByMobile(cleanMobile) > 0) {
            return AuthResult.Error("This mobile number is already registered.")
        }

        var cloudUserId: String? = null
        if (apiService != null) {
            try {
                val response = apiService.register(RegisterRequest(cleanName, cleanMobile, password))
                if (response.isSuccessful && response.body() != null) {
                    val body = response.body()!!
                    cloudUserId = body.user.id
                    sessionManager?.saveAuthToken(body.token)
                } else if (response.code() == 409) {
                    return AuthResult.Error("This mobile number is already registered.")
                }
            } catch (_: Exception) {
                // Cloud unreachable, proceed with local account creation
            }
        }

        val user = UserEntity(
            id = cloudUserId ?: UUID.randomUUID().toString(),
            name = cleanName,
            mobileNumber = cleanMobile,
            passwordHash = PasswordHasher.hash(password),
            role = UserRole.OWNER.name,
            shopId = null,
            createdAt = System.currentTimeMillis()
        )
        userDao.insert(user)
        return AuthResult.Success(user)
    }

    suspend fun login(mobileNumber: String, password: String): AuthResult {
        val cleanMobile = mobileNumber.trim()

        // 1. Try online cloud login first
        if (apiService != null) {
            try {
                val response = apiService.login(LoginRequest(cleanMobile, password))
                if (response.isSuccessful && response.body() != null) {
                    val body = response.body()!!
                    sessionManager?.saveAuthToken(body.token)

                    val targetShop = body.shops.firstOrNull()
                    val userRole = targetShop?.role ?: UserRole.STAFF.name

                    val user = UserEntity(
                        id = body.user.id,
                        name = body.user.name,
                        mobileNumber = cleanMobile,
                        passwordHash = PasswordHasher.hash(password),
                        role = userRole,
                        shopId = targetShop?.id,
                        createdAt = System.currentTimeMillis()
                    )
                    userDao.insert(user)

                    if (targetShop != null && shopDao != null) {
                        val shopEntity = ShopEntity(
                            id = targetShop.id,
                            shopName = targetShop.name,
                            ownerName = "",
                            mobileNumber = cleanMobile,
                            address = targetShop.address,
                            shopCode = targetShop.shopCode,
                            ownerId = targetShop.ownerId,
                            createdAt = targetShop.createdAt ?: System.currentTimeMillis()
                        )
                        shopDao.insert(shopEntity)
                        sessionManager?.updateShopId(targetShop.id)

                        // Immediately pull latest shop data from cloud
                        try {
                            syncRepository?.pullDeltaUpdates(targetShop.id, 0L)
                        } catch (_: Exception) {}
                    }

                    return AuthResult.Success(user)
                } else if (response.code() == 401) {
                    return AuthResult.Error("Incorrect mobile number or password.")
                }
            } catch (_: Exception) {
                // Cloud unreachable, fall back to local database
            }
        }

        // 2. Local database fallback
        val user = userDao.getUserByMobile(cleanMobile)
            ?: return AuthResult.Error("Incorrect mobile number or password.")

        if (!PasswordHasher.verify(password, user.passwordHash)) {
            return AuthResult.Error("Incorrect mobile number or password.")
        }

        return AuthResult.Success(user)
    }

    suspend fun getUserById(userId: String): UserEntity? = userDao.getUserById(userId)
}

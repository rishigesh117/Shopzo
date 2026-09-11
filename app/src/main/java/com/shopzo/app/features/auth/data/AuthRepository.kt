package com.shopzo.app.features.auth.data

import com.shopzo.app.core.database.dao.UserDao
import com.shopzo.app.core.database.entity.UserEntity
import com.shopzo.app.core.model.UserRole
import com.shopzo.app.core.security.PasswordHasher
import java.util.UUID

class AuthRepository(private val userDao: UserDao) {

    sealed class AuthResult {
        data class Success(val user: UserEntity) : AuthResult()
        data class Error(val message: String) : AuthResult()
    }

    suspend fun register(name: String, mobileNumber: String, password: String): AuthResult {
        if (userDao.countByMobile(mobileNumber) > 0) {
            return AuthResult.Error("This mobile number is already registered.")
        }

        val user = UserEntity(
            id = UUID.randomUUID().toString(),
            name = name.trim(),
            mobileNumber = mobileNumber.trim(),
            passwordHash = PasswordHasher.hash(password),
            role = UserRole.OWNER.name,
            shopId = null,
            createdAt = System.currentTimeMillis()
        )
        userDao.insert(user)
        return AuthResult.Success(user)
    }

    suspend fun login(mobileNumber: String, password: String): AuthResult {
        val user = userDao.getUserByMobile(mobileNumber.trim())
            ?: return AuthResult.Error("Incorrect mobile number or password.")

        if (!PasswordHasher.verify(password, user.passwordHash)) {
            return AuthResult.Error("Incorrect mobile number or password.")
        }

        return AuthResult.Success(user)
    }

    suspend fun getUserById(userId: String): UserEntity? = userDao.getUserById(userId)
}

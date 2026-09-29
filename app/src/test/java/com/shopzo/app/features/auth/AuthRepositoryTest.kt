package com.shopzo.app.features.auth

import com.shopzo.app.core.database.dao.UserDao
import com.shopzo.app.core.database.entity.UserEntity
import com.shopzo.app.core.model.UserRole
import com.shopzo.app.core.security.PasswordHasher
import com.shopzo.app.features.auth.data.AuthRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class FakeUserDao : UserDao {
    private val users = mutableMapOf<String, UserEntity>()

    override suspend fun insert(user: UserEntity) {
        users[user.id] = user
    }

    override suspend fun update(user: UserEntity) {
        users[user.id] = user
    }

    override suspend fun getUserByMobile(mobileNumber: String): UserEntity? {
        return users.values.find { it.mobileNumber == mobileNumber }
    }

    override suspend fun getUserById(userId: String): UserEntity? {
        return users[userId]
    }

    override fun getStaffByShop(shopId: String): Flow<List<UserEntity>> {
        return flowOf(users.values.filter { it.shopId == shopId && it.role == "STAFF" })
    }

    override suspend fun countByMobile(mobileNumber: String): Int {
        return users.values.count { it.mobileNumber == mobileNumber }
    }

    override suspend fun deleteById(userId: String) {
        users.remove(userId)
    }
}

class AuthRepositoryTest {

    private lateinit var userDao: FakeUserDao
    private lateinit var authRepository: AuthRepository

    @Before
    fun setup() {
        userDao = FakeUserDao()
        authRepository = AuthRepository(
            userDao = userDao,
            apiService = null,
            sessionManager = null,
            shopDao = null,
            syncRepository = null
        )
    }

    @Test
    fun register_createsUserLocally() = runTest {
        val result = authRepository.register("Test User", "8870635581", "Password123")
        assertTrue(result is AuthRepository.AuthResult.Success)
        val user = userDao.getUserByMobile("8870635581")
        assertNotNull(user)
        assertEquals("Test User", user?.name)
    }

    @Test
    fun login_succeedsWithCorrectPassword() = runTest {
        val rawPassword = "MyPassword123"
        authRepository.register("Test User", "8870635581", rawPassword)

        val result = authRepository.login("8870635581", rawPassword)

        assertTrue(result is AuthRepository.AuthResult.Success)
        val successResult = result as AuthRepository.AuthResult.Success
        assertEquals("8870635581", successResult.user.mobileNumber)
    }

    @Test
    fun login_failsWithIncorrectPassword() = runTest {
        authRepository.register("Test User", "8870635581", "MyPassword123")

        val result = authRepository.login("8870635581", "WrongPassword")

        assertTrue(result is AuthRepository.AuthResult.Error)
        val errorResult = result as AuthRepository.AuthResult.Error
        assertEquals("Incorrect mobile number or password.", errorResult.message)
    }
}

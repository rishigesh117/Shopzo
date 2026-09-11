package com.shopzo.app.features.staff.data

import com.shopzo.app.core.database.dao.StaffPermissionDao
import com.shopzo.app.core.database.dao.UserDao
import com.shopzo.app.core.database.entity.StaffPermissionEntity
import com.shopzo.app.core.database.entity.UserEntity
import com.shopzo.app.core.model.Permission
import com.shopzo.app.core.model.UserRole
import com.shopzo.app.core.security.PasswordHasher
import kotlinx.coroutines.flow.Flow
import java.util.UUID

class StaffRepository(
    private val userDao: UserDao,
    private val staffPermissionDao: StaffPermissionDao
) {

    sealed class StaffResult {
        data class Success(val user: UserEntity) : StaffResult()
        data class Error(val message: String) : StaffResult()
    }

    suspend fun createStaff(
        name: String,
        mobileNumber: String,
        password: String,
        permissions: Set<Permission>,
        shopId: String
    ): StaffResult {
        if (userDao.countByMobile(mobileNumber) > 0) {
            return StaffResult.Error("This mobile number is already registered.")
        }

        val userId = UUID.randomUUID().toString()
        val user = UserEntity(
            id = userId,
            name = name.trim(),
            mobileNumber = mobileNumber.trim(),
            passwordHash = PasswordHasher.hash(password),
            role = UserRole.STAFF.name,
            shopId = shopId,
            createdAt = System.currentTimeMillis()
        )
        userDao.insert(user)

        // Save permissions
        val permissionEntities = permissions.map { perm ->
            StaffPermissionEntity(
                id = UUID.randomUUID().toString(),
                userId = userId,
                permission = perm.name,
                shopId = shopId
            )
        }
        staffPermissionDao.insertAll(permissionEntities)

        return StaffResult.Success(user)
    }

    fun getStaffByShop(shopId: String): Flow<List<UserEntity>> = userDao.getStaffByShop(shopId)

    fun getPermissions(userId: String, shopId: String): Flow<List<StaffPermissionEntity>> =
        staffPermissionDao.getPermissions(userId, shopId)

    suspend fun getPermissionsList(userId: String, shopId: String): List<StaffPermissionEntity> =
        staffPermissionDao.getPermissionsList(userId, shopId)

    suspend fun updatePermissions(userId: String, shopId: String, permissions: Set<Permission>) {
        staffPermissionDao.deleteAllForUser(userId, shopId)
        val permissionEntities = permissions.map { perm ->
            StaffPermissionEntity(
                id = UUID.randomUUID().toString(),
                userId = userId,
                permission = perm.name,
                shopId = shopId
            )
        }
        staffPermissionDao.insertAll(permissionEntities)
    }

    suspend fun deleteStaff(userId: String) {
        staffPermissionDao.deleteAllForUser(userId)
        userDao.deleteById(userId)
    }

    suspend fun updateStaff(user: UserEntity) {
        userDao.update(user)
    }
}

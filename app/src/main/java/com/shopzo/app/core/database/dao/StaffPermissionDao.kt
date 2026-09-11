package com.shopzo.app.core.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import com.shopzo.app.core.database.entity.StaffPermissionEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface StaffPermissionDao {

    @Insert
    suspend fun insertAll(permissions: List<StaffPermissionEntity>)

    @Query("SELECT * FROM staff_permissions WHERE userId = :userId AND shopId = :shopId")
    fun getPermissions(userId: String, shopId: String): Flow<List<StaffPermissionEntity>>

    @Query("SELECT * FROM staff_permissions WHERE userId = :userId AND shopId = :shopId")
    suspend fun getPermissionsList(userId: String, shopId: String): List<StaffPermissionEntity>

    @Query("DELETE FROM staff_permissions WHERE userId = :userId AND shopId = :shopId")
    suspend fun deleteAllForUser(userId: String, shopId: String)

    @Query("DELETE FROM staff_permissions WHERE userId = :userId")
    suspend fun deleteAllForUser(userId: String)
}

package com.shopzo.app.core.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import com.shopzo.app.core.database.entity.UserEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface UserDao {

    @Insert
    suspend fun insert(user: UserEntity)

    @Update
    suspend fun update(user: UserEntity)

    @Query("SELECT * FROM users WHERE mobileNumber = :mobileNumber LIMIT 1")
    suspend fun getUserByMobile(mobileNumber: String): UserEntity?

    @Query("SELECT * FROM users WHERE id = :userId LIMIT 1")
    suspend fun getUserById(userId: String): UserEntity?

    @Query("SELECT * FROM users WHERE shopId = :shopId AND role = 'STAFF'")
    fun getStaffByShop(shopId: String): Flow<List<UserEntity>>

    @Query("SELECT COUNT(*) FROM users WHERE mobileNumber = :mobileNumber")
    suspend fun countByMobile(mobileNumber: String): Int

    @Query("DELETE FROM users WHERE id = :userId")
    suspend fun deleteById(userId: String)
}

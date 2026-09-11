package com.shopzo.app.core.database.dao

import androidx.room.*
import com.shopzo.app.core.database.entity.CustomerEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface CustomerDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCustomer(customer: CustomerEntity)

    @Update
    suspend fun updateCustomer(customer: CustomerEntity)

    @Query("SELECT * FROM customers WHERE id = :id")
    suspend fun getCustomerById(id: String): CustomerEntity?

    @Query("SELECT * FROM customers WHERE id = :id")
    fun getCustomerByIdFlow(id: String): Flow<CustomerEntity?>

    @Query("SELECT * FROM customers WHERE shopId = :shopId ORDER BY name ASC")
    fun getCustomersByShop(shopId: String): Flow<List<CustomerEntity>>

    @Query("SELECT * FROM customers WHERE shopId = :shopId AND (name LIKE '%' || :query || '%' OR mobileNumber LIKE '%' || :query || '%') ORDER BY name ASC")
    fun searchCustomers(shopId: String, query: String): Flow<List<CustomerEntity>>

    @Query("SELECT COUNT(*) FROM customers WHERE shopId = :shopId")
    fun countCustomers(shopId: String): Flow<Int>

    @Query("SELECT SUM(outstandingDuePaise) FROM customers WHERE shopId = :shopId")
    fun getTotalOutstandingDues(shopId: String): Flow<Long?>

    @Query("SELECT COUNT(*) FROM customers WHERE shopId = :shopId AND outstandingDuePaise > 0")
    fun getCustomersWithDuesCount(shopId: String): Flow<Int>

    @Query("SELECT * FROM customers WHERE shopId = :shopId AND outstandingDuePaise > 0 ORDER BY outstandingDuePaise DESC")
    fun getCustomersWithDues(shopId: String): Flow<List<CustomerEntity>>

    @Query("UPDATE customers SET totalPurchasePaise = totalPurchasePaise + :addPurchasePaise, outstandingDuePaise = outstandingDuePaise + :addDuePaise, updatedAt = :updatedAt WHERE id = :id")
    suspend fun updateDuesAndPurchase(id: String, addPurchasePaise: Long, addDuePaise: Long, updatedAt: Long = System.currentTimeMillis())

    @Query("UPDATE customers SET outstandingDuePaise = outstandingDuePaise - :amountPaise, updatedAt = :updatedAt WHERE id = :id")
    suspend fun reduceOutstandingDue(id: String, amountPaise: Long, updatedAt: Long = System.currentTimeMillis())
}

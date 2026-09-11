package com.shopzo.app.features.customers.data

import com.shopzo.app.core.database.ShopzoDatabase
import com.shopzo.app.core.database.entity.CustomerEntity
import com.shopzo.app.core.database.entity.SyncQueueEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.UUID

class CustomerRepository(
    private val database: ShopzoDatabase
) {
    private val customerDao = database.customerDao()
    private val syncDao = database.syncDao()
    private val json = Json { ignoreUnknownKeys = true }

    fun getCustomersByShop(shopId: String): Flow<List<CustomerEntity>> {
        return customerDao.getCustomersByShop(shopId)
    }

    fun searchCustomers(shopId: String, query: String): Flow<List<CustomerEntity>> {
        return customerDao.searchCustomers(shopId, query)
    }

    suspend fun getCustomerById(id: String): CustomerEntity? {
        return customerDao.getCustomerById(id)
    }

    fun getCustomerByIdFlow(id: String): Flow<CustomerEntity?> {
        return customerDao.getCustomerByIdFlow(id)
    }

    fun getCustomersWithDues(shopId: String): Flow<List<CustomerEntity>> {
        return customerDao.getCustomersWithDues(shopId)
    }

    fun getTotalOutstandingDues(shopId: String): Flow<Long?> {
        return customerDao.getTotalOutstandingDues(shopId)
    }

    suspend fun createCustomer(
        shopId: String,
        name: String,
        mobileNumber: String,
        address: String? = null
    ): Result<CustomerEntity> {
        val trimmedName = name.trim()
        val trimmedMobile = mobileNumber.trim()
        if (trimmedName.isEmpty()) {
            return Result.failure(IllegalArgumentException("Customer name is required."))
        }
        if (trimmedMobile.isEmpty()) {
            return Result.failure(IllegalArgumentException("Mobile number is required."))
        }

        val customer = CustomerEntity(
            id = UUID.randomUUID().toString(),
            name = trimmedName,
            mobileNumber = trimmedMobile,
            address = address?.trim()?.ifEmpty { null },
            shopId = shopId
        )
        return try {
            customerDao.insertCustomer(customer)
            enqueueSync("CUSTOMER", customer.id, "CREATE", json.encodeToString(customer), shopId)
            Result.success(customer)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun updateCustomer(customer: CustomerEntity): Result<Unit> {
        return try {
            val updated = customer.copy(updatedAt = System.currentTimeMillis())
            customerDao.updateCustomer(updated)
            enqueueSync("CUSTOMER", updated.id, "UPDATE", json.encodeToString(updated), updated.shopId)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
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

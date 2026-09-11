package com.shopzo.app.features.backup

import com.shopzo.app.core.database.ShopzoDatabase
import com.shopzo.app.features.backup.data.BackupRepository
import com.shopzo.app.features.backup.data.ShopzoBackup
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class BackupRestoreTest {

    private val json = Json { ignoreUnknownKeys = true }

    private class FakeDatabase : ShopzoDatabase() {
        override fun userDao(): com.shopzo.app.core.database.dao.UserDao = TODO()
        override fun shopDao(): com.shopzo.app.core.database.dao.ShopDao = TODO()
        override fun staffPermissionDao(): com.shopzo.app.core.database.dao.StaffPermissionDao = TODO()
        override fun categoryDao(): com.shopzo.app.core.database.dao.CategoryDao = TODO()
        override fun productDao(): com.shopzo.app.core.database.dao.ProductDao = TODO()
        override fun stockMovementDao(): com.shopzo.app.core.database.dao.StockMovementDao = TODO()
        override fun customerDao(): com.shopzo.app.core.database.dao.CustomerDao = TODO()
        override fun billDao(): com.shopzo.app.core.database.dao.BillDao = TODO()
        override fun billItemDao(): com.shopzo.app.core.database.dao.BillItemDao = TODO()
        override fun paymentDao(): com.shopzo.app.core.database.dao.PaymentDao = TODO()
        override fun returnDao(): com.shopzo.app.core.database.dao.ReturnDao = TODO()
        override fun syncDao(): com.shopzo.app.core.database.dao.SyncDao = TODO()
        override fun createOpenHelper(config: androidx.room.DatabaseConfiguration): androidx.sqlite.db.SupportSQLiteOpenHelper = TODO()
        override fun createInvalidationTracker(): androidx.room.InvalidationTracker = TODO()
        override fun clearAllTables() {}
    }

    @Test
    fun testBackupValidationSuccess() {
        val backup = ShopzoBackup(
            version = 1,
            exportedAt = System.currentTimeMillis(),
            shopId = "shop-123"
        )
        val jsonString = json.encodeToString(backup)

        val repository = BackupRepository(FakeDatabase())
        val result = repository.validateBackup(jsonString, "shop-123")

        assertTrue(result.isSuccess)
        assertEquals("shop-123", result.getOrNull()?.shopId)
    }

    @Test
    fun testBackupValidationShopMismatchFails() {
        val backup = ShopzoBackup(
            version = 1,
            exportedAt = System.currentTimeMillis(),
            shopId = "shop-A"
        )
        val jsonString = json.encodeToString(backup)

        val repository = BackupRepository(FakeDatabase())
        val result = repository.validateBackup(jsonString, "shop-B")

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull()?.message?.contains("does not match current shop") == true)
    }

    @Test
    fun testBackupValidationCorruptJsonFails() {
        val repository = BackupRepository(FakeDatabase())
        val result = repository.validateBackup("{corrupt_json: true", "shop-123")

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull()?.message?.contains("Invalid or corrupted") == true)
    }
}

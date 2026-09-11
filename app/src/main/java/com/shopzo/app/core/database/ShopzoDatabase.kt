package com.shopzo.app.core.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.shopzo.app.core.database.dao.*
import com.shopzo.app.core.database.entity.*

/**
 * Main Room database for SHOPZO.
 *
 * Version 1: Phase 1 entities (User, Shop, StaffPermission, Category, Product, StockMovement)
 * Version 2: Phase 2 entities (Customer, Bill, BillItem, Payment, Return)
 * Version 3: Phase 3 entities (SyncQueue)
 */
@Database(
    entities = [
        UserEntity::class,
        ShopEntity::class,
        StaffPermissionEntity::class,
        CategoryEntity::class,
        ProductEntity::class,
        StockMovementEntity::class,
        CustomerEntity::class,
        BillEntity::class,
        BillItemEntity::class,
        PaymentEntity::class,
        ReturnEntity::class,
        SyncQueueEntity::class
    ],
    version = 3,
    exportSchema = false
)
abstract class ShopzoDatabase : RoomDatabase() {

    abstract fun userDao(): UserDao
    abstract fun shopDao(): ShopDao
    abstract fun staffPermissionDao(): StaffPermissionDao
    abstract fun categoryDao(): CategoryDao
    abstract fun productDao(): ProductDao
    abstract fun stockMovementDao(): StockMovementDao
    abstract fun customerDao(): CustomerDao
    abstract fun billDao(): BillDao
    abstract fun billItemDao(): BillItemDao
    abstract fun paymentDao(): PaymentDao
    abstract fun returnDao(): ReturnDao
    abstract fun syncDao(): SyncDao

    companion object {
        @Volatile
        private var INSTANCE: ShopzoDatabase? = null

        val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                // Create customers table
                db.execSQL("""
                    CREATE TABLE IF NOT EXISTS `customers` (
                        `id` TEXT NOT NULL,
                        `name` TEXT NOT NULL,
                        `mobileNumber` TEXT NOT NULL,
                        `address` TEXT,
                        `totalPurchasePaise` INTEGER NOT NULL,
                        `outstandingDuePaise` INTEGER NOT NULL,
                        `createdAt` INTEGER NOT NULL,
                        `updatedAt` INTEGER NOT NULL,
                        `shopId` TEXT NOT NULL,
                        PRIMARY KEY(`id`)
                    )
                """.trimIndent())
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_customers_shopId` ON `customers` (`shopId`)")
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_customers_mobileNumber` ON `customers` (`mobileNumber`)")

                // Create bills table
                db.execSQL("""
                    CREATE TABLE IF NOT EXISTS `bills` (
                        `id` TEXT NOT NULL,
                        `billNumber` TEXT NOT NULL,
                        `customerId` TEXT,
                        `customerNameSnapshot` TEXT NOT NULL,
                        `customerMobileSnapshot` TEXT NOT NULL,
                        `subtotalPaise` INTEGER NOT NULL,
                        `grandTotalPaise` INTEGER NOT NULL,
                        `paidAmountPaise` INTEGER NOT NULL,
                        `pendingAmountPaise` INTEGER NOT NULL,
                        `paymentStatus` TEXT NOT NULL,
                        `createdAt` INTEGER NOT NULL,
                        `shopId` TEXT NOT NULL,
                        PRIMARY KEY(`id`)
                    )
                """.trimIndent())
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_bills_shopId` ON `bills` (`shopId`)")
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_bills_customerId` ON `bills` (`customerId`)")
                db.execSQL("CREATE UNIQUE INDEX IF NOT EXISTS `index_bills_shopId_billNumber` ON `bills` (`shopId`, `billNumber`)")

                // Create bill_items table
                db.execSQL("""
                    CREATE TABLE IF NOT EXISTS `bill_items` (
                        `id` TEXT NOT NULL,
                        `billId` TEXT NOT NULL,
                        `productId` TEXT NOT NULL,
                        `productNameSnapshot` TEXT NOT NULL,
                        `quantity` REAL NOT NULL,
                        `unit` TEXT NOT NULL,
                        `sellingPricePaise` INTEGER NOT NULL,
                        `buyingPricePaise` INTEGER NOT NULL,
                        `subtotalPaise` INTEGER NOT NULL,
                        `shopId` TEXT NOT NULL,
                        PRIMARY KEY(`id`)
                    )
                """.trimIndent())
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_bill_items_billId` ON `bill_items` (`billId`)")
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_bill_items_productId` ON `bill_items` (`productId`)")
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_bill_items_shopId` ON `bill_items` (`shopId`)")

                // Create payments table
                db.execSQL("""
                    CREATE TABLE IF NOT EXISTS `payments` (
                        `id` TEXT NOT NULL,
                        `billId` TEXT,
                        `customerId` TEXT NOT NULL,
                        `amountPaise` INTEGER NOT NULL,
                        `paymentMethod` TEXT NOT NULL,
                        `createdAt` INTEGER NOT NULL,
                        `shopId` TEXT NOT NULL,
                        PRIMARY KEY(`id`)
                    )
                """.trimIndent())
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_payments_billId` ON `payments` (`billId`)")
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_payments_customerId` ON `payments` (`customerId`)")
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_payments_shopId` ON `payments` (`shopId`)")

                // Create returns table
                db.execSQL("""
                    CREATE TABLE IF NOT EXISTS `returns` (
                        `id` TEXT NOT NULL,
                        `billId` TEXT NOT NULL,
                        `billItemId` TEXT NOT NULL,
                        `productId` TEXT NOT NULL,
                        `quantityReturned` REAL NOT NULL,
                        `refundAmountPaise` INTEGER NOT NULL,
                        `stockRestored` INTEGER NOT NULL,
                        `reason` TEXT NOT NULL,
                        `createdAt` INTEGER NOT NULL,
                        `shopId` TEXT NOT NULL,
                        PRIMARY KEY(`id`)
                    )
                """.trimIndent())
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_returns_billId` ON `returns` (`billId`)")
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_returns_billItemId` ON `returns` (`billItemId`)")
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_returns_productId` ON `returns` (`productId`)")
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_returns_shopId` ON `returns` (`shopId`)")
            }
        }

        val MIGRATION_2_3 = object : Migration(2, 3) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("""
                    CREATE TABLE IF NOT EXISTS `sync_queue` (
                        `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        `entityType` TEXT NOT NULL,
                        `entityId` TEXT NOT NULL,
                        `operationType` TEXT NOT NULL,
                        `payloadJson` TEXT NOT NULL,
                        `shopId` TEXT NOT NULL,
                        `createdAt` INTEGER NOT NULL,
                        `retryCount` INTEGER NOT NULL,
                        `lastAttemptAt` INTEGER,
                        `status` TEXT NOT NULL,
                        `errorMessage` TEXT
                    )
                """.trimIndent())
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_sync_queue_shopId` ON `sync_queue` (`shopId`)")
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_sync_queue_status` ON `sync_queue` (`status`)")
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_sync_queue_shopId_status` ON `sync_queue` (`shopId`, `status`)")
            }
        }

        fun getInstance(context: Context): ShopzoDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    ShopzoDatabase::class.java,
                    "shopzo_database"
                )
                .addMigrations(MIGRATION_1_2, MIGRATION_2_3)
                .build()
                INSTANCE = instance
                instance
            }
        }
    }
}

package com.shopzo.app

import android.app.Application
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import com.shopzo.app.core.database.ShopzoDatabase
import com.shopzo.app.core.network.ApiClient
import com.shopzo.app.core.network.ShopzoApiService
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.core.sync.SyncManager
import com.shopzo.app.core.sync.SyncRepository
import com.shopzo.app.features.auth.data.AuthRepository
import com.shopzo.app.features.billing.data.BillingRepository
import com.shopzo.app.features.customers.data.CustomerRepository
import com.shopzo.app.features.payments.data.PaymentRepository
import com.shopzo.app.features.products.data.ProductRepository
import com.shopzo.app.features.reports.data.ReportRepository
import com.shopzo.app.features.returns.data.ReturnRepository
import com.shopzo.app.features.shop.data.ShopRepository
import com.shopzo.app.features.staff.data.StaffRepository
import com.shopzo.app.features.stock.data.StockRepository

/**
 * Application-level service locator for dependency injection.
 * Service locator provides centralized singleton repositories across Phase 1, Phase 2 & Phase 3.
 */
class ShopzoApplication : Application() {

    lateinit var database: ShopzoDatabase
        private set
    lateinit var sessionManager: SessionManager
        private set
    lateinit var apiService: ShopzoApiService
        private set
    lateinit var syncRepository: SyncRepository
        private set
    lateinit var syncManager: SyncManager
        private set
    lateinit var authRepository: AuthRepository
        private set
    lateinit var shopRepository: ShopRepository
        private set
    lateinit var staffRepository: StaffRepository
        private set
    lateinit var productRepository: ProductRepository
        private set
    lateinit var stockRepository: StockRepository
        private set
    lateinit var customerRepository: CustomerRepository
        private set
    lateinit var billingRepository: BillingRepository
        private set
    lateinit var paymentRepository: PaymentRepository
        private set
    lateinit var returnRepository: ReturnRepository
        private set
    lateinit var reportRepository: ReportRepository
        private set
    lateinit var backupRepository: com.shopzo.app.features.backup.data.BackupRepository
        private set

    override fun onCreate() {
        super.onCreate()
        database = ShopzoDatabase.getInstance(this)
        sessionManager = SessionManager(this)

        apiService = ApiClient.create(
            tokenProvider = { sessionManager.getAuthToken() },
            shopIdProvider = { sessionManager.getCurrentShopId() }
        )

        syncRepository = SyncRepository(database, apiService)
        syncManager = SyncManager(
            syncRepository = syncRepository,
            getCurrentShopId = { sessionManager.getCurrentShopId() },
            isNetworkAvailable = { checkNetworkAvailable() }
        )

        authRepository = AuthRepository(database.userDao())
        shopRepository = ShopRepository(database.shopDao(), database.userDao(), database.categoryDao())
        staffRepository = StaffRepository(database.userDao(), database.staffPermissionDao())
        productRepository = ProductRepository(database)
        stockRepository = StockRepository(database)
        customerRepository = CustomerRepository(database)
        billingRepository = BillingRepository(database)
        paymentRepository = PaymentRepository(database)
        returnRepository = ReturnRepository(database)
        reportRepository = ReportRepository(database)
        backupRepository = com.shopzo.app.features.backup.data.BackupRepository(database)
    }

    private fun checkNetworkAvailable(): Boolean {
        val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager ?: return false
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }
}

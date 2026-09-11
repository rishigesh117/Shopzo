package com.shopzo.app.features.dashboard.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.features.customers.data.CustomerRepository
import com.shopzo.app.features.products.data.ProductRepository
import com.shopzo.app.features.reports.data.DateRangePeriod
import com.shopzo.app.features.reports.data.ReportRepository
import com.shopzo.app.features.reports.data.getTimeRange
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

class DashboardViewModel(
    private val productRepository: ProductRepository,
    private val reportRepository: ReportRepository,
    private val customerRepository: CustomerRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _shopId = MutableStateFlow("")

    val lowStockCount: StateFlow<Int> = _shopId.flatMapLatest { shopId ->
        if (shopId.isNotEmpty()) productRepository.countLowStock(shopId) else flowOf(0)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    val outOfStockCount: StateFlow<Int> = _shopId.flatMapLatest { shopId ->
        if (shopId.isNotEmpty()) productRepository.countOutOfStock(shopId) else flowOf(0)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    val totalProducts: StateFlow<Int> = _shopId.flatMapLatest { shopId ->
        if (shopId.isNotEmpty()) productRepository.countProducts(shopId) else flowOf(0)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    val todaySalesReport = _shopId.flatMapLatest { id ->
        if (id.isNotEmpty()) reportRepository.getSalesReport(id, DateRangePeriod.TODAY.getTimeRange())
        else flowOf(com.shopzo.app.features.reports.data.SalesReportData())
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), com.shopzo.app.features.reports.data.SalesReportData())

    val totalOutstandingDues: StateFlow<Long> = _shopId.flatMapLatest { id ->
        if (id.isNotEmpty()) customerRepository.getTotalOutstandingDues(id).map { it ?: 0L } else flowOf(0L)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0L)

    init {
        viewModelScope.launch {
            sessionManager.sessionFlow.collect { session ->
                _shopId.value = session?.shopId ?: ""
            }
        }
    }

    class Factory(
        private val productRepository: ProductRepository,
        private val reportRepository: ReportRepository,
        private val customerRepository: CustomerRepository,
        private val sessionManager: SessionManager
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return DashboardViewModel(productRepository, reportRepository, customerRepository, sessionManager) as T
        }
    }
}

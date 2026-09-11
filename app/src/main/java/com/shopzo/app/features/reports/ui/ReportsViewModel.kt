package com.shopzo.app.features.reports.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.shopzo.app.core.database.dao.BestSellerAggregate
import com.shopzo.app.core.database.entity.CustomerEntity
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.features.customers.data.CustomerRepository
import com.shopzo.app.features.reports.data.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

data class ReportsUiState(
    val selectedPeriod: DateRangePeriod = DateRangePeriod.TODAY,
    val bestSellerMetric: BestSellerMetric = BestSellerMetric.QUANTITY,
    val bestSellerLimit: Int = 10,
    val customStart: Long? = null,
    val customEnd: Long? = null
)

class ReportsViewModel(
    private val reportRepository: ReportRepository,
    private val customerRepository: CustomerRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _shopId = MutableStateFlow("")
    val shopId: StateFlow<String> = _shopId.asStateFlow()

    private val _uiState = MutableStateFlow(ReportsUiState())
    val uiState: StateFlow<ReportsUiState> = _uiState.asStateFlow()

    private val timeRange: Flow<TimeRange> = _uiState.map { state ->
        state.selectedPeriod.getTimeRange(state.customStart, state.customEnd)
    }

    val salesReport: StateFlow<SalesReportData> = combine(_shopId, timeRange) { id, range ->
        Pair(id, range)
    }.flatMapLatest { (id, range) ->
        if (id.isNotEmpty()) reportRepository.getSalesReport(id, range) else flowOf(SalesReportData())
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), SalesReportData())

    val profitReport: StateFlow<ProfitReportData> = combine(_shopId, timeRange) { id, range ->
        Pair(id, range)
    }.flatMapLatest { (id, range) ->
        if (id.isNotEmpty()) reportRepository.getProfitReport(id, range) else flowOf(ProfitReportData())
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), ProfitReportData())

    val stockReport: StateFlow<StockReportData> = _shopId.flatMapLatest { id ->
        if (id.isNotEmpty()) reportRepository.getStockReport(id) else flowOf(StockReportData())
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), StockReportData())

    val bestSellers: StateFlow<List<BestSellerAggregate>> = combine(_shopId, timeRange, _uiState) { id, range, state ->
        Triple(id, range, state)
    }.flatMapLatest { (id, range, state) ->
        if (id.isNotEmpty()) reportRepository.getBestSellers(id, range, state.bestSellerMetric, state.bestSellerLimit)
        else flowOf(emptyList())
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val customersWithDues: StateFlow<List<CustomerEntity>> = _shopId.flatMapLatest { id ->
        if (id.isNotEmpty()) customerRepository.getCustomersWithDues(id) else flowOf(emptyList())
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    init {
        viewModelScope.launch {
            sessionManager.sessionFlow.collect { session ->
                _shopId.value = session?.shopId ?: ""
            }
        }
    }

    fun setPeriod(period: DateRangePeriod) {
        _uiState.update { it.copy(selectedPeriod = period) }
    }

    fun setBestSellerMetric(metric: BestSellerMetric) {
        _uiState.update { it.copy(bestSellerMetric = metric) }
    }

    fun setBestSellerLimit(limit: Int) {
        _uiState.update { it.copy(bestSellerLimit = limit) }
    }

    class Factory(
        private val reportRepository: ReportRepository,
        private val customerRepository: CustomerRepository,
        private val sessionManager: SessionManager
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return ReportsViewModel(reportRepository, customerRepository, sessionManager) as T
        }
    }
}

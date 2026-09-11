package com.shopzo.app.features.billing.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.shopzo.app.core.database.entity.BillEntity
import com.shopzo.app.core.database.entity.BillItemEntity
import com.shopzo.app.core.database.entity.PaymentEntity
import com.shopzo.app.core.database.entity.ReturnEntity
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.features.billing.data.BillingRepository
import com.shopzo.app.features.payments.data.PaymentRepository
import com.shopzo.app.features.returns.data.ReturnRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

data class BillsUiState(
    val selectedFilter: String = "ALL", // ALL, PAID, PARTIALLY_PAID, PENDING
    val searchQuery: String = ""
)

class BillsViewModel(
    private val billingRepository: BillingRepository,
    private val paymentRepository: PaymentRepository,
    private val returnRepository: ReturnRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _shopId = MutableStateFlow("")
    val shopId: StateFlow<String> = _shopId.asStateFlow()

    private val _uiState = MutableStateFlow(BillsUiState())
    val uiState: StateFlow<BillsUiState> = _uiState.asStateFlow()

    val bills: StateFlow<List<BillEntity>> = combine(_shopId, _uiState) { id, state ->
        Pair(id, state)
    }.flatMapLatest { (id, state) ->
        if (id.isEmpty()) flowOf(emptyList())
        else if (state.searchQuery.isNotBlank()) billingRepository.searchBills(id, state.searchQuery)
        else if (state.selectedFilter != "ALL") billingRepository.getBillsByStatus(id, state.selectedFilter)
        else billingRepository.getBillsByShop(id)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    init {
        viewModelScope.launch {
            sessionManager.sessionFlow.collect { session ->
                _shopId.value = session?.shopId ?: ""
            }
        }
    }

    fun setFilter(filter: String) {
        _uiState.update { it.copy(selectedFilter = filter) }
    }

    fun setSearchQuery(query: String) {
        _uiState.update { it.copy(searchQuery = query) }
    }

    fun getBillDetail(billId: String): Flow<BillEntity?> {
        return billingRepository.getBillByIdFlow(billId)
    }

    fun getBillItems(billId: String): Flow<List<BillItemEntity>> {
        return billingRepository.getBillItemsFlow(billId)
    }

    fun getPaymentHistory(billId: String): Flow<List<PaymentEntity>> {
        return paymentRepository.getPaymentsByBill(billId)
    }

    fun getReturnHistory(billId: String): Flow<List<ReturnEntity>> {
        return returnRepository.getReturnsByBill(billId)
    }

    class Factory(
        private val billingRepository: BillingRepository,
        private val paymentRepository: PaymentRepository,
        private val returnRepository: ReturnRepository,
        private val sessionManager: SessionManager
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return BillsViewModel(billingRepository, paymentRepository, returnRepository, sessionManager) as T
        }
    }
}

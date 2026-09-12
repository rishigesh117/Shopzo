package com.shopzo.app.features.customers.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.shopzo.app.core.database.entity.BillEntity
import com.shopzo.app.core.database.entity.CustomerEntity
import com.shopzo.app.core.database.entity.PaymentEntity
import com.shopzo.app.core.database.entity.ReturnEntity
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.features.billing.data.BillingRepository
import com.shopzo.app.features.customers.data.CustomerRepository
import com.shopzo.app.features.payments.data.PaymentRepository
import com.shopzo.app.features.returns.data.ReturnRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

data class CustomerUiState(
    val searchQuery: String = "",
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val successMessage: String? = null
)

class CustomerViewModel(
    private val customerRepository: CustomerRepository,
    private val billingRepository: BillingRepository,
    private val paymentRepository: PaymentRepository,
    private val returnRepository: ReturnRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _shopId = MutableStateFlow("")
    val shopId: StateFlow<String> = _shopId.asStateFlow()

    private val _uiState = MutableStateFlow(CustomerUiState())
    val uiState: StateFlow<CustomerUiState> = _uiState.asStateFlow()

    val customers: StateFlow<List<CustomerEntity>> = combine(_shopId, _uiState) { id, state ->
        Pair(id, state)
    }.flatMapLatest { (id, state) ->
        if (id.isEmpty()) flowOf(emptyList())
        else if (state.searchQuery.isNotBlank()) customerRepository.searchCustomers(id, state.searchQuery)
        else customerRepository.getCustomersByShop(id)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

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

    fun setSearchQuery(query: String) {
        _uiState.update { it.copy(searchQuery = query) }
    }

    fun getCustomerDetail(customerId: String): Flow<CustomerEntity?> {
        return customerRepository.getCustomerByIdFlow(customerId)
    }

    fun getCustomerBills(shopId: String, customerId: String): Flow<List<BillEntity>> {
        return billingRepository.getBillsByShop(shopId).map { list ->
            list.filter { it.customerId == customerId }
        }
    }

    fun getCustomerPayments(customerId: String): Flow<List<PaymentEntity>> {
        return paymentRepository.getPaymentsByCustomer(customerId)
    }

    fun createCustomer(
        name: String,
        mobileNumber: String,
        address: String?,
        onSuccess: (CustomerEntity) -> Unit
    ) {
        val id = _shopId.value
        if (id.isEmpty()) return
        _uiState.update { it.copy(isLoading = true, errorMessage = null) }

        viewModelScope.launch {
            val result = customerRepository.createCustomer(id, name, mobileNumber, address)
            result.fold(
                onSuccess = { customer ->
                    _uiState.update { it.copy(isLoading = false, successMessage = "Customer created successfully.") }
                    onSuccess(customer)
                },
                onFailure = { err ->
                    _uiState.update { it.copy(isLoading = false, errorMessage = err.message ?: "Failed to create customer.") }
                }
            )
        }
    }

    fun updateCustomer(
        customer: CustomerEntity,
        name: String,
        mobileNumber: String,
        address: String?,
        onSuccess: (CustomerEntity) -> Unit
    ) {
        val trimmedName = name.trim()
        val trimmedMobile = mobileNumber.trim()
        val nameErr = com.shopzo.app.core.utils.ValidationUtils.validateName(trimmedName, "Customer name")
        if (nameErr != null) {
            _uiState.update { it.copy(errorMessage = nameErr) }
            return
        }
        val mobileErr = com.shopzo.app.core.utils.ValidationUtils.validateMobileNumber(trimmedMobile)
        if (mobileErr != null) {
            _uiState.update { it.copy(errorMessage = mobileErr) }
            return
        }

        _uiState.update { it.copy(isLoading = true, errorMessage = null) }
        viewModelScope.launch {
            val updated = customer.copy(
                name = trimmedName,
                mobileNumber = trimmedMobile,
                address = address?.trim()?.ifEmpty { null }
            )
            val result = customerRepository.updateCustomer(updated)
            result.fold(
                onSuccess = {
                    _uiState.update { it.copy(isLoading = false, successMessage = "Customer updated successfully.") }
                    onSuccess(updated)
                },
                onFailure = { err ->
                    _uiState.update { it.copy(isLoading = false, errorMessage = err.message ?: "Failed to update customer.") }
                }
            )
        }
    }

    fun deleteCustomer(
        customerId: String,
        onSuccess: () -> Unit
    ) {
        _uiState.update { it.copy(isLoading = true, errorMessage = null) }
        viewModelScope.launch {
            val result = customerRepository.deleteCustomer(customerId)
            result.fold(
                onSuccess = {
                    _uiState.update { it.copy(isLoading = false, successMessage = "Customer deleted successfully.") }
                    onSuccess()
                },
                onFailure = { err ->
                    _uiState.update { it.copy(isLoading = false, errorMessage = err.message ?: "Failed to delete customer.") }
                }
            )
        }
    }

    fun clearMessages() {
        _uiState.update { it.copy(errorMessage = null, successMessage = null) }
    }

    class Factory(
        private val customerRepository: CustomerRepository,
        private val billingRepository: BillingRepository,
        private val paymentRepository: PaymentRepository,
        private val returnRepository: ReturnRepository,
        private val sessionManager: SessionManager
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return CustomerViewModel(customerRepository, billingRepository, paymentRepository, returnRepository, sessionManager) as T
        }
    }
}

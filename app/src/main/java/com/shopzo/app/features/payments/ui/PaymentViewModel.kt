package com.shopzo.app.features.payments.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.shopzo.app.core.database.entity.PaymentEntity
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.features.payments.data.PaymentRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

data class PaymentUiState(
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val successMessage: String? = null
)

class PaymentViewModel(
    private val paymentRepository: PaymentRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _shopId = MutableStateFlow("")
    val shopId: StateFlow<String> = _shopId.asStateFlow()

    private val _uiState = MutableStateFlow(PaymentUiState())
    val uiState: StateFlow<PaymentUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            sessionManager.sessionFlow.collect { session ->
                _shopId.value = session?.shopId ?: ""
            }
        }
    }

    fun recordPayment(
        customerId: String,
        billId: String?,
        amountPaise: Long,
        paymentMethod: String,
        onSuccess: (PaymentEntity) -> Unit
    ) {
        val id = _shopId.value
        if (id.isEmpty()) return
        _uiState.update { it.copy(isLoading = true, errorMessage = null) }

        viewModelScope.launch {
            val result = paymentRepository.recordPayment(
                shopId = id,
                customerId = customerId,
                billId = billId,
                amountPaise = amountPaise,
                paymentMethod = paymentMethod
            )

            result.fold(
                onSuccess = { payment ->
                    _uiState.update { it.copy(isLoading = false, successMessage = "Payment recorded successfully.") }
                    onSuccess(payment)
                },
                onFailure = { err ->
                    _uiState.update { it.copy(isLoading = false, errorMessage = err.message ?: "Failed to record payment.") }
                }
            )
        }
    }

    fun clearMessages() {
        _uiState.update { it.copy(errorMessage = null, successMessage = null) }
    }

    class Factory(
        private val paymentRepository: PaymentRepository,
        private val sessionManager: SessionManager
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return PaymentViewModel(paymentRepository, sessionManager) as T
        }
    }
}

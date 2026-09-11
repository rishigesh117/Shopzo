package com.shopzo.app.features.returns.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.shopzo.app.core.database.entity.ReturnEntity
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.features.returns.data.ReturnRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

data class ReturnsUiState(
    val isLoading: Boolean = false,
    val errorMessage: String? = null,
    val successMessage: String? = null
)

class ReturnsViewModel(
    private val returnRepository: ReturnRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _shopId = MutableStateFlow("")
    val shopId: StateFlow<String> = _shopId.asStateFlow()

    private val _uiState = MutableStateFlow(ReturnsUiState())
    val uiState: StateFlow<ReturnsUiState> = _uiState.asStateFlow()

    val returns: StateFlow<List<ReturnEntity>> = _shopId.flatMapLatest { id ->
        if (id.isNotEmpty()) returnRepository.getReturnsByShop(id) else flowOf(emptyList())
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    init {
        viewModelScope.launch {
            sessionManager.sessionFlow.collect { session ->
                _shopId.value = session?.shopId ?: ""
            }
        }
    }

    suspend fun getPreviouslyReturnedQty(billItemId: String): Double {
        return returnRepository.getPreviouslyReturnedQuantity(billItemId)
    }

    fun processReturn(
        billId: String,
        billItemId: String,
        quantityToReturn: Double,
        stockRestored: Boolean,
        reason: String,
        onSuccess: (ReturnEntity) -> Unit
    ) {
        val id = _shopId.value
        if (id.isEmpty()) return
        _uiState.update { it.copy(isLoading = true, errorMessage = null) }

        viewModelScope.launch {
            val result = returnRepository.processReturn(
                shopId = id,
                billId = billId,
                billItemId = billItemId,
                quantityToReturn = quantityToReturn,
                stockRestored = stockRestored,
                reason = reason
            )

            result.fold(
                onSuccess = { returnRecord ->
                    _uiState.update { it.copy(isLoading = false, successMessage = "Return processed successfully.") }
                    onSuccess(returnRecord)
                },
                onFailure = { err ->
                    _uiState.update { it.copy(isLoading = false, errorMessage = err.message ?: "Failed to process return.") }
                }
            )
        }
    }

    fun clearMessages() {
        _uiState.update { it.copy(errorMessage = null, successMessage = null) }
    }

    class Factory(
        private val returnRepository: ReturnRepository,
        private val sessionManager: SessionManager
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return ReturnsViewModel(returnRepository, sessionManager) as T
        }
    }
}

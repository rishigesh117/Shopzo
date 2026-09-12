package com.shopzo.app.features.stock.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.shopzo.app.core.database.entity.StockMovementEntity
import com.shopzo.app.core.model.AdjustmentReason
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.core.utils.MoneyUtils
import com.shopzo.app.core.utils.ValidationUtils
import com.shopzo.app.features.stock.data.StockRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

class StockViewModel(
    private val stockRepository: StockRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _shopId = MutableStateFlow("")

    // Restock form
    var restockQuantity by mutableStateOf("")
    var restockBuyingPrice by mutableStateOf("")
    var restockSupplier by mutableStateOf("")
    var restockNotes by mutableStateOf("")

    // Adjustment form
    var adjustQuantity by mutableStateOf("")
    var selectedReason by mutableStateOf(AdjustmentReason.DAMAGED_PRODUCT)
    var adjustNotes by mutableStateOf("")

    var isLoading by mutableStateOf(false)
        private set
    var errorMessage by mutableStateOf<String?>(null)
        private set

    init {
        viewModelScope.launch {
            sessionManager.sessionFlow.collect { session ->
                _shopId.value = session?.shopId ?: ""
            }
        }
    }

    fun getMovementsForProduct(productId: String): Flow<List<StockMovementEntity>> =
        stockRepository.getMovementsForProduct(productId)

    fun restock(productId: String, onSuccess: () -> Unit) {
        val qtyError = ValidationUtils.validatePositiveQuantity(restockQuantity)
        if (qtyError != null) { errorMessage = qtyError; return }

        val buyPaise = if (restockBuyingPrice.isNotBlank()) {
            MoneyUtils.rupeesToPaise(restockBuyingPrice) ?: run {
                errorMessage = "Enter a valid buying price."; return
            }
        } else null

        isLoading = true
        errorMessage = null
        viewModelScope.launch {
            try {
                val success = stockRepository.restock(
                    productId = productId,
                    quantity = restockQuantity.trim().toDouble(),
                    buyingPricePaise = buyPaise?.toLong(),
                    supplier = restockSupplier.ifBlank { null },
                    notes = restockNotes.ifBlank { null },
                    shopId = _shopId.value
                )
                isLoading = false
                if (success) {
                    resetRestockForm()
                    onSuccess()
                } else {
                    errorMessage = "Failed to restock. Product not found."
                }
            } catch (e: Exception) {
                e.printStackTrace()
                isLoading = false
                errorMessage = e.localizedMessage ?: "Failed to restock."
            }
        }
    }

    fun adjustStock(productId: String, onSuccess: () -> Unit) {
        val qtyError = ValidationUtils.validatePositiveQuantity(adjustQuantity)
        if (qtyError != null) { errorMessage = qtyError; return }

        isLoading = true
        errorMessage = null
        viewModelScope.launch {
            try {
                val quantityChange = -adjustQuantity.trim().toDouble() // Adjustments reduce stock
                val success = stockRepository.adjustStock(
                    productId = productId,
                    quantityChange = quantityChange,
                    reason = selectedReason,
                    notes = adjustNotes.ifBlank { null },
                    shopId = _shopId.value
                )
                isLoading = false
                if (success) {
                    resetAdjustForm()
                    onSuccess()
                } else {
                    errorMessage = "Failed to adjust stock."
                }
            } catch (e: Exception) {
                e.printStackTrace()
                isLoading = false
                errorMessage = e.localizedMessage ?: "Failed to adjust stock."
            }
        }
    }

    private fun resetRestockForm() {
        restockQuantity = ""; restockBuyingPrice = ""; restockSupplier = ""; restockNotes = ""
    }

    private fun resetAdjustForm() {
        adjustQuantity = ""; selectedReason = AdjustmentReason.DAMAGED_PRODUCT; adjustNotes = ""
    }

    fun clearError() { errorMessage = null }

    class Factory(
        private val stockRepository: StockRepository,
        private val sessionManager: SessionManager
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return StockViewModel(stockRepository, sessionManager) as T
        }
    }
}

package com.shopzo.app.features.shop.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.core.utils.ValidationUtils
import com.shopzo.app.features.shop.data.ShopRepository
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

class ShopViewModel(
    private val shopRepository: ShopRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    var shopName by mutableStateOf("")
    var ownerName by mutableStateOf("")
    var mobileNumber by mutableStateOf("")
    var address by mutableStateOf("")
    var isLoading by mutableStateOf(false)
        private set
    var errorMessage by mutableStateOf<String?>(null)
        private set
    var createdShopCode by mutableStateOf<String?>(null)
        private set

    init {
        // Pre-fill owner details from session
        viewModelScope.launch {
            val session = sessionManager.sessionFlow.first()
            if (session != null) {
                ownerName = session.userName
            }
        }
    }

    fun createShop(onSuccess: () -> Unit) {
        val nameError = ValidationUtils.validateShopName(shopName)
        val ownerError = ValidationUtils.validateName(ownerName, "Owner name")
        val mobileError = ValidationUtils.validateMobileNumber(mobileNumber)
        val firstError = nameError ?: ownerError ?: mobileError
        if (firstError != null) {
            errorMessage = firstError
            return
        }

        isLoading = true
        errorMessage = null
        viewModelScope.launch {
            try {
                val session = sessionManager.sessionFlow.first() ?: return@launch
                val shop = shopRepository.createShop(
                    shopName = shopName,
                    ownerName = ownerName,
                    mobileNumber = mobileNumber,
                    address = address.ifBlank { null },
                    ownerId = session.userId
                )
                sessionManager.updateShopId(shop.id)
                createdShopCode = shop.shopCode
                isLoading = false
                onSuccess()
            } catch (e: Exception) {
                errorMessage = "Failed to create shop. Please try again."
                isLoading = false
            }
        }
    }

    fun clearError() { errorMessage = null }

    class Factory(
        private val shopRepository: ShopRepository,
        private val sessionManager: SessionManager
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return ShopViewModel(shopRepository, sessionManager) as T
        }
    }
}

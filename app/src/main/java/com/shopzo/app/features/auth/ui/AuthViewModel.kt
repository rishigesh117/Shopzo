package com.shopzo.app.features.auth.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.shopzo.app.core.model.UserRole
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.core.utils.ValidationUtils
import com.shopzo.app.features.auth.data.AuthRepository
import com.shopzo.app.features.shop.data.ShopRepository
import kotlinx.coroutines.launch

class AuthViewModel(
    private val authRepository: AuthRepository,
    private val shopRepository: ShopRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    var name by mutableStateOf("")
    var mobileNumber by mutableStateOf("")
    var password by mutableStateOf("")
    var isLoading by mutableStateOf(false)
        private set
    var errorMessage by mutableStateOf<String?>(null)
        private set

    // Navigation events
    var navigateToDashboard by mutableStateOf(false)
        private set
    var navigateToCreateShop by mutableStateOf(false)
        private set

    fun register(onSuccess: () -> Unit) {
        val nameError = ValidationUtils.validateName(name, "Owner name")
        val mobileError = ValidationUtils.validateMobileNumber(mobileNumber)
        val passwordError = ValidationUtils.validatePassword(password)

        val firstError = nameError ?: mobileError ?: passwordError
        if (firstError != null) {
            errorMessage = firstError
            return
        }

        isLoading = true
        errorMessage = null
        viewModelScope.launch {
            when (val result = authRepository.register(name, mobileNumber, password)) {
                is AuthRepository.AuthResult.Success -> {
                    sessionManager.saveSession(
                        userId = result.user.id,
                        shopId = "",
                        role = UserRole.OWNER,
                        userName = result.user.name
                    )
                    isLoading = false
                    onSuccess()
                }
                is AuthRepository.AuthResult.Error -> {
                    errorMessage = result.message
                    isLoading = false
                }
            }
        }
    }

    fun login(onDashboard: () -> Unit, onCreateShop: () -> Unit) {
        val mobileError = ValidationUtils.validateMobileNumber(mobileNumber)
        val passwordError = ValidationUtils.validatePassword(password)
        val firstError = mobileError ?: passwordError
        if (firstError != null) {
            errorMessage = firstError
            return
        }

        isLoading = true
        errorMessage = null
        viewModelScope.launch {
            when (val result = authRepository.login(mobileNumber, password)) {
                is AuthRepository.AuthResult.Success -> {
                    val user = result.user
                    val role = try { UserRole.valueOf(user.role) } catch (_: Exception) { UserRole.STAFF }

                    if (role == UserRole.OWNER && user.shopId == null) {
                        sessionManager.saveSession(user.id, "", role, user.name)
                        isLoading = false
                        onCreateShop()
                    } else {
                        sessionManager.saveSession(user.id, user.shopId ?: "", role, user.name)
                        isLoading = false
                        onDashboard()
                    }
                }
                is AuthRepository.AuthResult.Error -> {
                    errorMessage = result.message
                    isLoading = false
                }
            }
        }
    }

    fun clearError() {
        errorMessage = null
    }

    class Factory(
        private val authRepository: AuthRepository,
        private val shopRepository: ShopRepository,
        private val sessionManager: SessionManager
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return AuthViewModel(authRepository, shopRepository, sessionManager) as T
        }
    }
}

package com.shopzo.app.features.staff.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.shopzo.app.core.database.entity.UserEntity
import com.shopzo.app.core.model.Permission
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.core.utils.ValidationUtils
import com.shopzo.app.features.staff.data.StaffRepository
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

class StaffViewModel(
    private val staffRepository: StaffRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _shopId = MutableStateFlow("")

    val staffList: StateFlow<List<UserEntity>> = _shopId.flatMapLatest { shopId ->
        if (shopId.isNotEmpty()) staffRepository.getStaffByShop(shopId) else flowOf(emptyList())
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Add Staff form state
    var staffName by mutableStateOf("")
    var staffMobile by mutableStateOf("")
    var staffPassword by mutableStateOf("")
    var fullAccess by mutableStateOf(false)
    var selectedPermissions by mutableStateOf(setOf<Permission>())
    var isLoading by mutableStateOf(false)
        private set
    var errorMessage by mutableStateOf<String?>(null)
        private set
    var successMessage by mutableStateOf<String?>(null)
        private set

    // Staff permissions for edit
    var editPermissions by mutableStateOf(setOf<Permission>())
    var editFullAccess by mutableStateOf(false)

    init {
        viewModelScope.launch {
            sessionManager.sessionFlow.collect { session ->
                _shopId.value = session?.shopId ?: ""
            }
        }
    }

    fun toggleFullAccess(enabled: Boolean) {
        fullAccess = enabled
        selectedPermissions = if (enabled) Permission.entries.toSet() else emptySet()
    }

    fun togglePermission(permission: Permission) {
        selectedPermissions = if (permission in selectedPermissions) {
            selectedPermissions - permission
        } else {
            selectedPermissions + permission
        }
        fullAccess = selectedPermissions.size == Permission.entries.size
    }

    fun createStaff(onSuccess: () -> Unit) {
        val nameError = ValidationUtils.validateName(staffName, "Staff name")
        val mobileError = ValidationUtils.validateMobileNumber(staffMobile)
        val passwordError = ValidationUtils.validatePassword(staffPassword)
        val firstError = nameError ?: mobileError ?: passwordError
        if (firstError != null) {
            errorMessage = firstError
            return
        }

        isLoading = true
        errorMessage = null
        viewModelScope.launch {
            val result = staffRepository.createStaff(
                name = staffName,
                mobileNumber = staffMobile,
                password = staffPassword,
                permissions = selectedPermissions,
                shopId = _shopId.value
            )
            when (result) {
                is StaffRepository.StaffResult.Success -> {
                    isLoading = false
                    resetForm()
                    onSuccess()
                }
                is StaffRepository.StaffResult.Error -> {
                    errorMessage = result.message
                    isLoading = false
                }
            }
        }
    }

    fun loadStaffPermissions(userId: String) {
        viewModelScope.launch {
            val permissions = staffRepository.getPermissionsList(userId, _shopId.value)
            editPermissions = permissions.mapNotNull { entity ->
                try { Permission.valueOf(entity.permission) } catch (_: Exception) { null }
            }.toSet()
            editFullAccess = editPermissions.size == Permission.entries.size
        }
    }

    fun toggleEditFullAccess(enabled: Boolean) {
        editFullAccess = enabled
        editPermissions = if (enabled) Permission.entries.toSet() else emptySet()
    }

    fun toggleEditPermission(permission: Permission) {
        editPermissions = if (permission in editPermissions) {
            editPermissions - permission
        } else {
            editPermissions + permission
        }
        editFullAccess = editPermissions.size == Permission.entries.size
    }

    fun updatePermissions(userId: String, onSuccess: () -> Unit) {
        isLoading = true
        viewModelScope.launch {
            staffRepository.updatePermissions(userId, _shopId.value, editPermissions)
            isLoading = false
            onSuccess()
        }
    }

    fun deleteStaff(userId: String, onSuccess: () -> Unit) {
        viewModelScope.launch {
            staffRepository.deleteStaff(userId)
            onSuccess()
        }
    }

    private fun resetForm() {
        staffName = ""
        staffMobile = ""
        staffPassword = ""
        fullAccess = false
        selectedPermissions = emptySet()
    }

    fun clearError() { errorMessage = null }

    class Factory(
        private val staffRepository: StaffRepository,
        private val sessionManager: SessionManager
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return StaffViewModel(staffRepository, sessionManager) as T
        }
    }
}

package com.shopzo.app.features.backup.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.shopzo.app.core.security.SessionManager
import com.shopzo.app.features.backup.data.BackupRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class BackupUiState(
    val isLoading: Boolean = false,
    val exportedJson: String? = null,
    val successMessage: String? = null,
    val errorMessage: String? = null
)

class BackupViewModel(
    private val backupRepository: BackupRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(BackupUiState())
    val uiState: StateFlow<BackupUiState> = _uiState.asStateFlow()

    fun exportBackup() {
        val shopId = sessionManager.getCurrentShopId() ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null, successMessage = null)
            try {
                val json = backupRepository.exportBackup(shopId)
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    exportedJson = json,
                    successMessage = "Backup generated successfully!"
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "Failed to generate backup: ${e.message}"
                )
            }
        }
    }

    fun restoreBackup(backupJson: String) {
        val shopId = sessionManager.getCurrentShopId() ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null, successMessage = null)

            val validation = backupRepository.validateBackup(backupJson, shopId)
            if (validation.isFailure) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = validation.exceptionOrNull()?.message ?: "Invalid backup file"
                )
                return@launch
            }

            val backup = validation.getOrThrow()
            val result = backupRepository.restoreBackup(backup)

            if (result.isSuccess) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    successMessage = "Database restored successfully! All data has been updated."
                )
            } else {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "Restore failed: ${result.exceptionOrNull()?.message}"
                )
            }
        }
    }

    fun clearMessages() {
        _uiState.value = _uiState.value.copy(successMessage = null, errorMessage = null, exportedJson = null)
    }

    class Factory(
        private val backupRepository: BackupRepository,
        private val sessionManager: SessionManager
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return BackupViewModel(backupRepository, sessionManager) as T
        }
    }
}

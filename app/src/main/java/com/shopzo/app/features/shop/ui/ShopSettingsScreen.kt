package com.shopzo.app.features.shop.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.database.entity.ShopEntity
import com.shopzo.app.core.sync.SyncManager
import com.shopzo.app.core.sync.SyncState
import com.shopzo.app.core.sync.SyncStatusInfo
import com.shopzo.app.core.ui.components.SyncStatusBadge
import com.shopzo.app.features.backup.ui.BackupViewModel
import com.shopzo.app.features.shop.data.ShopRepository
import kotlinx.coroutines.flow.collectLatest

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShopSettingsScreen(
    shopId: String,
    shopRepository: ShopRepository,
    syncManager: SyncManager? = null,
    backupViewModel: BackupViewModel? = null,
    onNavigateBack: () -> Unit
) {
    var shop by remember { mutableStateOf<ShopEntity?>(null) }
    val syncStatusState by syncManager?.syncStatus?.collectAsState() ?: remember { mutableStateOf(SyncStatusInfo()) }
    val backupUiState by backupViewModel?.uiState?.collectAsState() ?: remember { mutableStateOf(com.shopzo.app.features.backup.ui.BackupUiState()) }

    var showRestoreConfirmDialog by remember { mutableStateOf(false) }

    LaunchedEffect(shopId) {
        shopRepository.getShopFlow(shopId).collectLatest { shop = it }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Shop Settings") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    SyncStatusBadge(state = syncStatusState.state, modifier = Modifier.padding(end = 12.dp))
                }
            )
        }
    ) { padding ->
        shop?.let { s ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .verticalScroll(rememberScrollState())
                    .padding(24.dp)
            ) {
                // Success / Error Banners for Backup & Sync
                backupUiState.successMessage?.let { msg ->
                    Card(
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer),
                        modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp)
                    ) {
                        Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Outlined.CheckCircle, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(msg, style = MaterialTheme.typography.bodyMedium)
                        }
                    }
                }
                backupUiState.errorMessage?.let { err ->
                    Card(
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer),
                        modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp)
                    ) {
                        Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Outlined.Error, contentDescription = null, tint = MaterialTheme.colorScheme.error)
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(err, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onErrorContainer)
                        }
                    }
                }

                // Shop Code Card
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
                ) {
                    Column(
                        modifier = Modifier.padding(20.dp).fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text("Shop Code", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onPrimaryContainer)
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = s.shopCode,
                            style = MaterialTheme.typography.headlineMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                // Cloud & Synchronization Section
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Outlined.CloudSync, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Cloud Sync", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                            }
                            SyncStatusBadge(state = syncStatusState.state)
                        }

                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = syncStatusState.message,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )

                        Spacer(modifier = Modifier.height(12.dp))
                        Button(
                            onClick = { syncManager?.syncNow() },
                            modifier = Modifier.fillMaxWidth(),
                            enabled = syncStatusState.state != SyncState.SYNCING
                        ) {
                            Icon(Icons.Outlined.Sync, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Sync Now")
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                // Database Backup & Restore Section
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Outlined.Backup, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Database Backup & Restore", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                        }

                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Export a safe versioned backup of products, sales, customers, and financial records or restore data.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )

                        Spacer(modifier = Modifier.height(12.dp))
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            OutlinedButton(
                                onClick = { backupViewModel?.exportBackup() },
                                modifier = Modifier.weight(1f),
                                enabled = !backupUiState.isLoading
                            ) {
                                Icon(Icons.Outlined.Download, contentDescription = null, modifier = Modifier.size(18.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Export")
                            }

                            Button(
                                onClick = { showRestoreConfirmDialog = true },
                                modifier = Modifier.weight(1f),
                                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary),
                                enabled = !backupUiState.isLoading
                            ) {
                                Icon(Icons.Outlined.Upload, contentDescription = null, modifier = Modifier.size(18.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Restore")
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Shop Details
                Text("Shop Details", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Spacer(modifier = Modifier.height(16.dp))

                ShopInfoRow(Icons.Outlined.Store, "Shop Name", s.shopName)
                ShopInfoRow(Icons.Outlined.Person, "Owner", s.ownerName)
                ShopInfoRow(Icons.Outlined.Phone, "Mobile", s.mobileNumber)
                if (!s.address.isNullOrBlank()) {
                    ShopInfoRow(Icons.Outlined.LocationOn, "Address", s.address)
                }
            }
        }
    }

    // Confirmation Dialog before Restore
    if (showRestoreConfirmDialog) {
        AlertDialog(
            onDismissRequest = { showRestoreConfirmDialog = false },
            title = { Text("Confirm Data Restore") },
            text = {
                Text("Restoring a database backup will update local products, customers, bills, and payments. Are you sure you want to proceed?")
            },
            confirmButton = {
                Button(
                    onClick = {
                        showRestoreConfirmDialog = false
                        backupUiState.exportedJson?.let { json ->
                            backupViewModel?.restoreBackup(json)
                        } ?: run {
                            backupViewModel?.exportBackup()
                        }
                    }
                ) {
                    Text("Proceed & Restore")
                }
            },
            dismissButton = {
                TextButton(onClick = { showRestoreConfirmDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun ShopInfoRow(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, null, modifier = Modifier.size(20.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(modifier = Modifier.width(12.dp))
        Column {
            Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(value, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium)
        }
    }
}

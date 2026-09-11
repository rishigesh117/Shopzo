package com.shopzo.app.features.staff.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.model.Permission
import com.shopzo.app.core.model.PermissionGroup

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StaffPermissionsScreen(
    userId: String,
    viewModel: StaffViewModel,
    onNavigateBack: () -> Unit
) {
    LaunchedEffect(userId) { viewModel.loadStaffPermissions(userId) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Edit Permissions") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(24.dp)
        ) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = if (viewModel.editFullAccess) MaterialTheme.colorScheme.primaryContainer
                    else MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column {
                        Text("Full Access", fontWeight = FontWeight.SemiBold)
                        Text(
                            "Grant all permissions",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Switch(checked = viewModel.editFullAccess, onCheckedChange = { viewModel.toggleEditFullAccess(it) })
                }
            }

            if (!viewModel.editFullAccess) {
                Spacer(modifier = Modifier.height(16.dp))
                PermissionGroup.entries.forEach { group ->
                    val groupPermissions = Permission.entries.filter { it.group == group }
                    Text(
                        text = group.displayName,
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.padding(top = 12.dp, bottom = 4.dp)
                    )
                    groupPermissions.forEach { permission ->
                        Row(
                            modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(permission.displayName, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
                            Checkbox(
                                checked = permission in viewModel.editPermissions,
                                onCheckedChange = { viewModel.toggleEditPermission(permission) }
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = if (viewModel.editFullAccess) "Full Access" else "${viewModel.editPermissions.size} Permissions Enabled",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = { viewModel.updatePermissions(userId, onSuccess = onNavigateBack) },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = MaterialTheme.shapes.medium,
                enabled = !viewModel.isLoading
            ) {
                if (viewModel.isLoading) {
                    CircularProgressIndicator(Modifier.size(24.dp), MaterialTheme.colorScheme.onPrimary, strokeWidth = 2.dp)
                } else {
                    Text("Save Permissions", style = MaterialTheme.typography.titleMedium)
                }
            }
        }
    }
}

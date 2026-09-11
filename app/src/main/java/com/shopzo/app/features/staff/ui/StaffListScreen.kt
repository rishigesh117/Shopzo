package com.shopzo.app.features.staff.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.outlined.AdminPanelSettings
import androidx.compose.material.icons.outlined.People
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.Phone
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.ui.components.EmptyState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StaffListScreen(
    viewModel: StaffViewModel,
    onNavigateBack: () -> Unit,
    onNavigateToAddStaff: () -> Unit,
    onNavigateToPermissions: (String) -> Unit
) {
    val staffList by viewModel.staffList.collectAsState()
    var deleteUserId by remember { mutableStateOf<String?>(null) }

    if (deleteUserId != null) {
        AlertDialog(
            onDismissRequest = { deleteUserId = null },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.deleteStaff(deleteUserId!!) { deleteUserId = null }
                }) { Text("Delete", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = {
                TextButton(onClick = { deleteUserId = null }) { Text("Cancel") }
            },
            title = { Text("Delete Staff") },
            text = { Text("Are you sure you want to remove this staff member?") }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Manage Staff") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = onNavigateToAddStaff) {
                        Icon(Icons.Filled.Add, contentDescription = "Add Staff")
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = onNavigateToAddStaff) {
                Icon(Icons.Filled.Add, contentDescription = "Add Staff")
            }
        }
    ) { padding ->
        if (staffList.isEmpty()) {
            EmptyState(
                icon = Icons.Outlined.People,
                title = "No Staff Members",
                subtitle = "Tap + to add your first staff member",
                modifier = Modifier.padding(padding)
            )
        } else {
            LazyColumn(
                modifier = Modifier.padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(staffList, key = { it.id }) { staff ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = MaterialTheme.shapes.medium,
                        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                Icons.Outlined.Person,
                                contentDescription = null,
                                modifier = Modifier.size(40.dp),
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.width(16.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = staff.name,
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.SemiBold
                                )
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(
                                        Icons.Outlined.Phone,
                                        contentDescription = null,
                                        modifier = Modifier.size(14.dp),
                                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(
                                        text = staff.mobileNumber,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                            IconButton(onClick = { onNavigateToPermissions(staff.id) }) {
                                Icon(
                                    Icons.Outlined.AdminPanelSettings,
                                    contentDescription = "Permissions",
                                    tint = MaterialTheme.colorScheme.primary
                                )
                            }
                            IconButton(onClick = { deleteUserId = staff.id }) {
                                Icon(
                                    Icons.Filled.Delete,
                                    contentDescription = "Delete",
                                    tint = MaterialTheme.colorScheme.error
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

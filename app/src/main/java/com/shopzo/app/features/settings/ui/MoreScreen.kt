package com.shopzo.app.features.settings.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MoreScreen(
    onNavigateToStaff: () -> Unit,
    onNavigateToCategories: () -> Unit,
    onNavigateToShopSettings: () -> Unit,
    onLogout: () -> Unit
) {
    var showLogoutDialog by remember { mutableStateOf(false) }

    if (showLogoutDialog) {
        AlertDialog(
            onDismissRequest = { showLogoutDialog = false },
            confirmButton = {
                TextButton(onClick = { showLogoutDialog = false; onLogout() }) {
                    Text("Logout", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = { TextButton(onClick = { showLogoutDialog = false }) { Text("Cancel") } },
            title = { Text("Logout") },
            text = { Text("Are you sure you want to logout?") }
        )
    }

    Scaffold(
        topBar = { TopAppBar(title = { Text("More") }) }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
        ) {
            MoreMenuItem(
                icon = Icons.Outlined.People,
                title = "Manage Staff",
                subtitle = "Add, edit, and manage staff accounts",
                onClick = onNavigateToStaff
            )
            MoreMenuItem(
                icon = Icons.Outlined.Category,
                title = "Categories",
                subtitle = "Manage product categories",
                onClick = onNavigateToCategories
            )
            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
            MoreMenuItem(
                icon = Icons.Outlined.Payment,
                title = "Payments",
                subtitle = "Coming in Phase 2",
                onClick = {},
                enabled = false
            )
            MoreMenuItem(
                icon = Icons.Outlined.AssignmentReturn,
                title = "Returns",
                subtitle = "Coming in Phase 2",
                onClick = {},
                enabled = false
            )
            MoreMenuItem(
                icon = Icons.Outlined.Assessment,
                title = "Reports",
                subtitle = "Coming in Phase 2",
                onClick = {},
                enabled = false
            )
            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
            MoreMenuItem(
                icon = Icons.Outlined.Store,
                title = "Shop Settings",
                subtitle = "View shop information",
                onClick = onNavigateToShopSettings
            )
            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
            MoreMenuItem(
                icon = Icons.AutoMirrored.Outlined.Logout,
                title = "Logout",
                subtitle = "Sign out of your account",
                onClick = { showLogoutDialog = true },
                tint = MaterialTheme.colorScheme.error
            )
        }
    }
}

@Composable
fun MoreMenuItem(
    icon: ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit,
    enabled: Boolean = true,
    tint: androidx.compose.ui.graphics.Color = MaterialTheme.colorScheme.onSurface
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(24.dp),
            tint = if (enabled) tint else tint.copy(alpha = 0.4f)
        )
        Spacer(modifier = Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Medium,
                color = if (enabled) tint else tint.copy(alpha = 0.4f)
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = if (enabled) 1f else 0.4f)
            )
        }
    }
}

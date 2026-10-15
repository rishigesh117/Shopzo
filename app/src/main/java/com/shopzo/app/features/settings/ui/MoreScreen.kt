package com.shopzo.app.features.settings.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.AssignmentReturn
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.filled.Person
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
    userName: String = "",
    userRole: String = "OWNER",
    shopName: String = "",
    onNavigateToStaff: () -> Unit,
    onNavigateToCategories: () -> Unit,
    onNavigateToPayments: () -> Unit,
    onNavigateToReturns: () -> Unit,
    onNavigateToReports: () -> Unit,
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
        topBar = { TopAppBar(title = { Text("Settings & More", fontWeight = FontWeight.Bold) }) }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
        ) {
            // Profile Card showing logged in Owner Name and Role
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        shape = CircleShape,
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(52.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = Icons.Filled.Person,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onPrimary,
                                modifier = Modifier.size(32.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.width(16.dp))

                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = if (userName.isNotBlank()) userName else "Store Owner",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        val roleDisplay = if (userRole.equals("OWNER", ignoreCase = true)) "Owner" else "Staff"
                        val subtitle = if (shopName.isNotBlank()) "$roleDisplay • $shopName" else roleDisplay
                        Text(
                            text = subtitle,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.8f)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

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
                subtitle = "View payment history",
                onClick = onNavigateToPayments
            )
            MoreMenuItem(
                icon = Icons.AutoMirrored.Outlined.AssignmentReturn,
                title = "Returns",
                subtitle = "View product return history",
                onClick = onNavigateToReturns
            )
            MoreMenuItem(
                icon = Icons.Outlined.Assessment,
                title = "Reports",
                subtitle = "View sales, stock, and customer reports",
                onClick = onNavigateToReports
            )
            HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
            MoreMenuItem(
                icon = Icons.Outlined.Store,
                title = "Shop Settings",
                subtitle = "View shop details, owner info, and backup options",
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

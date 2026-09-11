package com.shopzo.app.features.dashboard.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shopzo.app.core.model.Permission
import com.shopzo.app.core.ui.components.PermissionGate
import com.shopzo.app.core.ui.theme.*
import com.shopzo.app.core.utils.MoneyUtils

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    viewModel: DashboardViewModel,
    onNavigateToProducts: () -> Unit,
    onNavigateToAddProduct: () -> Unit,
    onNavigateToNewBill: () -> Unit,
    onNavigateToCustomers: () -> Unit,
    onNavigateToReturns: () -> Unit,
    onNavigateToReports: () -> Unit,
    userName: String
) {
    val lowStock by viewModel.lowStockCount.collectAsState()
    val outOfStock by viewModel.outOfStockCount.collectAsState()
    val totalProducts by viewModel.totalProducts.collectAsState()
    val todaySales by viewModel.todaySalesReport.collectAsState()
    val totalDues by viewModel.totalOutstandingDues.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "Hello, $userName",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = "Welcome to SHOPZO",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                actions = {
                    IconButton(onClick = {}) {
                        Icon(Icons.Outlined.Notifications, contentDescription = "Notifications")
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
                .padding(horizontal = 16.dp)
        ) {
            Spacer(modifier = Modifier.height(8.dp))

            // Stat Cards Row 1: Real Sales & Real Bills today
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                DashboardStatCard(
                    title = "Today's Sales",
                    value = MoneyUtils.formatPaise(todaySales.totalSalesPaise),
                    icon = Icons.Outlined.CurrencyRupee,
                    color = Teal700,
                    modifier = Modifier.weight(1f)
                )
                DashboardStatCard(
                    title = "Today's Bills",
                    value = "${todaySales.billCount}",
                    icon = Icons.Outlined.Receipt,
                    color = Amber600,
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Stat Cards Row 2: Total Products & Outstanding Dues
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                DashboardStatCard(
                    title = "Total Products",
                    value = "$totalProducts",
                    icon = Icons.Outlined.Inventory2,
                    color = Color(0xFF5C6BC0),
                    modifier = Modifier.weight(1f),
                    onClick = onNavigateToProducts
                )
                DashboardStatCard(
                    title = "Pending Customer Dues",
                    value = MoneyUtils.formatPaise(totalDues),
                    icon = Icons.Outlined.AccountBalanceWallet,
                    color = StockRed,
                    modifier = Modifier.weight(1f),
                    onClick = onNavigateToCustomers
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Stock Alerts Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                DashboardStatCard(
                    title = "Low Stock",
                    value = "$lowStock",
                    icon = Icons.Outlined.Warning,
                    color = StockOrange,
                    modifier = Modifier.weight(1f),
                    onClick = onNavigateToProducts
                )
                DashboardStatCard(
                    title = "Out of Stock",
                    value = "$outOfStock",
                    icon = Icons.Outlined.RemoveShoppingCart,
                    color = StockRed,
                    modifier = Modifier.weight(1f),
                    onClick = onNavigateToProducts
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Quick Actions Title
            Text(
                text = "Quick Actions",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(modifier = Modifier.height(12.dp))

            // Row 1 Quick Actions: New Bill, Add Product, Restock, Customers
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                PermissionGate(permission = Permission.BILLING_CREATE) {
                    QuickActionCard(
                        title = "New Bill",
                        icon = Icons.Outlined.ReceiptLong,
                        color = Teal700,
                        modifier = Modifier.weight(1f),
                        onClick = onNavigateToNewBill
                    )
                }

                PermissionGate(permission = Permission.INVENTORY_ADD) {
                    QuickActionCard(
                        title = "Add Product",
                        icon = Icons.Filled.Add,
                        color = Color(0xFF5C6BC0),
                        modifier = Modifier.weight(1f),
                        onClick = onNavigateToAddProduct
                    )
                }

                PermissionGate(permission = Permission.INVENTORY_UPDATE_STOCK) {
                    QuickActionCard(
                        title = "Stock",
                        icon = Icons.Outlined.Inventory,
                        color = Amber600,
                        modifier = Modifier.weight(1f),
                        onClick = onNavigateToProducts
                    )
                }

                PermissionGate(permission = Permission.CUSTOMERS_VIEW) {
                    QuickActionCard(
                        title = "Customers",
                        icon = Icons.Outlined.People,
                        color = Color(0xFF8D6E63),
                        modifier = Modifier.weight(1f),
                        onClick = onNavigateToCustomers
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Row 2 Quick Actions: Returns, Reports
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                PermissionGate(permission = Permission.BILLING_VIEW) {
                    QuickActionCard(
                        title = "Returns",
                        icon = Icons.Outlined.Undo,
                        color = StockOrange,
                        modifier = Modifier.weight(1f),
                        onClick = onNavigateToReturns
                    )
                }

                PermissionGate(permission = Permission.REPORTS_VIEW) {
                    QuickActionCard(
                        title = "Reports",
                        icon = Icons.Outlined.BarChart,
                        color = Teal700,
                        modifier = Modifier.weight(1f),
                        onClick = onNavigateToReports
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}

@Composable
fun DashboardStatCard(
    title: String,
    value: String,
    icon: ImageVector,
    color: Color,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        onClick = onClick ?: {}
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(28.dp)
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = value,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = title,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
fun QuickActionCard(
    title: String,
    icon: ImageVector,
    color: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = color.copy(alpha = 0.1f)),
        onClick = onClick
    ) {
        Column(
            modifier = Modifier.padding(12.dp).fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(28.dp)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = title,
                style = MaterialTheme.typography.labelMedium,
                color = color,
                fontWeight = FontWeight.Medium
            )
        }
    }
}
